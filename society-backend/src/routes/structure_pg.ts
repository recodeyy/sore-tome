import { Router, Request, Response } from "express";
import { z } from "zod";
import { StructureService } from "../services/structure/StructureService";
import { BulkImportService } from "../services/structure/BulkImportService";
import { validate } from "../middleware/validate";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, canManageContent } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();
const societyOf = (req: Request) => (req as any).societyId as string;
const s = z.string().trim().min(1);

const WingSchema = z.object({ body: z.object({ name: s.max(60), position: z.number().int().optional() }).strict() });
const WingPatchSchema = z.object({ body: z.object({ name: s.max(60).optional(), position: z.number().int().optional(), isActive: z.boolean().optional() }).strict() });
const BlockSchema = z.object({ body: z.object({ name: s.max(60), wingId: z.string().uuid().optional(), position: z.number().int().optional() }).strict() });
const FloorSchema = z.object({ body: z.object({ label: s.max(20), blockId: z.string().uuid().optional(), position: z.number().int().optional() }).strict() });
const UnitSchema = z.object({ body: z.object({ number: s.max(20), wingId: z.string().uuid().optional(), blockId: z.string().uuid().optional(), floorId: z.string().uuid().optional(), unitType: z.string().max(30).optional(), areaSqft: z.number().nonnegative().optional(), maintenanceWeight: z.number().nonnegative().optional(), ownershipStatus: z.enum(["owned", "rented", "vacant", "jointly_owned"]).optional() }).strict() });
const UnitPatchSchema = z.object({ body: z.object({ unitType: z.string().max(30).optional(), areaSqft: z.number().nonnegative().optional(), maintenanceWeight: z.number().nonnegative().optional(), ownershipStatus: z.enum(["owned", "rented", "vacant", "jointly_owned"]).optional(), isActive: z.boolean().optional() }).strict() });
const OccupancySchema = z.object({ body: z.object({ residentId: s.max(64), relation: z.enum(["owner", "tenant", "co_owner", "family"]).optional(), fromDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional() }).strict() });
const VacateSchema = z.object({ body: z.object({ relation: z.enum(["owner", "tenant", "co_owner", "family"]).optional() }).strict() });

const map = (res: Response, e: any, fallback: string) => {
  if (e.code === "NOT_FOUND") return res.status(404).json({ error: e.message });
  if (e.code === "ALREADY_EXISTS") return res.status(409).json({ error: e.message });
  logger.error({ error: e.message }, fallback);
  return res.status(500).json({ error: fallback });
};

// Summary
router.get("/summary", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json(await StructureService.summary(societyOf(req))); }
  catch (e: any) { map(res, e, "Failed to build summary"); }
});

// Wings
router.get("/wings", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ wings: await StructureService.listWings(societyOf(req)) }); }
  catch (e: any) { map(res, e, "Failed to list wings"); }
});
router.post("/wings", authMiddleware, tenantMiddleware, canManageContent, validate(WingSchema), async (req, res) => {
  try { res.status(201).json({ wing: await StructureService.createWing(societyOf(req), req.body) }); }
  catch (e: any) { map(res, e, "Failed to create wing"); }
});
router.patch("/wings/:id", authMiddleware, tenantMiddleware, canManageContent, validate(WingPatchSchema), async (req, res) => {
  try { res.json({ wing: await StructureService.updateWing(societyOf(req), req.params.id, req.body) }); }
  catch (e: any) { map(res, e, "Failed to update wing"); }
});

// Blocks
router.get("/blocks", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ blocks: await StructureService.listBlocks(societyOf(req), { wingId: req.query.wingId as string }) }); }
  catch (e: any) { map(res, e, "Failed to list blocks"); }
});
router.post("/blocks", authMiddleware, tenantMiddleware, canManageContent, validate(BlockSchema), async (req, res) => {
  try { res.status(201).json({ block: await StructureService.createBlock(societyOf(req), req.body) }); }
  catch (e: any) { map(res, e, "Failed to create block"); }
});

// Floors
router.get("/floors", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ floors: await StructureService.listFloors(societyOf(req), { blockId: req.query.blockId as string }) }); }
  catch (e: any) { map(res, e, "Failed to list floors"); }
});
router.post("/floors", authMiddleware, tenantMiddleware, canManageContent, validate(FloorSchema), async (req, res) => {
  try { res.status(201).json({ floor: await StructureService.createFloor(societyOf(req), req.body) }); }
  catch (e: any) { map(res, e, "Failed to create floor"); }
});

// Units
router.get("/units", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    res.json({ units: await StructureService.listUnits(societyOf(req), {
      occupancyStatus: req.query.occupancyStatus as string,
      blockId: req.query.blockId as string,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    }) });
  } catch (e: any) { map(res, e, "Failed to list units"); }
});
router.post("/units", authMiddleware, tenantMiddleware, canManageContent, validate(UnitSchema), async (req, res) => {
  try { res.status(201).json({ unit: await StructureService.createUnit(societyOf(req), req.body) }); }
  catch (e: any) { map(res, e, "Failed to create unit"); }
});
router.patch("/units/:id", authMiddleware, tenantMiddleware, canManageContent, validate(UnitPatchSchema), async (req, res) => {
  try { res.json({ unit: await StructureService.updateUnit(societyOf(req), req.params.id, req.body) }); }
  catch (e: any) { map(res, e, "Failed to update unit"); }
});
router.get("/units/:id/occupancy", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ history: await StructureService.unitOccupancyHistory(societyOf(req), req.params.id) }); }
  catch (e: any) { map(res, e, "Failed to get occupancy history"); }
});
router.post("/units/:id/occupancy", authMiddleware, tenantMiddleware, canManageContent, validate(OccupancySchema), async (req, res) => {
  try { res.status(201).json({ occupancy: await StructureService.setOccupancy(societyOf(req), req.params.id, req.body) }); }
  catch (e: any) { map(res, e, "Failed to set occupancy"); }
});
router.post("/units/:id/vacate", authMiddleware, tenantMiddleware, canManageContent, validate(VacateSchema), async (req, res) => {
  try { res.json(await StructureService.vacateUnit(societyOf(req), req.params.id, req.body.relation)); }
  catch (e: any) { map(res, e, "Failed to vacate unit"); }
});

// --- Bulk import (capability 15) ---
const ImportSchema = z.object({
  body: z.object({
    csv: z.string().optional(),
    rows: z.array(z.record(z.string(), z.string())).optional(),
    dryRun: z.boolean().optional(),
  }).refine((b) => b.csv !== undefined || b.rows !== undefined, { message: "csv or rows is required" }),
});

router.post("/units/import", authMiddleware, tenantMiddleware, canManageContent, validate(ImportSchema), async (req, res) => {
  try {
    const report = await BulkImportService.importUnits(societyOf(req), req.body.csv ?? req.body.rows, { dryRun: !!req.body.dryRun });
    res.json({ success: true, data: report });
  } catch (e: any) { map(res, e, "Unit bulk import failed"); }
});

router.post("/members/import", authMiddleware, tenantMiddleware, canManageContent, validate(ImportSchema), async (req, res) => {
  try {
    const report = await BulkImportService.importMembers(societyOf(req), req.body.csv ?? req.body.rows, { dryRun: !!req.body.dryRun });
    res.json({ success: true, data: report });
  } catch (e: any) { map(res, e, "Member bulk import failed"); }
});

export default router;
