import { db } from "../../shared/Database";
import type { PoolClient } from "pg";

/**
 * Shared double-entry ledger primitives. Money is in integer minor units.
 *
 * Standard account codes (auto-created per society):
 *   1000 Cash/Bank (asset)
 *   1100 Accounts Receivable (asset)
 *   4000 Maintenance Income (income)
 *   5000 Operating Expense (expense)
 */

/**
 * Cap 29 — Proration. Computes the prorated charge (integer minor units) for a
 * partial occupancy within a billing period. Days are inclusive on both ends.
 * Occupancy is clamped to the period; full occupancy returns the full amount.
 */
export function prorateMinor(
  fullAmountMinor: number,
  periodStart: string | Date,
  periodEnd: string | Date,
  occupancyStart?: string | Date | null,
  occupancyEnd?: string | Date | null
): { amountMinor: number; chargedDays: number; periodDays: number } {
  const day = 86400000;
  const toUTC = (d: string | Date) => {
    const x = new Date(d);
    return Date.UTC(x.getUTCFullYear(), x.getUTCMonth(), x.getUTCDate());
  };
  const pStart = toUTC(periodStart);
  const pEnd = toUTC(periodEnd);
  if (pEnd < pStart) throw new Error("periodEnd before periodStart");
  const periodDays = Math.round((pEnd - pStart) / day) + 1;

  const oStart = occupancyStart ? Math.max(pStart, toUTC(occupancyStart)) : pStart;
  const oEnd = occupancyEnd ? Math.min(pEnd, toUTC(occupancyEnd)) : pEnd;
  const chargedDays = oEnd < oStart ? 0 : Math.round((oEnd - oStart) / day) + 1;

  // Round to the nearest paise; never exceed the full amount.
  const amountMinor = Math.min(
    fullAmountMinor,
    Math.round((fullAmountMinor * chargedDays) / periodDays)
  );
  return { amountMinor, chargedDays, periodDays };
}

export async function withTx<T>(fn: (client: PoolClient) => Promise<T>): Promise<T> {
  const client = await db.connect();
  try {
    await client.query("BEGIN");
    const result = await fn(client);
    await client.query("COMMIT");
    return result;
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}

export async function ensureAccount(
  client: PoolClient,
  societyId: string,
  code: string,
  name: string,
  type: string
): Promise<string> {
  const { rows } = await client.query(
    `INSERT INTO chart_of_accounts (society_id, code, name, type)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (society_id, code) DO UPDATE SET name = chart_of_accounts.name
     RETURNING id`,
    [societyId, code, name, type]
  );
  return rows[0].id;
}

/** Posts a balanced journal entry. Debits must equal credits. */
export async function postJournal(
  client: PoolClient,
  societyId: string,
  entry: { date?: string; memo: string; sourceType: string; sourceId: string; createdBy?: string },
  lines: { accountId: string; debitMinor?: number; creditMinor?: number }[]
): Promise<string> {
  // pg returns bigint columns as strings, so coerce before arithmetic.
  const debit = lines.reduce((s, l) => s + Number(l.debitMinor || 0), 0);
  const credit = lines.reduce((s, l) => s + Number(l.creditMinor || 0), 0);
  if (debit !== credit) {
    throw new Error(`Unbalanced journal: debit ${debit} != credit ${credit}`);
  }

  const { rows } = await client.query(
    `INSERT INTO journal_entries (society_id, entry_date, memo, source_type, source_id, created_by)
     VALUES ($1, COALESCE($2::date, current_date), $3, $4, $5, $6)
     RETURNING id`,
    [societyId, entry.date || null, entry.memo, entry.sourceType, entry.sourceId, entry.createdBy || null]
  );
  const entryId = rows[0].id;

  for (const l of lines) {
    await client.query(
      `INSERT INTO journal_lines (society_id, journal_entry_id, account_id, debit_minor, credit_minor)
       VALUES ($1, $2, $3, $4, $5)`,
      [societyId, entryId, l.accountId, Number(l.debitMinor || 0), Number(l.creditMinor || 0)]
    );
  }
  return entryId;
}
