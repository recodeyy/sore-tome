import { Router, Request, Response } from "express";
import { z } from "zod";
import { GuardService } from "../services/guard/GuardService";
import { validate } from "../middleware/validate";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, canManageContent, canManageSecurity } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();
const societyOf = (req: Request) => (req as any).societyId as string;
const guardOf = (req: Request) => ((req as any).user || {}).uid as string | undefined;

const s = z.string().trim().min(1);

const CheckInSchema = z.object({ body: z.object({
  name: s.max(120), phone: z.string().max(20).optional(), purpose: z.string().max(200).optional(),
  unitId: z.string().max(64).optional(), preApprovalId: z.string().uuid().optional(),
}).strict() });
const GatePassSchema = z.object({ body: z.object({
  type: z.enum(["visitor", "delivery", "cab", "service"]), code: s.max(64), validUntil: z.string().min(1),
}).strict() });
const ValidatePassSchema = z.object({ body: z.object({ code: s.max(64) }).strict() });
const PatrolSchema = z.object({ body: z.object({ checkpoint: s.max(120), note: z.string().max(500).optional() }).strict() });
const IncidentSchema = z.object({ body: z.object({
  category: s.max(80), description: z.string().max(2000).optional(),
  severity: z.enum(["low", "medium", "high", "critical"]).optional(),
}).strict() });
const IncidentStatusSchema = z.object({ body: z.object({ status: z.enum(["open", "investigating", "resolved", "closed"]) }).strict() });

const map = (res: Response, err: any, fallback: string) => {
  if (err.code === "NOT_FOUND") return res.status(404).json({ error: err.message });
  if (["INVALID_STATE", "ALREADY_EXISTS"].includes(err.code)) return res.status(409).json({ error: err.message });
  if (err.code === "INVALID_INPUT") return res.status(400).json({ error: err.message });
  logger.error({ error: err.message }, fallback);
  return res.status(500).json({ error: fallback });
};

// ---- Visitors ----
router.get("/visitors", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ visitors: await GuardService.listVisitors(societyOf(req), { status: req.query.status as string }) }); }
  catch (e: any) { map(res, e, "Failed to list visitors"); }
});
router.post("/visitors/check-in", authMiddleware, tenantMiddleware, canManageSecurity, validate(CheckInSchema), async (req, res) => {
  try { res.status(201).json({ visitor: await GuardService.checkInVisitor(societyOf(req), { ...req.body, guardId: guardOf(req) }) }); }
  catch (e: any) { map(res, e, "Check-in failed"); }
});
router.post("/visitors/:id/check-out", authMiddleware, tenantMiddleware, canManageSecurity, async (req, res) => {
  try { res.json({ visitor: await GuardService.checkOutVisitor(societyOf(req), req.params.id as string, guardOf(req)) }); }
  catch (e: any) { map(res, e, "Check-out failed"); }
});
router.post("/visitors/:id/entry", authMiddleware, tenantMiddleware, canManageSecurity, async (req, res) => {
  try { res.json({ visitor: await GuardService.recordEntry(societyOf(req), req.params.id as string, guardOf(req)) }); }
  catch (e: any) { map(res, e, "Record entry failed"); }
});
// Resident approve/reject of a logged visitor (notifies the guard). No canManageContent gate.
router.post("/visitors/:id/decision", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const decision = req.body && req.body.decision === "rejected" ? "rejected" : "approved";
    res.json({ visitor: await GuardService.decideVisitor(societyOf(req), req.params.id as string, decision, guardOf(req)) });
  } catch (e: any) { map(res, e, "Visitor decision failed"); }
});
router.post("/visitors/:id/deny", authMiddleware, tenantMiddleware, canManageSecurity, async (req, res) => {
  try { res.json({ visitor: await GuardService.denyVisitor(societyOf(req), req.params.id as string, guardOf(req)) }); }
  catch (e: any) { map(res, e, "Deny failed"); }
});

// ---- Gate passes ----
router.get("/gate-passes", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ passes: await GuardService.listGatePasses(societyOf(req), { status: req.query.status as string }) }); }
  catch (e: any) { map(res, e, "Failed to list gate passes"); }
});
router.post("/gate-passes", authMiddleware, tenantMiddleware, canManageSecurity, validate(GatePassSchema), async (req, res) => {
  try { res.status(201).json({ pass: await GuardService.createGatePass(societyOf(req), { ...req.body, guardId: guardOf(req) }) }); }
  catch (e: any) { map(res, e, "Failed to create gate pass"); }
});
router.post("/gate-passes/validate", authMiddleware, tenantMiddleware, canManageSecurity, validate(ValidatePassSchema), async (req, res) => {
  try { res.json({ pass: await GuardService.validateGatePass(societyOf(req), req.body.code) }); }
  catch (e: any) { map(res, e, "Failed to validate gate pass"); }
});

// ---- Patrols ----
router.get("/patrols", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ patrols: await GuardService.listPatrols(societyOf(req)) }); }
  catch (e: any) { map(res, e, "Failed to list patrols"); }
});
router.post("/patrols", authMiddleware, tenantMiddleware, canManageSecurity, validate(PatrolSchema), async (req, res) => {
  try { res.status(201).json({ patrol: await GuardService.logPatrol(societyOf(req), { ...req.body, guardId: guardOf(req) }) }); }
  catch (e: any) { map(res, e, "Failed to log patrol"); }
});

// ---- Incidents ----
router.get("/incidents", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ incidents: await GuardService.listIncidents(societyOf(req), { status: req.query.status as string }) }); }
  catch (e: any) { map(res, e, "Failed to list incidents"); }
});
router.post("/incidents", authMiddleware, tenantMiddleware, canManageSecurity, validate(IncidentSchema), async (req, res) => {
  try { res.status(201).json({ incident: await GuardService.reportIncident(societyOf(req), { ...req.body, guardId: guardOf(req) }) }); }
  catch (e: any) { map(res, e, "Failed to report incident"); }
});
router.patch("/incidents/:id/status", authMiddleware, tenantMiddleware, canManageSecurity, validate(IncidentStatusSchema), async (req, res) => {
  try { res.json({ incident: await GuardService.updateIncidentStatus(societyOf(req), req.params.id as string, req.body.status) }); }
  catch (e: any) { map(res, e, "Failed to update incident"); }
});

export default router;
