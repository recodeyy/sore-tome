import { Router, Request, Response } from "express";
import { z } from "zod";
import { BookingService } from "../services/amenities/BookingService";
import { validate } from "../middleware/validate";
import { CreateAmenitySchema, BookAmenitySchema } from "../shared/schemas";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, adminOnly, canManageContent } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();
const societyOf = (req: Request) => (req as any).societyId as string;

// The shared `validate` middleware reassigns `req.params` to the schema's parsed
// `params` (undefined when a schema omits it), which would strip the `:id` path
// param. For routes that both validate a body AND need the path id, declare the
// param in the schema so it survives validation.
const BookWithIdSchema = z.object({
  params: z.object({ id: z.string() }),
  body: BookAmenitySchema.shape.body,
});

const BlackoutSchema = z.object({
  body: z.object({
    fromAt: z.string().datetime(),
    toAt: z.string().datetime(),
    reason: z.string().max(300).optional(),
  }).strict(),
});

const PricingSchema = z.object({
  body: z.object({
    priceMinor: z.number().int().nonnegative().optional(),
    depositMinor: z.number().int().nonnegative().optional(),
    requiresApproval: z.boolean().optional(),
    maxPerMember: z.number().int().positive().optional(),
    openMinutes: z.number().int().min(0).max(1440).optional(),
    closeMinutes: z.number().int().min(0).max(1440).optional(),
  }).strict(),
});

const CancelSchema = z.object({
  params: z.object({ id: z.string() }),
  body: z.object({ withRefund: z.boolean().optional().default(false) }).strict(),
});

const RescheduleSchema = z.object({
  body: z.object({
    startAt: z.string().datetime(),
    endAt: z.string().datetime(),
  }).strict(),
});

const ReviewSchema = z.object({
  body: z.object({
    rating: z.number().int().min(1).max(5),
    comment: z.string().max(1000).optional(),
    memberId: z.string().optional(),
    bookingId: z.string().uuid().optional(),
  }).strict(),
});

const AnalyticsSchema = z.object({
  query: z.object({
    fromAt: z.string().datetime(),
    toAt: z.string().datetime(),
  }),
});

const ENH_CODES: Record<string, number> = {
  BLACKOUT: 409, OUTSIDE_HOURS: 409, LIMIT_REACHED: 409, INVALID_STATE: 409,
  SLOT_TAKEN: 409, INVALID_RANGE: 400, NOT_FOUND: 404,
};

function handleEnhErr(err: any, res: Response, msg: string) {
  const status = ENH_CODES[err.code];
  if (status) return res.status(status).json({ error: err.message });
  logger.error({ error: err.message }, msg);
  return res.status(500).json({ error: msg });
}

// GET /amenities — list all amenities for the society
router.get("/", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const amenities = await BookingService.listAmenities(societyOf(req));
    res.json({ amenities });
  } catch (err: any) {
    logger.error({ error: err.message }, "List amenities failed");
    res.status(500).json({ error: "Failed to list amenities" });
  }
});

// POST /amenities — create an amenity (admin)
router.post("/", authMiddleware, tenantMiddleware, adminOnly, validate(CreateAmenitySchema), async (req: Request, res: Response) => {
  try {
    const amenity = await BookingService.createAmenity(societyOf(req), req.body);
    res.status(201).json({ amenity });
  } catch (err: any) {
    logger.error({ error: err.message }, "Create amenity failed");
    res.status(500).json({ error: "Failed to create amenity" });
  }
});

// GET /amenities/bookings/mine — the caller's own bookings (registered BEFORE
// any /:id route so "bookings" isn't captured as an amenity id)
router.get("/bookings/mine", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const bookings = await BookingService.listMine(societyOf(req), (req as any).user?.uid);
    res.json({ bookings });
  } catch (err: any) {
    logger.error({ error: err.message }, "List my bookings failed");
    res.status(500).json({ error: "Failed to list my bookings" });
  }
});

// GET /amenities/:id/bookings — confirmed bookings for an amenity
router.get("/:id/bookings", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const bookings = await BookingService.list(societyOf(req), (req.params.id as string));
    res.json({ bookings });
  } catch (err: any) {
    logger.error({ error: err.message }, "List bookings failed");
    res.status(500).json({ error: "Failed to list bookings" });
  }
});

// POST /amenities/:id/book — book a slot (overlap rejected by the DB constraint)
router.post("/:id/book", authMiddleware, tenantMiddleware, validate(BookWithIdSchema), async (req: Request, res: Response) => {
  try {
    const booking = await BookingService.book(societyOf(req), {
      amenityId: (req.params.id as string),
      memberId: req.body.memberId || (req as any).user?.uid,
      startAt: req.body.startAt,
      endAt: req.body.endAt,
    });
    res.status(201).json({ booking });
  } catch (err: any) {
    if (err.code === "SLOT_TAKEN") return res.status(409).json({ error: err.message });
    if (err.code === "INVALID_RANGE") return res.status(400).json({ error: err.message });
    logger.error({ error: err.message }, "Booking failed");
    res.status(500).json({ error: "Failed to book amenity" });
  }
});

// DELETE /amenities/bookings/:bookingId — cancel a booking
router.delete("/bookings/:bookingId", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const booking = await BookingService.cancel(societyOf(req), (req.params.bookingId as string));
    res.json({ booking });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Booking not found" });
    logger.error({ error: err.message }, "Cancel booking failed");
    res.status(500).json({ error: "Failed to cancel booking" });
  }
});

// POST /amenities/:id/blackouts — register a blackout (admin)
router.post("/:id/blackouts", authMiddleware, tenantMiddleware, canManageContent, validate(BlackoutSchema), async (req: Request, res: Response) => {
  try {
    const blackout = await BookingService.addBlackout(societyOf(req), (req.params.id as string), req.body);
    res.status(201).json({ blackout });
  } catch (err: any) {
    handleEnhErr(err, res, "Failed to add blackout");
  }
});

// PATCH /amenities/:id/pricing — set pricing/hours/approval/cap (admin)
router.patch("/:id/pricing", authMiddleware, tenantMiddleware, canManageContent, validate(PricingSchema), async (req: Request, res: Response) => {
  try {
    const amenity = await BookingService.setPricing(societyOf(req), (req.params.id as string), req.body);
    res.json({ amenity });
  } catch (err: any) {
    handleEnhErr(err, res, "Failed to set pricing");
  }
});

// POST /amenities/:id/request — request a booking (auth)
router.post("/:id/request", authMiddleware, tenantMiddleware, validate(BookWithIdSchema), async (req: Request, res: Response) => {
  try {
    const booking = await BookingService.requestBooking(societyOf(req), {
      amenityId: (req.params.id as string),
      memberId: req.body.memberId || (req as any).user?.uid,
      startAt: req.body.startAt,
      endAt: req.body.endAt,
    });
    res.status(201).json({ booking });
  } catch (err: any) {
    handleEnhErr(err, res, "Failed to request booking");
  }
});

// POST /amenities/bookings/:id/approve (admin)
router.post("/bookings/:id/approve", authMiddleware, tenantMiddleware, canManageContent, async (req: Request, res: Response) => {
  try {
    const booking = await BookingService.approveBooking(societyOf(req), (req.params.id as string));
    res.json({ booking });
  } catch (err: any) {
    handleEnhErr(err, res, "Failed to approve booking");
  }
});

// POST /amenities/bookings/:id/reject (admin)
router.post("/bookings/:id/reject", authMiddleware, tenantMiddleware, canManageContent, async (req: Request, res: Response) => {
  try {
    const booking = await BookingService.rejectBooking(societyOf(req), (req.params.id as string));
    res.json({ booking });
  } catch (err: any) {
    handleEnhErr(err, res, "Failed to reject booking");
  }
});

// POST /amenities/bookings/:id/cancel (auth)
router.post("/bookings/:id/cancel", authMiddleware, tenantMiddleware, validate(CancelSchema), async (req: Request, res: Response) => {
  try {
    const booking = await BookingService.cancelBooking(societyOf(req), (req.params.id as string), req.body.withRefund);
    res.json({ booking });
  } catch (err: any) {
    handleEnhErr(err, res, "Failed to cancel booking");
  }
});

// POST /amenities/bookings/:id/no-show (admin)
router.post("/bookings/:id/no-show", authMiddleware, tenantMiddleware, canManageContent, async (req: Request, res: Response) => {
  try {
    const booking = await BookingService.markNoShow(societyOf(req), (req.params.id as string));
    res.json({ booking });
  } catch (err: any) {
    handleEnhErr(err, res, "Failed to mark no-show");
  }
});

// POST /amenities/bookings/:id/reschedule (auth)
router.post("/bookings/:id/reschedule", authMiddleware, tenantMiddleware, validate(RescheduleSchema), async (req: Request, res: Response) => {
  try {
    const booking = await BookingService.rescheduleBooking(societyOf(req), (req.params.id as string), req.body);
    res.json({ booking });
  } catch (err: any) {
    handleEnhErr(err, res, "Failed to reschedule booking");
  }
});

// POST /amenities/:id/reviews (auth)
router.post("/:id/reviews", authMiddleware, tenantMiddleware, validate(ReviewSchema), async (req: Request, res: Response) => {
  try {
    const review = await BookingService.addReview(societyOf(req), (req.params.id as string), {
      ...req.body,
      memberId: req.body.memberId || (req as any).user?.uid,
    });
    res.status(201).json({ review });
  } catch (err: any) {
    handleEnhErr(err, res, "Failed to add review");
  }
});

// GET /amenities/:id/reviews (auth)
router.get("/:id/reviews", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const result = await BookingService.listReviews(societyOf(req), (req.params.id as string));
    res.json(result);
  } catch (err: any) {
    handleEnhErr(err, res, "Failed to list reviews");
  }
});

// GET /amenities/:id/analytics?fromAt=&toAt= (admin) — utilization + revenue (cap 85)
router.get("/:id/analytics", authMiddleware, tenantMiddleware, canManageContent, validate(AnalyticsSchema), async (req: Request, res: Response) => {
  try {
    const result = await BookingService.analytics(
      societyOf(req), (req.params.id as string),
      String(req.query.fromAt), String(req.query.toAt)
    );
    res.json(result);
  } catch (err: any) {
    handleEnhErr(err, res, "Failed to compute analytics");
  }
});

export default router;
