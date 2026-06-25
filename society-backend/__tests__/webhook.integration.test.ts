import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import crypto from "crypto";
import { FinanceService } from "../src/services/finance/FinanceService";
import { RazorpayWebhookService } from "../src/services/payment/RazorpayWebhookService";
import { db, dbManager } from "../src/shared/Database";

const SECRET = "test_secret_whsec";
process.env.RAZORPAY_WEBHOOK_SECRET = SECRET;
const SOC = `test-wh-${Date.now()}`;

const sign = (body: string) => crypto.createHmac("sha256", SECRET).update(body).digest("hex");

async function ledgerBalance(society: string) {
  const { rows } = await db.query(
    `SELECT COALESCE(SUM(debit_minor),0)::bigint d, COALESCE(SUM(credit_minor),0)::bigint c
     FROM journal_lines WHERE society_id = $1`,
    [society]
  );
  return { debit: Number(rows[0].d), credit: Number(rows[0].c) };
}

afterAll(async () => {
  await db.query(`DELETE FROM payment_webhook_events WHERE society_id = $1`, [SOC]);
  for (const t of ["payment_allocations", "payments", "journal_lines", "journal_entries", "invoice_lines", "invoices", "chart_of_accounts"]) {
    await db.query(`DELETE FROM ${t} WHERE society_id = $1`, [SOC]);
  }
  await dbManager.close();
});

describe("RazorpayWebhookService (integration)", () => {
  it("rejects an invalid signature", async () => {
    await expect(RazorpayWebhookService.handle("{}", "bad-signature")).rejects.toMatchObject({ code: "INVALID_SIGNATURE" });
  });

  it("processes a captured payment exactly once and ignores duplicate deliveries", async () => {
    const invoice = await FinanceService.createInvoice(SOC, {
      number: `INV-WH-${Date.now()}`,
      lines: [{ description: "Maintenance", unitPriceMinor: 45000 }],
    });
    await FinanceService.publishInvoice(SOC, invoice.id);

    const paymentId = `pay_${Date.now()}`;
    const event = {
      event: "payment.captured",
      payload: { payment: { entity: { id: paymentId, order_id: "order_x", amount: 45000, notes: { societyId: SOC, invoiceId: invoice.id } } } },
    };
    const raw = JSON.stringify(event);
    const sig = sign(raw);
    const eventId = `evt_${Date.now()}`;

    const first = await RazorpayWebhookService.handle(raw, sig, eventId);
    expect(first.processed).toBe(true);

    const second = await RazorpayWebhookService.handle(raw, sig, eventId);
    expect(second.duplicate).toBe(true);

    const { rows } = await db.query(
      `SELECT count(*)::int n FROM payments WHERE society_id = $1 AND provider_payment_id = $2`,
      [SOC, paymentId]
    );
    expect(rows[0].n).toBe(1);

    const bal = await ledgerBalance(SOC);
    expect(bal.debit).toBe(bal.credit);
  });
});
