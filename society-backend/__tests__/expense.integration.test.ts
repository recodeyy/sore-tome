import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { ExpenseService } from "../src/services/finance/ExpenseService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-exp-${Date.now()}`;
const MAKER = "user-maker";
const CHECKER = "user-checker";

async function ledgerBalance(society: string) {
  const { rows } = await db.query(
    `SELECT COALESCE(SUM(debit_minor),0)::bigint d, COALESCE(SUM(credit_minor),0)::bigint c
     FROM journal_lines WHERE society_id = $1`,
    [society]
  );
  return { debit: Number(rows[0].d), credit: Number(rows[0].c) };
}

afterAll(async () => {
  await db.query(`DELETE FROM expense_approvals WHERE society_id = $1`, [SOC]);
  await db.query(`DELETE FROM expenses WHERE society_id = $1`, [SOC]);
  for (const t of ["journal_lines", "journal_entries", "chart_of_accounts"]) {
    await db.query(`DELETE FROM ${t} WHERE society_id = $1`, [SOC]);
  }
  await dbManager.close();
});

describe("ExpenseService (integration)", () => {
  it("blocks the creator from approving their own expense", async () => {
    const expense = await ExpenseService.createExpense(SOC, { description: "Lift AMC", amountMinor: 120000 }, MAKER);
    expect(expense.status).toBe("pending_approval");

    await expect(ExpenseService.decide(SOC, expense.id, MAKER, "approved")).rejects.toMatchObject({ code: "MAKER_CHECKER" });

    // No posting happened.
    const bal = await ledgerBalance(SOC);
    expect(bal.debit).toBe(0);
    expect(bal.credit).toBe(0);
  });

  it("posts a balanced journal when a different approver approves", async () => {
    const expense = await ExpenseService.createExpense(SOC, { description: "Generator fuel", amountMinor: 80000 }, MAKER);
    const approved = await ExpenseService.decide(SOC, expense.id, CHECKER, "approved");

    expect(approved.status).toBe("approved");
    expect(approved.journal_entry_id).toBeTruthy();

    const bal = await ledgerBalance(SOC);
    expect(bal.debit).toBe(bal.credit);
    expect(bal.debit).toBe(80000);
  });
});
