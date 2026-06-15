import { Queue, Worker } from "bullmq";
import { redis } from "../shared/Redis";
// @ts-ignore
import { getDb, getStorage } from "../../config/firebase";
import { logger } from "../shared/Logger";

export const cleanupQueue = new Queue("cleanup-tasks", { connection: redis });

export const cleanupWorker = new Worker(
  "cleanup-tasks",
  async (job) => {
    const { type, payload } = job.data;
    const db = getDb();
    const storage = getStorage();

    logger.info({ type, payload }, "🚀 Processing async cleanup task");

    try {
      switch (type) {
        case "DELETE_USER_DATA":
          // Cleanup notifications and sessions associated with a deleted user
          const notifSnap = await db.collection("notifications").where("userId", "==", payload.uid).get();
          const batch = db.batch();
          notifSnap.docs.forEach((doc: any) => batch.delete(doc.ref));
          
          await batch.commit();
          logger.info({ uid: payload.uid, count: notifSnap.size }, "Cleaned up user notifications");
          break;

        case "DELETE_ISSUE_MEDIA":
          // Cleanup associated media in Storage if an issue is deleted
          if (payload.mediaUrls && Array.isArray(payload.mediaUrls)) {
            const bucket = storage.bucket();
            for (const url of payload.mediaUrls) {
              try {
                // Extract path from public URL
                const path = url.split("/").slice(-3).join("/"); // Basic parser
                await bucket.file(path).delete();
              } catch (e) {
                logger.warn({ url }, "Failed to delete storage file, might already be gone");
              }
            }
          }
          break;

        default:
          logger.warn({ type }, "Unknown cleanup task type");
      }
    } catch (err: any) {
      logger.error({ type, error: err.message }, "Cleanup task failed");
      throw err;
    }
  },
  { connection: redis }
);
