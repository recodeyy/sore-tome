import { db } from "../../shared/Database";

/**
 * Dashboard analytics — read-only aggregation over phase tables, tenant-scoped.
 * Every sub-query is guarded so a missing table (to_regclass NULL) or an empty
 * table returns 0 / [] instead of throwing. Money is in integer minor units.
 */

/** Run a query that returns a single numeric value; return 0 on any failure. */
async function safeCount(sql: string, params: any[]): Promise<number> {
  try {
    const { rows } = await db.query(sql, params);
    const v = rows[0] ? Object.values(rows[0])[0] : 0;
    return Number(v) || 0;
  } catch {
    return 0;
  }
}

/** True if the table exists in the current database. */
async function tableExists(name: string): Promise<boolean> {
  try {
    const { rows } = await db.query(`SELECT to_regclass($1) AS t`, [`public.${name}`]);
    return !!(rows[0] && rows[0].t);
  } catch {
    return false;
  }
}

function parseDate(v: any): Date | null {
  if (typeof v !== "string" || !v.trim()) return null;
  const d = new Date(v);
  return isNaN(d.getTime()) ? null : d;
}

export const AnalyticsService = {
  async summary(societyId: string) {
    const [
      pendingApprovals,
      openComplaints,
      todaysCollectionMinor,
      maintenanceDueMinor,
      visitorsToday,
      staffOnDuty,
    ] = await Promise.all([
      safeCount(
        `SELECT COUNT(*) FROM members WHERE society_id = $1 AND status = 'pending'`,
        [societyId]
      ),
      safeCount(
        `SELECT COUNT(*) FROM complaints WHERE society_id = $1 AND status IN ('open','in_progress')`,
        [societyId]
      ),
      safeCount(
        `SELECT COALESCE(SUM(amount_minor),0) FROM payments
         WHERE society_id = $1 AND status = 'captured' AND created_at::date = current_date`,
        [societyId]
      ),
      safeCount(
        `SELECT COALESCE(SUM(total_minor),0) FROM invoices
         WHERE society_id = $1 AND status = 'published'`,
        [societyId]
      ),
      (async () =>
        (await tableExists("visitor_parking"))
          ? safeCount(
              `SELECT COUNT(*) FROM visitor_parking
               WHERE society_id = $1 AND created_at::date = current_date`,
              [societyId]
            )
          : 0)(),
      safeCount(
        `SELECT COUNT(*) FROM staff WHERE society_id = $1 AND status = 'active'`,
        [societyId]
      ),
    ]);

    return {
      pendingApprovals,
      openComplaints,
      todaysCollectionMinor,
      maintenanceDueMinor,
      visitorsToday,
      staffOnDuty,
    };
  },

  /**
   * Daily collections (payments) and expenses between fromDate and toDate.
   * Dates are validated; defaults to the last 30 days.
   */
  async trends(societyId: string, fromDate?: string, toDate?: string) {
    let to = parseDate(toDate) || new Date();
    let from = parseDate(fromDate);
    if (!from) {
      from = new Date(to.getTime() - 30 * 86400000);
    }
    if (from > to) {
      const tmp = from;
      from = to;
      to = tmp;
    }
    const fromStr = from.toISOString().slice(0, 10);
    const toStr = to.toISOString().slice(0, 10);

    const collect = async (table: string, amountCol: string, extraWhere = "") => {
      if (!(await tableExists(table))) return [] as { date: string; amountMinor: number }[];
      try {
        const { rows } = await db.query(
          `SELECT created_at::date AS d, COALESCE(SUM(${amountCol}),0)::bigint AS amt
           FROM ${table}
           WHERE society_id = $1 AND created_at::date BETWEEN $2 AND $3${extraWhere}
           GROUP BY created_at::date
           ORDER BY created_at::date`,
          [societyId, fromStr, toStr]
        );
        return rows.map((r: any) => ({
          date: typeof r.d === "string" ? r.d : new Date(r.d).toISOString().slice(0, 10),
          amountMinor: Number(r.amt),
        }));
      } catch {
        return [] as { date: string; amountMinor: number }[];
      }
    };

    const [collections, expenses] = await Promise.all([
      collect("payments", "amount_minor", " AND status = 'captured'"),
      collect("expenses", "amount_minor"),
    ]);

    return { from: fromStr, to: toStr, collections, expenses };
  },

  /** Operational alerts. Each source is guarded and returns 0/empty on failure. */
  async alerts(societyId: string) {
    const alerts: { type: string; severity: string; message: string; count: number }[] = [];

    const overdueInvoices = await safeCount(
      `SELECT COUNT(*) FROM invoices
       WHERE society_id = $1 AND status = 'published'
         AND due_date IS NOT NULL AND due_date < current_date`,
      [societyId]
    );
    if (overdueInvoices > 0) {
      alerts.push({
        type: "overdue_invoices",
        severity: "high",
        message: `${overdueInvoices} overdue invoice(s)`,
        count: overdueInvoices,
      });
    }

    const breachedSlas = await safeCount(
      `SELECT COUNT(*) FROM complaints
       WHERE society_id = $1 AND due_at IS NOT NULL AND due_at < now()
         AND status NOT IN ('resolved','closed')`,
      [societyId]
    );
    if (breachedSlas > 0) {
      alerts.push({
        type: "complaint_sla_breach",
        severity: "high",
        message: `${breachedSlas} complaint SLA(s) breached`,
        count: breachedSlas,
      });
    }

    if (await tableExists("amc_contracts")) {
      const amcExpiring = await safeCount(
        `SELECT COUNT(*) FROM amc_contracts
         WHERE society_id = $1 AND status = 'active'
           AND end_date >= current_date
           AND end_date <= current_date + INTERVAL '30 days'`,
        [societyId]
      );
      if (amcExpiring > 0) {
        alerts.push({
          type: "amc_expiring",
          severity: "medium",
          message: `${amcExpiring} AMC contract(s) expiring in 30 days`,
          count: amcExpiring,
        });
      }
    }

    const paymentFailures = await safeCount(
      `SELECT COUNT(*) FROM payments
       WHERE society_id = $1 AND status = 'failed'`,
      [societyId]
    );
    if (paymentFailures > 0) {
      alerts.push({
        type: "payment_failures",
        severity: "medium",
        message: `${paymentFailures} failed payment(s)`,
        count: paymentFailures,
      });
    }

    return alerts;
  },
};
