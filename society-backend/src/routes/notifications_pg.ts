import { Router, Request, Response } from "express";
import { z } from "zod";
import { NotificationService } from "../services/notifications/NotificationService";
import { validate } from "../middleware/validate";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, canManageContent } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();

const societyOf = (req: Request) => (req as any).societyId as string;
const userOf = (req: Request) => (req as any).user || {};

const RegisterDeviceSchema = z.object({
  body: z.object({
    token: z.string().min(1),
    platform: z.enum(["android", "ios", "web"]).optional(),
    appVersion: z.string().max(40).optional(),
  }),
});

const RemoveDeviceSchema = z.object({
  body: z.object({ token: z.string().min(1) }),
});

const TestNotifySchema = z.object({
  body: z.object({
    userId: z.string().min(1),
    title: z.string().min(1),
    body: z.string().optional(),
  }),
});

// POST /devices — register/refresh the caller's device token (MR-001).
// Auth only — a user without an active society scope (e.g. mid-onboarding)
// must still be reachable by push, so tenantMiddleware is NOT required here.
router.post("/devices", authMiddleware, validate(RegisterDeviceSchema), async (req: Request, res: Response) => {
  try {
    const device = await NotificationService.registerDevice(
      userOf(req).society_id || null, userOf(req).uid, req.body.token,
      req.body.platform || "android", req.body.appVersion
    );
    res.status(200).json({ success: true, device });
  } catch (err: any) {
    logger.error({ error: err.message }, "Register device failed");
    res.status(500).json({ error: "Failed to register device" });
  }
});

// DELETE /devices — unregister a device token (logout / token rotation).
router.delete("/devices", authMiddleware, validate(RemoveDeviceSchema), async (req: Request, res: Response) => {
  try {
    const result = await NotificationService.removeDevice(userOf(req).uid, req.body.token);
    res.status(200).json({ success: true, ...result });
  } catch (err: any) {
    logger.error({ error: err.message }, "Remove device failed");
    res.status(500).json({ error: "Failed to remove device" });
  }
});

// GET / — list the caller's notifications
router.get("/", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const notifications = await NotificationService.listForUser(societyOf(req), userOf(req).uid);
    res.json({ notifications });
  } catch (err: any) {
    logger.error({ error: err.message }, "List notifications failed");
    res.status(500).json({ error: "Failed to list notifications" });
  }
});

// POST /test — admin sends a test notification to a user
router.post("/test", authMiddleware, tenantMiddleware, canManageContent, validate(TestNotifySchema), async (req: Request, res: Response) => {
  try {
    const result = await NotificationService.notifyUser(societyOf(req), req.body.userId, {
      title: req.body.title, body: req.body.body,
    });
    res.status(201).json(result);
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: err.message });
    logger.error({ error: err.message }, "Test notification failed");
    res.status(500).json({ error: "Failed to send notification" });
  }
});

export default router;
