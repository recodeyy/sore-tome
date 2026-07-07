import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { FinanceService } from "../src/services/finance/FinanceService";
import { prorateMinor } from "../src/services/finance/ledger";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-bill-${Date.now()}`;

async function ledgerBalance(society: string) {
  const { rows } = await db.query(
    `SELECT COALESCE(SUM(debit_minor),0)::bigint d, COALESCE(SUM(credit_minor),0)::bigint c
     FROM journal_lines WHERE society_id = $1`,
    [society]
  );
  return { debit: Number(rows[0].d), credit: Number(rows[0].c) };
}

afterAll(async () => {
  for (const t of [
    "receipts", "credit_notes", "recurring_billing_runs",
    "payment_allocations", "payments", "journal_lines", "journal_entries",
    "invoice_lines", "invoices", "chart_of_accounts",
  ]) {
    await db.query(`DELETE FROM ${t} WHERE society_id = $1`, [SOC]);
  }
  await dbManager.close();
});

describe("Finance billing depth (integration)", () => {
  // Cap 29 — proration math
  it("prorates a partial period correctly", () => {
    // June (30 days), occupancy from the 16th -> 15 days inclusive.
    const r = prorateMinor(30000, "2026-06-01", "2026-06-30", "2026-06-16", null);
    expect(r.periodDays).toBe(30);
    expect(r.chargedDays).toBe(15);
    expect(r.amountMinor).toBe(15000);
    // Full occupancy returns full amount.
    expect(prorateMinor(30000, "2026-06-01", "2026-06-30").amountMinor).toBe(30000);
    // No overlap -> zero.
    expect(prorateMinor(30000, "2026-06-01", "2026-06-30", "2026-07-01").amountMinor).toBe(0);
  });

  it("applies proration on an invoice line", async () => {
    const inv = await FinanceService.createInvoice(SOC, {
      number: `INV-PRO-${Date.now()}`,
      lines: [{
        description: "Maintenance (partial)",
        unitPriceMinor: 30000,
        proration: { periodStart: "2026-06-01", periodEnd: "2026-06-30", occupancyStart: "2026-06-16" },
      }],
    });
    expect(Number(inv.subtotal_minor)).toBe(15000);
    expect(Number(inv.total_minor)).toBe(15000);
  });

  // Cap 31 — GST tax breakdown
  it("derives a GST tax breakdown from rate", async () => {
    const inv = await FinanceService.createInvoice(SOC, {
      number: `INV-GST-${Date.now()}`,
      lines: [{ description: "Service", unitPriceMinor: 100000, taxRate: 18 }],
    });
    expect(Number(inv.subtotal_minor)).toBe(100000);
    expect(Number(inv.tax_minor)).toBe(18000);
    expect(Number(inv.total_minor)).toBe(118000);
    const full = await FinanceService.getInvoice(SOC, inv.id);
    expect(Number(full.lines[0].taxable_minor)).toBe(100000);
    expect(Number(full.lines[0].tax_minor)).toBe(18000);
  });

  // Cap 30 — late fee idempotency + waiver
  it("applies a late fee once and waives it, keeping the ledger balanced", async () => {
    const inv = await FinanceService.createInvoice(SOC, {
      number: `INV-LATE-${Date.now()}`,
      dueDate: "2026-01-01",
      lines: [{ description: "Maintenance", unitPriceMinor: 50000 }],
    });
    await FinanceService.publishInvoice(SOC, inv.id);

    const first = await FinanceService.applyLateFee(SOC, inv.id, { feeMinor: 5000, asOf: "2026-06-16" });
    const second = await FinanceService.applyLateFee(SOC, inv.id, { feeMinor: 5000, asOf: "2026-06-16" });
    expect(first.applied).toBe(true);
    expect(second.applied).toBe(false);
    expect(Number(first.invoice.total_minor)).toBe(55000);

    const afterFee = await ledgerBalance(SOC);
    expect(afterFee.debit).toBe(afterFee.credit);

    const waive = await FinanceService.waiveLateFee(SOC, inv.id, { reason: "goodwill" });
    expect(waive.waived).toBe(true);
    expect(Number(waive.invoice.late_fee_minor)).toBe(0);
    expect(Number(waive.invoice.total_minor)).toBe(50000);

    const afterWaive = await ledgerBalance(SOC);
    expect(afterWaive.debit).toBe(afterWaive.credit);
  });

  // Cap 31 — credit note immutability + numbering + balance
  it("issues immutable credit notes with sequential numbering", async () => {
    const inv = await FinanceService.createInvoice(SOC, {
      number: `INV-CN-${Date.now()}`,
      lines: [{ description: "Service", unitPriceMinor: 100000, taxRate: 18 }],
    });
    await FinanceService.publishInvoice(SOC, inv.id);

    const cn1 = await FinanceService.createCreditNote(SOC, {
      invoiceId: inv.id, reason: "overcharge", taxableMinor: 10000, taxMinor: 1800,
    });
    expect(cn1.number).toMatch(/^CN-\d{6}$/);
    expect(Number(cn1.total_minor)).toBe(11800);

    const cn2 = await FinanceService.createCreditNote(SOC, {
      invoiceId: inv.id, reason: "adjustment", taxableMinor: 5000,
    });
    // Sequential numbering.
    const n1 = Number(cn1.number.split("-")[1]);
    const n2 = Number(cn2.number.split("-")[1]);
    expect(n2).toBe(n1 + 1);

    // Immutable: no UPDATE path; rows persist as written.
    const { rows } = await db.query(`SELECT count(*)::int n FROM credit_notes WHERE invoice_id = $1`, [inv.id]);
    expect(rows[0].n).toBe(2);

    const bal = await ledgerBalance(SOC);
    expect(bal.debit).toBe(bal.credit);

    // Over-credit rejected.
    await expect(
      FinanceService.createCreditNote(SOC, { invoiceId: inv.id, reason: "x", taxableMinor: 999999999 })
    ).rejects.toThrow();
  });

  // Cap 28 — recurring billing idempotency
  it("runs recurring billing idempotently per period", async () => {
    const args = {
      policyKey: "monthly-maint",
      period: "2026-07",
      numberPrefix: `REC-${Date.now()}`,
      dueDate: "2026-07-10",
      members: [
        { memberId: "m1", lines: [{ description: "Maintenance", unitPriceMinor: 40000 }] },
        { memberId: "m2", lines: [{ description: "Maintenance", unitPriceMinor: 40000 }] },
      ],
    };
    const first = await FinanceService.runRecurringBilling(SOC, args);
    const second = await FinanceService.runRecurringBilling(SOC, args);
    expect(first.duplicate).toBe(false);
    expect(first.run.invoices_created).toBe(2);
    expect(second.duplicate).toBe(true);

    const { rows } = await db.query(
      `SELECT count(*)::int n FROM invoices WHERE society_id = $1 AND recurring_run_id = $2`,
      [SOC, first.run.id]
    );
    expect(rows[0].n).toBe(2);

    const bal = await ledgerBalance(SOC);
    expect(bal.debit).toBe(bal.credit);
  });

  // Cap 35 — receipt issuance + void/reissue
  it("issues a receipt on payment and supports void/reissue", async () => {
    const inv = await FinanceService.createInvoice(SOC, {
      number: `INV-RCPT-${Date.now()}`,
      lines: [{ description: "Maintenance", unitPriceMinor: 20000 }],
    });
    await FinanceService.publishInvoice(SOC, inv.id);

    const pay = await FinanceService.recordPayment(SOC, {
      idempotencyKey: `rk-${Date.now()}`, invoiceId: inv.id, amountMinor: 20000,
    });
    expect(pay.receipt).toBeTruthy();
    expect(pay.receipt.status).toBe("issued");

    const result = await FinanceService.voidReceipt(SOC, pay.receipt.id, { reason: "wrong amount", reissue: true });
    expect(result.voided.status).toBe("void");
    expect(result.reissued).toBeTruthy();
    expect(result.reissued.status).toBe("issued");
    expect(result.reissued.reissued_from).toBe(pay.receipt.id);

    // Only one live receipt remains for the payment.
    const { rows } = await db.query(
      `SELECT count(*)::int n FROM receipts WHERE society_id = $1 AND payment_id = $2 AND status = 'issued'`,
      [SOC, pay.payment.id]
    );
    expect(rows[0].n).toBe(1);

    // Double void rejected.
    await expect(
      FinanceService.voidReceipt(SOC, pay.receipt.id, { reason: "again" })
    ).rejects.toThrow();
  });
});

