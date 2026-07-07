import { Router, Request, Response } from "express";
import { z } from "zod";
import { NoticeService } from "../services/notices/NoticeService";
import { validate } from "../middleware/validate";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, canManageContent } from "../../middleware/auth";
import { tenantMiddleware, requireSociety } from "../../middleware/tenantMiddleware";

const router = Router();

const societyOf = (req: Request) => (req as any).societyId as string;
const userOf = (req: Request) => (req as any).user || {};

// ---- Inline Zod schemas (request shape: { body, query, params }) ----

const NoticeTypeEnum = z.enum(["general", "event", "maintenance", "festival", "governance"]);
const PriorityEnum = z.enum(["low", "medium", "high", "critical"]);
const AudienceTypeEnum = z.enum(["all", "role", "wing", "block", "unit", "ownership", "custom"]);

const CreateNoticeSchema = z.object({
  body: z.object({
    title: z.string().min(1).max(300),
    body: z.string().min(1),
    type: NoticeTypeEnum.optional(),
    category: z.string().max(120).optional(),
    priority: PriorityEnum.optional(),
    ackRequired: z.boolean().optional(),
    expiresAt: z.string().datetime().optional(),
  }),
});

const UpdateNoticeSchema = z.object({
  body: z.object({
    title: z.string().min(1).max(300).optional(),
    body: z.string().min(1).optional(),
    type: NoticeTypeEnum.optional(),
    category: z.string().max(120).optional(),
    priority: PriorityEnum.optional(),
    ackRequired: z.boolean().optional(),
    expiresAt: z.string().datetime().nullable().optional(),
  }),
});

const SetAudiencesSchema = z.object({
  body: z.object({
    audiences: z
      .array(
        z.object({
          type: AudienceTypeEnum,
          value: z.string().max(200).optional(),
        })
      )
      .min(1),
  }),
});

const ScheduleSchema = z.object({
  body: z.object({
    publishAt: z.string().datetime(),
  }),
});

const errToStatus = (err: any, res: Response, fallbackMsg: string) => {
  if (err.code === "NOT_FOUND") return res.status(404).json({ error: err.message });
  if (err.code === "INVALID_STATE") return res.status(409).json({ error: err.message });
  logger.error({ error: err.message }, fallbackMsg);
  return res.status(500).json({ error: fallbackMsg });
};

// GET /notices — list (optionally filter by status)
router.get("/", authMiddleware, requireSociety, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const status = typeof req.query.status === "string" ? req.query.status : undefined;
    const limit = req.query.limit ? Number(req.query.limit) : undefined;
    const notices = await NoticeService.listNotices(societyOf(req), { status, limit });
    res.json({ notices });
  } catch (err: any) {
    logger.error({ error: err.message }, "List notices failed");
    res.status(500).json({ error: "Failed to list notices" });
  }
});

// GET /notices/unread/count — unread published notices for the current user
router.get("/unread/count", authMiddleware, requireSociety, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const unread = await NoticeService.unreadCountForUser(societyOf(req), userOf(req).uid);
    res.json({ unread });
  } catch (err: any) {
    logger.error({ error: err.message }, "Unread count failed");
    res.status(500).json({ error: "Failed to compute unread count" });
  }
});

// GET /notices/:id — detail with audiences + read stats
router.get("/:id", authMiddleware, requireSociety, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const detail = await NoticeService.getNotice(societyOf(req), (req.params.id as string));
    if (!detail) return res.status(404).json({ error: "Notice not found" });
    res.json(detail);
  } catch (err: any) {
    logger.error({ error: err.message }, "Get notice failed");
    res.status(500).json({ error: "Failed to get notice" });
  }
});

// POST /notices — create a draft (content managers)
router.post("/", authMiddleware, requireSociety, tenantMiddleware, canManageContent, validate(CreateNoticeSchema), async (req: Request, res: Response) => {
  try {
    const notice = await NoticeService.createNotice(societyOf(req), req.body, {
      id: userOf(req).uid,
      name: userOf(req).name,
    });
    res.status(201).json({ notice });
  } catch (err: any) {
    logger.error({ error: err.message }, "Create notice failed");
    res.status(500).json({ error: "Failed to create notice" });
  }
});

// PUT /notices/:id — edit (bumps version + snapshot)
router.put("/:id", authMiddleware, requireSociety, tenantMiddleware, canManageContent, validate(UpdateNoticeSchema), async (req: Request, res: Response) => {
  try {
    const notice = await NoticeService.updateNotice(societyOf(req), (req.params.id as string), req.body, userOf(req).uid);
    res.json({ notice });
  } catch (err: any) {
    return errToStatus(err, res, "Failed to update notice");
  }
});

// POST /notices/:id/audiences — replace audience targeting set
router.post("/:id/audiences", authMiddleware, requireSociety, tenantMiddleware, canManageContent, validate(SetAudiencesSchema), async (req: Request, res: Response) => {
  try {
    const audiences = await NoticeService.setAudiences(societyOf(req), (req.params.id as string), req.body.audiences);
    res.json({ audiences });
  } catch (err: any) {
    return errToStatus(err, res, "Failed to set audiences");
  }
});

// POST /notices/:id/schedule — schedule for future publication
router.post("/:id/schedule", authMiddleware, requireSociety, tenantMiddleware, canManageContent, validate(ScheduleSchema), async (req: Request, res: Response) => {
  try {
    const notice = await NoticeService.schedule(societyOf(req), (req.params.id as string), req.body.publishAt);
    res.json({ notice });
  } catch (err: any) {
    return errToStatus(err, res, "Failed to schedule notice");
  }
});

// POST /notices/:id/publish — publish now (or keep scheduled if future)
router.post("/:id/publish", authMiddleware, requireSociety, tenantMiddleware, canManageContent, async (req: Request, res: Response) => {
  try {
    const notice = await NoticeService.publish(societyOf(req), (req.params.id as string), userOf(req).uid);
    res.json({ notice });
  } catch (err: any) {
    return errToStatus(err, res, "Failed to publish notice");
  }
});

// POST /notices/:id/unpublish — revert to draft
router.post("/:id/unpublish", authMiddleware, requireSociety, tenantMiddleware, canManageContent, async (req: Request, res: Response) => {
  try {
    const notice = await NoticeService.unpublish(societyOf(req), (req.params.id as string));
    res.json({ notice });
  } catch (err: any) {
    return errToStatus(err, res, "Failed to unpublish notice");
  }
});

// POST /notices/:id/archive — archive (terminal)
router.post("/:id/archive", authMiddleware, requireSociety, tenantMiddleware, canManageContent, async (req: Request, res: Response) => {
  try {
    const notice = await NoticeService.archive(societyOf(req), (req.params.id as string));
    res.json({ notice });
  } catch (err: any) {
    return errToStatus(err, res, "Failed to archive notice");
  }
});

// POST /notices/:id/read — any authenticated user records a read receipt
router.post("/:id/read", authMiddleware, requireSociety, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const read = await NoticeService.markRead(societyOf(req), (req.params.id as string), userOf(req).uid);
    res.status(201).json({ read });
  } catch (err: any) {
    return errToStatus(err, res, "Failed to mark notice read");
  }
});

// POST /notices/:id/ack — acknowledge (only if ack_required)
router.post("/:id/ack", authMiddleware, requireSociety, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const read = await NoticeService.acknowledge(societyOf(req), (req.params.id as string), userOf(req).uid);
    res.status(201).json({ read });
  } catch (err: any) {
    return errToStatus(err, res, "Failed to acknowledge notice");
  }
});

export default router;
