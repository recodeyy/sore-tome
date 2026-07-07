import { db } from "../../shared/Database";

/** Finance reports. All amounts returned in integer minor units. */
export const FinanceReportService = {
  async summary(societyId: string) {
    const { rows } = await db.query(
      `SELECT
         (SELECT COALESCE(SUM(total_minor),0) FROM invoices WHERE society_id = $1 AND status = 'published')::bigint AS invoiced,
         (SELECT COALESCE(SUM(amount_minor),0) FROM payments WHERE society_id = $1 AND status = 'captured')::bigint AS collected,
         (SELECT COALESCE(SUM(amount_minor),0) FROM payment_allocations WHERE society_id = $1)::bigint AS allocated,
         (SELECT COALESCE(SUM(amount_minor),0) FROM expenses WHERE society_id = $1 AND status = 'approved')::bigint AS expenses`,
      [societyId]
    );
    const r = rows[0];
    const invoicedMinor = Number(r.invoiced);
    const allocatedMinor = Number(r.allocated);
    return {
      invoicedMinor,
      collectedMinor: Number(r.collected),
      expensesMinor: Number(r.expenses),
      outstandingMinor: invoicedMinor - allocatedMinor,
    };
  },

  /** Per-account debit/credit totals. For a correct ledger, total debit === total credit. */
  async trialBalance(societyId: string) {
    const { rows } = await db.query(
      `SELECT a.code, a.name, a.type,
              COALESCE(SUM(jl.debit_minor),0)::bigint AS debit,
              COALESCE(SUM(jl.credit_minor),0)::bigint AS credit
       FROM chart_of_accounts a
       LEFT JOIN journal_lines jl ON jl.account_id = a.id AND jl.society_id = $1
       WHERE a.society_id = $1
       GROUP BY a.id, a.code, a.name, a.type
       ORDER BY a.code`,
      [societyId]
    );
    const accounts = rows.map((x: any) => ({
      code: x.code,
      name: x.name,
      type: x.type,
      debitMinor: Number(x.debit),
      creditMinor: Number(x.credit),
    }));
    const totalDebitMinor = accounts.reduce((s, a) => s + a.debitMinor, 0);
    const totalCreditMinor = accounts.reduce((s, a) => s + a.creditMinor, 0);
    return { accounts, totalDebitMinor, totalCreditMinor, balanced: totalDebitMinor === totalCreditMinor };
  },

  /** Outstanding published invoices with ageing buckets. */
  async dues(societyId: string) {
    const { rows } = await db.query(
      `SELECT i.id, i.number, i.member_id, i.total_minor::bigint AS total,
              COALESCE(SUM(pa.amount_minor),0)::bigint AS allocated,
              i.due_date, i.created_at
       FROM invoices i
       LEFT JOIN payment_allocations pa ON pa.invoice_id = i.id AND pa.society_id = $1
       WHERE i.society_id = $1 AND i.status = 'published'
       GROUP BY i.id
       HAVING i.total_minor - COALESCE(SUM(pa.amount_minor),0) > 0
       ORDER BY i.due_date NULLS LAST`,
      [societyId]
    );

    const now = Date.now();
    const bucketFor = (days: number) =>
      days <= 30 ? "0-30" : days <= 60 ? "31-60" : days <= 90 ? "61-90" : "90+";

    const items = rows.map((x: any) => {
      const ref = x.due_date || x.created_at;
      const ageDays = ref ? Math.max(0, Math.floor((now - new Date(ref).getTime()) / 86400000)) : 0;
      return {
        invoiceId: x.id,
        number: x.number,
        memberId: x.member_id,
        totalMinor: Number(x.total),
        allocatedMinor: Number(x.allocated),
        outstandingMinor: Number(x.total) - Number(x.allocated),
        ageDays,
        bucket: bucketFor(ageDays),
      };
    });

    const buckets = { "0-30": 0, "31-60": 0, "61-90": 0, "90+": 0 } as Record<string, number>;
    for (const it of items) buckets[it.bucket] += it.outstandingMinor;

    return { items, buckets, totalOutstandingMinor: items.reduce((s, i) => s + i.outstandingMinor, 0) };
  },
};
