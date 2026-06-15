import { Router, Request, Response } from "express";
import { ComplaintService } from "../services/complaints/ComplaintService";
import { validate } from "../middleware/validate";
import {
  CreateComplaintSchema, AssignComplaintSchema, ComplaintStatusSchema,
  ComplaintSlaPauseSchema, ComplaintCommentSchema, ComplaintFeedbackSchema,
} from "../shared/schemas";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, canManageContent } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();

const societyOf = (req: Request) => (req as any).societyId as string;
const userOf = (req: Request) => (req as any).user || {};
const isAdminRole = (req: Request) =>
  ["main_admin", "secretary", "admin", "super_admin", "superadmin"].includes(userOf(req).role);

// GET /complaints — list (admins see all; residents see only their own)
router.get("/", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const opts: any = {
      status: typeof req.query.status === "string" ? req.query.status : undefined,
      overdue: req.query.overdue === "true",
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    };
    if (!isAdminRole(req)) opts.assignedTo = undefined; // residents filtered below
    let complaints = await ComplaintService.listComplaints(societyOf(req), opts);
    if (!isAdminRole(req)) {
      const uid = userOf(req).uid;
      complaints = complaints.filter((c: any) => c.created_by === uid);
    }
    res.json({ complaints });
  } catch (err: any) {
    logger.error({ error: err.message }, "List complaints failed");
    res.status(500).json({ error: "Failed to list complaints" });
  }
});

// GET /complaints/analytics — SLA/resolution analytics (admin)
router.get("/analytics", authMiddleware, tenantMiddleware, canManageContent, async (req: Request, res: Response) => {
  try {
    res.json(await ComplaintService.analytics(societyOf(req)));
  } catch (err: any) {
    logger.error({ error: err.message }, "Complaint analytics failed");
    res.status(500).json({ error: "Failed to build analytics" });
  }
});

// GET /complaints/:id — detail. Internal notes only for admins / the assignee.
router.get("/:id", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const includeInternal = isAdminRole(req);
    const detail = await ComplaintService.getComplaint(societyOf(req), req.params.id, includeInternal);
    if (!detail) return res.status(404).json({ error: "Complaint not found" });
    // Resident may only view their own complaint (mask existence otherwise).
    if (!isAdminRole(req) && detail.complaint.created_by !== userOf(req).uid) {
      return res.status(404).json({ error: "Complaint not found" });
    }
    res.json(detail);
  } catch (err: any) {
    logger.error({ error: err.message }, "Get complaint failed");
    res.status(500).json({ error: "Failed to get complaint" });
  }
});

// POST /complaints — any resident can raise a complaint
router.post("/", authMiddleware, tenantMiddleware, validate(CreateComplaintSchema), async (req: Request, res: Response) => {
  try {
    const complaint = await ComplaintService.createComplaint(societyOf(req), req.body, userOf(req).uid);
    res.status(201).json({ complaint });
  } catch (err: any) {
    logger.error({ error: err.message }, "Create complaint failed");
    res.status(500).json({ error: "Failed to create complaint" });
  }
});

// POST /complaints/:id/assign — admin assigns to staff/committee/vendor
router.post("/:id/assign", authMiddleware, tenantMiddleware, canManageContent, validate(AssignComplaintSchema), async (req: Request, res: Response) => {
  try {
    const c = await ComplaintService.assign(
      societyOf(req), req.params.id, req.body.assigneeId, req.body.assigneeType, userOf(req).uid, req.body.reason
    );
    res.json({ complaint: c });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Complaint not found" });
    logger.error({ error: err.message }, "Assign complaint failed");
    res.status(500).json({ error: "Failed to assign complaint" });
  }
});

// PATCH /complaints/:id/status — admin drives the state machine
router.patch("/:id/status", authMiddleware, tenantMiddleware, canManageContent, validate(ComplaintStatusSchema), async (req: Request, res: Response) => {
  try {
    const c = await ComplaintService.changeStatus(societyOf(req), req.params.id, req.body.status, userOf(req).uid, req.body.note);
    res.json({ complaint: c });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Complaint not found" });
    if (err.code === "INVALID_TRANSITION") return res.status(409).json({ error: err.message });
    logger.error({ error: err.message }, "Change complaint status failed");
    res.status(500).json({ error: "Failed to change status" });
  }
});

// POST /complaints/:id/sla-pause — pause/resume SLA clock (admin)
router.post("/:id/sla-pause", authMiddleware, tenantMiddleware, canManageContent, validate(ComplaintSlaPauseSchema), async (req: Request, res: Response) => {
  try {
    const r = await ComplaintService.setSlaPause(societyOf(req), req.params.id, req.body.pause, req.body.reason);
    res.json(r);
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Complaint not found" });
    logger.error({ error: err.message }, "SLA pause failed");
    res.status(500).json({ error: "Failed to toggle SLA pause" });
  }
});

// POST /complaints/:id/comments — internal notes (admin only) or resident-visible
router.post("/:id/comments", authMiddleware, tenantMiddleware, validate(ComplaintCommentSchema), async (req: Request, res: Response) => {
  try {
    // Only admins/assignees may post internal notes.
    const visibility = req.body.visibility === "internal" && isAdminRole(req) ? "internal" : "resident";
    const comment = await ComplaintService.addComment(societyOf(req), req.params.id, {
      body: req.body.body, visibility, authorId: userOf(req).uid, authorName: userOf(req).name,
    });
    res.status(201).json({ comment });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Complaint not found" });
    logger.error({ error: err.message }, "Add complaint comment failed");
    res.status(500).json({ error: "Failed to add comment" });
  }
});

// POST /complaints/:id/feedback — resident CSAT, once only
router.post("/:id/feedback", authMiddleware, tenantMiddleware, validate(ComplaintFeedbackSchema), async (req: Request, res: Response) => {
  try {
    const feedback = await ComplaintService.submitFeedback(societyOf(req), req.params.id, req.body.rating, req.body.comment, userOf(req).uid);
    res.status(201).json({ feedback });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Complaint not found" });
    if (err.code === "INVALID_STATE") return res.status(409).json({ error: err.message });
    if (err.code === "ALREADY_EXISTS") return res.status(409).json({ error: err.message });
    logger.error({ error: err.message }, "Submit complaint feedback failed");
    res.status(500).json({ error: "Failed to submit feedback" });
  }
});

// GET /complaints/:id/attachments — list evidence (admins, or owning resident)
router.get("/:id/attachments", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    if (!isAdminRole(req)) {
      const detail = await ComplaintService.getComplaint(societyOf(req), req.params.id, false);
      if (!detail || detail.complaint.created_by !== userOf(req).uid) {
        return res.status(404).json({ error: "Complaint not found" });
      }
    }
    const attachments = await ComplaintService.listAttachments(societyOf(req), req.params.id);
    res.json({ attachments });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Complaint not found" });
    logger.error({ error: err.message }, "List complaint attachments failed");
    res.status(500).json({ error: "Failed to list attachments" });
  }
});

// POST /complaints/:id/attachments — attach evidence
router.post("/:id/attachments", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const { fileUrl, mime, kind } = req.body || {};
    if (!fileUrl || typeof fileUrl !== "string") return res.status(400).json({ error: "fileUrl is required" });
    const attachment = await ComplaintService.addAttachment(societyOf(req), req.params.id, {
      fileUrl, mime, kind, uploadedBy: userOf(req).uid,
    });
    res.status(201).json({ attachment });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Complaint not found" });
    logger.error({ error: err.message }, "Add complaint attachment failed");
    res.status(500).json({ error: "Failed to add attachment" });
  }
});

// POST /complaints/run-escalations — trigger the SLA escalation worker (admin)
router.post("/run-escalations", authMiddleware, tenantMiddleware, canManageContent, async (req: Request, res: Response) => {
  try {
    res.json(await ComplaintService.runEscalations(societyOf(req)));
  } catch (err: any) {
    logger.error({ error: err.message }, "Run escalations failed");
    res.status(500).json({ error: "Failed to run escalations" });
  }
});

export default router;
