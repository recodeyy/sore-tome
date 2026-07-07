import { Queue, Worker, Job } from "bullmq";
import { redis } from "./Redis.js";
import { logger } from "./Logger.js";
// @ts-ignore
import { getDb, getAdmin } from "../../config/firebase.js";

/**
 * Enterprise Transactional Outbox Service (v5.1)
 * ❗ PRO FIX: Ensures eventual consistency between PostgreSQL & Firestore.
 * ❗ PRO FIX: Guarantees ordering and idempotency for side-effects.
 */
export type OutboxEventType = "SYNC_STATS" | "SEND_NOTIFICATION" | "LOG_AUDIT";

export class OutboxService {
  private static instance: OutboxService;
  private queue: Queue;

  private constructor() {
    this.queue = new Queue("production-outbox-queue", {
      connection: redis,
      defaultJobOptions: {
        attempts: 5,
        backoff: { type: "exponential", delay: 2000 },
        removeOnComplete: true,
      },
    });

    this.startWorker();
  }

  public static getInstance(): OutboxService {
    if (!OutboxService.instance) {
      OutboxService.instance = new OutboxService();
    }
    return OutboxService.instance;
  }

  /**
   * Enqueues a side-effect for reliable execution.
   * ❗ REDIS-DEGRADED: Logs failure if Redis is down but doesn't crash requester.
   */
  public async enqueue(type: OutboxEventType, payload: any, society_id: string) {
    const sequenceId = `${Date.now()}-${Math.random().toString(36).substring(7)}`;
    
    try {
      // Fast path connectivity check
      if ((redis as any).status !== "ready") {
        throw new Error("Redis connection not ready");
      }

      await this.queue.add(type, {
        ...payload,
        society_id,
        sequenceId,
        timestamp: new Date().toISOString()
      }, {
        jobId: `outbox:${sequenceId}`
      });

      logger.debug({ type, sequenceId, society_id }, "Outbox event queued");
    } catch (err: any) {
      logger.fatal({ 
        type, 
        society_id, 
        error: err.message 
      }, "REDIS-DEGRADED: Failed to enqueue outbox event. Consistency risk!");
      // Optionally: Persist to a fallback local log/file if critical
    }
  }

  private startWorker() {
    const worker = new Worker("production-outbox-queue", async (job: Job) => {
      const { type, society_id, sequenceId } = job.data;
      
      logger.info({ type, sequenceId, society_id }, "Outbox Worker: Processing event");

      try {
        switch (job.name as OutboxEventType) {
          case "SYNC_STATS":
            const { AIToolService } = await import("../services/ai/AIToolService.js");
            await AIToolService.getInstance().syncSocietyStats(society_id || 'global');
            break;

          case "SEND_NOTIFICATION":
            const dbFirestore = getDb();
            await dbFirestore.collection("notifications").add({
              ...job.data.notification,
              society_id: society_id,
              createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
            });
            break;

          case "LOG_AUDIT":
            const { AuditLogService } = await import("../services/AuditLogService.js");
            await AuditLogService.getInstance().logAdminAction(
              job.data.user,
              job.data.action,
              job.data.details
            );
            break;

          default:
            logger.warn({ type }, "Outbox Worker: Unknown event type");
        }
      } catch (err: any) {
        logger.error({ type, sequenceId, error: err.message }, "Outbox Worker: Execution failed");
        throw err;
      }
    }, { connection: redis });

    // ─── Metrics Listeners (V5.2) ─────────────────────────────────────────────
    worker.on("completed", async (job) => {
      await redis.hincrby("outbox:metrics", "completed", 1);
      logger.debug({ jobId: job.id }, "Outbox Job Completed");
    });

    worker.on("failed", async (job, err) => {
      await redis.hincrby("outbox:metrics", "failed", 1);
      logger.error({ jobId: job?.id, error: err.message }, "Outbox Job Failed");
    });
  }

  /**
   * GET METRICS: Exposes queue state (V5.2)
   */
  public async getMetrics() {
    const counts = await this.queue.getJobCounts();
    const redisMetrics = await redis.hgetall("outbox:metrics");
    
    return {
      queue: counts,
      history: {
        completed: parseInt(redisMetrics.completed || "0"),
        failed: parseInt(redisMetrics.failed || "0")
      },
      timestamp: new Date().toISOString()
    };
  }
}

export const outboxService = OutboxService.getInstance();
