import { Request, Response, NextFunction } from "express";

export interface TenantRequest extends Request {
  user?: {
    uid: string;
    role: string;
    society_id: string;
    [key: string]: any;
  };
  societyId?: string;
}

/**
 * Middleware to enforce multi-tenancy by extracting societyId from the authenticated user.
 * Assumes the request has already passed through authMiddleware.
 */
export const tenantMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const tReq = req as TenantRequest;

  if (!tReq.user) {
    return res.status(401).json({ error: "Authentication required for tenant enforcement" });
  }

  const societyId = tReq.user.society_id;

  if (!societyId) {
    // SECURITY: Reject requests without a valid tenant context
    return res.status(403).json({ error: "Tenant context (societyId) is required for this action" });
  }

  // Inject societyId into the request object for easy access in routes/services
  tReq.societyId = societyId;
  if ((tReq as any).context) {
    (tReq as any).context.societyId = societyId;
  }

  next();
};

/**
 * FIND-002 guard: society-scoped data routes must NOT silently return empty/zero
 * results when the caller's JWT has no active workspace (society_id = null/empty,
 * e.g. a multi-workspace account that hasn't selected one yet). Instead return a
 * clear, machine-readable 409 so the client knows to force workspace selection.
 *
 * Run this BEFORE tenantMiddleware on the highest-value data routes. It does not
 * touch platform/super-admin routes that legitimately have a null society.
 */
export const requireSociety = (req: Request, res: Response, next: NextFunction) => {
  const tReq = req as TenantRequest;
  const societyId = tReq.user?.society_id;
  if (!societyId) {
    return res.status(409).json({
      error: { code: "NO_ACTIVE_WORKSPACE", message: "Select a workspace first." },
    });
  }
  next();
};
