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
  
  next();
};
