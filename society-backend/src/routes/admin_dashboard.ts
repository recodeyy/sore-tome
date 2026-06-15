import { Router, Request, Response } from "express";
import { DashboardService } from "../services/DashboardService";
import { logger } from "../shared/Logger";

// @ts-ignore
import { authMiddleware, adminOnly } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();

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

export default router;
