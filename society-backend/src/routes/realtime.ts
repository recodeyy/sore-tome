import { Router, Request, Response } from "express";
import { eventBus, RealtimeEvent } from "../services/realtime/EventBus";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();

const HEARTBEAT_MS = 25000;

// GET /realtime/sse — Server-Sent Events stream, tenant-scoped.
router.get("/sse", authMiddleware, tenantMiddleware, (req: Request, res: Response) => {
  const societyId = (req as any).societyId as string;
  const userId = (req as any).user?.uid as string;

  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");
  res.flushHeaders?.();

  // Initial comment so proxies/clients open the stream immediately.
  res.write(":ok\n\n");

  const send = (event: RealtimeEvent) => {
    res.write(`event: ${event.type}\n`);
    res.write(`data: ${JSON.stringify(event.payload)}\n\n`);
  };

  // Tenant-scoped subscriptions only — never another society's room.
  const unsubSociety = eventBus.subscribe(`society:${societyId}`, send);
  const unsubUser = userId
    ? eventBus.subscribe(`user:${userId}`, send)
    : () => {};

  const heartbeat = setInterval(() => {
    res.write(":hb\n\n");
  }, HEARTBEAT_MS);
  heartbeat.unref?.();

  logger.info({ societyId, userId }, "SSE client connected");

  req.on("close", () => {
    clearInterval(heartbeat);
    unsubSociety();
    unsubUser();
    logger.info({ societyId, userId }, "SSE client disconnected");
  });
});

export default router;
