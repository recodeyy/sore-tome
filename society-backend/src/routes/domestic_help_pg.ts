import { Router, Request, Response } from "express";
import { z } from "zod";
import { DomesticHelpService } from "../services/domestic/DomesticHelpService";
import { ResidentService } from "../services/resident/ResidentService";
import { validate } from "../middleware/validate";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, canManageSecurity } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();
const societyOf = (req: Request) => (req as any).societyId as string;
const userIdOf = (req: Request) =>
  ((req as any).user?.uid || (req as any).context?.userId) as string | undefined;
const s = z.string().trim().min(1);

const AddSchema = z.object({ body: z.object({
  name: s.max(120),
  phone: z.string().max(20).optional(),
  helperType: z.enum(["maid", "cook", "driver", "nanny", "other"]).optional(),
  photoUrl: z.string().max(1000).optional(),
  schedule: z.record(z.string(), z.any()).optional(),
}).strict() });

const StatusSchema = z.object({ body: z.object({
  status: z.enum(["active", "paused", "revoked"]),
}).strict() });

const LogSchema = z.object({ body: z.object({
  action: z.enum(["check_in", "check_out"]),
}).strict() });

const map = (res: Response, err: any, fallback: string) => {
  if (err.code === "NOT_FOUND" || err.code === "NOT_A_MEMBER") return res.status(err.code === "NOT_A_MEMBER" ? 403 : 404).json({ error: err.message });
  if (err.code === "INVALID_INPUT") return res.status(400).json({ error: err.message });
  if (err.code === "INVALID_STATE") return res.status(409).json({ error: err.message });
  logger.error({ error: err.message }, fallback);
  return res.status(500).json({ error: fallback });
};

const ctxOf = (req: Request) => {
  const u = (req as any).user || {};
  return ResidentService.resolveContext(societyOf(req), userIdOf(req) as string, {
    role: u.role,
    name: u.name,
    phone: u.phone,
  });
};

/** GET /domestic-help — the resident's own registered helpers. */
router.get("/", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ helpers: await DomesticHelpService.list(await ctxOf(req)) }); }
  catch (e: any) { map(res, e, "Failed to list helpers"); }
});

/** POST /domestic-help — register a maid/cook/driver. */
router.post("/", authMiddleware, tenantMiddleware, validate(AddSchema), async (req, res) => {
  try { res.status(201).json({ helper: await DomesticHelpService.add(await ctxOf(req), req.body) }); }
  catch (e: any) { map(res, e, "Failed to add helper"); }
});

/** PATCH /domestic-help/:id/status — pause / revoke / re-activate gate access. */
router.patch("/:id/status", authMiddleware, tenantMiddleware, validate(StatusSchema), async (req, res) => {
  try { res.json({ helper: await DomesticHelpService.updateStatus(await ctxOf(req), req.params.id as string, req.body.status) }); }
  catch (e: any) { map(res, e, "Failed to update helper access"); }
});

/** DELETE /domestic-help/:id */
router.delete("/:id", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json(await DomesticHelpService.remove(await ctxOf(req), req.params.id as string)); }
  catch (e: any) { map(res, e, "Failed to remove helper"); }
});

/** GET /domestic-help/:id/history — access log (check-in/out). */
router.get("/:id/history", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ logs: await DomesticHelpService.history(await ctxOf(req), req.params.id as string) }); }
  catch (e: any) { map(res, e, "Failed to load history"); }
});

/**
 * POST /domestic-help/:id/log — guard records a check-in/check-out and notifies
 * the resident. Security-role only.
 */
router.post("/:id/log", authMiddleware, tenantMiddleware, canManageSecurity, validate(LogSchema), async (req, res) => {
  try {
    res.status(201).json({ log: await DomesticHelpService.logAccess(societyOf(req), req.params.id as string, req.body.action, userIdOf(req)) });
  } catch (e: any) { map(res, e, "Failed to log access"); }
});

export default router;
