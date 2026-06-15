import { Router, Request, Response, NextFunction } from "express";
import { SuperAdminService } from "../services/platform/SuperAdminService";
import { logger } from "../shared/Logger";

// @ts-ignore
import { authMiddleware } from "../../middleware/auth";

const router = Router();

function superAdminOnly(req: Request, res: Response, next: NextFunction) {
  const role = SuperAdminService.normalizeRole((req as any).user?.role);
  if (role !== "super_admin") {
    logger.warn(
      { userId: (req as any).user?.uid, role, path: req.path },
      "SEC-WARN: Unauthorized Super Admin access attempt"
    );
    return res.status(403).json({
      success: false,
      error: { code: "SUPER_ADMIN_REQUIRED", message: "Super Admin access required" },
    });
  }
  (req as any).user.role = role;
  return next();
}

function actorId(req: Request): string {
  return (req as any).user?.uid || "unknown";
}

function sendError(res: Response, route: string, error: any) {
  const statusCode = Number(error?.statusCode) || 500;
  logger.error({ error: error?.message, route }, "Super Admin route failed");
  return res.status(statusCode).json({
    success: false,
    error: {
      code: statusCode === 400 ? "VALIDATION_FAILED" : "SUPER_ADMIN_ROUTE_FAILED",
      message: error?.message || "Super Admin request failed",
    },
  });
}

router.use(authMiddleware, superAdminOnly);

router.get("/overview", async (_req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.overview();
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "GET /super-admin/overview", error);
  }
});

router.get("/societies", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.societies({
      status: req.query.status as string | undefined,
      q: req.query.q as string | undefined,
      limit: req.query.limit,
      cursor: req.query.cursor,
    });
    return res.json({ success: true, ...data });
  } catch (error: any) {
    return sendError(res, "GET /super-admin/societies", error);
  }
});

router.get("/societies/:societyId", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.societyDetail(req.params.societyId);
    if (!data) {
      return res.status(404).json({
        success: false,
        error: { code: "SOCIETY_NOT_FOUND", message: "Society not found" },
      });
    }
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "GET /super-admin/societies/:societyId", error);
  }
});

router.get("/applications", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.applications((req.query.status as string) || "pending");
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "GET /super-admin/applications", error);
  }
});

router.post("/applications/:id/review", async (req: Request, res: Response) => {
  try {
    const action = req.body?.action;
    if (action !== "approve" && action !== "reject") {
      return res.status(400).json({
        success: false,
        error: { code: "VALIDATION_FAILED", message: "action must be approve or reject" },
      });
    }
    const data = await SuperAdminService.reviewApplication(
      req.params.id,
      action,
      actorId(req),
      req.body?.reason
    );
    if (!data) {
      return res.status(409).json({
        success: false,
        error: { code: "APPLICATION_NOT_PENDING", message: "Application is not pending or was not found" },
      });
    }
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/applications/:id/review", error);
  }
});

router.get("/plans", async (_req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.plans();
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "GET /super-admin/plans", error);
  }
});

router.get("/revenue", async (_req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.overview();
    return res.json({ success: true, data: data.revenue });
  } catch (error: any) {
    return sendError(res, "GET /super-admin/revenue", error);
  }
});

router.get("/support/tickets", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.supportTickets((req.query.status as string) || "open");
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "GET /super-admin/support/tickets", error);
  }
});

router.patch("/societies/:societyId/features/:featureKey", async (req: Request, res: Response) => {
  try {
    if (typeof req.body?.enabled !== "boolean") {
      return res.status(400).json({
        success: false,
        error: { code: "VALIDATION_FAILED", message: "enabled must be boolean" },
      });
    }
    const data = await SuperAdminService.setFeatureOverride(
      req.params.societyId,
      req.params.featureKey,
      req.body.enabled,
      actorId(req)
    );
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "PATCH /super-admin/societies/:societyId/features/:featureKey", error);
  }
});

router.post("/impersonation/start", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.startImpersonation({
      actorId: actorId(req),
      targetUserId: String(req.body?.targetUserId || ""),
      societyId: req.body?.societyId,
      reason: String(req.body?.reason || ""),
      durationMinutes: Number(req.body?.durationMinutes || 15),
    });
    return res.status(201).json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/impersonation/start", error);
  }
});

router.post("/impersonation/:id/stop", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.stopImpersonation(req.params.id, actorId(req));
    if (!data) {
      return res.status(404).json({
        success: false,
        error: { code: "IMPERSONATION_NOT_FOUND", message: "Active impersonation session not found" },
      });
    }
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/impersonation/:id/stop", error);
  }
});

router.get("/audit-logs", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.auditLogs(req.query.limit);
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "GET /super-admin/audit-logs", error);
  }
});

router.get("/system-health", async (_req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.overview();
    return res.json({ success: true, data: data.systemHealth });
  } catch (error: any) {
    return sendError(res, "GET /super-admin/system-health", error);
  }
});

export default router;
