import crypto from "crypto";
import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx, ensureAccount, postJournal, prorateMinor } from "./ledger";
import { PaymentService } from "../payment/PaymentService";
import { isRazorpayConfigured, isRazorpayTestMode } from "../payment/RazorpayProvider";
import { Recipients } from "../notifications/Recipients";

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

/**
 * §10 notification triggers — resolve who should be notified about an invoice:
 * the billed member's login (invoices.member_id -> members.user_id) plus the
 * billed unit's residents. De-duplicated by Recipients.fanOut.
 */
async function invoiceRecipients(client: any, societyId: string, invoice: any): Promise<string[]> {
  const out: string[] = [];
  try {
    if (invoice.member_id) {
      const m = await client.query(
        `SELECT user_id FROM members WHERE society_id = $1 AND id::text = $2::text AND user_id IS NOT NULL`,
        [societyId, String(invoice.member_id)]
      );
      if (m.rows[0]?.user_id) out.push(m.rows[0].user_id);
    }
    if (invoice.unit_id) {
      out.push(...await Recipients.unitResidentUserIds(client, societyId, invoice.unit_id));
    }
  } catch (e: any) {
    logger.warn({ societyId, invoiceId: invoice.id, error: e.message }, "invoiceRecipients resolution failed");
  }
  return Array.from(new Set(out));
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

      // §10 trigger: invoice published → notify the billed resident(s).
      const recipients = await invoiceRecipients(client, societyId, upd.rows[0]);
      if (recipients.length) {
        await Recipients.fanOut(client, {
          societyId,
          eventType: "invoice.published",
          payload: { id: invoice.id, number: invoice.number, totalMinor: Number(invoice.total_minor) },
          recipients,
          notification: {
            title: "New invoice",
            body: `Invoice ${invoice.number}${invoice.period ? ` for ${invoice.period}` : ""} of ₹${(Number(invoice.total_minor) / 100).toFixed(2)} is due${invoice.due_date ? ` by ${new Date(invoice.due_date).toISOString().slice(0, 10)}` : ""}.`,
            type: "billing",
            data: { invoiceId: invoice.id, number: invoice.number, deeplink: `/billing/invoices/${invoice.id}` },
          },
        });
      }
      logger.info({ societyId, invoiceId, total: invoice.total_minor, notified: recipients.length }, "Invoice published + ledger posted");
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

      // §10 trigger: payment captured/verified → notify the billed resident(s).
      const recipients = await invoiceRecipients(client, societyId, invoice);
      if (recipients.length) {
        await Recipients.fanOut(client, {
          societyId,
          eventType: "payment.captured",
          payload: { paymentId: payment.id, invoiceId: invoice.id, amountMinor: input.amountMinor },
          recipients,
          notification: {
            title: "Payment received",
            body: `Your payment of ₹${(input.amountMinor / 100).toFixed(2)} for invoice ${invoice.number} was verified. Receipt ${rcpt.rows[0]?.number || "issued"}.`,
            type: "billing",
            data: { paymentId: payment.id, invoiceId: invoice.id, deeplink: `/billing/invoices/${invoice.id}` },
          },
        });
      }

      logger.info({ societyId, paymentId: payment.id, invoiceId: invoice.id, amount: input.amountMinor, notified: recipients.length }, "Payment recorded + ledger posted");
      return { payment, duplicate: false, receipt: rcpt.rows[0] || null };
    });
  },

  /**
   * Computes how much of an invoice is still outstanding (minor units), as
   * total_minor minus the sum of captured payment allocations.
   */
  async outstandingMinor(client: any, societyId: string, invoiceId: string): Promise<number> {
    const { rows } = await client.query(
      `SELECT i.total_minor::bigint AS total,
              COALESCE((
                SELECT SUM(pa.amount_minor)::bigint
                  FROM payment_allocations pa
                  JOIN payments p ON p.id = pa.payment_id
                 WHERE pa.society_id = $1 AND pa.invoice_id = i.id AND p.status = 'captured'
              ), 0) AS paid
         FROM invoices i
        WHERE i.id = $2 AND i.society_id = $1`,
      [societyId, invoiceId]
    );
    if (rows.length === 0) throw Object.assign(new Error("Invoice not found"), { code: "NOT_FOUND" });
    return Number(rows[0].total) - Number(rows[0].paid);
  },

  /**
   * §12 / §6.2 — Creates a Razorpay TEST order for an invoice. The amount is
   * derived SERVER-SIDE from the invoice's outstanding balance; the client never
   * supplies it. A `pending` payment intent is recorded (idempotent per order),
   * so the resident sees "processing" until the payment is verified/captured.
   *
   * @returns the gateway order id + amount + key id (+ testMode flag) for checkout.
   * @throws { code: 'GATEWAY_DISABLED' } when Razorpay keys are absent.
   */
  async createPaymentOrder(
    societyId: string,
    invoiceId: string,
    opts: { createdBy?: string; payerMemberId?: string } = {}
  ) {
    if (!isRazorpayConfigured()) {
      throw Object.assign(new Error("Razorpay is not configured"), { code: "GATEWAY_DISABLED" });
    }

    // Validate the invoice and compute the server-side amount in one read.
    const inv = await db.query(
      `SELECT * FROM invoices WHERE id = $1 AND society_id = $2`,
      [invoiceId, societyId]
    );
    const invoice = inv.rows[0];
    if (!invoice) throw Object.assign(new Error("Invoice not found"), { code: "NOT_FOUND" });
    if (invoice.status !== "published") {
      throw Object.assign(new Error("Only a published invoice can be paid"), { code: "INVALID_STATE" });
    }
    const amountMinor = await this.outstandingMinor(db, societyId, invoiceId);
    if (amountMinor <= 0) {
      throw Object.assign(new Error("Invoice is already settled"), { code: "INVALID_STATE" });
    }

    const provider = PaymentService.getInstance().getProvider();
    // createOrder takes amount in standard units; receipt carries invoice number.
    const order = await provider.createOrder(amountMinor / 100, invoice.currency || "INR", invoice.number);

    // Record a pending intent keyed by the order id so a retry returns the same
    // intent and the resident UI can show "processing".
    await db.query(
      `INSERT INTO payments (society_id, provider, amount_minor, currency, status, idempotency_key, metadata)
       VALUES ($1, 'razorpay', $2, $3, 'pending', $4, $5)
       ON CONFLICT (society_id, idempotency_key) DO NOTHING`,
      [
        societyId,
        amountMinor,
        invoice.currency || "INR",
        `rzp_order:${order.id}`,
        JSON.stringify({ orderId: order.id, invoiceId, payerMemberId: opts.payerMemberId || null, createdBy: opts.createdBy || null }),
      ]
    );

    logger.info({ societyId, invoiceId, orderId: order.id, amountMinor }, "Razorpay order created (intent pending)");
    return {
      orderId: order.id,
      amountMinor,
      amount: amountMinor / 100,
      currency: invoice.currency || "INR",
      keyId: process.env.RAZORPAY_KEY_ID,
      invoiceId,
      invoiceNumber: invoice.number,
      status: "processing",
      testMode: isRazorpayTestMode(),
    };
  },

  /**
   * §12 / §6.2 — Authoritatively verifies a Razorpay checkout callback signature
   * server-side (HMAC-SHA256 of `order_id|payment_id` with the key secret), then
   * captures the payment via the transactional recordPayment path (payment +
   * allocation + ledger + receipt in ONE tx). Idempotent: a duplicate callback
   * for the same payment id produces exactly one financial effect.
   *
   * @throws { code: 'BAD_SIGNATURE' } on signature mismatch (caller → 400).
   */
  async confirmRazorpayPayment(
    societyId: string,
    input: { orderId: string; paymentId: string; signature: string; invoiceId?: string }
  ) {
    if (!isRazorpayConfigured()) {
      throw Object.assign(new Error("Razorpay is not configured"), { code: "GATEWAY_DISABLED" });
    }
    const { orderId, paymentId, signature } = input;
    if (!orderId || !paymentId || !signature) {
      throw Object.assign(new Error("Missing order/payment/signature"), { code: "BAD_SIGNATURE" });
    }

    const secret = process.env.RAZORPAY_KEY_SECRET as string;
    const expected = crypto.createHmac("sha256", secret).update(`${orderId}|${paymentId}`).digest("hex");
    const a = Buffer.from(expected);
    const b = Buffer.from(signature);
    if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) {
      logger.warn({ societyId, orderId }, "SEC-ALERT: Invalid Razorpay checkout signature");
      throw Object.assign(new Error("Invalid payment signature"), { code: "BAD_SIGNATURE" });
    }

    // Resolve the invoice from the pending intent recorded at order creation
    // (server-side source of truth) so the client cannot redirect funds.
    const intent = await db.query(
      `SELECT amount_minor, metadata FROM payments WHERE society_id = $1 AND idempotency_key = $2`,
      [societyId, `rzp_order:${orderId}`]
    );
    const invoiceId = input.invoiceId || intent.rows[0]?.metadata?.invoiceId;
    if (!invoiceId) {
      throw Object.assign(new Error("Unknown order; cannot resolve invoice"), { code: "NOT_FOUND" });
    }
    const amountMinor = Number(intent.rows[0]?.amount_minor) || (await this.outstandingMinor(db, societyId, invoiceId));

    // Capture via the existing idempotent transactional path, keyed by payment id.
    const result = await this.recordPayment(societyId, {
      idempotencyKey: `rzp:${paymentId}`,
      invoiceId,
      amountMinor,
      provider: "razorpay",
      providerPaymentId: paymentId,
      metadata: { orderId, source: "checkout_verify", testMode: isRazorpayTestMode() },
    });

    // Retire the pending intent once a real captured payment exists for this
    // order. The captured row (idempotency_key rzp:<paymentId>, with its
    // allocation + ledger + receipt) is the source of truth; mark the intent
    // 'failed' so it is not double-counted. Best-effort, safe to repeat.
    await db.query(
      `UPDATE payments SET status = 'failed'
        WHERE society_id = $1 AND idempotency_key = $2 AND status = 'pending'`,
      [societyId, `rzp_order:${orderId}`]
    );

    logger.info({ societyId, invoiceId, paymentId, duplicate: result.duplicate }, "Razorpay checkout verified + captured");
    return { ...result, invoiceId, testMode: isRazorpayTestMode() };
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

  /**
   * §13 demo — admin-only UPI-demo "mark paid". Settles an invoice's outstanding
   * balance through the normal recordPayment path (ONE financial effect:
   * payment + allocation + ledger + receipt, idempotent on the reference), and
   * writes a demo_payment_audits row (who/when/reference). Route gates this to
   * non-production / ADMIN_DEMO_MODE.
   */
  async markInvoicePaidDemo(
    societyId: string,
    input: { invoiceId: string; reference: string; actorId: string }
  ) {
    // Idempotency first: a repeat of the same invoice+reference returns the
    // existing payment (no second financial effect, no "already settled" error).
    const idempotencyKey = `upi-demo:${input.invoiceId}:${input.reference}`;
    const existing = await db.query(
      `SELECT * FROM payments WHERE society_id = $1 AND idempotency_key = $2`,
      [societyId, idempotencyKey]
    );
    if (existing.rows.length > 0) {
      return { payment: existing.rows[0], duplicate: true, amountMinor: Number(existing.rows[0].amount_minor), invoiceId: input.invoiceId };
    }

    const amountMinor = await this.outstandingMinor(db, societyId, input.invoiceId);
    if (amountMinor <= 0) {
      throw Object.assign(new Error("Invoice is already settled"), { code: "INVALID_STATE" });
    }
    const result = await this.recordPayment(societyId, {
      idempotencyKey,
      invoiceId: input.invoiceId,
      amountMinor,
      provider: "upi_demo",
      providerPaymentId: input.reference,
      metadata: { source: "upi_demo_mark_paid", reference: input.reference, markedBy: input.actorId, testMode: true },
    });
    await db.query(
      `INSERT INTO demo_payment_audits (society_id, invoice_id, payment_id, action, reference, actor_id)
       VALUES ($1, $2, $3, 'upi_demo_mark_paid', $4, $5)`,
      [societyId, input.invoiceId, result.payment.id, input.reference, input.actorId]
    );
    logger.info({ societyId, invoiceId: input.invoiceId, reference: input.reference, actor: input.actorId, duplicate: result.duplicate }, "UPI demo mark-paid");
    return { ...result, amountMinor, invoiceId: input.invoiceId };
  },

  /**
   * §7.2 receipts list. Admin/committee callers see the whole society;
   * a resident (userId set) sees only receipts whose paid invoice is billed to
   * their member record or unit.
   */
  async listReceipts(societyId: string, opts: { limit?: number; userId?: string } = {}) {
    const params: any[] = [societyId];
    let where = `r.society_id = $1`;
    if (opts.userId) {
      params.push(opts.userId);
      where += ` AND EXISTS (
        SELECT 1 FROM payment_allocations pa
        JOIN invoices i ON i.id = pa.invoice_id
        LEFT JOIN members m ON m.id::text = i.member_id::text AND m.society_id = i.society_id
        WHERE pa.payment_id = r.payment_id AND pa.society_id = r.society_id
          AND (m.user_id = $${params.length}
               OR i.unit_id::text IN (SELECT unit_id::text FROM members WHERE society_id = $1 AND user_id = $${params.length} AND unit_id IS NOT NULL))
      )`;
    }
    params.push(Math.min(opts.limit || 50, 200));
    const { rows } = await db.query(
      `SELECT r.*, p.provider, p.provider_payment_id, p.status AS payment_status, p.metadata AS payment_metadata,
              inv.id AS invoice_id, inv.number AS invoice_number, inv.period AS invoice_period
         FROM receipts r
         JOIN payments p ON p.id = r.payment_id
         LEFT JOIN LATERAL (
           SELECT i.id, i.number, i.period FROM payment_allocations pa
           JOIN invoices i ON i.id = pa.invoice_id
           WHERE pa.payment_id = r.payment_id AND pa.society_id = r.society_id
           LIMIT 1
         ) inv ON true
        WHERE ${where}
        ORDER BY r.created_at DESC
        LIMIT $${params.length}`,
      params
    );
    return rows;
  },

  /**
   * Full detail for one receipt (PDF rendering + API access checks):
   * receipt + payment + invoice(+lines) + society profile + unit + payer.
   * Returns null when not found in this society.
   */
  async getReceiptDetail(societyId: string, receiptId: string) {
    const { rows } = await db.query(
      `SELECT r.*, p.provider, p.provider_payment_id, p.status AS payment_status,
              p.metadata AS payment_metadata, p.created_at AS payment_created_at, p.currency AS payment_currency
         FROM receipts r JOIN payments p ON p.id = r.payment_id
        WHERE r.id = $1 AND r.society_id = $2`,
      [receiptId, societyId]
    );
    const receipt = rows[0];
    if (!receipt) return null;

    const alloc = await db.query(
      `SELECT i.* FROM payment_allocations pa JOIN invoices i ON i.id = pa.invoice_id
        WHERE pa.payment_id = $1 AND pa.society_id = $2 LIMIT 1`,
      [receipt.payment_id, societyId]
    );
    const invoice = alloc.rows[0] || null;
    let lines: any[] = [];
    let unit: any = null;
    let payer: any = null;
    if (invoice) {
      lines = (await db.query(
        `SELECT * FROM invoice_lines WHERE invoice_id = $1 AND society_id = $2 ORDER BY id`,
        [invoice.id, societyId]
      )).rows;
      if (invoice.unit_id) {
        unit = (await db.query(`SELECT number FROM units WHERE id::text = $1::text AND society_id = $2`, [String(invoice.unit_id), societyId])).rows[0] || null;
      }
      if (invoice.member_id) {
        payer = (await db.query(`SELECT name, phone, user_id FROM members WHERE id::text = $1::text AND society_id = $2`, [String(invoice.member_id), societyId])).rows[0] || null;
      }
    }
    const society = (await db.query(
      `SELECT name, address, registration_no FROM society_profiles WHERE society_id = $1`,
      [societyId]
    )).rows[0] || null;

    return { receipt, invoice, lines, unit, payer, society };
  },

  /**
   * §13 dues reminders — pushes a "dues reminder" (category billing, deeplink
   * /resident/payments) for every published invoice past its due date that still
   * has an outstanding balance. At most once per invoice per day, tracked via
   * invoices.last_reminded_at (claimed atomically so concurrent runs can't
   * double-send).
   */
  async runDuesReminders(societyId: string) {
    const { rows: due } = await db.query(
      `SELECT i.*,
              i.total_minor - COALESCE((
                SELECT SUM(pa.amount_minor) FROM payment_allocations pa
                JOIN payments p ON p.id = pa.payment_id
                WHERE pa.society_id = i.society_id AND pa.invoice_id = i.id AND p.status IN ('captured','verified')
              ), 0) AS outstanding_minor
         FROM invoices i
        WHERE i.society_id = $1 AND i.status = 'published'
          AND i.due_date IS NOT NULL AND i.due_date < current_date
          AND (i.last_reminded_at IS NULL OR i.last_reminded_at::date < current_date)`,
      [societyId]
    );

    let reminded = 0;
    const results: any[] = [];
    for (const inv of due) {
      const outstanding = Number(inv.outstanding_minor);
      if (outstanding <= 0) continue;
      await withTx(async (client) => {
        // Atomically claim today's reminder slot; skip if another run beat us.
        const claim = await client.query(
          `UPDATE invoices SET last_reminded_at = now()
            WHERE id = $1 AND society_id = $2
              AND (last_reminded_at IS NULL OR last_reminded_at::date < current_date)
            RETURNING id`,
          [inv.id, societyId]
        );
        if (claim.rows.length === 0) return;
        const recipients = await invoiceRecipients(client, societyId, inv);
        let notified = 0;
        if (recipients.length) {
          notified = await Recipients.fanOut(client, {
            societyId,
            eventType: "invoice.due_reminder",
            payload: { id: inv.id, number: inv.number, outstandingMinor: outstanding },
            recipients,
            notification: {
              title: "Dues reminder",
              body: `Invoice ${inv.number}${inv.period ? ` (${inv.period})` : ""} of ₹${(outstanding / 100).toFixed(2)} is overdue since ${new Date(inv.due_date).toISOString().slice(0, 10)}. Please pay to avoid late fees.`,
              type: "billing",
              data: { invoiceId: inv.id, number: inv.number, deeplink: `/resident/payments` },
            },
          });
        }
        reminded++;
        results.push({ invoiceId: inv.id, number: inv.number, outstandingMinor: outstanding, notified });
      });
    }
    logger.info({ societyId, checked: due.length, reminded }, "Dues reminder run completed");
    return { checked: due.length, reminded, invoices: results };
  },

  /** Cron entry point: run dues reminders for every society with overdue invoices. */
  async runDuesRemindersAll() {
    const { rows } = await db.query(
      `SELECT DISTINCT society_id FROM invoices
        WHERE status = 'published' AND due_date IS NOT NULL AND due_date < current_date
          AND (last_reminded_at IS NULL OR last_reminded_at::date < current_date)`
    );
    const out: Record<string, any> = {};
    for (const r of rows) {
      try {
        out[r.society_id] = await this.runDuesReminders(r.society_id);
      } catch (e: any) {
        logger.error({ societyId: r.society_id, error: e.message }, "Dues reminder run failed for society");
        out[r.society_id] = { error: e.message };
      }
    }
    return out;
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
