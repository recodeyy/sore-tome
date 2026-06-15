import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx, ensureAccount, postJournal, prorateMinor } from "./ledger";

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
  /** Cap 31 — GST rate (percent, e.g. 18). If set and taxMinor omitted, tax is derived. */
  taxRate?: number;
  /** Cap 29 — when present, the line amount is prorated to the occupied days. */
  proration?: {
    periodStart: string;
    periodEnd: string;
    occupancyStart?: string | null;
    occupancyEnd?: string | null;
  };
};

/**
 * Generates a sequential document number (e.g. CN-000007, RCPT-000012) scoped to
 * the society. Uses a per-society advisory lock on the running transaction so two
 * concurrent issuers cannot collide; the unique index is the final guard.
 */
async function nextNumber(client: any, societyId: string, prefix: string): Promise<string> {
  const table = prefix === "CN" ? "credit_notes" : "receipts";
  await client.query(`SELECT pg_advisory_xact_lock(hashtext($1), hashtext($2))`, [societyId, prefix]);
  const { rows } = await client.query(
    `SELECT COALESCE(MAX((regexp_replace(number, '^${prefix}-', ''))::int), 0) AS n
     FROM ${table} WHERE society_id = $1 AND number ~ ('^${prefix}-[0-9]+$')`,
    [societyId]
  );
  const next = Number(rows[0].n) + 1;
  return `${prefix}-${String(next).padStart(6, "0")}`;
}

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
        let amount = qty * l.unitPriceMinor;
        // Cap 29 — prorate the taxable base before computing tax.
        if (l.proration) {
          amount = prorateMinor(
            amount,
            l.proration.periodStart,
            l.proration.periodEnd,
            l.proration.occupancyStart,
            l.proration.occupancyEnd
          ).amountMinor;
        }
        // Cap 31 — derive tax from rate when an explicit taxMinor is not supplied.
        const taxMinor =
          l.taxMinor != null
            ? l.taxMinor
            : l.taxRate
              ? Math.round((amount * l.taxRate) / 100)
              : 0;
        subtotal += amount;
        tax += taxMinor;
        return { ...l, qty, amount, taxableMinor: amount, taxMinor, taxRate: l.taxRate || 0 };
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
          `INSERT INTO invoice_lines (society_id, invoice_id, description, component, quantity, unit_price_minor, taxable_minor, tax_rate, tax_minor, amount_minor)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
          [societyId, invoice.id, l.description, l.component || null, l.qty, l.unitPriceMinor, l.taxableMinor, l.taxRate, l.taxMinor, l.amount]
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

      // Cap 35 — issue a receipt on capture (idempotent via partial unique index).
      const rcptNo = await nextNumber(client, societyId, "RCPT");
      const rcpt = await client.query(
        `INSERT INTO receipts (society_id, number, payment_id, amount_minor, status, created_by)
         VALUES ($1, $2, $3, $4, 'issued', $5)
         ON CONFLICT (society_id, payment_id) WHERE status = 'issued' DO NOTHING
         RETURNING *`,
        [societyId, rcptNo, payment.id, input.amountMinor, input.metadata?.createdBy || null]
      );

      logger.info({ societyId, paymentId: payment.id, invoiceId: invoice.id, amount: input.amountMinor }, "Payment recorded + ledger posted");
      return { payment, duplicate: false, receipt: rcpt.rows[0] || null };
    });
  },

  /**
   * Cap 30 — Applies a configurable late fee to an overdue published invoice.
   * Idempotent: a second call is a no-op while a fee is already applied.
   * Posts Dr A/R, Cr Penalty Income and records the fee on the invoice.
   */
  async applyLateFee(
    societyId: string,
    invoiceId: string,
    input: { feeMinor: number; asOf?: string }
  ) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM invoices WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [invoiceId, societyId]
      );
      const inv = rows[0];
      if (!inv) throw Object.assign(new Error("Invoice not found"), { code: "NOT_FOUND" });
      if (inv.status !== "published") {
        throw Object.assign(new Error("Late fee applies to published invoices only"), { code: "INVALID_STATE" });
      }
      if (inv.late_fee_applied_at) return { invoice: inv, applied: false };

      const asOf = input.asOf ? new Date(input.asOf) : new Date();
      if (inv.due_date && new Date(inv.due_date) >= asOf) {
        throw Object.assign(new Error("Invoice is not overdue"), { code: "INVALID_STATE" });
      }

      const ar = await ensureAccount(client, societyId, "1100", "Accounts Receivable", "asset");
      const penalty = await ensureAccount(client, societyId, "4100", "Penalty Income", "income");
      await postJournal(
        client,
        societyId,
        { memo: `Late fee ${inv.number}`, sourceType: "late_fee", sourceId: inv.id },
        [
          { accountId: ar, debitMinor: input.feeMinor },
          { accountId: penalty, creditMinor: input.feeMinor },
        ]
      );

      const upd = await client.query(
        `UPDATE invoices
         SET late_fee_minor = $3, total_minor = total_minor + $3,
             late_fee_applied_at = now(), version = version + 1, updated_at = now()
         WHERE id = $1 AND society_id = $2 RETURNING *`,
        [invoiceId, societyId, input.feeMinor]
      );
      logger.info({ societyId, invoiceId, fee: input.feeMinor }, "Late fee applied");
      return { invoice: upd.rows[0], applied: true };
    });
  },

  /**
   * Cap 30 — Waives a previously applied late fee. Reverses the ledger
   * (Dr Penalty Income, Cr A/R) with an audit reason. Idempotent.
   */
  async waiveLateFee(societyId: string, invoiceId: string, input: { reason: string; waivedBy?: string }) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM invoices WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [invoiceId, societyId]
      );
      const inv = rows[0];
      if (!inv) throw Object.assign(new Error("Invoice not found"), { code: "NOT_FOUND" });
      const fee = Number(inv.late_fee_minor);
      if (!inv.late_fee_applied_at || fee <= 0) return { invoice: inv, waived: false };

      const ar = await ensureAccount(client, societyId, "1100", "Accounts Receivable", "asset");
      const penalty = await ensureAccount(client, societyId, "4100", "Penalty Income", "income");
      await postJournal(
        client,
        societyId,
        { memo: `Waive late fee ${inv.number}: ${input.reason}`, sourceType: "late_fee_waiver", sourceId: inv.id, createdBy: input.waivedBy },
        [
          { accountId: penalty, debitMinor: fee },
          { accountId: ar, creditMinor: fee },
        ]
      );

      const upd = await client.query(
        `UPDATE invoices
         SET late_fee_minor = 0, total_minor = total_minor - $3,
             late_fee_applied_at = NULL, version = version + 1, updated_at = now()
         WHERE id = $1 AND society_id = $2 RETURNING *`,
        [invoiceId, societyId, fee]
      );
      logger.info({ societyId, invoiceId, fee, reason: input.reason }, "Late fee waived");
      return { invoice: upd.rows[0], waived: true };
    });
  },

  /**
   * Cap 31 — Issues an immutable credit note against a published invoice with its
   * own numbering and a tax breakdown. Posts Dr Income/Penalty, Cr A/R.
   */
  async createCreditNote(
    societyId: string,
    input: { invoiceId: string; reason: string; taxableMinor: number; taxMinor?: number; createdBy?: string }
  ) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM invoices WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [input.invoiceId, societyId]
      );
      const inv = rows[0];
      if (!inv) throw Object.assign(new Error("Invoice not found"), { code: "NOT_FOUND" });
      if (inv.status !== "published") {
        throw Object.assign(new Error("Credit notes apply to published invoices only"), { code: "INVALID_STATE" });
      }
      const taxMinor = input.taxMinor || 0;
      const total = input.taxableMinor + taxMinor;
      if (total <= 0) throw Object.assign(new Error("Credit note total must be positive"), { code: "VALIDATION" });
      if (total > Number(inv.total_minor)) {
        throw Object.assign(new Error("Credit note exceeds invoice total"), { code: "VALIDATION" });
      }

      const ar = await ensureAccount(client, societyId, "1100", "Accounts Receivable", "asset");
      const income = await ensureAccount(client, societyId, "4000", "Maintenance Income", "income");
      const jeId = await postJournal(
        client,
        societyId,
        { memo: `Credit note for ${inv.number}: ${input.reason}`, sourceType: "credit_note", sourceId: inv.id, createdBy: input.createdBy },
        [
          { accountId: income, debitMinor: total },
          { accountId: ar, creditMinor: total },
        ]
      );

      const number = await nextNumber(client, societyId, "CN");
      const cn = await client.query(
        `INSERT INTO credit_notes (society_id, number, invoice_id, reason, taxable_minor, tax_minor, total_minor, journal_entry_id, created_by)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *`,
        [societyId, number, inv.id, input.reason, input.taxableMinor, taxMinor, total, jeId, input.createdBy || null]
      );
      logger.info({ societyId, invoiceId: inv.id, creditNoteId: cn.rows[0].id, total }, "Credit note issued");
      return cn.rows[0];
    });
  },

  /**
   * Cap 28 — Generates the next period's recurring billing run. Idempotent on
   * (society, policyKey, period): a repeat returns the existing run unchanged.
   * Each member spec becomes a published invoice for the period.
   */
  async runRecurringBilling(
    societyId: string,
    input: {
      policyKey: string;
      period: string; // e.g. 2026-07
      numberPrefix: string;
      dueDate?: string;
      members: { unitId?: string; memberId?: string; lines: LineInput[] }[];
    },
    createdBy?: string
  ) {
    // Reserve the run idempotently first (unique on society+policy+period).
    const ins = await db.query(
      `INSERT INTO recurring_billing_runs (society_id, policy_key, period, status, created_by)
       VALUES ($1, $2, $3, 'running', $4)
       ON CONFLICT (society_id, policy_key, period) DO NOTHING
       RETURNING *`,
      [societyId, input.policyKey, input.period, createdBy || null]
    );
    if (ins.rows.length === 0) {
      const existing = await db.query(
        `SELECT * FROM recurring_billing_runs WHERE society_id = $1 AND policy_key = $2 AND period = $3`,
        [societyId, input.policyKey, input.period]
      );
      return { run: existing.rows[0], duplicate: true };
    }
    const run = ins.rows[0];

    try {
      let count = 0;
      for (let i = 0; i < input.members.length; i++) {
        const m = input.members[i];
        const invoice = await this.createInvoice(
          societyId,
          {
            number: `${input.numberPrefix}-${input.period}-${i + 1}`,
            unitId: m.unitId,
            memberId: m.memberId,
            period: input.period,
            dueDate: input.dueDate,
            lines: m.lines,
          },
          createdBy
        );
        await db.query(`UPDATE invoices SET recurring_run_id = $1 WHERE id = $2 AND society_id = $3`, [run.id, invoice.id, societyId]);
        await this.publishInvoice(societyId, invoice.id);
        count++;
      }
      const upd = await db.query(
        `UPDATE recurring_billing_runs SET status = 'completed', invoices_created = $2, completed_at = now()
         WHERE id = $1 RETURNING *`,
        [run.id, count]
      );
      logger.info({ societyId, runId: run.id, period: input.period, count }, "Recurring billing run completed");
      return { run: upd.rows[0], duplicate: false };
    } catch (err) {
      await db.query(`UPDATE recurring_billing_runs SET status = 'failed' WHERE id = $1`, [run.id]);
      throw err;
    }
  },

  /**
   * Cap 35 — Voids a receipt (audit reason) and optionally reissues a fresh one
   * for the same payment. Reissue is blocked while a live receipt exists.
   */
  async voidReceipt(societyId: string, receiptId: string, input: { reason: string; reissue?: boolean; voidedBy?: string }) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM receipts WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [receiptId, societyId]
      );
      const rcpt = rows[0];
      if (!rcpt) throw Object.assign(new Error("Receipt not found"), { code: "NOT_FOUND" });
      if (rcpt.status === "void") throw Object.assign(new Error("Receipt already void"), { code: "INVALID_STATE" });

      const voided = await client.query(
        `UPDATE receipts SET status = 'void', void_reason = $3, voided_at = now()
         WHERE id = $1 AND society_id = $2 RETURNING *`,
        [receiptId, societyId, input.reason]
      );

      let reissued = null;
      if (input.reissue) {
        const number = await nextNumber(client, societyId, "RCPT");
        const ri = await client.query(
          `INSERT INTO receipts (society_id, number, payment_id, amount_minor, status, reissued_from, created_by)
           VALUES ($1, $2, $3, $4, 'issued', $5, $6) RETURNING *`,
          [societyId, number, rcpt.payment_id, rcpt.amount_minor, rcpt.id, input.voidedBy || null]
        );
        reissued = ri.rows[0];
      }
      logger.info({ societyId, receiptId, reissue: !!input.reissue }, "Receipt voided");
      return { voided: voided.rows[0], reissued };
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
