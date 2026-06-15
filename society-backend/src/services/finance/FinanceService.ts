import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx, ensureAccount, postJournal } from "./ledger";

/**
 * Finance service: invoices + double-entry ledger + payments.
 * All money is in integer minor units (paise). Every posting balances.
 * Shared ledger primitives live in ./ledger.
 */

type LineInput = {
  description: string;
  component?: string;
  quantity?: number;
  unitPriceMinor: number;
  taxMinor?: number;
};

export const FinanceService = {
  /** Creates a draft invoice with lines. Totals are derived, never trusted from the client. */
  async createInvoice(
    societyId: string,
    input: { number: string; unitId?: string; memberId?: string; period?: string; dueDate?: string; lines: LineInput[] },
    createdBy?: string
  ) {
    return withTx(async (client) => {
      let subtotal = 0;
      let tax = 0;
      const computed = input.lines.map((l) => {
        const qty = l.quantity ?? 1;
        const amount = qty * l.unitPriceMinor;
        subtotal += amount;
        tax += l.taxMinor || 0;
        return { ...l, qty, amount };
      });
      const total = subtotal + tax;

      const { rows } = await client.query(
        `INSERT INTO invoices (society_id, number, unit_id, member_id, period, status,
            subtotal_minor, tax_minor, total_minor, due_date, created_by)
         VALUES ($1, $2, $3, $4, $5, 'draft', $6, $7, $8, $9, $10)
         RETURNING *`,
        [societyId, input.number, input.unitId || null, input.memberId || null, input.period || null,
         subtotal, tax, total, input.dueDate || null, createdBy || null]
      );
      const invoice = rows[0];

      for (const l of computed) {
        await client.query(
          `INSERT INTO invoice_lines (society_id, invoice_id, description, component, quantity, unit_price_minor, tax_minor, amount_minor)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
          [societyId, invoice.id, l.description, l.component || null, l.qty, l.unitPriceMinor, l.taxMinor || 0, l.amount]
        );
      }

      logger.info({ societyId, invoiceId: invoice.id, total }, "Invoice draft created");
      return invoice;
    });
  },

  /** Publishes a draft invoice and posts Dr A/R, Cr Income atomically. Idempotent on already-published. */
  async publishInvoice(societyId: string, invoiceId: string) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM invoices WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [invoiceId, societyId]
      );
      const invoice = rows[0];
      if (!invoice) throw Object.assign(new Error("Invoice not found"), { code: "NOT_FOUND" });
      if (invoice.status === "published") return invoice;
      if (invoice.status !== "draft") {
        throw Object.assign(new Error(`Cannot publish a ${invoice.status} invoice`), { code: "INVALID_STATE" });
      }

      const ar = await ensureAccount(client, societyId, "1100", "Accounts Receivable", "asset");
      const income = await ensureAccount(client, societyId, "4000", "Maintenance Income", "income");

      await postJournal(
        client,
        societyId,
        { memo: `Invoice ${invoice.number}`, sourceType: "invoice", sourceId: invoice.id, createdBy: invoice.created_by },
        [
          { accountId: ar, debitMinor: invoice.total_minor },
          { accountId: income, creditMinor: invoice.total_minor },
        ]
      );

      const upd = await client.query(
        `UPDATE invoices SET status = 'published', published_at = now(), version = version + 1, updated_at = now()
         WHERE id = $1 AND society_id = $2 RETURNING *`,
        [invoiceId, societyId]
      );
      logger.info({ societyId, invoiceId, total: invoice.total_minor }, "Invoice published + ledger posted");
      return upd.rows[0];
    });
  },

  /**
   * Records a payment and allocates it to an invoice, posting Dr Cash, Cr A/R.
   * Idempotent via idempotencyKey: a repeat returns the existing payment with no duplicate effect.
   */
  async recordPayment(
    societyId: string,
    input: { idempotencyKey: string; invoiceId: string; amountMinor: number; provider?: string; providerPaymentId?: string; metadata?: any }
  ) {
    return withTx(async (client) => {
      const existing = await client.query(
        `SELECT * FROM payments WHERE society_id = $1 AND idempotency_key = $2`,
        [societyId, input.idempotencyKey]
      );
      if (existing.rows.length > 0) {
        return { payment: existing.rows[0], duplicate: true };
      }

      const inv = await client.query(
        `SELECT * FROM invoices WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [input.invoiceId, societyId]
      );
      const invoice = inv.rows[0];
      if (!invoice) throw Object.assign(new Error("Invoice not found"), { code: "NOT_FOUND" });

      const pay = await client.query(
        `INSERT INTO payments (society_id, provider, provider_payment_id, amount_minor, status, idempotency_key, metadata)
         VALUES ($1, $2, $3, $4, 'captured', $5, $6)
         RETURNING *`,
        [societyId, input.provider || "manual", input.providerPaymentId || null, input.amountMinor,
         input.idempotencyKey, input.metadata ? JSON.stringify(input.metadata) : null]
      );
      const payment = pay.rows[0];

      await client.query(
        `INSERT INTO payment_allocations (society_id, payment_id, invoice_id, amount_minor)
         VALUES ($1, $2, $3, $4)`,
        [societyId, payment.id, invoice.id, input.amountMinor]
      );

      const cash = await ensureAccount(client, societyId, "1000", "Cash/Bank", "asset");
      const ar = await ensureAccount(client, societyId, "1100", "Accounts Receivable", "asset");

      await postJournal(
        client,
        societyId,
        { memo: `Payment for ${invoice.number}`, sourceType: "payment", sourceId: payment.id },
        [
          { accountId: cash, debitMinor: input.amountMinor },
          { accountId: ar, creditMinor: input.amountMinor },
        ]
      );

      logger.info({ societyId, paymentId: payment.id, invoiceId: invoice.id, amount: input.amountMinor }, "Payment recorded + ledger posted");
      return { payment, duplicate: false };
    });
  },

  async getInvoice(societyId: string, invoiceId: string) {
    const inv = await db.query(`SELECT * FROM invoices WHERE id = $1 AND society_id = $2`, [invoiceId, societyId]);
    if (inv.rows.length === 0) return null;
    const lines = await db.query(
      `SELECT * FROM invoice_lines WHERE invoice_id = $1 AND society_id = $2 ORDER BY id`,
      [invoiceId, societyId]
    );
    return { ...inv.rows[0], lines: lines.rows };
  },

  async listInvoices(societyId: string, opts: { status?: string; limit?: number } = {}) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.status) {
      params.push(opts.status);
      where += ` AND status = $${params.length}`;
    }
    params.push(Math.min(opts.limit || 50, 200));
    const { rows } = await db.query(
      `SELECT * FROM invoices WHERE ${where} ORDER BY created_at DESC LIMIT $${params.length}`,
      params
    );
    return rows;
  },
};
