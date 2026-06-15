import { Router, Request, Response } from "express";
import { z } from "zod";
import { SocietyService } from "../services/society/SocietyService";
import { validate } from "../middleware/validate";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, canManageContent } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

/**
 * Admin Society Setup (capabilities 9, 10, 21, 22): profile, logo/branding,
 * settings, and onboarding checklist. Tenant-scoped by society_id.
 */

const router = Router();
const societyOf = (req: Request) => (req as any).societyId as string;
const s = z.string().trim().min(1);

const ContactSchema = z.object({
  label: z.string().max(60).optional(),
  name: z.string().max(120).optional(),
  phone: z.string().max(20).optional(),
  email: z.string().email().max(120).optional(),
}).strict();

const ProfileSchema = z.object({ body: z.object({
  name: s.max(160).optional(),
  registrationNo: z.string().max(80).optional(),
  address: z.string().max(500).optional(),
  timezone: z.string().max(60).optional(),
  currency: z.string().max(8).optional(),
  financialYearStart: z.string().regex(/^\d{2}-\d{2}$/).optional(),
  contacts: z.array(ContactSchema).max(20).optional(),
}).strict() });

const SettingsSchema = z.object({ body: z.object({
  numbering: z.record(z.string(), z.any()).optional(),
  billingDefaults: z.record(z.string(), z.any()).optional(),
  notificationPrefs: z.record(z.string(), z.any()).optional(),
  bookingPolicy: z.record(z.string(), z.any()).optional(),
  featureFlags: z.record(z.string(), z.any()).optional(),
}).strict() });

const LogoSchema = z.object({ body: z.object({ fileUrl: s.max(1000) }).strict() });

const map = (res: Response, e: any, fallback: string) => {
  if (e.code === "NOT_FOUND") return res.status(404).json({ success: false, error: e.message });
  logger.error({ error: e.message }, fallback);
  return res.status(500).json({ success: false, error: fallback });
};

// ---- Cap 9: Profile -----------------------------------------------------
router.get("/profile", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ success: true, data: await SocietyService.getProfile(societyOf(req)) }); }
  catch (e: any) { map(res, e, "Failed to get society profile"); }
});

router.put("/profile", authMiddleware, tenantMiddleware, canManageContent, validate(ProfileSchema), async (req, res) => {
  try { res.json({ success: true, data: await SocietyService.upsertProfile(societyOf(req), req.body) }); }
  catch (e: any) { map(res, e, "Failed to update society profile"); }
});

// ---- Cap 21: Settings ---------------------------------------------------
router.get("/settings", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ success: true, data: await SocietyService.getSettings(societyOf(req)) }); }
  catch (e: any) { map(res, e, "Failed to get society settings"); }
});

router.put("/settings", authMiddleware, tenantMiddleware, canManageContent, validate(SettingsSchema), async (req, res) => {
  try { res.json({ success: true, data: await SocietyService.upsertSettings(societyOf(req), req.body) }); }
  catch (e: any) { map(res, e, "Failed to update society settings"); }
});

// ---- Cap 10: Logo / branding -------------------------------------------
router.get("/logo", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ success: true, data: await SocietyService.getLogo(societyOf(req)) }); }
  catch (e: any) { map(res, e, "Failed to get logo"); }
});

router.put("/logo", authMiddleware, tenantMiddleware, canManageContent, validate(LogoSchema), async (req, res) => {
  try { res.json({ success: true, data: await SocietyService.setLogo(societyOf(req), req.body.fileUrl) }); }
  catch (e: any) { map(res, e, "Failed to set logo"); }
});

router.delete("/logo", authMiddleware, tenantMiddleware, canManageContent, async (req, res) => {
  try { res.json({ success: true, data: await SocietyService.deleteLogo(societyOf(req)) }); }
  catch (e: any) { map(res, e, "Failed to delete logo"); }
});

// ---- Cap 22: Onboarding checklist --------------------------------------
router.get("/setup-progress", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ success: true, data: await SocietyService.setupProgress(societyOf(req)) }); }
  catch (e: any) { map(res, e, "Failed to compute setup progress"); }
});

export default router;
