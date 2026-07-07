import { Router, Request, Response } from "express";
import { z } from "zod";
import { ParcelService } from "../services/parcels/ParcelService";
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
const roleOf = (req: Request) => ((req as any).user?.role || (req as any).context?.role) as string | undefined;
const s = z.string().trim().min(1);

const LogSchema = z.object({ body: z.object({
  unitId: z.string().max(64).optional(),
  recipientName: z.string().max(120).optional(),
  courier: s.max(80),
  trackingCode: z.string().max(120).optional(),
  description: z.string().max(500).optional(),
  photoUrl: z.string().max(1000).optional(),
}).strict() });

const CollectSchema = z.object({ body: z.object({
  otp: s.max(12),
}).strict() });

const map = (res: Response, err: any, fallback: string) => {
  if (err.code === "NOT_FOUND") return res.status(404).json({ error: err.message });
  if (err.code === "INVALID_OTP") return res.status(400).json({ error: err.message });
  if (["INVALID_STATE", "ALREADY_EXISTS"].includes(err.code)) return res.status(409).json({ error: err.message });
  logger.error({ error: err.message }, fallback);
  return res.status(500).json({ error: fallback });
};

const SECURITY_ROLES = ["guard", "security_manager", "security", "supervisor", "reception_staff", "parcel_desk_staff", "main_admin", "admin"];

/**
 * GET /parcels — residents see their own flat's parcels; guards/admins see the
 * whole society's queue (optionally ?status=pending).
 */
router.get("/", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const role = roleOf(req) || "";
    if (SECURITY_ROLES.includes(role)) {
      return res.json({ parcels: await ParcelService.listAll(societyOf(req), { status: req.query.status as string }) });
    }
    const ctx = await ResidentService.resolveContext(societyOf(req), userIdOf(req) as string);
    res.json({ parcels: await ParcelService.listForUnit(societyOf(req), ctx.unitId) });
  } catch (e: any) { map(res, e, "Failed to list parcels"); }
});

/** POST /parcels — guard/reception logs a delivery for a flat. */
router.post("/", authMiddleware, tenantMiddleware, canManageSecurity, validate(LogSchema), async (req, res) => {
  try {
    res.status(201).json({ parcel: await ParcelService.log(societyOf(req), { ...req.body, loggedBy: userIdOf(req) }) });
  } catch (e: any) { map(res, e, "Failed to log parcel"); }
});

/** POST /parcels/:id/collect — hand over against the resident's OTP. */
router.post("/:id/collect", authMiddleware, tenantMiddleware, canManageSecurity, validate(CollectSchema), async (req, res) => {
  try {
    res.json({ parcel: await ParcelService.collect(societyOf(req), req.params.id as string, { otp: req.body.otp, collectedBy: userIdOf(req) }) });
  } catch (e: any) { map(res, e, "Failed to collect parcel"); }
});

export default router;
