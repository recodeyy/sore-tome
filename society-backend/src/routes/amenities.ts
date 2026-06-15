import { Router, Request, Response } from "express";
import { BookingService } from "../services/amenities/BookingService";
import { validate } from "../middleware/validate";
import { CreateAmenitySchema, BookAmenitySchema } from "../shared/schemas";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, adminOnly } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();
const societyOf = (req: Request) => (req as any).societyId as string;

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

// GET /amenities/:id/bookings — confirmed bookings for an amenity
router.get("/:id/bookings", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const bookings = await BookingService.list(societyOf(req), req.params.id);
    res.json({ bookings });
  } catch (err: any) {
    logger.error({ error: err.message }, "List bookings failed");
    res.status(500).json({ error: "Failed to list bookings" });
  }
});

// POST /amenities/:id/book — book a slot (overlap rejected by the DB constraint)
router.post("/:id/book", authMiddleware, tenantMiddleware, validate(BookAmenitySchema), async (req: Request, res: Response) => {
  try {
    const booking = await BookingService.book(societyOf(req), {
      amenityId: req.params.id,
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
    const booking = await BookingService.cancel(societyOf(req), req.params.bookingId);
    res.json({ booking });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Booking not found" });
    logger.error({ error: err.message }, "Cancel booking failed");
    res.status(500).json({ error: "Failed to cancel booking" });
  }
});

export default router;
