import { db } from "../../shared/Database";
import { withTx } from "./ledger";

/**
 * Bank reconciliation (capability 40). Imports statement lines, auto-matches
 * each unmatched line to a single captured payment of the same amount that is
 * not already matched to another line, and supports manual match/unmatch. All
 * queries are tenant-scoped by society_id; matching never crosses tenants.
 */

function err(message: string, code: string) {
  return Object.assign(new Error(message), { code });
}

export const ReconciliationService = {
  async createAccount(societyId: string, input: { name: string; accountNoMasked?: string }) {
    const { rows } = await db.query(
      `INSERT INTO bank_accounts (society_id, name, account_no_masked) VALUES ($1,$2,$3) RETURNING *`,
      [societyId, input.name, input.accountNoMasked || null]
    );
    return rows[0];
  },

  /** Create an import with its lines in one transaction. */
  async importStatement(
    societyId: string,
    input: {
      bankAccountId?: string;
      filename?: string;
      lines: { txnDate?: string; amountMinor: number; description?: string; reference?: string }[];
    }
  ) {
    const lines = input.lines || [];
    if (lines.length === 0) throw err("No statement lines provided", "VALIDATION");
    return withTx(async (client) => {
      const imp = await client.query(
        `INSERT INTO bank_statement_imports (society_id, bank_account_id, filename, line_count)
         VALUES ($1,$2,$3,$4) RETURNING *`,
        [societyId, input.bankAccountId || null, input.filename || null, lines.length]
      );
      const importId = imp.rows[0].id;
      for (const l of lines) {
        await client.query(
          `INSERT INTO bank_statement_lines (society_id, import_id, txn_date, amount_minor, description, reference)
           VALUES ($1,$2,$3,$4,$5,$6)`,
          [societyId, importId, l.txnDate || null, l.amountMinor, l.description || null, l.reference || null]
        );
      }
      return imp.rows[0];
    });
  },

  /**
   * Auto-match unmatched lines for an import. For each line, pick one captured
   * payment of the same amount in this society that is not already matched to
   * another line. Returns counts. Runs in a transaction to avoid two lines
   * grabbing the same payment.
   */
  async autoMatch(societyId: string, importId: string) {
    return withTx(async (client) => {
      const { rows: lines } = await client.query(
        `SELECT id, amount_minor FROM bank_statement_lines
          WHERE society_id = $1 AND import_id = $2 AND match_status = 'unmatched'
          ORDER BY created_at ASC
          FOR UPDATE`,
        [societyId, importId]
      );
      let matched = 0;
      for (const line of lines) {
        const { rows: pay } = await client.query(
          `SELECT p.id FROM payments p
            WHERE p.society_id = $1 AND p.status = 'captured' AND p.amount_minor = $2
              AND NOT EXISTS (
                SELECT 1 FROM bank_statement_lines bl
                 WHERE bl.society_id = $1 AND bl.matched_payment_id = p.id
              )
            LIMIT 1`,
          [societyId, line.amount_minor]
        );
        if (pay[0]) {
          await client.query(
            `UPDATE bank_statement_lines
                SET match_status = 'matched', matched_payment_id = $2
              WHERE id = $1`,
            [line.id, pay[0].id]
          );
          matched++;
        }
      }
      const unmatched = lines.length - matched;
      return { processed: lines.length, matched, unmatched };
    });
  },

  /** Manually match a line to a payment (both validated to belong to the tenant). */
  async manualMatch(societyId: string, lineId: string, paymentId: string) {
    const { rows: pay } = await db.query(
      `SELECT id FROM payments WHERE id = $1 AND society_id = $2`,
      [paymentId, societyId]
    );
    if (!pay[0]) throw err("Payment not found", "NOT_FOUND");
    const { rows } = await db.query(
      `UPDATE bank_statement_lines
          SET match_status = 'matched', matched_payment_id = $3
        WHERE id = $1 AND society_id = $2 RETURNING *`,
      [lineId, societyId, paymentId]
    );
    if (!rows[0]) throw err("Statement line not found", "NOT_FOUND");
    return rows[0];
  },

  /** Reconciliation summary for an import. */
  async summary(societyId: string, importId: string) {
    const { rows } = await db.query(
      `SELECT match_status, COUNT(*)::int AS c, COALESCE(SUM(amount_minor),0)::bigint AS amt
         FROM bank_statement_lines
        WHERE society_id = $1 AND import_id = $2
        GROUP BY match_status`,
      [societyId, importId]
    );
    const out: any = { matched: 0, partial: 0, unmatched: 0, matchedAmountMinor: 0, unmatchedAmountMinor: 0 };
    for (const r of rows) {
      out[r.match_status] = r.c;
      if (r.match_status === "matched") out.matchedAmountMinor = Number(r.amt);
      if (r.match_status === "unmatched") out.unmatchedAmountMinor = Number(r.amt);
    }
    return out;
  },
};
