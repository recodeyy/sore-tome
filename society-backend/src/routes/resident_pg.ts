import { Router, Request, Response } from "express";
import { z } from "zod";
import { ResidentService } from "../services/resident/ResidentService";
import { validate } from "../middleware/validate";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();

const societyOf = (req: Request) => (req as any).societyId as string;
const userIdOf = (req: Request) => ((req as any).user?.uid || (req as any).context?.userId) as string | undefined;
const s = z.string().trim().min(1);

const ComplaintSchema = z.object({ body: z.object({
  title: s.max(160),
  description: s.max(4000),
  categoryId: z.string().uuid().optional(),
  location: z.string().max(160).optional(),
  priority: z.enum(["low", "medium", "high", "critical"]).optional(),
}).strict() });

const BookingSchema = z.object({ body: z.object({
  amenityId: z.string().uuid(),
  startAt: s,
  endAt: s,
}).strict() });

const VoteSchema = z.object({ body: z.object({ optionId: z.string().uuid() }).strict() });

const VisitorSchema = z.object({ body: z.object({
  visitorName: s.max(120),
  visitorPhone: z.string().max(20).optional(),
  purpose: z.string().max(200).optional(),
  expectedAt: s.optional(),
  expiresAt: s.optional(),
}).strict() });

const map = (res: Response, e: any, fallback: string) => {
  if (e.code === "NOT_A_MEMBER") return res.status(403).json({ error: e.message });
  if (e.code === "NOT_FOUND") return res.status(404).json({ error: e.message });
  if (e.code === "NO_UNIT") return res.status(409).json({ error: e.message });
  if (["INVALID_STATE", "ALREADY_VOTED", "NOT_ELIGIBLE", "SLOT_TAKEN", "BLACKOUT",
       "OUTSIDE_HOURS", "LIMIT_REACHED", "INVALID_RANGE"].includes(e.code)) {
    return res.status(409).json({ error: e.message });
  }
  logger.error({ error: e.message }, fallback);
  return res.status(500).json({ error: fallback });
};

/** Resolves the resident context (society + own member/unit) for every request. */
async function withCtx(req: Request, res: Response, fn: (ctx: any) => Promise<any>, fallback: string) {
  try {
    const userId = userIdOf(req);
    if (!userId) return res.status(401).json({ error: "Unauthenticated" });
    const ctx = await ResidentService.resolveContext(societyOf(req), userId);
    return await fn(ctx);
  } catch (e: any) { return map(res, e, fallback); }
}

router.use(authMiddleware, tenantMiddleware);

router.get("/dashboard", (req, res) =>
  withCtx(req, res, async (ctx) => res.json({ dashboard: await ResidentService.dashboard(ctx) }), "Failed to load dashboard"));

router.get("/dues", (req, res) =>
  withCtx(req, res, async (ctx) => res.json({ dues: await ResidentService.dues(ctx) }), "Failed to load dues"));

router.get("/payments", (req, res) =>
  withCtx(req, res, async (ctx) => res.json({ payments: await ResidentService.payments(ctx) }), "Failed to load payments"));

router.get("/complaints", (req, res) =>
  withCtx(req, res, async (ctx) => res.json({ complaints: await ResidentService.complaints(ctx) }), "Failed to load complaints"));

router.post("/complaints", validate(ComplaintSchema), (req, res) =>
  withCtx(req, res, async (ctx) => res.status(201).json({ complaint: await ResidentService.raiseComplaint(ctx, req.body) }), "Failed to raise complaint"));

router.get("/bookings", (req, res) =>
  withCtx(req, res, async (ctx) => res.json({ bookings: await ResidentService.bookings(ctx) }), "Failed to load bookings"));

router.post("/bookings", validate(BookingSchema), (req, res) =>
  withCtx(req, res, async (ctx) => res.status(201).json({ booking: await ResidentService.requestBooking(ctx, req.body) }), "Failed to request booking"));

router.get("/notices", (req, res) =>
  withCtx(req, res, async (ctx) => res.json({ notices: await ResidentService.notices(ctx) }), "Failed to load notices"));

router.post("/polls/:id/vote", validate(VoteSchema), (req, res) =>
  withCtx(req, res, async (ctx) => res.status(201).json({ vote: await ResidentService.vote(ctx, req.params.id as string, req.body.optionId) }), "Failed to cast vote"));

router.get("/visitors", (req, res) =>
  withCtx(req, res, async (ctx) => res.json({ visitors: await ResidentService.visitors(ctx) }), "Failed to load visitors"));

router.post("/visitors", validate(VisitorSchema), (req, res) =>
  withCtx(req, res, async (ctx) => res.status(201).json({ visitor: await ResidentService.preApproveVisitor(ctx, req.body) }), "Failed to pre-approve visitor"));

export default router;
