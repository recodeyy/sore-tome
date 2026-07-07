import { Router, Request, Response } from "express";
import { db } from "../shared/Database";
import { logger } from "../shared/Logger";

/**
 * MR-006 — public society directory for resident onboarding.
 *
 * GET /api/v1/societies/search?q=hubtown
 * No auth: a brand-new user must find their society before they have any
 * membership/scope. Returns only non-sensitive directory fields (id, name,
 * city, address) of active societies. Rate limited at the mount point.
 */

const router = Router();

/** Best-effort city extraction from a free-text address ("..., Mumbai 400069"). */
function cityOf(address?: string | null): string | null {
  if (!address) return null;
  const m = address.match(/,\s*([A-Za-z .]+?)\s*(\d{6})?\s*$/);
  return m ? m[1].trim() : null;
}

router.get("/search", async (req: Request, res: Response) => {
  try {
    const q = String(req.query.q ?? "").trim().slice(0, 80);
    if (q.length < 2) {
      return res.status(400).json({ error: "Query parameter q must be at least 2 characters" });
    }
    const { rows } = await db.query(
      `SELECT p.society_id AS id,
              COALESCE(p.name, sa.society_name, p.society_id) AS name,
              p.address
         FROM society_profiles p
         LEFT JOIN society_applications sa ON sa.society_id = p.society_id
        WHERE (sa.status IS NULL OR sa.status = 'approved')
          AND (p.name ILIKE '%' || $1 || '%'
               OR sa.society_name ILIKE '%' || $1 || '%'
               OR p.address ILIKE '%' || $1 || '%')
        ORDER BY name ASC
        LIMIT 20`,
      [q]
    );
    res.json({
      societies: rows.map((r: any) => ({
        id: r.id,
        name: r.name,
        city: cityOf(r.address),
        address: r.address || null,
      })),
    });
  } catch (err: any) {
    logger.error({ error: err.message }, "Society search failed");
    res.status(500).json({ error: "Failed to search societies" });
  }
});

export default router;
