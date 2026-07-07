import { Router, Request, Response } from "express";
import { z } from "zod";
import { ParkingService } from "../services/parking/ParkingService";
import { validate } from "../middleware/validate";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, canManageFacilities } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();
const societyOf = (req: Request) => (req as any).societyId as string;
const userOf = (req: Request) => (req as any).user || {};
const s = z.string().trim().min(1);

const SlotSchema = z.object({ body: z.object({ code: s.max(40), type: z.enum(["car", "bike", "ev", "visitor", "accessible"]).optional(), location: z.string().max(80).optional(), isEv: z.boolean().optional(), isAccessible: z.boolean().optional(), isReserved: z.boolean().optional() }).strict() });
const VehicleSchema = z.object({ body: z.object({ plate: s.max(20), type: z.enum(["car", "bike", "ev", "other"]).optional(), unitId: z.string().max(64).optional(), ownerId: z.string().max(64).optional(), makeModel: z.string().max(80).optional() }).strict() });
const AllocateSchema = z.object({ body: z.object({ slotId: z.string().uuid(), vehicleId: z.string().uuid().optional(), unitId: z.string().max(64).optional(), allocatedTo: z.string().max(64).optional() }).strict() });
const TransferSchema = z.object({ body: z.object({ toSlotId: z.string().uuid() }).strict() });
const RequestSchema = z.object({ body: z.object({ unitId: z.string().max(64).optional(), vehicleType: z.enum(["car", "bike", "ev"]).optional() }).strict() });
const VisitorSchema = z.object({ body: z.object({ plate: s.max(20), visitingUnitId: z.string().max(64).optional(), slotId: z.string().uuid().optional(), validUntil: z.string().datetime() }).strict() });
const ViolationSchema = z.object({ body: z.object({ slotId: z.string().uuid().optional(), plate: z.string().max(20).optional(), description: s.max(300), evidenceUrl: z.string().max(500).optional(), fineMinor: z.number().int().nonnegative().optional() }).strict() });
const ResolveViolationSchema = z.object({ body: z.object({ status: z.enum(["waived", "paid", "disputed"]) }).strict() });

const map = (res: Response, e: any, fallback: string) => {
  if (e.code === "NOT_FOUND") return res.status(404).json({ error: e.message });
  if (["SLOT_TAKEN", "INVALID_STATE", "ALREADY_EXISTS"].includes(e.code)) return res.status(409).json({ error: e.message });
  logger.error({ error: e.message }, fallback);
  return res.status(500).json({ error: fallback });
};

// Slots
router.get("/slots", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ slots: await ParkingService.listSlots(societyOf(req), { status: req.query.status as string }) }); }
  catch (e: any) { map(res, e, "Failed to list slots"); }
});
// Resident-facing: my active parking allocation(s). No canManageFacilities —
// any authenticated tenant member may read their own allocations.
router.get("/my", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ allocations: await ParkingService.listForResident(societyOf(req), userOf(req).uid) }); }
  catch (e: any) { map(res, e, "Failed to list my parking"); }
});
router.post("/slots", authMiddleware, tenantMiddleware, canManageFacilities, validate(SlotSchema), async (req, res) => {
  try { res.status(201).json({ slot: await ParkingService.createSlot(societyOf(req), req.body) }); }
  catch (e: any) { map(res, e, "Failed to create slot"); }
});

// Vehicles
router.post("/vehicles", authMiddleware, tenantMiddleware, validate(VehicleSchema), async (req, res) => {
  try { res.status(201).json({ vehicle: await ParkingService.registerVehicle(societyOf(req), { ...req.body, ownerId: req.body.ownerId || userOf(req).uid }) }); }
  catch (e: any) { map(res, e, "Failed to register vehicle"); }
});

// Allocations
// MR-004: the Flutter admin app lists allocations here; only POST existed
// before, so GET 404'd. Society-scoped; committee/admin roles only.
router.get("/allocations", authMiddleware, tenantMiddleware, canManageFacilities, async (req, res) => {
  try {
    res.json({ allocations: await ParkingService.listAllocations(societyOf(req), {
      status: req.query.status as string,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    }) });
  } catch (e: any) { map(res, e, "Failed to list allocations"); }
});
router.post("/allocations", authMiddleware, tenantMiddleware, canManageFacilities, validate(AllocateSchema), async (req, res) => {
  try { res.status(201).json({ allocation: await ParkingService.allocate(societyOf(req), { ...req.body, allocatedBy: userOf(req).uid }) }); }
  catch (e: any) { map(res, e, "Failed to allocate slot"); }
});
router.post("/allocations/:id/release", authMiddleware, tenantMiddleware, canManageFacilities, async (req, res) => {
  try { res.json(await ParkingService.release(societyOf(req), (req.params.id as string))); }
  catch (e: any) { map(res, e, "Failed to release allocation"); }
});
router.post("/allocations/:id/transfer", authMiddleware, tenantMiddleware, canManageFacilities, validate(TransferSchema), async (req, res) => {
  try { res.json({ allocation: await ParkingService.transfer(societyOf(req), (req.params.id as string), req.body.toSlotId, userOf(req).uid) }); }
  catch (e: any) { map(res, e, "Failed to transfer allocation"); }
});

// Requests / waitlist
router.get("/requests", authMiddleware, tenantMiddleware, canManageFacilities, async (req, res) => {
  try { res.json({ requests: await ParkingService.listRequests(societyOf(req), { status: req.query.status as string }) }); }
  catch (e: any) { map(res, e, "Failed to list requests"); }
});
router.post("/requests", authMiddleware, tenantMiddleware, validate(RequestSchema), async (req, res) => {
  try { res.status(201).json({ request: await ParkingService.requestSlot(societyOf(req), { ...req.body, requestedBy: userOf(req).uid }) }); }
  catch (e: any) { map(res, e, "Failed to create request"); }
});

// Visitor parking
router.post("/visitor", authMiddleware, tenantMiddleware, validate(VisitorSchema), async (req, res) => {
  try { res.status(201).json({ pass: await ParkingService.createVisitorPass(societyOf(req), req.body) }); }
  catch (e: any) { map(res, e, "Failed to create visitor pass"); }
});

// Violations
router.get("/violations", authMiddleware, tenantMiddleware, canManageFacilities, async (req, res) => {
  try { res.json({ violations: await ParkingService.listViolations(societyOf(req), { status: req.query.status as string }) }); }
  catch (e: any) { map(res, e, "Failed to list violations"); }
});
router.post("/violations", authMiddleware, tenantMiddleware, canManageFacilities, validate(ViolationSchema), async (req, res) => {
  try { res.status(201).json({ violation: await ParkingService.recordViolation(societyOf(req), req.body, userOf(req).uid) }); }
  catch (e: any) { map(res, e, "Failed to record violation"); }
});
router.post("/violations/:id/resolve", authMiddleware, tenantMiddleware, canManageFacilities, validate(ResolveViolationSchema), async (req, res) => {
  try { res.json({ violation: await ParkingService.resolveViolation(societyOf(req), (req.params.id as string), req.body.status) }); }
  catch (e: any) { map(res, e, "Failed to resolve violation"); }
});

export default router;
