import { Router, Request, Response } from "express";
import { z } from "zod";
import { MeetingService } from "../services/meetings/MeetingService";
import { validate } from "../middleware/validate";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, canManageContent } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();

const societyOf = (req: Request) => (req as any).societyId as string;
const userOf = (req: Request) => (req as any).user || {};

// ---- Inline Zod schemas -----------------------------------------------------

const AgendaItemInput = z.object({
  title: z.string().min(1),
  description: z.string().optional().nullable(),
});

const CreateMeetingSchema = z.object({
  body: z.object({
    title: z.string().min(1),
    type: z.enum(["agm", "committee", "general"]).optional(),
    scheduledAt: z.string().optional().nullable(),
    location: z.string().optional().nullable(),
    quorumRequired: z.number().int().min(0).optional(),
    agendaItems: z.array(AgendaItemInput).optional(),
  }),
});

const AddAgendaSchema = z.object({
  body: z.object({
    title: z.string().min(1),
    description: z.string().optional().nullable(),
    position: z.number().int().min(0).optional(),
  }),
});

const AttendanceSchema = z.object({
  body: z.object({ present: z.boolean() }),
});

const ProxySchema = z.object({
  body: z.object({ proxyHolderId: z.string().min(1) }),
});

const ResolutionSchema = z.object({
  body: z.object({
    title: z.string().min(1),
    text: z.string().optional().nullable(),
  }),
});

const ResolutionOutcomeSchema = z.object({
  body: z.object({
    outcome: z.enum(["pending", "passed", "failed"]),
    votesFor: z.number().int().min(0).optional(),
    votesAgainst: z.number().int().min(0).optional(),
  }),
});

const MinutesSchema = z.object({
  body: z.object({ body: z.string().min(1) }),
});

const ActionItemSchema = z.object({
  body: z.object({
    description: z.string().min(1),
    ownerId: z.string().optional().nullable(),
    dueDate: z.string().optional().nullable(),
  }),
});

const ActionItemUpdateSchema = z.object({
  body: z.object({ status: z.enum(["open", "in_progress", "done"]) }),
});

// ---- Routes -----------------------------------------------------------------

// GET /meetings — list (optional ?status, ?limit)
router.get("/", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const meetings = await MeetingService.listMeetings(societyOf(req), {
      status: typeof req.query.status === "string" ? req.query.status : undefined,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    });
    res.json({ meetings });
  } catch (err: any) {
    logger.error({ error: err.message }, "List meetings failed");
    res.status(500).json({ error: "Failed to list meetings" });
  }
});

// GET /meetings/:id — detail (agenda, attendance count, resolutions, minutes, action items)
router.get("/:id", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const detail = await MeetingService.getMeeting(societyOf(req), (req.params.id as string));
    if (!detail) return res.status(404).json({ error: "Meeting not found" });
    res.json(detail);
  } catch (err: any) {
    logger.error({ error: err.message }, "Get meeting failed");
    res.status(500).json({ error: "Failed to get meeting" });
  }
});

// POST /meetings — create with optional agenda (admin)
router.post("/", authMiddleware, tenantMiddleware, canManageContent, validate(CreateMeetingSchema), async (req: Request, res: Response) => {
  try {
    const meeting = await MeetingService.createMeeting(societyOf(req), req.body, userOf(req).uid);
    res.status(201).json({ meeting });
  } catch (err: any) {
    logger.error({ error: err.message }, "Create meeting failed");
    res.status(500).json({ error: "Failed to create meeting" });
  }
});

// POST /meetings/:id/agenda — add an agenda item (admin)
router.post("/:id/agenda", authMiddleware, tenantMiddleware, canManageContent, validate(AddAgendaSchema), async (req: Request, res: Response) => {
  try {
    const item = await MeetingService.addAgendaItem(societyOf(req), (req.params.id as string), req.body);
    res.status(201).json({ agendaItem: item });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Meeting not found" });
    logger.error({ error: err.message }, "Add agenda item failed");
    res.status(500).json({ error: "Failed to add agenda item" });
  }
});

// POST /meetings/:id/attendance — mark self present/absent (any auth user)
router.post("/:id/attendance", authMiddleware, tenantMiddleware, validate(AttendanceSchema), async (req: Request, res: Response) => {
  try {
    const att = await MeetingService.recordAttendance(societyOf(req), (req.params.id as string), userOf(req).uid, req.body.present);
    res.status(201).json({ attendance: att });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Meeting not found" });
    logger.error({ error: err.message }, "Record attendance failed");
    res.status(500).json({ error: "Failed to record attendance" });
  }
});

// POST /meetings/:id/proxy — grant own vote to a proxy holder (any auth user)
router.post("/:id/proxy", authMiddleware, tenantMiddleware, validate(ProxySchema), async (req: Request, res: Response) => {
  try {
    const proxy = await MeetingService.grantProxy(societyOf(req), (req.params.id as string), userOf(req).uid, req.body.proxyHolderId);
    res.status(201).json({ proxy });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Meeting not found" });
    logger.error({ error: err.message }, "Grant proxy failed");
    res.status(500).json({ error: "Failed to grant proxy" });
  }
});

// GET /meetings/:id/quorum — present (incl. proxies) vs required
router.get("/:id/quorum", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const status = await MeetingService.quorumStatus(societyOf(req), (req.params.id as string));
    res.json(status);
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Meeting not found" });
    logger.error({ error: err.message }, "Quorum status failed");
    res.status(500).json({ error: "Failed to get quorum status" });
  }
});

// POST /meetings/:id/resolutions — add a resolution (admin)
router.post("/:id/resolutions", authMiddleware, tenantMiddleware, canManageContent, validate(ResolutionSchema), async (req: Request, res: Response) => {
  try {
    const resolution = await MeetingService.addResolution(societyOf(req), (req.params.id as string), req.body);
    res.status(201).json({ resolution });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Meeting not found" });
    logger.error({ error: err.message }, "Add resolution failed");
    res.status(500).json({ error: "Failed to add resolution" });
  }
});

// POST /meetings/resolutions/:rid/outcome — record voting outcome (admin)
router.post("/resolutions/:rid/outcome", authMiddleware, tenantMiddleware, canManageContent, validate(ResolutionOutcomeSchema), async (req: Request, res: Response) => {
  try {
    const resolution = await MeetingService.recordResolutionOutcome(
      societyOf(req), (req.params.rid as string), req.body.outcome, req.body.votesFor || 0, req.body.votesAgainst || 0
    );
    res.json({ resolution });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Resolution not found" });
    logger.error({ error: err.message }, "Record resolution outcome failed");
    res.status(500).json({ error: "Failed to record resolution outcome" });
  }
});

// POST /meetings/:id/minutes — record minutes (admin)
router.post("/:id/minutes", authMiddleware, tenantMiddleware, canManageContent, validate(MinutesSchema), async (req: Request, res: Response) => {
  try {
    const minutes = await MeetingService.addMinutes(societyOf(req), (req.params.id as string), req.body, userOf(req).uid);
    res.status(201).json({ minutes });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Meeting not found" });
    logger.error({ error: err.message }, "Add minutes failed");
    res.status(500).json({ error: "Failed to add minutes" });
  }
});

// POST /meetings/:id/action-items — create an action item (admin)
router.post("/:id/action-items", authMiddleware, tenantMiddleware, canManageContent, validate(ActionItemSchema), async (req: Request, res: Response) => {
  try {
    const actionItem = await MeetingService.addActionItem(societyOf(req), (req.params.id as string), req.body);
    res.status(201).json({ actionItem });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Meeting not found" });
    logger.error({ error: err.message }, "Add action item failed");
    res.status(500).json({ error: "Failed to add action item" });
  }
});

// PATCH /meetings/action-items/:aid — update completion status (admin)
router.patch("/action-items/:aid", authMiddleware, tenantMiddleware, canManageContent, validate(ActionItemUpdateSchema), async (req: Request, res: Response) => {
  try {
    const actionItem = await MeetingService.updateActionItem(societyOf(req), (req.params.aid as string), req.body.status);
    res.json({ actionItem });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Action item not found" });
    logger.error({ error: err.message }, "Update action item failed");
    res.status(500).json({ error: "Failed to update action item" });
  }
});

// POST /meetings/:id/start — scheduled -> in_progress (admin)
router.post("/:id/start", authMiddleware, tenantMiddleware, canManageContent, async (req: Request, res: Response) => {
  try {
    const meeting = await MeetingService.startMeeting(societyOf(req), (req.params.id as string));
    res.json({ meeting });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Meeting not found" });
    if (err.code === "INVALID_STATE") return res.status(409).json({ error: err.message });
    logger.error({ error: err.message }, "Start meeting failed");
    res.status(500).json({ error: "Failed to start meeting" });
  }
});

// POST /meetings/:id/complete — in_progress -> completed (admin)
router.post("/:id/complete", authMiddleware, tenantMiddleware, canManageContent, async (req: Request, res: Response) => {
  try {
    const meeting = await MeetingService.completeMeeting(societyOf(req), (req.params.id as string));
    res.json({ meeting });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Meeting not found" });
    if (err.code === "INVALID_STATE") return res.status(409).json({ error: err.message });
    logger.error({ error: err.message }, "Complete meeting failed");
    res.status(500).json({ error: "Failed to complete meeting" });
  }
});

// POST /meetings/:id/cancel — scheduled -> cancelled (admin)
router.post("/:id/cancel", authMiddleware, tenantMiddleware, canManageContent, async (req: Request, res: Response) => {
  try {
    const meeting = await MeetingService.cancelMeeting(societyOf(req), (req.params.id as string));
    res.json({ meeting });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Meeting not found" });
    if (err.code === "INVALID_STATE") return res.status(409).json({ error: err.message });
    logger.error({ error: err.message }, "Cancel meeting failed");
    res.status(500).json({ error: "Failed to cancel meeting" });
  }
});

export default router;
