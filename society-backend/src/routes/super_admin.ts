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

router.get("/dashboard", async (_req: Request, res: Response) => {
  try {
    const overview = await SuperAdminService.overview();
    return res.json({
      success: true,
      data: {
        adminName: "Super Admin",
        metrics: [
          {
            key: "total_societies",
            label: "Total Societies",
            value: String((overview.societies as any).total || 0),
            trend: "Live",
          },
          {
            key: "pending_approvals",
            label: "Pending Approvals",
            value: String((overview.applications as any).pending_approvals || 0),
            trend: "Queue",
          },
          {
            key: "active_users",
            label: "Active Users",
            value: String((overview.users as any).active_users || 0),
            trend: "MAU",
          },
          {
            key: "monthly_revenue",
            label: "Monthly Revenue",
            value: `₹${Number((overview.revenue as any).mrr_minor || 0) / 100}`,
            trend: "MRR",
          },
          {
            key: "open_support",
            label: "Open Support Tickets",
            value: String((overview.support as any).open_tickets || 0),
            trend: "SLA",
          },
          {
            key: "system_health",
            label: "System Health",
            value: (overview.systemHealth as any).status || "unknown",
            trend: "Now",
          },
        ],
        revenue: overview.revenue,
        support: overview.support,
        platformHealth: [
          { label: "API", status: (overview.systemHealth as any).api || "unknown" },
          { label: "Database", status: (overview.systemHealth as any).database || "unknown" },
          { label: "Queue", status: (overview.systemHealth as any).queue || "unknown" },
          { label: "AI Providers", status: (overview.systemHealth as any).aiProviders || "unknown" },
        ],
        activityTrend: [
          { label: "DAU", value: (overview.adoption as any).dau || 0 },
          { label: "MAU", value: (overview.adoption as any).mau || 0 },
        ],
        onboardingFunnel: [
          { label: "Pending", count: (overview.applications as any).pending_approvals || 0, completionRate: 0 },
          { label: "Approved", count: (overview.applications as any).approved || 0, completionRate: 100 },
        ],
        recentActivity: [],
        failedJobs: 0,
        aiUsage: { spend: 0 },
      },
    });
  } catch (error: any) {
    return sendError(res, "GET /super-admin/dashboard", error);
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
    const data = await SuperAdminService.societyDetail((req.params.societyId as string));
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
      (req.params.id as string),
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

router.get("/analytics/revenue", async (_req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.overview();
    return res.json({ success: true, data: data.revenue });
  } catch (error: any) {
    return sendError(res, "GET /super-admin/analytics/revenue", error);
  }
});

router.get("/support/analytics", async (_req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.overview();
    return res.json({ success: true, data: data.support });
  } catch (error: any) {
    return sendError(res, "GET /super-admin/support/analytics", error);
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
      (req.params.societyId as string),
      (req.params.featureKey as string),
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

router.post("/impersonation/sessions", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.startImpersonation({
      actorId: actorId(req),
      targetUserId: String(req.body?.userId || req.body?.targetUserId || ""),
      societyId: req.body?.societyId,
      reason: String(req.body?.reason || ""),
      durationMinutes: Number(req.body?.durationMinutes || 15),
    });
    return res.status(201).json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/impersonation/sessions", error);
  }
});

router.post("/impersonation/:id/stop", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.stopImpersonation((req.params.id as string), actorId(req));
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

router.post("/impersonation/sessions/current/stop", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.stopCurrentImpersonation(actorId(req));
    if (!data) {
      return res.status(404).json({
        success: false,
        error: { code: "IMPERSONATION_NOT_FOUND", message: "No active impersonation session found for super admin" },
      });
    }
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/impersonation/sessions/current/stop", error);
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

router.get("/societies/:societyId/activity", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.societyActivity((req.params.societyId as string), req.query.limit as string);
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "GET /super-admin/societies/:societyId/activity", error);
  }
});

router.post("/societies/:societyId/approve", async (req: Request, res: Response) => {
  try {
    const reason = req.body?.reason || "Approved by Super Admin";
    await SuperAdminService.approveSociety((req.params.societyId as string), actorId(req), reason);
    return res.json({ success: true, message: "Society approved" });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/societies/:societyId/approve", error);
  }
});

router.post("/societies/:societyId/reject", async (req: Request, res: Response) => {
  try {
    const reason = req.body?.reason;
    if (!reason?.trim()) {
      return res.status(400).json({ success: false, error: { code: "VALIDATION_FAILED", message: "reason is required" } });
    }
    await SuperAdminService.rejectSociety((req.params.societyId as string), actorId(req), reason);
    return res.json({ success: true, message: "Society rejected" });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/societies/:societyId/reject", error);
  }
});

router.post("/societies/:societyId/request-information", async (req: Request, res: Response) => {
  try {
    const reason = req.body?.reason || "";
    const requestedFields = req.body?.requestedFields || [];
    await SuperAdminService.requestSocietyInformation((req.params.societyId as string), actorId(req), reason, requestedFields);
    return res.json({ success: true, message: "Information requested" });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/societies/:societyId/request-information", error);
  }
});

router.post("/societies/:societyId/suspend", async (req: Request, res: Response) => {
  try {
    const reason = req.body?.reason || "Suspended by Super Admin";
    await SuperAdminService.suspendSociety((req.params.societyId as string), actorId(req), reason);
    return res.json({ success: true, message: "Society suspended" });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/societies/:societyId/suspend", error);
  }
});

router.post("/societies/:societyId/reactivate", async (req: Request, res: Response) => {
  try {
    const reason = req.body?.reason || "Reactivated by Super Admin";
    await SuperAdminService.reactivateSociety((req.params.societyId as string), actorId(req), reason);
    return res.json({ success: true, message: "Society reactivated" });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/societies/:societyId/reactivate", error);
  }
});

router.post("/support/tickets/:ticketId/assign", async (req: Request, res: Response) => {
  try {
    const { assigneeId, reason } = req.body;
    if (!assigneeId || !reason) {
      return res.status(400).json({ success: false, error: { code: "VALIDATION_FAILED", message: "assigneeId and reason are required" } });
    }
    const data = await SuperAdminService.assignTicket((req.params.ticketId as string), assigneeId, reason, actorId(req));
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/support/tickets/:ticketId/assign", error);
  }
});

router.post("/support/tickets/:ticketId/internal-note", async (req: Request, res: Response) => {
  try {
    const { note } = req.body;
    if (!note) {
      return res.status(400).json({ success: false, error: { code: "VALIDATION_FAILED", message: "note is required" } });
    }
    await SuperAdminService.addInternalNote((req.params.ticketId as string), note, actorId(req));
    return res.json({ success: true, message: "Internal note added" });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/support/tickets/:ticketId/internal-note", error);
  }
});

router.post("/support/tickets/:ticketId/resolve", async (req: Request, res: Response) => {
  try {
    const { resolution } = req.body;
    if (!resolution) {
      return res.status(400).json({ success: false, error: { code: "VALIDATION_FAILED", message: "resolution is required" } });
    }
    const data = await SuperAdminService.resolveTicket((req.params.ticketId as string), resolution, actorId(req));
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/support/tickets/:ticketId/resolve", error);
  }
});

router.get("/features", async (_req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.getFeatures();
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "GET /super-admin/features", error);
  }
});

router.get("/announcements", async (_req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.getAnnouncements();
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "GET /super-admin/announcements", error);
  }
});

router.post("/announcements", async (req: Request, res: Response) => {
  try {
    const { title, body } = req.body;
    if (!title || !body) {
      return res.status(400).json({ success: false, error: { code: "VALIDATION_FAILED", message: "title and body are required" } });
    }
    const data = await SuperAdminService.createAnnouncement(title, body, actorId(req));
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/announcements", error);
  }
});

router.post("/reports", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.requestReport(req.body, actorId(req));
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/reports", error);
  }
});

// --- Subscription plan CRUD & assignment ------------------------------------

router.post("/plans", async (req: Request, res: Response) => {
  try {
    const { code, name, priceMinor, currency, interval, features, isActive } = req.body || {};
    const data = await SuperAdminService.createPlan({ code, name, priceMinor, currency, interval, features, isActive });
    return res.status(201).json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/plans", error);
  }
});

router.patch("/plans/:planId", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.updatePlan((req.params.planId as string), req.body || {});
    if (!data) {
      return res.status(404).json({ success: false, error: { code: "PLAN_NOT_FOUND", message: "Plan not found" } });
    }
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "PATCH /super-admin/plans/:planId", error);
  }
});

router.post("/plans/:planId/deactivate", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.deactivatePlan((req.params.planId as string));
    if (!data) {
      return res.status(404).json({ success: false, error: { code: "PLAN_NOT_FOUND", message: "Plan not found" } });
    }
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/plans/:planId/deactivate", error);
  }
});

router.post("/societies/:societyId/assign-plan", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.assignPlan({
      societyId: (req.params.societyId as string),
      planId: String(req.body?.planId || ""),
      effectiveDate: req.body?.effectiveDate,
      actorId: actorId(req),
      reason: req.body?.reason,
    });
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/societies/:societyId/assign-plan", error);
  }
});

router.post("/plans/:planId/proration-preview", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.prorationPreview({
      planId: (req.params.planId as string),
      renewsAt: req.body?.renewsAt,
      cycleDays: req.body?.cycleDays,
      asOf: req.body?.asOf,
    });
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/plans/:planId/proration-preview", error);
  }
});

// --- Society lifecycle: KYC + archive/offboard ------------------------------

router.post("/societies/:societyId/kyc-review", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.reviewSocietyKyc({
      societyId: (req.params.societyId as string),
      applicationId: req.body?.applicationId,
      decision: req.body?.decision,
      reason: req.body?.reason,
      actorId: actorId(req),
    });
    return res.status(201).json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/societies/:societyId/kyc-review", error);
  }
});

router.post("/societies/:societyId/archive", async (req: Request, res: Response) => {
  try {
    const reason = req.body?.reason || "Archived by Super Admin";
    await SuperAdminService.archiveSociety((req.params.societyId as string), actorId(req), reason);
    return res.json({ success: true, message: "Society archived" });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/societies/:societyId/archive", error);
  }
});

router.post("/societies/:societyId/offboard", async (req: Request, res: Response) => {
  try {
    const reason = req.body?.reason || "Offboarded by Super Admin";
    await SuperAdminService.offboardSociety((req.params.societyId as string), actorId(req), reason);
    return res.json({ success: true, message: "Society offboarded" });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/societies/:societyId/offboard", error);
  }
});

// --- Platform configuration: caps 20-23 -------------------------------------

// cap 20: feature rollouts
router.put("/rollouts/:featureKey", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.setRollout({
      featureKey: (req.params.featureKey as string),
      cohort: req.body?.cohort,
      percentage: req.body?.percentage,
      status: req.body?.status,
    });
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "PUT /super-admin/rollouts/:featureKey", error);
  }
});

router.get("/rollouts/:featureKey/evaluate", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.evaluateRollout(
      (req.params.featureKey as string),
      String(req.query.societyId || "")
    );
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "GET /super-admin/rollouts/:featureKey/evaluate", error);
  }
});

// cap 21: white-label profiles
router.get("/societies/:societyId/white-label", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.getWhiteLabel((req.params.societyId as string));
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "GET /super-admin/societies/:societyId/white-label", error);
  }
});

router.put("/societies/:societyId/white-label", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.upsertWhiteLabel({
      societyId: (req.params.societyId as string),
      brandName: req.body?.brandName,
      colors: req.body?.colors,
      logoUrl: req.body?.logoUrl,
    });
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "PUT /super-admin/societies/:societyId/white-label", error);
  }
});

router.post("/societies/:societyId/white-label/publish", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.publishWhiteLabel((req.params.societyId as string));
    if (!data) {
      return res.status(404).json({ success: false, error: { code: "WHITE_LABEL_NOT_FOUND", message: "White-label profile not found" } });
    }
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/societies/:societyId/white-label/publish", error);
  }
});

// cap 22: API clients
router.get("/societies/:societyId/api-clients", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.listApiClients((req.params.societyId as string));
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "GET /super-admin/societies/:societyId/api-clients", error);
  }
});

router.post("/societies/:societyId/api-clients", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.createApiClient({
      societyId: (req.params.societyId as string),
      name: String(req.body?.name || ""),
      scopes: req.body?.scopes,
      quotaPerDay: req.body?.quotaPerDay,
    });
    return res.status(201).json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/societies/:societyId/api-clients", error);
  }
});

router.post("/api-clients/:id/revoke", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.revokeApiClient((req.params.id as string));
    if (!data) {
      return res.status(404).json({ success: false, error: { code: "API_CLIENT_NOT_FOUND", message: "API client not found" } });
    }
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/api-clients/:id/revoke", error);
  }
});

// cap 23: webhooks + integrations
router.get("/societies/:societyId/webhooks", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.listWebhooks((req.params.societyId as string));
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "GET /super-admin/societies/:societyId/webhooks", error);
  }
});

router.post("/societies/:societyId/webhooks", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.createWebhook({
      societyId: (req.params.societyId as string),
      url: String(req.body?.url || ""),
      events: req.body?.events,
      secret: req.body?.secret,
    });
    return res.status(201).json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "POST /super-admin/societies/:societyId/webhooks", error);
  }
});

router.put("/societies/:societyId/integrations/:provider", async (req: Request, res: Response) => {
  try {
    const data = await SuperAdminService.setIntegration({
      societyId: (req.params.societyId as string),
      provider: (req.params.provider as string),
      config: req.body?.config,
      status: req.body?.status,
    });
    return res.json({ success: true, data });
  } catch (error: any) {
    return sendError(res, "PUT /super-admin/societies/:societyId/integrations/:provider", error);
  }
});

export default router;
