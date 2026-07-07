import "dotenv/config";
import { describe, it, expect, afterAll, beforeAll } from "@jest/globals";
import crypto from "crypto";
import { FinanceService } from "../src/services/finance/FinanceService";
import { RazorpayWebhookService } from "../src/services/payment/RazorpayWebhookService";
import { ReceiptPdfService } from "../src/services/finance/ReceiptPdfService";
import { db, dbManager } from "../src/shared/Database";

/**
 * §7.2/§13 demo payment stack:
 *  - checkout verify idempotency (duplicate verify → ONE payment row / ledger effect)
 *  - webhook + verify double delivery for the SAME gateway payment → still one effect
 *  - receipt auto-generation + PDF bytes (%PDF) with TEST MODE watermark data
 *  - UPI demo mark-paid (one financial effect, audit row, idempotent on reference)
 *  - dues reminders (once per invoice per day, notification rows written)
 */

const KEY_SECRET = "test_key_secret_demo";
const WH_SECRET = "test_webhook_secret_demo";
process.env.RAZORPAY_KEY_ID = "rzp_test_demo123";
process.env.RAZORPAY_KEY_SECRET = KEY_SECRET;
process.env.RAZORPAY_WEBHOOK_SECRET = WH_SECRET;

const SOC = `test-paydemo-${Date.now()}`;

const checkoutSig = (orderId: string, paymentId: string) =>
  crypto.createHmac("sha256", KEY_SECRET).update(`${orderId}|${paymentId}`).digest("hex");
const webhookSig = (body: string) => crypto.createHmac("sha256", WH_SECRET).update(body).digest("hex");

let seq = 0;
async function makePublishedInvoice(totalMinor = 50000) {
  const invoice = await FinanceService.createInvoice(SOC, {
    number: `INV-PD-${Date.now()}-${seq++}`,
    lines: [{ description: "Maintenance", unitPriceMinor: totalMinor }],
  });
  await FinanceService.publishInvoice(SOC, invoice.id);
  return invoice;
}

async function seedOrderIntent(orderId: string, invoiceId: string, amountMinor: number) {
  await db.query(
    `INSERT INTO payments (society_id, provider, amount_minor, currency, status, idempotency_key, metadata)
     VALUES ($1,'razorpay',$2,'INR','pending',$3,$4) ON CONFLICT DO NOTHING`,
    [SOC, amountMinor, `rzp_order:${orderId}`, JSON.stringify({ orderId, invoiceId })]
  );
}

async function paymentCount(providerPaymentId: string) {
  const { rows } = await db.query(
    `SELECT count(*)::int n FROM payments WHERE society_id = $1 AND provider_payment_id = $2 AND status = 'captured'`,
    [SOC, providerPaymentId]
  );
  return rows[0].n;
}

afterAll(async () => {
  for (const t of [
    "demo_payment_audits", "outbox_events", "notifications", "receipts", "payment_allocations", "payments",
    "journal_lines", "journal_entries", "invoice_lines", "invoices", "chart_of_accounts",
  ]) {
    await db.query(`DELETE FROM ${t} WHERE society_id = $1`, [SOC]);
  }
  await db.query(`DELETE FROM payment_webhook_events WHERE society_id = $1`, [SOC]);
  await dbManager.close();
});

describe("Razorpay checkout verify idempotency", () => {
  it("applies a duplicate verify exactly once (one payment row, one receipt, balanced ledger)", async () => {
    const invoice = await makePublishedInvoice(45000);
    const orderId = `order_demo_${Date.now()}`;
    const paymentId = `pay_demo_${Date.now()}`;
    await seedOrderIntent(orderId, invoice.id, 45000);

    const input = { orderId, paymentId, signature: checkoutSig(orderId, paymentId) };
    const first = await FinanceService.confirmRazorpayPayment(SOC, input);
    expect(first.duplicate).toBe(false);
    expect(first.receipt).toBeTruthy();

    const second = await FinanceService.confirmRazorpayPayment(SOC, input);
    expect(second.duplicate).toBe(true);

    expect(await paymentCount(paymentId)).toBe(1);

    const receipts = await db.query(
      `SELECT count(*)::int n FROM receipts r JOIN payments p ON p.id = r.payment_id
       WHERE r.society_id = $1 AND p.provider_payment_id = $2 AND r.status = 'issued'`,
      [SOC, paymentId]
    );
    expect(receipts.rows[0].n).toBe(1);

    const bal = await db.query(
      `SELECT COALESCE(SUM(debit_minor),0)::bigint d, COALESCE(SUM(credit_minor),0)::bigint c
       FROM journal_lines WHERE society_id = $1`, [SOC]
    );
    expect(Number(bal.rows[0].d)).toBe(Number(bal.rows[0].c));
  });

  it("rejects a bad signature", async () => {
    await expect(
      FinanceService.confirmRazorpayPayment(SOC, { orderId: "order_x", paymentId: "pay_x", signature: "bad" })
    ).rejects.toMatchObject({ code: "BAD_SIGNATURE" });
  });

  it("webhook delivery after checkout verify for the SAME gateway payment adds no second effect", async () => {
    const invoice = await makePublishedInvoice(30000);
    const orderId = `order_both_${Date.now()}`;
    const paymentId = `pay_both_${Date.now()}`;
    await seedOrderIntent(orderId, invoice.id, 30000);

    await FinanceService.confirmRazorpayPayment(SOC, { orderId, paymentId, signature: checkoutSig(orderId, paymentId) });

    const event = {
      event: "payment.captured",
      payload: { payment: { entity: { id: paymentId, order_id: orderId, amount: 30000, notes: { societyId: SOC, invoiceId: invoice.id } } } },
    };
    const raw = JSON.stringify(event);
    const res = await RazorpayWebhookService.handle(raw, webhookSig(raw), `evt_both_${Date.now()}`);
    expect(res.processed).toBe(true);

    expect(await paymentCount(paymentId)).toBe(1);
    expect(await FinanceService.outstandingMinor(db, SOC, invoice.id)).toBe(0);
  });
});

describe("Receipts", () => {
  it("auto-generates a numbered receipt on capture and renders a %PDF with TEST MODE watermark", async () => {
    const invoice = await makePublishedInvoice(20000);
    const { receipt } = await FinanceService.recordPayment(SOC, {
      idempotencyKey: `manual:${Date.now()}`,
      invoiceId: invoice.id,
      amountMinor: 20000,
      provider: "upi_demo",
      providerPaymentId: `UTR-${Date.now()}`,
      metadata: { testMode: true },
    }) as any;
    expect(receipt).toBeTruthy();
    expect(receipt.number).toMatch(/^RCPT-\d{6}$/);

    const list = await FinanceService.listReceipts(SOC, { limit: 10 });
    expect(list.some((r: any) => r.id === receipt.id)).toBe(true);

    const detail = await FinanceService.getReceiptDetail(SOC, receipt.id);
    expect(detail).toBeTruthy();
    expect(ReceiptPdfService.isTestPayment(detail!)).toBe(true);
    const pdf = await ReceiptPdfService.render(detail!);
    expect(Buffer.from(pdf.slice(0, 4)).toString()).toBe("%PDF");
    expect(pdf.length).toBeGreaterThan(500);
  });
});

describe("UPI demo mark-paid", () => {
  it("settles the invoice once (idempotent on reference) and writes an audit row", async () => {
    const invoice = await makePublishedInvoice(60000);

    const first = await FinanceService.markInvoicePaidDemo(SOC, {
      invoiceId: invoice.id, reference: "UTR123456", actorId: "test-admin",
    });
    expect(first.duplicate).toBe(false);
    expect(first.amountMinor).toBe(60000);
    expect(first.receipt).toBeTruthy();

    const second = await FinanceService.markInvoicePaidDemo(SOC, {
      invoiceId: invoice.id, reference: "UTR123456", actorId: "test-admin",
    });
    expect(second.duplicate).toBe(true);

    expect(await paymentCount("UTR123456")).toBe(1);
    expect(await FinanceService.outstandingMinor(db, SOC, invoice.id)).toBe(0);

    const audits = await db.query(
      `SELECT * FROM demo_payment_audits WHERE society_id = $1 AND invoice_id = $2`, [SOC, invoice.id]
    );
    expect(audits.rows.length).toBeGreaterThanOrEqual(1);
    expect(audits.rows[0].reference).toBe("UTR123456");
    expect(audits.rows[0].actor_id).toBe("test-admin");
  });
});

describe("Dues reminders", () => {
  it("notifies overdue invoices at most once per day", async () => {
    // Overdue invoice billed to a member with a login so a notification lands.
    const memberId = crypto.randomUUID();
    await db.query(
      `INSERT INTO members (id, society_id, user_id, name, phone, status, role)
       VALUES ($1, $2, 'test-paydemo-user', 'Overdue Resident', '9998887770', 'approved', 'resident')`,
      [memberId, SOC]
    );
    const invoice = await FinanceService.createInvoice(SOC, {
      number: `INV-PD-OD-${Date.now()}`,
      memberId,
      dueDate: "2026-01-31",
      lines: [{ description: "Maintenance", unitPriceMinor: 40000 }],
    });
    await FinanceService.publishInvoice(SOC, invoice.id);

    const run1 = await FinanceService.runDuesReminders(SOC);
    expect(run1.reminded).toBeGreaterThanOrEqual(1);
    expect(run1.invoices.some((i: any) => i.invoiceId === invoice.id && i.notified >= 1)).toBe(true);

    const notif = await db.query(
      `SELECT * FROM notifications WHERE society_id = $1 AND user_id = 'test-paydemo-user' AND type = 'billing'
        AND title = 'Dues reminder'`,
      [SOC]
    );
    expect(notif.rows.length).toBe(1);
    expect(notif.rows[0].data.deeplink).toBe("/resident/payments");

    // Same day again → no new reminder for this invoice.
    const run2 = await FinanceService.runDuesReminders(SOC);
    expect(run2.invoices.some((i: any) => i.invoiceId === invoice.id)).toBe(false);

    await db.query(`DELETE FROM members WHERE society_id = $1`, [SOC]);
  });
});
