import { Router, Request, Response } from "express";
import { z } from "zod";
import { PollService } from "../services/polls/PollService";
import { validate } from "../middleware/validate";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, canManageContent } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();

const societyOf = (req: Request) => (req as any).societyId as string;
const userOf = (req: Request) => (req as any).user || {};
const isAdminRole = (req: Request) =>
  ["main_admin", "secretary", "admin", "super_admin", "superadmin"].includes(userOf(req).role);

// ---- Inline Zod schemas (validate() expects { body, query, params }) ----

const CreatePollSchema = z.object({
  body: z
    .object({
      title: z.string().min(1).max(200),
      description: z.string().max(2000).optional(),
      isAnonymous: z.boolean().optional().default(false),
      voteScope: z.enum(["user", "unit"]).optional().default("user"),
      resultsVisibility: z.enum(["always", "after_close", "admins_only"]).optional().default("after_close"),
      startsAt: z.string().datetime().optional(),
      endsAt: z.string().datetime().optional(),
      options: z
        .array(z.object({ label: z.string().min(1).max(200), position: z.number().int().optional() }))
        .min(2)
        .max(50),
      eligibility: z
        .array(
          z.object({
            audienceType: z.enum(["all", "role", "wing", "block", "unit"]),
            audienceValue: z.string().max(120).optional(),
          })
        )
        .max(100)
        .optional(),
    })
    .strict(),
});

const VoteSchema = z.object({
  body: z
    .object({
      optionId: z.string().uuid(),
      unitId: z.string().max(64).optional(),
    })
    .strict(),
});

const errToHttp = (res: Response, err: any, fallback: string) => {
  switch (err.code) {
    case "ALREADY_VOTED":
      return res.status(409).json({ error: err.message });
    case "NOT_FOUND":
      return res.status(404).json({ error: err.message });
    case "INVALID_STATE":
      return res.status(409).json({ error: err.message });
    case "NOT_ELIGIBLE":
      return res.status(403).json({ error: err.message });
    default:
      logger.error({ error: err.message }, fallback);
      return res.status(500).json({ error: fallback });
  }
};

// GET /polls — list (optionally filtered by status)
router.get("/", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const polls = await PollService.listPolls(societyOf(req), {
      status: typeof req.query.status === "string" ? req.query.status : undefined,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    });
    res.json({ polls });
  } catch (err: any) {
    logger.error({ error: err.message }, "List polls failed");
    res.status(500).json({ error: "Failed to list polls" });
  }
});

// GET /polls/:id — detail with options + whether requester has voted
router.get("/:id", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const detail = await PollService.getPoll(societyOf(req), req.params.id, {
      voterId: userOf(req).uid,
      unitId: userOf(req).unitId,
    });
    if (!detail) return res.status(404).json({ error: "Poll not found" });
    res.json(detail);
  } catch (err: any) {
    logger.error({ error: err.message }, "Get poll failed");
    res.status(500).json({ error: "Failed to get poll" });
  }
});

// POST /polls — create draft poll (admin)
router.post("/", authMiddleware, tenantMiddleware, canManageContent, validate(CreatePollSchema), async (req: Request, res: Response) => {
  try {
    const poll = await PollService.createPoll(societyOf(req), req.body, userOf(req).uid);
    res.status(201).json({ poll });
  } catch (err: any) {
    errToHttp(res, err, "Failed to create poll");
  }
});

// POST /polls/:id/open — draft -> open (admin)
router.post("/:id/open", authMiddleware, tenantMiddleware, canManageContent, async (req: Request, res: Response) => {
  try {
    const poll = await PollService.open(societyOf(req), req.params.id);
    res.json({ poll });
  } catch (err: any) {
    errToHttp(res, err, "Failed to open poll");
  }
});

// POST /polls/:id/close — open -> closed (admin)
router.post("/:id/close", authMiddleware, tenantMiddleware, canManageContent, async (req: Request, res: Response) => {
  try {
    const poll = await PollService.close(societyOf(req), req.params.id);
    res.json({ poll });
  } catch (err: any) {
    errToHttp(res, err, "Failed to close poll");
  }
});

// POST /polls/:id/vote — any authenticated user casts one eligible vote
router.post("/:id/vote", authMiddleware, tenantMiddleware, validate(VoteSchema), async (req: Request, res: Response) => {
  try {
    const vote = await PollService.castVote(societyOf(req), req.params.id, {
      optionId: req.body.optionId,
      voterId: userOf(req).uid,
      unitId: req.body.unitId || userOf(req).unitId,
    });
    res.status(201).json({ vote });
  } catch (err: any) {
    errToHttp(res, err, "Failed to cast vote");
  }
});

// GET /polls/:id/results — tallies respecting results_visibility
router.get("/:id/results", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const results = await PollService.results(societyOf(req), req.params.id, isAdminRole(req));
    res.json(results);
  } catch (err: any) {
    errToHttp(res, err, "Failed to get poll results");
  }
});

export default router;
