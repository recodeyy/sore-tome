import { Router, Request, Response } from "express";
import { z } from "zod";
import { MemberService } from "../services/members/MemberService";
import { validate } from "../middleware/validate";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, canManageContent } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();
const societyOf = (req: Request) => (req as any).societyId as string;
const userOf = (req: Request) => ((req as any).user?.id || (req as any).userId) as string | undefined;
const s = z.string().trim().min(1);
const dateStr = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);

const RegisterSchema = z.object({ body: z.object({
  name: s.max(120),
  phone: z.string().max(20).optional(),
  email: z.string().email().max(120).optional(),
  userId: z.string().max(64).optional(),
  unitId: z.string().uuid().optional(),
  role: z.string().max(40).optional(),
}).strict() });

const TransitionSchema = z.object({ body: z.object({
  status: z.enum(["approved", "rejected", "suspended", "deactivated", "moved_out"]),
  note: z.string().max(500).optional(),
}).strict() });

const FamilySchema = z.object({ body: z.object({
  name: s.max(120),
  relation: z.string().max(40).optional(),
  phone: z.string().max(20).optional(),
  isEmergencyContact: z.boolean().optional(),
}).strict() });

const CommitteeSchema = z.object({ body: z.object({
  designation: s.max(60),
  termStart: dateStr.optional(),
  termEnd: dateStr.optional(),
}).strict() });

const KycSchema = z.object({ body: z.object({
  docType: s.max(40),
  fileUrl: z.string().max(1000).optional(),
  expiresAt: dateStr.optional(),
}).strict() });

const KycReviewSchema = z.object({ body: z.object({
  decision: z.enum(["approved", "rejected"]),
  reason: z.string().max(500).optional(),
}).strict() });

const map = (res: Response, e: any, fallback: string) => {
  if (e.code === "NOT_FOUND") return res.status(404).json({ error: e.message });
  if (e.code === "INVALID_TRANSITION") return res.status(409).json({ error: e.message });
  logger.error({ error: e.message }, fallback);
  return res.status(500).json({ error: fallback });
};

// List members
router.get("/", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    res.json({ members: await MemberService.listMembers(societyOf(req), {
      status: req.query.status as string,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    }) });
  } catch (e: any) { map(res, e, "Failed to list members"); }
});

// Get one member (with family + committee + kyc)
router.get("/:id", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ member: await MemberService.getMember(societyOf(req), req.params.id) }); }
  catch (e: any) { map(res, e, "Failed to get member"); }
});

// Register (creates pending)
router.post("/", authMiddleware, tenantMiddleware, validate(RegisterSchema), async (req, res) => {
  try { res.status(201).json({ member: await MemberService.register(societyOf(req), req.body) }); }
  catch (e: any) { map(res, e, "Failed to register member"); }
});

// Lifecycle transition
router.post("/:id/transition", authMiddleware, tenantMiddleware, canManageContent, validate(TransitionSchema), async (req, res) => {
  try { res.json({ member: await MemberService.transition(societyOf(req), req.params.id, req.body.status) }); }
  catch (e: any) { map(res, e, "Failed to transition member"); }
});

// Family members
router.post("/:id/family", authMiddleware, tenantMiddleware, validate(FamilySchema), async (req, res) => {
  try { res.status(201).json({ family: await MemberService.addFamilyMember(societyOf(req), req.params.id, req.body) }); }
  catch (e: any) { map(res, e, "Failed to add family member"); }
});

// Committee role
router.post("/:id/committee", authMiddleware, tenantMiddleware, canManageContent, validate(CommitteeSchema), async (req, res) => {
  try { res.status(201).json({ committee: await MemberService.addCommitteeRole(societyOf(req), req.params.id, req.body) }); }
  catch (e: any) { map(res, e, "Failed to add committee role"); }
});

// KYC upload
router.post("/:id/kyc", authMiddleware, tenantMiddleware, validate(KycSchema), async (req, res) => {
  try { res.status(201).json({ kyc: await MemberService.addKyc(societyOf(req), req.params.id, req.body) }); }
  catch (e: any) { map(res, e, "Failed to add KYC document"); }
});

// KYC review
router.post("/kyc/:id/review", authMiddleware, tenantMiddleware, canManageContent, validate(KycReviewSchema), async (req, res) => {
  try {
    res.json({ kyc: await MemberService.reviewKyc(societyOf(req), req.params.id, req.body.decision, req.body.reason, userOf(req)) });
  } catch (e: any) { map(res, e, "Failed to review KYC document"); }
});

export default router;
