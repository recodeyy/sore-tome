import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { FinanceService } from "../src/services/finance/FinanceService";
import { db, dbManager } from "../src/shared/Database";

// Real Postgres integration test (uses DATABASE_URL from .env / dev compose).
const SOC = `test-soc-${Date.now()}`;

async function ledgerBalance(society: string) {
  const { rows } = await db.query(
    `SELECT COALESCE(SUM(debit_minor),0)::bigint d, COALESCE(SUM(credit_minor),0)::bigint c
     FROM journal_lines WHERE society_id = $1`,
    [society]
  );
  return { debit: Number(rows[0].d), credit: Number(rows[0].c) };
}

afterAll(async () => {
  for (const t of ["receipts", "payment_allocations", "payments", "journal_lines", "journal_entries", "invoice_lines", "invoices", "chart_of_accounts"]) {
    await db.query(`DELETE FROM ${t} WHERE society_id = $1`, [SOC]);
  }
  await dbManager.close();
});

describe("FinanceService (integration)", () => {
  it("publishes a draft invoice and posts a balanced journal entry", async () => {
    const invoice = await FinanceService.createInvoice(SOC, {
      number: `INV-${Date.now()}`,
      lines: [{ description: "Maintenance", unitPriceMinor: 50000, taxMinor: 9000 }],
    });
    expect(invoice.status).toBe("draft");
    expect(Number(invoice.total_minor)).toBe(59000);

    const published = await FinanceService.publishInvoice(SOC, invoice.id);
    expect(published.status).toBe("published");

    const bal = await ledgerBalance(SOC);
    expect(bal.debit).toBe(bal.credit);
    expect(bal.debit).toBe(59000);
  });

  it("records a payment exactly once under a repeated idempotency key", async () => {
    const invoice = await FinanceService.createInvoice(SOC, {
      number: `INV-P-${Date.now()}`,
      lines: [{ description: "Maintenance", unitPriceMinor: 30000 }],
    });
    await FinanceService.publishInvoice(SOC, invoice.id);

    const key = `idem-${Date.now()}`;
    const first = await FinanceService.recordPayment(SOC, { idempotencyKey: key, invoiceId: invoice.id, amountMinor: 30000 });
    const second = await FinanceService.recordPayment(SOC, { idempotencyKey: key, invoiceId: invoice.id, amountMinor: 30000 });

    expect(first.duplicate).toBe(false);
    expect(second.duplicate).toBe(true);
    expect(second.payment.id).toBe(first.payment.id);

    const { rows } = await db.query(
      `SELECT count(*)::int n FROM payments WHERE society_id = $1 AND idempotency_key = $2`,
      [SOC, key]
    );
    expect(rows[0].n).toBe(1);

    // Ledger remains balanced after invoice + single payment.
    const bal = await ledgerBalance(SOC);
    expect(bal.debit).toBe(bal.credit);
  });
});
