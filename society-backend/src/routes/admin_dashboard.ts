import { Router, Request, Response } from "express";
import { DashboardService } from "../services/DashboardService";
import { AnalyticsService } from "../services/dashboard/AnalyticsService";
import { SearchService } from "../services/dashboard/SearchService";
import { ActivityService } from "../services/dashboard/ActivityService";
import { PreferenceService } from "../services/dashboard/PreferenceService";
import { logger } from "../shared/Logger";

// @ts-ignore
import { authMiddleware, adminOnly } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();

const societyOf = (req: Request) => (req as any).societyId as string;
const userIdOf = (req: Request) => (req as any).user?.uid as string;

/**
 * GET /admin/dashboard-stats
 * High-performance centralized dashboard stats with integrated caching.
 */
router.get("/dashboard-stats", authMiddleware, adminOnly, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.uid || "anonymous";
    const societyId = (req as any).societyId;

    const dashboardService = DashboardService.getInstance();
    const stats = await dashboardService.getDashboardStats(societyId);

    logger.info({ userId, societyId }, "Admin Dashboard stats requested");
    return res.status(200).json(stats);

  } catch (error: any) {
    logger.error({ error: error.message }, "/admin/dashboard-stats failed");
    return res.status(500).json({ error: "Failed to fetch dashboard stats", message: error.message });
  }
});

/**
 * GET /admin/dashboard/summary
 * Tenant-scoped headline counters (capability 1).
 */
router.get("/dashboard/summary", authMiddleware, adminOnly, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const data = await AnalyticsService.summary(societyOf(req));
    return res.json({ success: true, data });
  } catch (error: any) {
    logger.error({ error: error.message }, "/admin/dashboard/summary failed");
    return res.status(500).json({ success: false, error: { code: "DASHBOARD_SUMMARY_FAILED", message: error.message } });
  }
});

/**
 * GET /admin/dashboard/vitals
 * Tenant-scoped live society vitals (parcels, guards on duty, active
 * maintenance, system status). Replaces the legacy Firestore vitals doc.
 */
router.get("/dashboard/vitals", authMiddleware, adminOnly, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const data = await AnalyticsService.vitals(societyOf(req));
    return res.json({ success: true, data });
  } catch (error: any) {
    logger.error({ error: error.message }, "/admin/dashboard/vitals failed");
    return res.status(500).json({ success: false, error: { code: "DASHBOARD_VITALS_FAILED", message: error.message } });
  }
});

/**
 * GET /admin/dashboard/trends?from=YYYY-MM-DD&to=YYYY-MM-DD
 * Daily collections & expenses over a date range (capability 4).
 */
router.get("/dashboard/trends", authMiddleware, adminOnly, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const data = await AnalyticsService.trends(societyOf(req), req.query.from as string, req.query.to as string);
    return res.json({ success: true, data });
  } catch (error: any) {
    logger.error({ error: error.message }, "/admin/dashboard/trends failed");
    return res.status(500).json({ success: false, error: { code: "DASHBOARD_TRENDS_FAILED", message: error.message } });
  }
});

/**
 * GET /admin/dashboard/alerts
 * Actionable operational alerts (capability 5).
 */
router.get("/dashboard/alerts", authMiddleware, adminOnly, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const data = await AnalyticsService.alerts(societyOf(req));
    return res.json({ success: true, data });
  } catch (error: any) {
    logger.error({ error: error.message }, "/admin/dashboard/alerts failed");
    return res.status(500).json({ success: false, error: { code: "DASHBOARD_ALERTS_FAILED", message: error.message } });
  }
});

/**
 * GET /admin/dashboard/activity?limit=...
 * Reverse-chronological activity feed across members, finance, complaints,
 * notices, bookings, and assets (capability 3).
 */
router.get("/dashboard/activity", authMiddleware, adminOnly, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const limit = req.query.limit ? Number(req.query.limit) : 20;
    const data = await ActivityService.feed(societyOf(req), limit);
    return res.json({ success: true, data });
  } catch (error: any) {
    logger.error({ error: error.message }, "/admin/dashboard/activity failed");
    return res.status(500).json({ success: false, error: { code: "DASHBOARD_ACTIVITY_FAILED", message: error.message } });
  }
});

/**
 * GET /admin/search?q=...&limit=...
 * Tenant-scoped global search across members, units, complaints, notices,
 * assets, and staff (capability 7).
 */
router.get("/search", authMiddleware, adminOnly, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const limit = req.query.limit ? Number(req.query.limit) : 20;
    const data = await SearchService.search(societyOf(req), (req.query.q as string) || "", limit);
    return res.json({ success: true, data });
  } catch (error: any) {
    logger.error({ error: error.message }, "/admin/search failed");
    return res.status(500).json({ success: false, error: { code: "SEARCH_FAILED", message: error.message } });
  }
});

/**
 * GET /admin/dashboard/preferences
 * The caller's saved widget layout and filters (capability 8).
 */
router.get("/dashboard/preferences", authMiddleware, adminOnly, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const data = await PreferenceService.get(societyOf(req), userIdOf(req));
    return res.json({ success: true, data });
  } catch (error: any) {
    logger.error({ error: error.message }, "/admin/dashboard/preferences GET failed");
    return res.status(500).json({ success: false, error: { code: "DASHBOARD_PREFS_FAILED", message: error.message } });
  }
});

/**
 * PUT /admin/dashboard/preferences
 * Upsert the caller's widget layout and saved filters.
 */
router.put("/dashboard/preferences", authMiddleware, adminOnly, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const { widgets, savedFilters } = req.body || {};
    if (widgets !== undefined && !Array.isArray(widgets)) {
      return res.status(400).json({ success: false, error: { code: "VALIDATION", message: "widgets must be an array" } });
    }
    if (savedFilters !== undefined && !Array.isArray(savedFilters)) {
      return res.status(400).json({ success: false, error: { code: "VALIDATION", message: "savedFilters must be an array" } });
    }
    const data = await PreferenceService.save(societyOf(req), userIdOf(req), { widgets, savedFilters });
    return res.json({ success: true, data });
  } catch (error: any) {
    logger.error({ error: error.message }, "/admin/dashboard/preferences PUT failed");
    return res.status(500).json({ success: false, error: { code: "DASHBOARD_PREFS_FAILED", message: error.message } });
  }
});

export default router;
