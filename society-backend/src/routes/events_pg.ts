import { Router, Request, Response } from "express";
import { z } from "zod";
import { EventService } from "../services/events/EventService";
import { validate } from "../middleware/validate";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, canManageContent } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();

const societyOf = (req: Request) => (req as any).societyId as string;
const userOf = (req: Request) => (req as any).user || {};

// ─── Inline Zod schemas (wrapped as { body } for the validate middleware) ──────
const CreateEventSchema = z.object({
  body: z
    .object({
      title: z.string().min(1).max(200),
      description: z.string().max(5000).optional(),
      location: z.string().max(300).optional(),
      startsAt: z.string().datetime(),
      endsAt: z.string().datetime().optional(),
      capacity: z.number().int().positive().nullable().optional(),
    })
    .strict(),
});

const RsvpSchema = z.object({
  body: z
    .object({
      guests: z.number().int().min(0).max(20).optional().default(0),
    })
    .strict(),
});

const AttendanceSchema = z.object({
  body: z
    .object({
      userId: z.string().min(1).max(128),
      attended: z.boolean(),
    })
    .strict(),
});

// GET /events/v2 — list events for the tenant
router.get("/", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const opts: any = {
      status: typeof req.query.status === "string" ? req.query.status : undefined,
      upcoming: req.query.upcoming === "true",
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    };
    const events = await EventService.listEvents(societyOf(req), opts);
    res.json({ events });
  } catch (err: any) {
    logger.error({ error: err.message }, "List events failed");
    res.status(500).json({ error: "Failed to list events" });
  }
});

// GET /events/v2/:id — event detail with RSVP counts
router.get("/:id", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const detail = await EventService.getEvent(societyOf(req), req.params.id);
    if (!detail) return res.status(404).json({ error: "Event not found" });
    res.json(detail);
  } catch (err: any) {
    logger.error({ error: err.message }, "Get event failed");
    res.status(500).json({ error: "Failed to get event" });
  }
});

// POST /events/v2 — create a draft event (admin)
router.post("/", authMiddleware, tenantMiddleware, canManageContent, validate(CreateEventSchema), async (req: Request, res: Response) => {
  try {
    const event = await EventService.createEvent(societyOf(req), req.body, userOf(req).uid);
    res.status(201).json({ event });
  } catch (err: any) {
    logger.error({ error: err.message }, "Create event failed");
    res.status(500).json({ error: "Failed to create event" });
  }
});

// POST /events/v2/:id/publish — publish a draft event (admin)
router.post("/:id/publish", authMiddleware, tenantMiddleware, canManageContent, async (req: Request, res: Response) => {
  try {
    const event = await EventService.publish(societyOf(req), req.params.id);
    res.json({ event });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Event not found" });
    if (err.code === "INVALID_STATE") return res.status(409).json({ error: err.message });
    logger.error({ error: err.message }, "Publish event failed");
    res.status(500).json({ error: "Failed to publish event" });
  }
});

// POST /events/v2/:id/cancel — cancel an event (admin)
router.post("/:id/cancel", authMiddleware, tenantMiddleware, canManageContent, async (req: Request, res: Response) => {
  try {
    const event = await EventService.cancel(societyOf(req), req.params.id);
    res.json({ event });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Event not found" });
    if (err.code === "INVALID_STATE") return res.status(409).json({ error: err.message });
    logger.error({ error: err.message }, "Cancel event failed");
    res.status(500).json({ error: "Failed to cancel event" });
  }
});

// POST /events/v2/:id/rsvp — any authenticated member RSVPs (auto-waitlist when full)
router.post("/:id/rsvp", authMiddleware, tenantMiddleware, validate(RsvpSchema), async (req: Request, res: Response) => {
  try {
    const rsvp = await EventService.rsvp(societyOf(req), req.params.id, userOf(req).uid, req.body.guests);
    res.status(201).json({ rsvp });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Event not found" });
    if (err.code === "INVALID_STATE") return res.status(409).json({ error: err.message });
    if (err.code === "EVENT_FULL") return res.status(409).json({ error: err.message });
    logger.error({ error: err.message }, "RSVP failed");
    res.status(500).json({ error: "Failed to RSVP" });
  }
});

// POST /events/v2/:id/rsvp/cancel — cancel own RSVP (promotes oldest waitlisted)
router.post("/:id/rsvp/cancel", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const result = await EventService.cancelRsvp(societyOf(req), req.params.id, userOf(req).uid);
    res.json(result);
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: err.message });
    logger.error({ error: err.message }, "Cancel RSVP failed");
    res.status(500).json({ error: "Failed to cancel RSVP" });
  }
});

// POST /events/v2/:id/attendance — mark attendance for a member (admin)
router.post("/:id/attendance", authMiddleware, tenantMiddleware, canManageContent, validate(AttendanceSchema), async (req: Request, res: Response) => {
  try {
    const rsvp = await EventService.markAttended(societyOf(req), req.params.id, req.body.userId, req.body.attended);
    res.json({ rsvp });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: err.message });
    logger.error({ error: err.message }, "Mark attendance failed");
    res.status(500).json({ error: "Failed to mark attendance" });
  }
});

export default router;
