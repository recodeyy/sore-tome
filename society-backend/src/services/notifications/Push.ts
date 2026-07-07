import { logger } from "../../shared/Logger";

/**
 * FCM push bridge (MR-001 / §10 notification triggers).
 *
 * The Postgres services insert per-user `notifications` rows inside their
 * transactions (see Recipients.fanOut). This helper schedules the actual FCM
 * push for those recipients AFTER the current tick (so it never runs inside —
 * or blocks — the DB transaction), delegating to the legacy
 * services/notificationService.sendToUser which reads ALL of the user's
 * device_tokens and prunes invalid ones.
 *
 * Best-effort by design: a failed push must never fail the domain operation.
 * Skipped entirely under Jest so integration tests stay hermetic.
 */
export interface PushPayload {
  title: string;
  body?: string;
  data?: Record<string, unknown>;
}

export function queuePush(userIds: string[] | string, payload: PushPayload): void {
  if (process.env.JEST_WORKER_ID || process.env.NODE_ENV === "test") return;
  const ids = Array.from(new Set((Array.isArray(userIds) ? userIds : [userIds]).filter(Boolean)));
  if (ids.length === 0) return;

  setImmediate(async () => {
    try {
      // Lazy require: keeps Firebase out of module-load paths (tests, workers).
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const NotificationService = require("../../../services/notificationService");
      for (const uid of ids) {
        await NotificationService.sendToUser(uid, {
          title: payload.title,
          body: payload.body || "",
          data: payload.data || {},
        });
      }
    } catch (err: any) {
      logger.warn({ error: err.message }, "queuePush: FCM push failed (non-fatal)");
    }
  });
}
