import { db } from "../../shared/Database";

/**
 * Tenant-scoped global search. Each source is queried independently (guarded for
 * table existence), capped to `limit`, then UNION-ed in app code. Every query is
 * filtered by society_id so results never cross tenants.
 */

type Hit = { type: string; id: string; label: string; sub: string | null };

async function tableExists(name: string): Promise<boolean> {
  try {
    const { rows } = await db.query(`SELECT to_regclass($1) AS t`, [`public.${name}`]);
    return !!(rows[0] && rows[0].t);
  } catch {
    return false;
  }
}

/** Run one guarded source query mapping rows to Hits; never throws. */
async function source(
  table: string,
  sql: string,
  params: any[],
  map: (r: any) => Hit
): Promise<Hit[]> {
  try {
    if (!(await tableExists(table))) return [];
    const { rows } = await db.query(sql, params);
    return rows.map(map);
  } catch {
    return [];
  }
}

export const SearchService = {
  async search(societyId: string, q: string, limit = 20) {
    const term = typeof q === "string" ? q.trim() : "";
    if (!term) return { query: "", results: [] as Hit[] };
    const like = `%${term}%`;
    const cap = Math.max(1, Math.min(Number(limit) || 20, 50));

    const groups = await Promise.all([
      source(
        "members",
        `SELECT id, name FROM members
         WHERE society_id = $1 AND name ILIKE $2 ORDER BY name LIMIT $3`,
        [societyId, like, cap],
        (r) => ({ type: "member", id: r.id, label: r.name, sub: null })
      ),
      source(
        "units",
        `SELECT id, number, unit_type FROM units
         WHERE society_id = $1 AND number ILIKE $2 ORDER BY number LIMIT $3`,
        [societyId, like, cap],
        (r) => ({ type: "unit", id: r.id, label: r.number, sub: r.unit_type || null })
      ),
      source(
        "complaints",
        `SELECT id, ref, title FROM complaints
         WHERE society_id = $1 AND (ref ILIKE $2 OR title ILIKE $2)
         ORDER BY created_at DESC LIMIT $3`,
        [societyId, like, cap],
        (r) => ({ type: "complaint", id: r.id, label: r.ref, sub: r.title })
      ),
      source(
        "notices",
        `SELECT id, title FROM notices
         WHERE society_id = $1 AND title ILIKE $2
         ORDER BY created_at DESC LIMIT $3`,
        [societyId, like, cap],
        (r) => ({ type: "notice", id: r.id, label: r.title, sub: null })
      ),
      source(
        "assets",
        `SELECT id, tag, name FROM assets
         WHERE society_id = $1 AND (tag ILIKE $2 OR name ILIKE $2)
         ORDER BY name LIMIT $3`,
        [societyId, like, cap],
        (r) => ({ type: "asset", id: r.id, label: r.name, sub: r.tag })
      ),
      source(
        "staff",
        `SELECT id, name, role FROM staff
         WHERE society_id = $1 AND name ILIKE $2 ORDER BY name LIMIT $3`,
        [societyId, like, cap],
        (r) => ({ type: "staff", id: r.id, label: r.name, sub: r.role || null })
      ),
    ]);

    const results = ([] as Hit[]).concat(...groups);
    return { query: term, results };
  },
};
