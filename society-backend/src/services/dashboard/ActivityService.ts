import { db } from "../../shared/Database";

/**
 * Recent activity feed (capability 3) — a tenant-scoped, reverse-chronological
 * stream merged from the core domain tables. Each source is queried
 * independently, guarded for table existence, capped, then merged and sorted in
 * app code so a missing/empty table never breaks the feed. Every query is
 * filtered by society_id so the feed never crosses tenants.
 */

type Item = {
  type: string;
  id: string;
  title: string;
  at: string; // ISO timestamp
};

async function tableExists(name: string): Promise<boolean> {
  try {
    const { rows } = await db.query(`SELECT to_regclass($1) AS t`, [`public.${name}`]);
    return !!(rows[0] && rows[0].t);
  } catch {
    return false;
  }
}

/** Run one guarded source query mapping rows to feed Items; never throws. */
async function source(
  table: string,
  sql: string,
  params: any[],
  map: (r: any) => Item
): Promise<Item[]> {
  try {
    if (!(await tableExists(table))) return [];
    const { rows } = await db.query(sql, params);
    return rows.map(map);
  } catch {
    return [];
  }
}

const iso = (v: any): string =>
  v instanceof Date ? v.toISOString() : new Date(v).toISOString();

export const ActivityService = {
  async feed(societyId: string, limit = 20) {
    const cap = Math.max(1, Math.min(Number(limit) || 20, 50));

    const groups = await Promise.all([
      source(
        "members",
        `SELECT id, name, status, created_at FROM members
         WHERE society_id = $1 ORDER BY created_at DESC LIMIT $2`,
        [societyId, cap],
        (r) => ({ type: "member", id: r.id, title: `Member ${r.name} (${r.status})`, at: iso(r.created_at) })
      ),
      source(
        "payments",
        `SELECT id, amount_minor, status, created_at FROM payments
         WHERE society_id = $1 ORDER BY created_at DESC LIMIT $2`,
        [societyId, cap],
        (r) => ({ type: "payment", id: r.id, title: `Payment ${r.status} (${r.amount_minor})`, at: iso(r.created_at) })
      ),
      source(
        "complaints",
        `SELECT id, ref, title, created_at FROM complaints
         WHERE society_id = $1 ORDER BY created_at DESC LIMIT $2`,
        [societyId, cap],
        (r) => ({ type: "complaint", id: r.id, title: `Complaint ${r.ref}: ${r.title}`, at: iso(r.created_at) })
      ),
      source(
        "notices",
        `SELECT id, title, created_at FROM notices
         WHERE society_id = $1 ORDER BY created_at DESC LIMIT $2`,
        [societyId, cap],
        (r) => ({ type: "notice", id: r.id, title: `Notice: ${r.title}`, at: iso(r.created_at) })
      ),
      source(
        "amenity_bookings",
        `SELECT id, status, created_at FROM amenity_bookings
         WHERE society_id = $1 ORDER BY created_at DESC LIMIT $2`,
        [societyId, cap],
        (r) => ({ type: "booking", id: r.id, title: `Booking ${r.status}`, at: iso(r.created_at) })
      ),
      source(
        "maintenance_work_orders",
        `SELECT id, status, created_at FROM maintenance_work_orders
         WHERE society_id = $1 ORDER BY created_at DESC LIMIT $2`,
        [societyId, cap],
        (r) => ({ type: "asset", id: r.id, title: `Work order ${r.status}`, at: iso(r.created_at) })
      ),
    ]);

    const items = ([] as Item[])
      .concat(...groups)
      .sort((a, b) => (a.at < b.at ? 1 : a.at > b.at ? -1 : 0))
      .slice(0, cap);

    return { items };
  },
};
