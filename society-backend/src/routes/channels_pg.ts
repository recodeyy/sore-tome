import { Router, Request, Response } from "express";
import { z } from "zod";
import { ChannelService } from "../services/channels/ChannelService";
import { validate } from "../middleware/validate";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, canManageContent } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();

const societyOf = (req: Request) => (req as any).societyId as string;
const userOf = (req: Request) => (req as any).user || {};
const isAdminRole = (req: Request) =>
  ["main_admin", "secretary", "admin", "super_admin", "superadmin"].includes(userOf(req).role);

const s = z.string().trim().min(1);

const CreateChannelSchema = z.object({
  body: z.object({
    name: s.max(80),
    description: z.string().max(300).optional(),
    type: z.enum(["community", "announcement", "committee", "support"]).optional().default("community"),
    isReadOnly: z.boolean().optional().default(false),
  }).strict(),
});
const AddMemberSchema = z.object({
  body: z.object({ userId: s.max(64), role: z.enum(["member", "moderator"]).optional().default("member") }).strict(),
});
const PostMessageSchema = z.object({
  body: z.object({ body: s.max(4000), isOfficial: z.boolean().optional().default(false) }).strict(),
});
const ReadSchema = z.object({
  body: z.object({ lastReadMessageId: z.string().uuid().optional() }).strict(),
});
const ReportSchema = z.object({
  body: z.object({ reason: s.max(500) }).strict(),
});
const ModerateSchema = z.object({
  body: z.object({
    messageId: z.string().uuid().optional(),
    reportId: z.string().uuid().optional(),
    action: z.enum(["soft_delete", "dismiss", "warn"]),
    note: z.string().max(500).optional(),
  }).strict(),
});

// GET /channels-v2 — list channels with member counts
router.get("/", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const channels = await ChannelService.listChannels(societyOf(req), { includeArchived: req.query.archived === "true" });
    res.json({ channels });
  } catch (err: any) {
    logger.error({ error: err.message }, "List channels failed");
    res.status(500).json({ error: "Failed to list channels" });
  }
});

// POST /channels-v2 — create channel (admin)
router.post("/", authMiddleware, tenantMiddleware, canManageContent, validate(CreateChannelSchema), async (req: Request, res: Response) => {
  try {
    const channel = await ChannelService.createChannel(societyOf(req), req.body, userOf(req).uid);
    res.status(201).json({ channel });
  } catch (err: any) {
    if (err.code === "ALREADY_EXISTS") return res.status(409).json({ error: err.message });
    logger.error({ error: err.message }, "Create channel failed");
    res.status(500).json({ error: "Failed to create channel" });
  }
});

// POST /channels-v2/:id/members — add a member (admin)
router.post("/:id/members", authMiddleware, tenantMiddleware, canManageContent, validate(AddMemberSchema), async (req: Request, res: Response) => {
  try {
    const member = await ChannelService.addMember(societyOf(req), req.params.id, req.body.userId, req.body.role);
    res.status(201).json({ member });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Channel not found" });
    logger.error({ error: err.message }, "Add channel member failed");
    res.status(500).json({ error: "Failed to add member" });
  }
});

// GET /channels-v2/:id/messages — cursor-paginated messages
router.get("/:id/messages", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const result = await ChannelService.listMessages(societyOf(req), req.params.id, {
      limit: req.query.limit ? Number(req.query.limit) : undefined,
      cursor: typeof req.query.cursor === "string" ? req.query.cursor : undefined,
      includeDeleted: isAdminRole(req) && req.query.includeDeleted === "true",
    });
    res.json(result);
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Channel not found" });
    logger.error({ error: err.message }, "List messages failed");
    res.status(500).json({ error: "Failed to list messages" });
  }
});

// POST /channels-v2/:id/messages — post a message (read-only channels: admins only)
router.post("/:id/messages", authMiddleware, tenantMiddleware, validate(PostMessageSchema), async (req: Request, res: Response) => {
  try {
    const message = await ChannelService.postMessage(societyOf(req), req.params.id, {
      body: req.body.body,
      authorId: userOf(req).uid,
      authorName: userOf(req).name,
      isOfficial: req.body.isOfficial,
      isAdmin: isAdminRole(req),
    });
    res.status(201).json({ message });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Channel not found" });
    if (err.code === "READ_ONLY") return res.status(403).json({ error: err.message });
    if (err.code === "INVALID_STATE") return res.status(409).json({ error: err.message });
    logger.error({ error: err.message }, "Post message failed");
    res.status(500).json({ error: "Failed to post message" });
  }
});

// POST /channels-v2/:id/read — mark read
router.post("/:id/read", authMiddleware, tenantMiddleware, validate(ReadSchema), async (req: Request, res: Response) => {
  try {
    const receipt = await ChannelService.markRead(societyOf(req), req.params.id, userOf(req).uid, req.body.lastReadMessageId);
    res.json({ receipt });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Channel not found" });
    logger.error({ error: err.message }, "Mark read failed");
    res.status(500).json({ error: "Failed to mark read" });
  }
});

// GET /channels-v2/:id/unread — unread count for the caller
router.get("/:id/unread", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const count = await ChannelService.unreadCount(societyOf(req), req.params.id, userOf(req).uid);
    res.json({ count });
  } catch (err: any) {
    logger.error({ error: err.message }, "Unread count failed");
    res.status(500).json({ error: "Failed to compute unread count" });
  }
});

// POST /channels-v2/messages/:messageId/report — abuse report (any member)
router.post("/messages/:messageId/report", authMiddleware, tenantMiddleware, validate(ReportSchema), async (req: Request, res: Response) => {
  try {
    const report = await ChannelService.reportMessage(societyOf(req), req.params.messageId, userOf(req).uid, req.body.reason);
    res.status(201).json({ report });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Message not found" });
    logger.error({ error: err.message }, "Report message failed");
    res.status(500).json({ error: "Failed to report message" });
  }
});

// GET /channels-v2/moderation/reports — moderation queue (admin)
router.get("/moderation/reports", authMiddleware, tenantMiddleware, canManageContent, async (req: Request, res: Response) => {
  try {
    const reports = await ChannelService.listReports(societyOf(req), {
      status: typeof req.query.status === "string" ? req.query.status : undefined,
    });
    res.json({ reports });
  } catch (err: any) {
    logger.error({ error: err.message }, "List reports failed");
    res.status(500).json({ error: "Failed to list reports" });
  }
});

// POST /channels-v2/moderation/actions — take a moderation action (admin)
router.post("/moderation/actions", authMiddleware, tenantMiddleware, canManageContent, validate(ModerateSchema), async (req: Request, res: Response) => {
  try {
    const action = await ChannelService.moderate(societyOf(req), { ...req.body, actorId: userOf(req).uid });
    res.status(201).json({ action });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: err.message });
    if (err.code === "INVALID_INPUT") return res.status(400).json({ error: err.message });
    logger.error({ error: err.message }, "Moderation action failed");
    res.status(500).json({ error: "Failed to take moderation action" });
  }
});

export default router;
