import { Router, Request, Response } from "express";
import { z } from "zod";
import { AssetService } from "../services/assets/AssetService";
import { validate } from "../middleware/validate";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, canManageContent } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();
const societyOf = (req: Request) => (req as any).societyId as string;
const userOf = (req: Request) => (req as any).user || {};
const s = z.string().trim().min(1);
const isoDate = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Expected YYYY-MM-DD");

const AssetSchema = z.object({ body: z.object({ tag: s.max(40), name: s.max(120), type: z.enum(["lift", "generator", "pump", "cctv", "fire", "other"]).optional(), categoryId: z.string().uuid().optional(), location: z.string().max(80).optional(), commissionedOn: isoDate.optional(), purchaseCostMinor: z.number().int().nonnegative().optional() }).strict() });
const VendorSchema = z.object({ body: z.object({ name: s.max(120), contact: z.string().max(80).optional(), speciality: z.string().max(80).optional() }).strict() });
const ScheduleSchema = z.object({ body: z.object({ assetId: z.string().uuid(), title: s.max(120), intervalDays: z.number().int().positive(), firstDueOn: isoDate }).strict() });
const WorkOrderSchema = z.object({ body: z.object({ assetId: z.string().uuid(), kind: z.enum(["preventive", "breakdown", "inspection"]).optional(), title: s.max(150), description: z.string().max(1000).optional(), vendorId: z.string().uuid().optional() }).strict() });
const CompleteSchema = z.object({ body: z.object({ costMinor: z.number().int().nonnegative().optional(), proofUrl: z.string().max(500).optional() }).strict() });
const FromScheduleSchema = z.object({ body: z.object({ scheduleId: z.string().uuid(), vendorId: z.string().uuid().optional() }).strict() });
const AmcSchema = z.object({ body: z.object({ assetId: z.string().uuid().optional(), vendorId: z.string().uuid().optional(), contractNo: z.string().max(60).optional(), startDate: isoDate, endDate: isoDate, valueMinor: z.number().int().nonnegative().optional() }).strict() });
const PartSchema = z.object({ body: z.object({ name: s.max(120), quantity: z.number().int().nonnegative(), unitCostMinor: z.number().int().nonnegative().optional() }).strict() });

const map = (res: Response, e: any, fallback: string) => {
  if (e.code === "NOT_FOUND") return res.status(404).json({ error: e.message });
  if (["DUPLICATE_WO", "INVALID_STATE", "ALREADY_EXISTS"].includes(e.code)) return res.status(409).json({ error: e.message });
  logger.error({ error: e.message }, fallback);
  return res.status(500).json({ error: fallback });
};

// Assets
router.get("/", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ assets: await AssetService.listAssets(societyOf(req), { status: req.query.status as string }) }); }
  catch (e: any) { map(res, e, "Failed to list assets"); }
});
router.get("/:id", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const a = await AssetService.getAsset(societyOf(req), req.params.id);
    if (!a) return res.status(404).json({ error: "Asset not found" });
    res.json(a);
  } catch (e: any) { map(res, e, "Failed to get asset"); }
});
router.post("/", authMiddleware, tenantMiddleware, canManageContent, validate(AssetSchema), async (req, res) => {
  try { res.status(201).json({ asset: await AssetService.createAsset(societyOf(req), req.body) }); }
  catch (e: any) { map(res, e, "Failed to create asset"); }
});

// Vendors
router.post("/vendors", authMiddleware, tenantMiddleware, canManageContent, validate(VendorSchema), async (req, res) => {
  try { res.status(201).json({ vendor: await AssetService.createVendor(societyOf(req), req.body) }); }
  catch (e: any) { map(res, e, "Failed to create vendor"); }
});

// Preventive schedules
router.post("/schedules", authMiddleware, tenantMiddleware, canManageContent, validate(ScheduleSchema), async (req, res) => {
  try { res.status(201).json({ schedule: await AssetService.createSchedule(societyOf(req), req.body) }); }
  catch (e: any) { map(res, e, "Failed to create schedule"); }
});
router.post("/work-orders/from-schedule", authMiddleware, tenantMiddleware, canManageContent, validate(FromScheduleSchema), async (req, res) => {
  try { res.status(201).json({ workOrder: await AssetService.generateWorkOrderFromSchedule(societyOf(req), req.body.scheduleId, req.body.vendorId, userOf(req).uid) }); }
  catch (e: any) { map(res, e, "Failed to generate work order"); }
});

// Work orders
router.post("/work-orders", authMiddleware, tenantMiddleware, canManageContent, validate(WorkOrderSchema), async (req, res) => {
  try { res.status(201).json({ workOrder: await AssetService.createWorkOrder(societyOf(req), req.body, userOf(req).uid) }); }
  catch (e: any) { map(res, e, "Failed to create work order"); }
});
router.post("/work-orders/:id/start", authMiddleware, tenantMiddleware, canManageContent, async (req, res) => {
  try { res.json({ workOrder: await AssetService.startWorkOrder(societyOf(req), req.params.id) }); }
  catch (e: any) { map(res, e, "Failed to start work order"); }
});
router.post("/work-orders/:id/complete", authMiddleware, tenantMiddleware, canManageContent, validate(CompleteSchema), async (req, res) => {
  try { res.json({ workOrder: await AssetService.completeWorkOrder(societyOf(req), req.params.id, req.body) }); }
  catch (e: any) { map(res, e, "Failed to complete work order"); }
});

// AMC
router.post("/amc", authMiddleware, tenantMiddleware, canManageContent, validate(AmcSchema), async (req, res) => {
  try { res.status(201).json({ amc: await AssetService.createAmc(societyOf(req), req.body) }); }
  catch (e: any) { map(res, e, "Failed to create AMC"); }
});
router.get("/amc/expiring", authMiddleware, tenantMiddleware, canManageContent, async (req, res) => {
  try { res.json({ contracts: await AssetService.amcExpiringSoon(societyOf(req), req.query.days ? Number(req.query.days) : 30) }); }
  catch (e: any) { map(res, e, "Failed to list expiring AMC"); }
});

// Spare parts
router.post("/spare-parts", authMiddleware, tenantMiddleware, canManageContent, validate(PartSchema), async (req, res) => {
  try { res.status(201).json({ part: await AssetService.upsertSparePart(societyOf(req), req.body) }); }
  catch (e: any) { map(res, e, "Failed to upsert spare part"); }
});

export default router;
