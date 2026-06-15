import { Queue, Worker, Job, QueueEvents } from "bullmq";
import { ParserService } from "./ParserService";
import { VectorStoreService } from "./VectorStoreService";
import { logger } from "../../shared/Logger";
import { redis } from "../../shared/Redis";
import dotenv from "dotenv";

dotenv.config();

// Helper
// @ts-ignore
import { getAdmin, getDb } from "../../../config/firebase";

export type AITaskType = "DOC_INGESTION" | "BULK_EXTRACTION" | "EMBEDDING_GENERATION" | "OCR_PROCESSING" | "CLEANUP_OLD_DOCS";

export class AIQueueService {
  private static instance: AIQueueService;
  private queue: Queue;
  private connection = redis;
  private queueEvents: QueueEvents;

  private constructor() {
    this.queue = new Queue("ai-production-queue", {
      connection: this.connection,
      defaultJobOptions: {
        attempts: 3,
        backoff: {
          type: "exponential",
          delay: 5000, // 5s, 10s, 20s
        },
        removeOnComplete: true,
        removeOnFail: false,
      },
    });
    this.queueEvents = new QueueEvents("ai-production-queue", { connection: this.connection });
    this.initWorker();
    this.setupListeners();
    this.scheduleCleanup();
  }

  private async scheduleCleanup() {
    // Register repeatable cleanup job (Daily at 2 AM)
    await this.queue.add("CLEANUP_OLD_DOCS", {}, {
      repeat: { pattern: "0 2 * * *" },
      jobId: "cleanup-job" // Fixed ID prevents multiple instances
    });
    logger.info("AI Cleanup Job Scheduled (Daily 2 AM)");
  }

  public static getInstance(): AIQueueService {
    if (!AIQueueService.instance) {
      AIQueueService.instance = new AIQueueService();
    }
    return AIQueueService.instance;
  }

  /**
   * Helper to synchronize BullMQ state with Firestore for real-time UI.
   */
  private async updateJobStatus(jobId: string, data: {
    status?: "uploading" | "processing" | "indexed" | "failed";
    progress?: number;
    error?: string;
    society_id?: string;
    file_name?: string;
    document_type?: string;
  }) {
    try {
      const db = getDb();
      const jobRef = db.collection("ai_jobs").doc(jobId);
      await jobRef.set({
        ...data,
        updated_at: getAdmin().firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    } catch (err: any) {
      logger.warn({ jobId, error: err.message }, "Failed to update AI Job status in Firestore");
    }
  }

  /**
   * Universal method to add AI jobs with priority support.
   */
  public async addJob(taskType: AITaskType, data: any, priority: number = 10) {
    const requestId = `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const job = await this.queue.add(taskType, { ...data, requestId }, { priority });
    
    // V3.10: Initialize Real-Time Tracking
    if (job.id) {
       await this.updateJobStatus(job.id, {
         status: "uploading",
         progress: 0,
         file_name: data.fileName || "unknown",
         document_type: data.documentType || "general",
         society_id: data.society_id,
       });
    }

    logger.info({
      requestId,
      taskType,
      societyId: data.society_id,
      userId: data.user_id,
    }, "AI Job Queued Successfully");
  }

  private setupListeners() {
    this.queueEvents.on("failed", async ({ jobId, failedReason }) => {
      logger.error({ jobId, error: failedReason }, "AI Job Failed permanently (Moved to DLQ)");
      await this.updateJobStatus(jobId, { status: "failed", error: failedReason });
    });
  }

  /**
   * Orchestrated Worker: Handles multiple task types with strict multi-tenancy.
   */
  private initWorker() {
    new Worker("ai-production-queue", async (job: Job) => {
      const { taskType, requestId, society_id, userId } = job.data;
      const context = { requestId, societyId: society_id, userId };
      
      const startTime = Date.now();
      logger.info({ ...context, taskType: job.name }, "AI Worker: Processing started");

      // V3.10: Start Processing
      await this.updateJobStatus(job.id!, { status: "processing", progress: 10 });

      try {
        switch (job.name as AITaskType) {
          case "DOC_INGESTION":
            await this.handleIngestion(job, context);
            break;
          case "OCR_PROCESSING":
            // ✅ BUG-14 FIX: Throw instead of silently succeeding as a no-op
            throw new Error("OCR_PROCESSING is not yet implemented as a standalone task. Use DOC_INGESTION which includes OCR fallback.");
          case "BULK_EXTRACTION":
            // ✅ BUG-14 FIX: Throw instead of silently succeeding as a no-op
            throw new Error("BULK_EXTRACTION is not yet implemented. This task type is reserved for Phase 5.");
          case "CLEANUP_OLD_DOCS":
            await this.handleCleanup();
            break;
          default:
            logger.warn({ ...context, taskType: job.name }, "AI Worker: Unknown task type received");
        }

        logger.info({
          ...context,
          taskType: job.name,
          latency_ms: Date.now() - startTime,
          status: "completed"
        }, "AI Worker: Job completed successfully");

        // V3.10: Complete
        await this.updateJobStatus(job.id!, { status: "indexed", progress: 100 });

      } catch (error: any) {
        logger.error({
          ...context,
          taskType: job.name,
          error: error.message,
          status: "failed"
        }, "AI Worker: Job processing failed");

        await this.updateJobStatus(job.id!, { status: "failed", error: error.message });
        throw error; // Trigger BullMQ retry
      }
    }, { 
      connection: this.connection,
      concurrency: 5 // Specified in OCR Optimization for V3.2
    });
  }

  private async handleIngestion(job: Job, context: { requestId: string }) {
    const { filePath, society_id } = job.data;
    const parser = ParserService.getInstance();
    const vectorStore = VectorStoreService.getInstance();

    // 1. Process & Chunk (includes OCR fallbacks & Heading-aware splitting)
    // V3.10: Pass progress callback to Parser
    const docs = await parser.processFile(filePath, society_id, { ...context, documentType: job.data.documentType }, (p) => {
       this.updateJobStatus(job.id!, { progress: 10 + (p * 0.75) }); // Map 0-100 to 10-85 range
    });

    // 2. Build Vector Store
    // V3.10: Final 15% is Vector indexing
    await this.updateJobStatus(job.id!, { progress: 85 });
    const store = await vectorStore.getVectorStore();
    await store.addDocuments(docs);
    await this.updateJobStatus(job.id!, { progress: 95 });

    // 3. Mark as Indexed in Storage Metadata (Phase 6 requirement)
    try {
      const bucket = getAdmin().storage().bucket();
      // Extract path from URL (Assuming Firebase Storage URL)
      const path = decodeURIComponent(filePath.split("/o/")[1].split("?")[0]);
      await bucket.file(path).setMetadata({
        metadata: {
          indexedAt: new Date().toISOString(),
          documentType: job.data.documentType || "general"
        }
      });
      logger.info({ ...context, filePath }, "Document marked as indexed in storage");
    } catch (err: any) {
      logger.warn({ ...context, error: err.message }, "Failed to mark document as indexed in metadata");
    }
  }

  private async handleCleanup() {
    const startTime = Date.now();
    logger.info("Starting Data Retention Cleanup Job");

    try {
      const bucket = getAdmin().storage().bucket();
      const [files] = await bucket.getFiles();
      let deletedCount = 0;
      let skippedCount = 0;

      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      for (const file of files) {
        const metadata = file.metadata;
        const createdDate = new Date(metadata.timeCreated);

        if (createdDate < thirtyDaysAgo) {
          // Safety Check: Only delete if indexed_at exists in metadata
          const indexedAt = metadata.metadata?.indexedAt;
          
          if (indexedAt) {
            await file.delete();
            deletedCount++;
          } else {
            skippedCount++;
            logger.warn({ fileName: file.name }, "Cleanup: Skipping unindexed file older than 30 days");
          }
        }
      }

      logger.info({
        deletedCount,
        skippedCount,
        duration_ms: Date.now() - startTime
      }, "Data Retention Cleanup Job Completed");

    } catch (error: any) {
      logger.error({ error: error.message }, "Data Retention Cleanup Job Failed");
      throw error;
    }
  }
}

