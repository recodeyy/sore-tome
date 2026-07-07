const { getAdmin, getDb } = require("../config/firebase");
const { logger } = require("../src/shared/Logger");
const { db: pg } = require("../src/shared/Database");

/**
 * FCM error codes that mean a token is permanently dead and must be pruned.
 * (messaging/registration-token-not-registered → app uninstalled / token rotated;
 *  messaging/invalid-argument or invalid-registration-token → malformed token.)
 */
const DEAD_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
  "messaging/invalid-argument",
]);

/** FCM `data` payloads must be flat string:string maps. */
function stringifyData(data = {}) {
  const out = {};
  for (const [k, v] of Object.entries(data)) {
    if (v === undefined || v === null) continue;
    out[k] = typeof v === "string" ? v : JSON.stringify(v);
  }
  // Canonical deep-link key for the app's router: data.deeplink = "/route/..."
  if (!out.deeplink && out.deepLink) out.deeplink = out.deepLink;
  return out;
}

class NotificationService {
  /**
   * Send a notification to ALL of a user's registered devices (Postgres
   * device_tokens), falling back to the legacy Firestore `fcmToken` field for
   * users on old app builds. Dead tokens are pruned on send failure.
   * @param {string} userId - The UID of the user
   * @param {Object} notification - { title, body, data }
   */
  static async sendToUser(userId, { title, body, data = {} }) {
    try {
      // 1. Collect all active device tokens from Postgres (multi-device).
      let tokens = [];
      try {
        const res = await pg.query(
          `SELECT token FROM device_tokens WHERE user_id = $1 AND is_active = true`,
          [userId]
        );
        tokens = res.rows.map((r) => r.token);
      } catch (e) {
        logger.warn({ userId, error: e.message }, "device_tokens lookup failed; falling back to Firestore");
      }

      // 2. Backward compat: Firestore fcmToken (written by legacy PATCH /users/me).
      if (tokens.length === 0) {
        const db = getDb();
        const userDoc = await db.collection("users").doc(userId).get();
        if (userDoc.exists && userDoc.data().fcmToken) tokens = [userDoc.data().fcmToken];
      }

      if (tokens.length === 0) {
        logger.info({ userId }, "User has no FCM token, skipping push notification");
        return;
      }

      const messaging = getAdmin().messaging();
      const payload = { notification: { title, body }, data: stringifyData(data) };

      const deadTokens = [];
      const send = messaging.sendEachForMulticast
        ? messaging.sendEachForMulticast.bind(messaging)
        : messaging.sendMulticast.bind(messaging);
      const result = await send({ ...payload, tokens });
      result.responses.forEach((r, i) => {
        if (!r.success && r.error && DEAD_TOKEN_CODES.has(r.error.code)) {
          deadTokens.push(tokens[i]);
        }
      });

      // 3. Prune dead tokens so they are never retried.
      if (deadTokens.length > 0) {
        try {
          await pg.query(`DELETE FROM device_tokens WHERE token = ANY($1)`, [deadTokens]);
        } catch (e) {
          logger.warn({ userId, error: e.message }, "Failed to prune dead device tokens");
        }
        logger.info({ userId, pruned: deadTokens.length }, "Pruned dead FCM tokens");
      }

      logger.info(
        { userId, title, devices: tokens.length, sent: result.successCount, failed: result.failureCount },
        "Push notification sent to user"
      );
    } catch (err) {
      logger.error({ userId, error: err.message }, "Error sending push notification to user");
    }
  }

  /**
   * Send a notification to all admins in a society
   * @param {string} societyId
   * @param {Object} notification
   */
  static async sendToAdmins(societyId, { title, body, data = {} }) {
    try {
      const db = getDb();
      const adminsSnap = await db.collection("users")
        .where("society_id", "==", societyId)
        .where("role", "in", ["admin", "main_admin", "secretary", "treasurer"])
        .get();

      const userIds = adminsSnap.docs.map((doc) => doc.id);
      for (const uid of userIds) {
        await NotificationService.sendToUser(uid, { title, body, data });
      }
      logger.info({ societyId, count: userIds.length }, "Push notification fan-out to admins");
    } catch (err) {
      logger.error({ societyId, error: err.message }, "Error sending push notification to admins");
    }
  }

  /**
   * Send a notification to all users in a society topic
   * @param {string} societyId
   * @param {Object} notification
   */
  static async sendToSociety(societyId, { title, body, data = {} }) {
    try {
      const message = {
        notification: { title, body },
        data: stringifyData(data),
        topic: `society_${societyId}`,
      };

      await getAdmin().messaging().send(message);
      logger.info({ societyId, title }, "Push notification sent to society topic");
    } catch (err) {
      logger.error({ societyId, error: err.message }, "Error sending push notification to society topic");
    }
  }
}

module.exports = NotificationService;
