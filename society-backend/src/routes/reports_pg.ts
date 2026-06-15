import { Router, Request, Response } from "express";
import { z } from "zod";
import { ReportService } from "../services/reports/ReportService";
import { validate } from "../middleware/validate";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, canManageContent } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();
const societyOf = (req: Request) => (req as any).societyId as string;
const userOf = (req: Request) => (req as any).user?.id || (req as any).userId || null;
const s = z.string().trim().min(1);
const kind = z.enum(["finance", "complaints", "staff", "occupancy", "custom"]);

const TemplateSchema = z.object({ body: z.object({
  name: s.max(80),
  kind: kind.optional(),
  format: z.enum(["pdf", "excel", "csv"]).optional(),
  config: z.record(z.any()).optional(),
}).strict() });

const JobSchema = z.object({ body: z.object({
  templateId: z.string().uuid().optional(),
  kind: kind.optional(),
  params: z.record(z.any()).optional(),
}).strict() });

const ScheduleSchema = z.object({ body: z.object({
  templateId: z.string().uuid(),
  cron: s.max(120),
  nextRunAt: z.string().datetime().optional(),
}).strict() });

const map = (res: Response, e: any, fallback: string) => {
  if (e.code === "NOT_FOUND") return res.status(404).json({ error: e.message });
  if (e.code === "INVALID_STATE") return res.status(409).json({ error: e.message });
  if (e.code === "ALREADY_EXISTS") return res.status(409).json({ error: e.message });
  logger.error({ error: e.message }, fallback);
  return res.status(500).json({ error: fallback });
};

// Templates
router.get("/templates", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ templates: await ReportService.listTemplates(societyOf(req)) }); }
  catch (e: any) { map(res, e, "Failed to list templates"); }
});
router.post("/templates", authMiddleware, tenantMiddleware, canManageContent, validate(TemplateSchema), async (req, res) => {
  try { res.status(201).json({ template: await ReportService.createTemplate(societyOf(req), req.body) }); }
  catch (e: any) { map(res, e, "Failed to create template"); }
});

// Jobs
router.get("/jobs", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    res.json({ jobs: await ReportService.listJobs(societyOf(req), {
      status: req.query.status as string,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    }) });
  } catch (e: any) { map(res, e, "Failed to list jobs"); }
});
router.get("/jobs/:id", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ job: await ReportService.getJob(societyOf(req), req.params.id) }); }
  catch (e: any) { map(res, e, "Failed to get job"); }
});
router.post("/jobs", authMiddleware, tenantMiddleware, canManageContent, validate(JobSchema), async (req, res) => {
  try {
    res.status(201).json({ job: await ReportService.enqueueJob(societyOf(req), {
      templateId: req.body.templateId, kind: req.body.kind, params: req.body.params, requestedBy: userOf(req),
    }) });
  } catch (e: any) { map(res, e, "Failed to enqueue job"); }
});

// Schedules
router.post("/schedules", authMiddleware, tenantMiddleware, canManageContent, validate(ScheduleSchema), async (req, res) => {
  try {
    res.status(201).json({ schedule: await ReportService.createSchedule(
      societyOf(req), req.body.templateId, req.body.cron, req.body.nextRunAt
    ) });
  } catch (e: any) { map(res, e, "Failed to create schedule"); }
});

export default router;
