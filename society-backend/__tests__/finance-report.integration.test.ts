import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { FinanceService } from "../src/services/finance/FinanceService";
import { ExpenseService } from "../src/services/finance/ExpenseService";
import { FinanceReportService } from "../src/services/finance/FinanceReportService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-rep-${Date.now()}`;

afterAll(async () => {
  await db.query(`DELETE FROM expense_approvals WHERE society_id = $1`, [SOC]);
  await db.query(`DELETE FROM expenses WHERE society_id = $1`, [SOC]);
  for (const t of ["payment_allocations", "payments", "journal_lines", "journal_entries", "invoice_lines", "invoices", "chart_of_accounts"]) {
    await db.query(`DELETE FROM ${t} WHERE society_id = $1`, [SOC]);
  }
  await dbManager.close();
});

describe("FinanceReportService (integration)", () => {
  it("summarises invoiced / collected / outstanding / expenses and keeps the trial balance balanced", async () => {
    // Two published invoices totalling 100000; pay 30000 of one. One approved expense 20000.
    const inv1 = await FinanceService.createInvoice(SOC, { number: `R1-${Date.now()}`, lines: [{ description: "Maint", unitPriceMinor: 60000 }] });
    await FinanceService.publishInvoice(SOC, inv1.id);
    const inv2 = await FinanceService.createInvoice(SOC, { number: `R2-${Date.now()}`, lines: [{ description: "Maint", unitPriceMinor: 40000 }] });
    await FinanceService.publishInvoice(SOC, inv2.id);

    await FinanceService.recordPayment(SOC, { idempotencyKey: `rep-${Date.now()}`, invoiceId: inv1.id, amountMinor: 30000 });

    const exp = await ExpenseService.createExpense(SOC, { description: "Cleaning", amountMinor: 20000 }, "maker");
    await ExpenseService.decide(SOC, exp.id, "checker", "approved");

    const summary = await FinanceReportService.summary(SOC);
    expect(summary.invoicedMinor).toBe(100000);
    expect(summary.collectedMinor).toBe(30000);
    expect(summary.outstandingMinor).toBe(70000);
    expect(summary.expensesMinor).toBe(20000);

    const tb = await FinanceReportService.trialBalance(SOC);
    expect(tb.balanced).toBe(true);
    expect(tb.totalDebitMinor).toBe(tb.totalCreditMinor);

    const dues = await FinanceReportService.dues(SOC);
    expect(dues.totalOutstandingMinor).toBe(70000);
    // inv1 has 30000 outstanding, inv2 has 40000 outstanding => 2 open invoices
    expect(dues.items.length).toBe(2);
  });
});
