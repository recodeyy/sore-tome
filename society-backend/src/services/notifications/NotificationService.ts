import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx } from "../finance/ledger";

/**
 * Notifications + delivery tracking (Phase 1).
 *
 * Records a notification, fans it out to a user's active registered devices as
 * queued delivery rows, and processes the queue. The actual FCM send is a
 * pluggable stub (`_send`) — this is where a real provider call would go.
 * Tenant-scoped by society_id throughout. Errors carry a `.code`.
 */

function err(message: string, code: string) {
  return Object.assign(new Error(message), { code });
}

export const NotificationService = {
  /** Register (or refresh) a device token. Idempotent on the token. */
  async registerDevice(
    societyId: string | null | undefined,
    userId: string,
    token: string,
    platform: "android" | "ios" | "web" = "android",
    appVersion?: string
  ) {
    const { rows } = await db.query(
      `INSERT INTO device_tokens (society_id, user_id, token, platform, app_version, is_active, last_seen_at)
       VALUES ($1,$2,$3,$4,$5,true, now())
       ON CONFLICT (token) DO UPDATE
         SET user_id = EXCLUDED.user_id,
             society_id = COALESCE(EXCLUDED.society_id, device_tokens.society_id),
             platform = EXCLUDED.platform,
             app_version = COALESCE(EXCLUDED.app_version, device_tokens.app_version),
             is_active = true,
             last_seen_at = now()
       RETURNING *`,
      [societyId || null, userId, token, platform, appVersion || null]
    );
    return rows[0];
  },

  /** Unregister a device token (logout / token rotation). Scoped to the caller. */
  async removeDevice(userId: string, token: string) {
    const { rows } = await db.query(
      `DELETE FROM device_tokens WHERE token = $1 AND user_id = $2 RETURNING id`,
      [token, userId]
    );
    return { removed: rows.length };
  },

  /**
   * Record a notification for a user and queue a delivery per active device.
   * Returns the notification row and the number of deliveries queued.
   */
  async notifyUser(
    societyId: string,
    userId: string,
    input: { title: string; body?: string; type?: string; data?: any }
  ) {
    return withTx(async (client) => {
      const ins = await client.query(
        `INSERT INTO notifications (society_id, user_id, title, body, type, data)
         VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
        [societyId, userId, input.title, input.body || null, input.type || null,
         JSON.stringify(input.data || {})]
      );
      const notification = ins.rows[0];

      const devices = await client.query(
        `SELECT id FROM device_tokens WHERE society_id = $1 AND user_id = $2 AND is_active = true`,
        [societyId, userId]
      );

      for (const d of devices.rows) {
        await client.query(
          `INSERT INTO notification_deliveries (society_id, notification_id, device_token_id, status)
           VALUES ($1,$2,$3,'queued')`,
          [societyId, notification.id, d.id]
        );
      }
      logger.info({ societyId, userId, deliveries: devices.rows.length }, "Notification queued");
      return { notification, deliveries: devices.rows.length };
    });
  },

  /** Update a delivery's status, bump attempts, and record any error. */
  async markDelivery(deliveryId: string, status: "queued" | "sent" | "failed", error?: string) {
    const { rows } = await db.query(
      `UPDATE notification_deliveries
          SET status = $2, attempts = attempts + 1, error = $3, updated_at = now()
        WHERE id = $1 RETURNING *`,
      [deliveryId, status, error || null]
    );
    if (!rows[0]) throw err("Delivery not found", "NOT_FOUND");
    return rows[0];
  },

  /**
   * Pluggable send stub. A real FCM call would replace this body.
   * Returns true on success; throw to simulate a transient failure.
   */
  async _send(_delivery: any): Promise<boolean> {
    return true;
  },

  /**
   * Process queued deliveries. Locks rows FOR UPDATE SKIP LOCKED so concurrent
   * workers don't double-send. Marks each sent or failed. Returns counts.
   */
  async processQueue(limit = 100) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM notification_deliveries
          WHERE status = 'queued'
          ORDER BY created_at ASC
          LIMIT $1
          FOR UPDATE SKIP LOCKED`,
        [limit]
      );

      let sent = 0, failed = 0;
      for (const d of rows) {
        try {
          const ok = await NotificationService._send(d);
          if (!ok) throw err("Send returned false", "SEND_FAILED");
          await client.query(
            `UPDATE notification_deliveries
                SET status = 'sent', attempts = attempts + 1, error = null, updated_at = now()
              WHERE id = $1`,
            [d.id]
          );
          sent++;
        } catch (e: any) {
          await client.query(
            `UPDATE notification_deliveries
                SET status = 'failed', attempts = attempts + 1, error = $2, updated_at = now()
              WHERE id = $1`,
            [d.id, e.message || "send failed"]
          );
          failed++;
        }
      }
      return { sent, failed };
    });
  },

  /** List a user's notifications (most recent first), tenant-scoped. */
  async listForUser(societyId: string, userId: string, limit = 50) {
    const { rows } = await db.query(
      `SELECT * FROM notifications
        WHERE society_id = $1 AND user_id = $2
        ORDER BY created_at DESC
        LIMIT $3`,
      [societyId, userId, Math.min(limit, 200)]
    );
    return rows;
  },
};
