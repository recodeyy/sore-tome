import { Router, Request, Response } from "express";
import { AuditLogService } from "../services/AuditLogService.js";
// @ts-ignore
import { authMiddleware, adminOnly } from "../../middleware/auth.js";

const router = Router();
const auditService = AuditLogService.getInstance();

/**
 * GET /admin/access-logs
 * Fetches unified society heartbeats/logs.
 * Query params: type (all|security|administrative|system), limit
 */
router.get("/access-logs", authMiddleware, adminOnly, async (req: Request, res: Response) => {
    try {
        const type = req.query.type as string || 'all';
        const limit = parseInt(req.query.limit as string) || 50;
        
        // In this architecture, societyId corresponds to the society the admin belongs to.
        // For current dev, we use 'global'.
        const logs = await auditService.getLogs('global', type, limit);
        
        res.json({ logs });
    } catch (err: any) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * POST /admin/access-logs/visitor
 * Manual entry for a visitor (Security Log)
 */
router.post("/access-logs/visitor", authMiddleware, adminOnly, async (req: Request, res: Response) => {
    try {
        const { visitorName, purpose, phone } = req.body;
        if (!visitorName) return res.status(400).json({ error: "Visitor name is required" });

        await auditService.logSecurityEvent(
            req.user.name || 'Admin',
            "Visitor Entry",
            `${visitorName} (${phone || 'No phone'}) - Purpose: ${purpose || 'General'}`
        );

        res.status(201).json({ message: "Visitor entry logged" });
    } catch (err: any) {
        res.status(500).json({ error: err.message });
    }
});

export default router;
