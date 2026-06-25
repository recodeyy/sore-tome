import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx, ensureAccount, postJournal } from "./ledger";

/**
 * Expenses with maker-checker approval. Money in integer minor units.
 * The creator cannot approve their own expense. Approval posts an immutable
 * journal entry (Dr Operating Expense, Cr Cash) in one transaction.
 */
export const ExpenseService = {
  async createExpense(
    societyId: string,
    input: { vendor?: string; category?: string; description: string; amountMinor: number; taxMinor?: number },
    createdBy?: string
  ) {
    const { rows } = await db.query(
      `INSERT INTO expenses (society_id, vendor, category, description, amount_minor, tax_minor, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [societyId, input.vendor || null, input.category || null, input.description,
       input.amountMinor, input.taxMinor || 0, createdBy || null]
    );
    logger.info({ societyId, expenseId: rows[0].id, amount: input.amountMinor }, "Expense created (pending approval)");
    return rows[0];
  },

  /**
   * Approve or reject. Maker-checker: approverId must differ from created_by.
   * On approval, posts the ledger entry and marks the expense approved.
   */
  async decide(
    societyId: string,
    expenseId: string,
    approverId: string,
    decision: "approved" | "rejected",
    comment?: string
  ) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM expenses WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [expenseId, societyId]
      );
      const expense = rows[0];
      if (!expense) throw Object.assign(new Error("Expense not found"), { code: "NOT_FOUND" });
      if (expense.status !== "pending_approval") {
        throw Object.assign(new Error(`Expense already ${expense.status}`), { code: "INVALID_STATE" });
      }
      if (expense.created_by && expense.created_by === approverId) {
        throw Object.assign(new Error("You cannot approve your own expense"), { code: "MAKER_CHECKER" });
      }

      await client.query(
        `INSERT INTO expense_approvals (society_id, expense_id, approver_id, decision, comment)
         VALUES ($1, $2, $3, $4, $5)`,
        [societyId, expenseId, approverId, decision, comment || null]
      );

      if (decision === "rejected") {
        const upd = await client.query(
          `UPDATE expenses SET status = 'rejected', approved_by = $3, version = version + 1, updated_at = now()
           WHERE id = $1 AND society_id = $2 RETURNING *`,
          [expenseId, societyId, approverId]
        );
        logger.info({ societyId, expenseId, approverId }, "Expense rejected");
        return upd.rows[0];
      }

      const expenseAcct = await ensureAccount(client, societyId, "5000", "Operating Expense", "expense");
      const cash = await ensureAccount(client, societyId, "1000", "Cash/Bank", "asset");

      const journalId = await postJournal(
        client,
        societyId,
        { memo: `Expense: ${expense.description}`, sourceType: "expense", sourceId: expense.id, createdBy: approverId },
        [
          { accountId: expenseAcct, debitMinor: expense.amount_minor },
          { accountId: cash, creditMinor: expense.amount_minor },
        ]
      );

      const upd = await client.query(
        `UPDATE expenses SET status = 'approved', approved_by = $3, journal_entry_id = $4, version = version + 1, updated_at = now()
         WHERE id = $1 AND society_id = $2 RETURNING *`,
        [expenseId, societyId, approverId, journalId]
      );
      logger.info({ societyId, expenseId, approverId, amount: expense.amount_minor }, "Expense approved + ledger posted");
      return upd.rows[0];
    });
  },

  async listExpenses(societyId: string, opts: { status?: string; limit?: number } = {}) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.status) {
      params.push(opts.status);
      where += ` AND status = $${params.length}`;
    }
    params.push(Math.min(opts.limit || 50, 200));
    const { rows } = await db.query(
      `SELECT * FROM expenses WHERE ${where} ORDER BY created_at DESC LIMIT $${params.length}`,
      params
    );
    return rows;
  },
};
