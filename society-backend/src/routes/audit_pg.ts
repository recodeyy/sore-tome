import { Router, Request, Response } from "express";
import { PgAuditService } from "../services/audit/PgAuditService";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, adminOnly } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

/**
 * Capability 92: immutable audit log read + CSV export, tenant-scoped and
 * restricted to admins. Audit rows are append-only at the DB level; no
 * update/delete route is exposed here.
 */
const router = Router();
const societyOf = (req: Request) => (req as any).societyId as string;
const actorOf = (req: Request) => {
  const u = (req as any).user || {};
  return {
    id: u.id || u.uid || (req as any).userId || null,
    name: u.name || u.email || null,
    ip: req.ip || (req.headers["x-forwarded-for"] as string) || null,
    requestId: (req.headers["x-request-id"] as string) || (req as any).requestId || null,
  };
};

const parseOpts = (req: Request) => ({
  actorId: req.query.actor ? String(req.query.actor) : undefined,
  from: req.query.from ? String(req.query.from) : undefined,
  to: req.query.to ? String(req.query.to) : undefined,
  limit: req.query.limit ? Number(req.query.limit) : undefined,
});

router.get("/", authMiddleware, tenantMiddleware, adminOnly, async (req, res) => {
  try {
    const logs = await PgAuditService.query(societyOf(req), parseOpts(req));
    res.json({ logs });
  } catch (e: any) {
    logger.error({ error: e.message }, "Failed to list audit logs");
    res.status(500).json({ error: "Failed to list audit logs" });
  }
});

router.get("/export", authMiddleware, tenantMiddleware, adminOnly, async (req, res) => {
  try {
    const csv = await PgAuditService.exportCsv(societyOf(req), parseOpts(req), actorOf(req));
    res.setHeader("Content-Type", "text/csv");
    res.setHeader("Content-Disposition", `attachment; filename="audit_logs.csv"`);
    res.send(csv);
  } catch (e: any) {
    logger.error({ error: e.message }, "Failed to export audit logs");
    res.status(500).json({ error: "Failed to export audit logs" });
  }
});

export default router;
