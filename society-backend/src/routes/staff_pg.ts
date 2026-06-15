import { Router, Request, Response } from "express";
import { z } from "zod";
import { StaffService } from "../services/staff/StaffService";
import { validate } from "../middleware/validate";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, canManageContent, canManageFunds } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();
const societyOf = (req: Request) => (req as any).societyId as string;
const userOf = (req: Request) => (req as any).user || {};

const s = z.string().trim().min(1);
const isoDate = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Expected YYYY-MM-DD");

const CreateStaffSchema = z.object({
  body: z.object({
    name: s.max(120), role: z.string().max(60).optional(), department: z.string().max(60).optional(),
    isContractor: z.boolean().optional(), phone: z.string().max(20).optional(), userId: z.string().max(64).optional(),
    joiningDate: isoDate.optional(), assignedAreas: z.array(z.string().max(60)).optional(),
    monthlyWageMinor: z.number().int().nonnegative().optional(), kycExpiresAt: isoDate.optional(),
  }).strict(),
});
const StatusSchema = z.object({ body: z.object({ status: z.enum(["active", "suspended", "terminated"]), leavingDate: isoDate.optional() }).strict() });
const CheckSchema = z.object({ body: z.object({ staffId: s.max(64), workDate: isoDate, source: z.string().max(20).optional() }).strict() });
const RosterSchema = z.object({ body: z.object({ staffId: s.max(64), dutyDate: isoDate, shiftTemplateId: z.string().uuid().optional(), area: z.string().max(60).optional() }).strict() });
const LeaveTypeSchema = z.object({ body: z.object({ name: s.max(60), annualQuotaDays: z.number().int().nonnegative().optional(), isPaid: z.boolean().optional() }).strict() });
const ShiftSchema = z.object({ body: z.object({ name: s.max(60), startMinutes: z.number().int().min(0), endMinutes: z.number().int().min(0) }).strict() });
const LeaveReqSchema = z.object({ body: z.object({ staffId: s.max(64), leaveTypeId: z.string().uuid(), fromDate: isoDate, toDate: isoDate, reason: z.string().max(300).optional() }).strict() });
const LeaveDecisionSchema = z.object({ body: z.object({ decision: z.enum(["approved", "rejected"]), comment: z.string().max(300).optional() }).strict() });
const PayrollGenSchema = z.object({ body: z.object({ period: z.string().regex(/^\d{4}-\d{2}$/, "Expected YYYY-MM") }).strict() });
const IncidentSchema = z.object({ body: z.object({ staffId: s.max(64), type: z.enum(["incident", "performance", "disciplinary"]).optional(), title: s.max(150), details: z.string().max(2000).optional(), isPrivate: z.boolean().optional() }).strict() });

const map = (res: Response, err: any, fallback: string) => {
  if (err.code === "NOT_FOUND") return res.status(404).json({ error: err.message });
  if (["INVALID_STATE", "ALREADY_CHECKED_IN", "ALREADY_EXISTS", "ROSTER_CONFLICT", "INSUFFICIENT_BALANCE", "MAKER_CHECKER"].includes(err.code)) {
    return res.status(409).json({ error: err.message });
  }
  if (err.code === "INVALID_INPUT") return res.status(400).json({ error: err.message });
  logger.error({ error: err.message }, fallback);
  return res.status(500).json({ error: fallback });
};

// Staff CRUD
router.get("/", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ staff: await StaffService.listStaff(societyOf(req), { status: req.query.status as string }) }); }
  catch (e: any) { map(res, e, "Failed to list staff"); }
});
router.post("/", authMiddleware, tenantMiddleware, canManageContent, validate(CreateStaffSchema), async (req, res) => {
  try { res.status(201).json({ staff: await StaffService.createStaff(societyOf(req), req.body) }); }
  catch (e: any) { map(res, e, "Failed to create staff"); }
});
router.patch("/:id/status", authMiddleware, tenantMiddleware, canManageContent, validate(StatusSchema), async (req, res) => {
  try { res.json({ staff: await StaffService.setStatus(societyOf(req), req.params.id, req.body.status, req.body.leavingDate) }); }
  catch (e: any) { map(res, e, "Failed to set staff status"); }
});

// Attendance
router.post("/attendance/check-in", authMiddleware, tenantMiddleware, canManageContent, validate(CheckSchema), async (req, res) => {
  try { res.status(201).json({ attendance: await StaffService.checkIn(societyOf(req), req.body.staffId, req.body.workDate, req.body.source) }); }
  catch (e: any) { map(res, e, "Check-in failed"); }
});
router.post("/attendance/check-out", authMiddleware, tenantMiddleware, canManageContent, validate(CheckSchema), async (req, res) => {
  try { res.json({ attendance: await StaffService.checkOut(societyOf(req), req.body.staffId, req.body.workDate) }); }
  catch (e: any) { map(res, e, "Check-out failed"); }
});

// Roster / shift / leave types
router.post("/roster", authMiddleware, tenantMiddleware, canManageContent, validate(RosterSchema), async (req, res) => {
  try { res.status(201).json({ roster: await StaffService.assignRoster(societyOf(req), req.body) }); }
  catch (e: any) { map(res, e, "Failed to assign roster"); }
});
router.post("/shift-templates", authMiddleware, tenantMiddleware, canManageContent, validate(ShiftSchema), async (req, res) => {
  try { res.status(201).json({ shift: await StaffService.createShiftTemplate(societyOf(req), req.body) }); }
  catch (e: any) { map(res, e, "Failed to create shift template"); }
});
router.post("/leave-types", authMiddleware, tenantMiddleware, canManageContent, validate(LeaveTypeSchema), async (req, res) => {
  try { res.status(201).json({ leaveType: await StaffService.createLeaveType(societyOf(req), req.body) }); }
  catch (e: any) { map(res, e, "Failed to create leave type"); }
});

// Leave
router.post("/leave/requests", authMiddleware, tenantMiddleware, canManageContent, validate(LeaveReqSchema), async (req, res) => {
  try {
    await StaffService.ensureLeaveBalance(societyOf(req), req.body.staffId, req.body.leaveTypeId, new Date(req.body.fromDate).getUTCFullYear());
    res.status(201).json({ request: await StaffService.requestLeave(societyOf(req), req.body) });
  } catch (e: any) { map(res, e, "Failed to request leave"); }
});
router.post("/leave/requests/:id/decision", authMiddleware, tenantMiddleware, canManageContent, validate(LeaveDecisionSchema), async (req, res) => {
  try { res.json({ request: await StaffService.decideLeave(societyOf(req), req.params.id, req.body.decision, userOf(req).uid, req.body.comment) }); }
  catch (e: any) { map(res, e, "Failed to decide leave"); }
});

// Payroll (finance permission)
router.post("/payroll/generate", authMiddleware, tenantMiddleware, canManageFunds, validate(PayrollGenSchema), async (req, res) => {
  try { res.status(201).json({ run: await StaffService.generatePayroll(societyOf(req), req.body.period, userOf(req).uid) }); }
  catch (e: any) { map(res, e, "Failed to generate payroll"); }
});
router.post("/payroll/:id/approve", authMiddleware, tenantMiddleware, canManageFunds, async (req, res) => {
  try { res.json({ run: await StaffService.approvePayroll(societyOf(req), req.params.id, userOf(req).uid) }); }
  catch (e: any) { map(res, e, "Failed to approve payroll"); }
});
router.get("/payroll/:id", authMiddleware, tenantMiddleware, canManageFunds, async (req, res) => {
  try {
    const r = await StaffService.getPayroll(societyOf(req), req.params.id);
    if (!r) return res.status(404).json({ error: "Payroll run not found" });
    res.json(r);
  } catch (e: any) { map(res, e, "Failed to get payroll"); }
});

// Incidents
router.post("/incidents", authMiddleware, tenantMiddleware, canManageContent, validate(IncidentSchema), async (req, res) => {
  try { res.status(201).json({ incident: await StaffService.recordIncident(societyOf(req), req.body, userOf(req).uid) }); }
  catch (e: any) { map(res, e, "Failed to record incident"); }
});

export default router;
