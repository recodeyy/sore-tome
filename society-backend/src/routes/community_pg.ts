import { Router, Request, Response } from "express";
import { z } from "zod";
import { CommunityService } from "../services/community/CommunityService";
import { validate } from "../middleware/validate";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();
const societyOf = (req: Request) => (req as any).societyId as string;
const userOf = (req: Request) => (req as any).user || {};

// ---- Zod schemas (validate() wraps body/query/params) --------------------
const MarketplaceSchema = z.object({
  body: z.object({
    title: z.string().trim().min(1).max(200),
    description: z.string().max(5000).optional(),
    priceMinor: z.number().int().nonnegative().optional(),
    category: z.string().max(80).optional(),
  }).strict(),
});

const CarpoolSchema = z.object({
  body: z.object({
    fromLocation: z.string().trim().min(1).max(200),
    toLocation: z.string().trim().min(1).max(200),
    rideTime: z.string().datetime().optional(),
    seats: z.number().int().positive().max(20).optional(),
    notes: z.string().max(2000).optional(),
  }).strict(),
});

const LostFoundSchema = z.object({
  body: z.object({
    kind: z.enum(["lost", "found"]),
    title: z.string().trim().min(1).max(200),
    description: z.string().max(5000).optional(),
    location: z.string().max(200).optional(),
  }).strict(),
});

const map = (res: Response, e: any, fallback: string) => {
  if (e.code === "NOT_FOUND") return res.status(404).json({ error: e.message });
  logger.error({ error: e.message }, fallback);
  return res.status(500).json({ error: fallback });
};

// ---- Marketplace ----------------------------------------------------------
router.get("/marketplace", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ items: await CommunityService.listMarketplace(societyOf(req)) }); }
  catch (e: any) { map(res, e, "Failed to list marketplace items"); }
});
router.post("/marketplace", authMiddleware, tenantMiddleware, validate(MarketplaceSchema), async (req, res) => {
  try { res.status(201).json({ item: await CommunityService.createMarketplaceItem(societyOf(req), { ...req.body, postedBy: userOf(req).uid }) }); }
  catch (e: any) { map(res, e, "Failed to create marketplace item"); }
});
router.post("/marketplace/:id/sold", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ item: await CommunityService.markMarketplaceSold(societyOf(req), (req.params.id as string)) }); }
  catch (e: any) { map(res, e, "Failed to mark item sold"); }
});

// ---- Carpool --------------------------------------------------------------
router.get("/carpool", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ rides: await CommunityService.listCarpool(societyOf(req)) }); }
  catch (e: any) { map(res, e, "Failed to list carpool rides"); }
});
router.post("/carpool", authMiddleware, tenantMiddleware, validate(CarpoolSchema), async (req, res) => {
  try { res.status(201).json({ ride: await CommunityService.createCarpoolRide(societyOf(req), { ...req.body, postedBy: userOf(req).uid }) }); }
  catch (e: any) { map(res, e, "Failed to create carpool ride"); }
});
router.post("/carpool/:id/close", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ ride: await CommunityService.closeCarpoolRide(societyOf(req), (req.params.id as string)) }); }
  catch (e: any) { map(res, e, "Failed to close carpool ride"); }
});

// ---- Lost & Found ---------------------------------------------------------
router.get("/lost-found", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ items: await CommunityService.listLostFound(societyOf(req)) }); }
  catch (e: any) { map(res, e, "Failed to list lost & found items"); }
});
router.post("/lost-found", authMiddleware, tenantMiddleware, validate(LostFoundSchema), async (req, res) => {
  try { res.status(201).json({ item: await CommunityService.createLostFoundItem(societyOf(req), { ...req.body, postedBy: userOf(req).uid }) }); }
  catch (e: any) { map(res, e, "Failed to create lost & found item"); }
});
router.post("/lost-found/:id/resolve", authMiddleware, tenantMiddleware, async (req, res) => {
  try { res.json({ item: await CommunityService.resolveLostFoundItem(societyOf(req), (req.params.id as string)) }); }
  catch (e: any) { map(res, e, "Failed to resolve lost & found item"); }
});

export default router;
