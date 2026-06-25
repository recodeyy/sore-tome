const { getAdmin, getDb } = require("../config/firebase");
const { logger } = require("../src/shared/Logger");

class NotificationService {
  /**
   * Send a notification to a specific user
   * @param {string} userId - The UID of the user
   * @param {Object} notification - { title, body, data }
   */
  static async sendToUser(userId, { title, body, data = {} }) {
    try {
      const db = getDb();
      const userDoc = await db.collection("users").doc(userId).get();
      
      if (!userDoc.exists) return;
      
      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        logger.info({ userId }, "User has no FCM token, skipping push notification");
        return;
      }

      const message = {
        notification: { title, body },
        data,
        token: fcmToken,
      };

      await getAdmin().messaging().send(message);
      logger.info({ userId, title }, "Push notification sent to user");
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

      const tokens = adminsSnap.docs
        .map(doc => doc.data().fcmToken)
        .filter(token => !!token);

      if (tokens.length === 0) return;

      const message = {
        notification: { title, body },
        data,
        tokens,
      };

      await getAdmin().messaging().sendMulticast(message);
      logger.info({ societyId, count: tokens.length }, "Push notification sent to admins");
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
        data,
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
