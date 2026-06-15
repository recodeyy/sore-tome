import { Router, Request, Response } from "express";
import { z } from "zod";
import { RuleService } from "../services/rules/RuleService";
import { validate } from "../middleware/validate";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, canManageContent } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();

const societyOf = (req: Request) => (req as any).societyId as string;
const userOf = (req: Request) => (req as any).user || {};

// ---- Inline Zod schemas (validate() wraps body/query/params) -------------

const CreateRuleSchema = z.object({
  body: z.object({
    title: z.string().min(1).max(200),
    body: z.string().min(1).max(20000),
    category: z.enum(["bylaw", "rule", "noc", "policy", "other"]).optional(),
  }).strict(),
});

const UpdateRuleSchema = z.object({
  body: z.object({
    title: z.string().min(1).max(200).optional(),
    body: z.string().min(1).max(20000).optional(),
    category: z.enum(["bylaw", "rule", "noc", "policy", "other"]).optional(),
  }).strict(),
});

const CreateDocumentSchema = z.object({
  body: z.object({
    title: z.string().min(1).max(200),
    docType: z.enum(["bylaw", "noc", "record", "minutes", "other"]).optional(),
  }).strict(),
});

const AddDocumentVersionSchema = z.object({
  body: z.object({
    fileUrl: z.string().min(1).max(2000),
    fileName: z.string().max(300).optional(),
    mimeType: z.string().max(150).optional(),
    checksum: z.string().max(200).optional(),
  }).strict(),
});

// ---- Rules ----------------------------------------------------------------

// GET / — list rules
router.get("/", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const rules = await RuleService.listRules(societyOf(req), {
      status: typeof req.query.status === "string" ? req.query.status : undefined,
      category: typeof req.query.category === "string" ? req.query.category : undefined,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    });
    res.json({ rules });
  } catch (err: any) {
    logger.error({ error: err.message }, "List rules failed");
    res.status(500).json({ error: "Failed to list rules" });
  }
});

// GET /search?q= — full-text search (MUST be before /:id)
router.get("/search", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const q = typeof req.query.q === "string" ? req.query.q : "";
    const rules = await RuleService.searchRules(societyOf(req), q);
    res.json({ rules });
  } catch (err: any) {
    logger.error({ error: err.message }, "Search rules failed");
    res.status(500).json({ error: "Failed to search rules" });
  }
});

// GET /documents — list documents (before /:id so "documents" isn't an id)
router.get("/documents", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const documents = await RuleService.listDocuments(societyOf(req), {
      docType: typeof req.query.docType === "string" ? req.query.docType : undefined,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    });
    res.json({ documents });
  } catch (err: any) {
    logger.error({ error: err.message }, "List documents failed");
    res.status(500).json({ error: "Failed to list documents" });
  }
});

// GET /documents/:id — document detail with versions
router.get("/documents/:id", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const detail = await RuleService.getDocument(societyOf(req), (req.params.id as string));
    if (!detail) return res.status(404).json({ error: "Document not found" });
    res.json(detail);
  } catch (err: any) {
    logger.error({ error: err.message }, "Get document failed");
    res.status(500).json({ error: "Failed to get document" });
  }
});

// POST /documents — create document metadata (admin)
router.post("/documents", authMiddleware, tenantMiddleware, canManageContent, validate(CreateDocumentSchema), async (req: Request, res: Response) => {
  try {
    const document = await RuleService.createDocument(societyOf(req), req.body, userOf(req).uid);
    res.status(201).json({ document });
  } catch (err: any) {
    logger.error({ error: err.message }, "Create document failed");
    res.status(500).json({ error: "Failed to create document" });
  }
});

// POST /documents/:id/versions — attach a new file revision (admin)
router.post("/documents/:id/versions", authMiddleware, tenantMiddleware, canManageContent, validate(AddDocumentVersionSchema), async (req: Request, res: Response) => {
  try {
    const result = await RuleService.addDocumentVersion(societyOf(req), (req.params.id as string), {
      ...req.body,
      uploadedBy: userOf(req).uid,
    });
    res.status(201).json(result);
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Document not found" });
    logger.error({ error: err.message }, "Add document version failed");
    res.status(500).json({ error: "Failed to add document version" });
  }
});

// GET /:id — rule detail with versions
router.get("/:id", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const detail = await RuleService.getRule(societyOf(req), (req.params.id as string));
    if (!detail) return res.status(404).json({ error: "Rule not found" });
    res.json(detail);
  } catch (err: any) {
    logger.error({ error: err.message }, "Get rule failed");
    res.status(500).json({ error: "Failed to get rule" });
  }
});

// POST / — create rule (admin)
router.post("/", authMiddleware, tenantMiddleware, canManageContent, validate(CreateRuleSchema), async (req: Request, res: Response) => {
  try {
    const rule = await RuleService.createRule(societyOf(req), req.body, userOf(req).uid);
    res.status(201).json({ rule });
  } catch (err: any) {
    logger.error({ error: err.message }, "Create rule failed");
    res.status(500).json({ error: "Failed to create rule" });
  }
});

// PUT /:id — update rule (snapshots prior version) (admin)
router.put("/:id", authMiddleware, tenantMiddleware, canManageContent, validate(UpdateRuleSchema), async (req: Request, res: Response) => {
  try {
    const rule = await RuleService.updateRule(societyOf(req), (req.params.id as string), req.body, userOf(req).uid);
    res.json({ rule });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Rule not found" });
    logger.error({ error: err.message }, "Update rule failed");
    res.status(500).json({ error: "Failed to update rule" });
  }
});

// POST /:id/activate — draft/archived -> active (admin)
router.post("/:id/activate", authMiddleware, tenantMiddleware, canManageContent, async (req: Request, res: Response) => {
  try {
    const rule = await RuleService.activate(societyOf(req), (req.params.id as string));
    res.json({ rule });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Rule not found" });
    if (err.code === "INVALID_STATE") return res.status(409).json({ error: err.message });
    logger.error({ error: err.message }, "Activate rule failed");
    res.status(500).json({ error: "Failed to activate rule" });
  }
});

// POST /:id/archive — -> archived (admin)
router.post("/:id/archive", authMiddleware, tenantMiddleware, canManageContent, async (req: Request, res: Response) => {
  try {
    const rule = await RuleService.archive(societyOf(req), (req.params.id as string));
    res.json({ rule });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Rule not found" });
    if (err.code === "INVALID_STATE") return res.status(409).json({ error: err.message });
    logger.error({ error: err.message }, "Archive rule failed");
    res.status(500).json({ error: "Failed to archive rule" });
  }
});

export default router;
