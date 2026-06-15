import { z } from "zod";
// @ts-ignore
import { getDb, getAdmin } from "../../../config/firebase.js";
import { VectorStoreService } from "./VectorStoreService.js";
import { logger } from "../../shared/Logger.js";
import { db } from "../../shared/Database.js";
import { redis } from "../../shared/Redis.js";
import { lockService } from "../../shared/LockService.js";
import { outboxService } from "../../shared/OutboxService.js";
import crypto from "crypto";

// Tool Definitions & Schemas
const NoticeSchema = z.object({
  title: z.string().min(5),
  body: z.string().min(10),
  type: z.enum(["general", "event", "maintenance", "festival"]).default("general"),
});

const ExpenseSchema = z.object({
  vendor: z.string(),
  amount: z.number().positive(),
  category: z.string(),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  note: z.string().optional(),
});

const ComplaintSchema = z.object({
  title: z.string().min(5),
  description: z.string().min(10),
  location: z.string().optional(),
  priority: z.enum(["low", "medium", "high"]).default("medium"),
});

export type ToolAction = "create_notice" | "log_expense" | "create_complaint";

// ... (NoticeSchema, ExpenseSchema, ComplaintSchema remain same)

export class AIToolService {
  private static instance: AIToolService;
  private pool = db;
  private redis = redis;
  private isPostgresAvailable: boolean = true;
  private isRedisAvailable: boolean = true;

  private constructor() {}

  public static getInstance(): AIToolService {
    if (!AIToolService.instance) {
      AIToolService.instance = new AIToolService();
    }
    return AIToolService.instance;
  }

  /**
   * ❗ PRO FIX: Global Multi-Tenant Assertion
   */
  private assertSocietyMatch(resourceSocietyId: string, userSocietyId: string) {
    if (resourceSocietyId !== userSocietyId) {
      logger.fatal({ resourceSocietyId, userSocietyId }, "SEC-CRITICAL: Cross-tenant access attempted!");
      throw new Error("Access Denied: Resource belongs to a different society.");
    }
  }

  public async proposeAction(userId: string, societyId: string, tool: ToolAction, params: any) {
    const actionId = crypto.randomUUID();
    const id = crypto.randomUUID(); // V5.1: UUID for Partitioned Table
    const createdAt = new Date();
    const expiresAt = new Date(createdAt.getTime() + 10 * 60000);
    
    // 1. Write to Legacy Table (Primary)
    const sqlLegacy = `
      INSERT INTO ai_audit_logs (action_id, tool_id, user_id, society_id, action, params, status, created_at, expires_at)
      VALUES ($1, $2, $3, $4, $5, $6, 'Proposed', $7, $8)
    `;
    
    await this.pool.query(sqlLegacy, [
      actionId, tool, userId, societyId, tool, JSON.stringify(params), createdAt, expiresAt
    ]);

    // 2. Dual Write: Partitioned Table (Experimental/New)
    try {
      const sqlPartitioned = `
        INSERT INTO ai_audit_logs_partitioned (id, action_id, tool_id, user_id, society_id, action, params, status, created_at, expires_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, 'Proposed', $8, $9)
      `;
      await this.pool.query(sqlPartitioned, [
        id, actionId, tool, userId, societyId, tool, JSON.stringify(params), createdAt, expiresAt
      ]);
    } catch (err: any) {
      logger.error({ actionId, error: err.message }, "DUAL-WRITE-FAIL: Partitioned log insert failed");
    }
    
    logger.info({ actionId, tool, userId, societyId }, "AI Action Proposed");
    return { actionId, tool, params, expires_at: expiresAt };
  }

  /**
   * EXECUTE: User has confirmed.
   * ❗ PRO FIX: Redlock distributed lock to prevent double-execution.
   * ❗ PRO FIX: Strict society_id enforcement.
   */
  public async executeAction(actionId: string, userId: string, societyId: string, role: string) {
    return await lockService.runWithLock(`ai:execute:${actionId}`, 30000, async () => {
      // 1. Fetch from Audit (Ensuring exact society match)
      const fetchSql = `SELECT * FROM ai_audit_logs WHERE action_id = $1 AND status = 'Proposed'`;
      const res = await this.pool.query(fetchSql, [actionId]);
      
      if (res.rows.length === 0) {
        throw new Error("Action not found, already executed, or expired.");
      }

      const task = res.rows[0];
      
      // ❗ SEC FIX: Multi-tenant Assertion
      this.assertSocietyMatch(task.society_id, societyId);
      
      // 2. RBAC Check
      this.checkPermissions(task.tool_id, role);

      // 3. Update status to Processing
      await this.updateStatus(actionId, "Processing");

      try {
        let result;
        // 4. Dispatch Tool
        switch (task.tool_id) {
          case "create_notice":
            const noticeData = NoticeSchema.parse(task.params);
            result = await this.createNotice(noticeData, userId, societyId);
            break;
          case "log_expense":
            const expenseData = ExpenseSchema.parse(task.params);
            result = await this.logExpense(expenseData, userId, societyId);
            break;
          case "create_complaint":
            const complaintData = ComplaintSchema.parse(task.params);
            const isDuplicate = await this.recentSimilarIssueExists(societyId, complaintData.title, complaintData.location);
            if (isDuplicate) {
              throw new Error("A similar issue was already reported in this society within the last 24 hours.");
            }
            result = await this.createComplaint(complaintData, userId, societyId);
            break;
          default:
            throw new Error(`Tool ${task.tool_id} not implemented`);
        }

        // 5. Mark Completed
        await this.updateStatus(actionId, "Completed");
        return result;
      } catch (error: any) {
        await this.updateStatus(actionId, "Failed", error.message);
        throw error;
      }
    });
  }


  /**
   * AI V3.10: Society Analytics (Enterprise O(1) Pattern)
   * ❗ PRO FIX: Reads from precomputed aggregate doc instead of scanning collections.
   */
  public async getSocietyStats(societyId: string) {
    // ✅ BUG-16 FIX: Removed self-assertion (assertSocietyMatch(societyId, societyId) always passes)
    // Callers already go through tenantMiddleware which enforces society_id on req
    const db = getDb();
    const statsDoc = await db.collection("society_stats").doc(societyId).get();

    if (statsDoc.exists) {
       return statsDoc.data();
    }

    // Fallback: Sync manually if doc doesn't exist (first run)
    return await this.syncSocietyStats(societyId);
  }

  /**
   * ❗ PRO FIX: Manual Refresh & Sync logic (User Requirement #7)
   */
  public async syncSocietyStats(societyId: string) {
    const db = getDb();
    
    // 1. Complaint Stats (Firestore) - Reduced Scan
    const issues = await db.collection("issues").where("society_id", "==", societyId).get();
    const complaints_count = issues.size;
    const open_complaints = issues.docs.filter((d: any) => d.data().status === "open").length;

    // 2. Notice Stats (Firestore)
    const notices = await db.collection("notices").where("society_id", "==", societyId).get();
    const notices_count = notices.size;

    // 3. AI Usage Stats (Postgres)
    const auditRes = await this.pool.query(
      `SELECT status, COUNT(*) FROM ai_audit_logs WHERE society_id = $1 GROUP BY status`,
      [societyId]
    );

    const stats = {
      complaints: { total: complaints_count, open: open_complaints },
      notices: { total: notices_count },
      ai_actions: auditRes.rows.reduce((acc: any, row: any) => {
        acc[row.status.toLowerCase()] = parseInt(row.count);
        return acc;
      }, {}),
      updatedAt: new Date().toISOString()
    };

    // Save Aggregate Document
    await db.collection("society_stats").doc(societyId).set(stats);
    
    // Clear Redis Cache
    await this.redis.del(`ai:stats:${societyId}`);
    
    return stats;
  }

  /**
   * AI V3.11: Proactive Society Digest Aggregator
   */
  public async getSocietyDigest(societyId: string) {
    // ✅ BUG-16 FIX: Removed self-assertion
    const cacheKey = `ai:digest:${societyId}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const stats = await this.getSocietyStats(targetSocietyId);
    const finance = await this.analyzeExpenses(targetSocietyId);
    
    // Get latest processed AI jobs
    const db = getDb();
    // V3.12: Fetch without orderBy to avoid composite index requirement
    // We fetch a larger batch and sort in-memory
    const jobsSnap = await db.collection("ai_jobs")
      .where("society_id", "==", targetSocietyId)
      .limit(10) 
      .get();

    const sortedJobs = jobsSnap.docs
      .map((d: any) => ({
        id: d.id,
        ...d.data()
      }))
      .sort((a: any, b: any) => {
        const dateA = a.updated_at?.toDate?.() || new Date(a.updated_at);
        const dateB = b.updated_at?.toDate?.() || new Date(b.updated_at);
        return dateB - dateA;
      })
      .slice(0, 3);

    const digest = {
      summary: `You have ${stats.complaints.open} open issues and ${stats.notices.total} active notices.`,
      insights: [
        stats.complaints.open > 5 ? "Issue volume is high. Consider sending a maintenance update." : "Issues are within normal range.",
        finance.totalSpent > 50000 ? `High spending detected this month (₹${finance.totalSpent.toLocaleString()}).` : "Spending is under control.",
        "AI is currently monitoring utility trends for anomalies."
      ],
      activeIndexing: sortedJobs.map((job: any) => ({
        file: job.file_name,
        status: job.status
      })),
      timestamp: new Date().toISOString()
    };

    await this.redis.setex(cacheKey, 300, JSON.stringify(digest)); // 5 min cache (V3.12 Optimized)
    return digest;
  }

  /**
   * AI V3.10: Financial Analysis Tool with Redis caching.
   */
  public async analyzeExpenses(societyId: string) {
    // ✅ BUG-16 FIX: Removed self-assertion
    const cacheKey = `ai:finance:${societyId}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const db = getDb();
    // V4.0: Optimized Indexed Query
    const transSnap = await db.collection("transactions")
      .where("society_id", "==", targetSocietyId)
      .where("type", "==", "debit")
      .get();

    const categoryMap: Record<string, { total: number, count: number }> = {};
    transSnap.docs.forEach((doc: any) => {
      const d = doc.data();
      
      if (!categoryMap[d.category]) {
        categoryMap[d.category] = { total: 0, count: 0 };
      }
      categoryMap[d.category].total += d.amount;
      categoryMap[d.category].count += 1;
    });

    const analysis = {
      categories: Object.entries(categoryMap).map(([name, data]) => ({
        name,
        amount: data.total,
        frequency: data.count
      })).sort((a: any, b: any) => b.amount - a.amount),
      totalSpent: Object.values(categoryMap).reduce((sum, data) => sum + data.total, 0),
      topCategory: Object.keys(categoryMap).length > 0 ? 
        Object.entries(categoryMap).sort((a, b) => b[1].total - a[1].total)[0][0] : "None",
      analyzedAt: new Date().toISOString()
    };

    await this.redis.setex(cacheKey, 600, JSON.stringify(analysis));
    return analysis;
  }

  private checkPermissions(tool: string, role: string) {
    if (tool === "create_notice" && !["admin", "main_admin", "secretary"].includes(role)) {
      throw new Error("Only Secretary or Admin can post notices.");
    }
    if (tool === "log_expense" && !["admin", "main_admin", "treasurer"].includes(role)) {
      throw new Error("Only Treasurer or Admin can log expenses.");
    }
    // Residents are allowed to create complaints
    if (tool === "create_complaint" && !["admin", "main_admin", "secretary", "resident"].includes(role)) {
       throw new Error("Not authorized to report issues.");
    }
  }

  private async recentSimilarIssueExists(societyId: string, title: string, location?: string): Promise<boolean> {
    const db = getDb();
    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    
    // V4.0: High-Frequency Scalable Query (Requires Index)
    const issuesMatch = await db.collection("issues")
      .where("society_id", "==", societyId)
      .where("createdAt", ">", twentyFourHoursAgo)
      .get();

    const recentIssues = issuesMatch.docs.filter((doc: any) => {
      const data = doc.data();
      
      // Check title similarity (exact) for recent issues
      if (data.title === title) return true;
      
      // Check location match for any open issue (handled in query or here)
      if (location && data.location === location && data.status === "open") return true;
      
      return false;
    });

    return recentIssues.length > 0;
  }

  private async updateStatus(actionId: string, status: string, error?: string) {
    // 1. Update Legacy
    const sqlLegacy = `UPDATE ai_audit_logs SET status = $1, error_message = $2 WHERE action_id = $3`;
    await this.pool.query(sqlLegacy, [status, error || null, actionId]);

    // 2. Dual Update (Partitioned)
    try {
      const sqlPartitioned = `UPDATE ai_audit_logs_partitioned SET status = $1, error_message = $2 WHERE action_id = $3`;
      await this.pool.query(sqlPartitioned, [status, error || null, actionId]);
    } catch (err: any) {
      logger.error({ actionId, error: err.message }, "DUAL-WRITE-FAIL: Partitioned status update failed");
    }
  }

  // --- Actual Tool Implementations ---

  private async createNotice(data: z.infer<typeof NoticeSchema>, userId: string, societyId: string) {
    const db = getDb();
    await db.collection("notices").add({
      ...data,
      society_id: societyId,
      postedBy: userId,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    // ❗ PRO FIX: Reliable Async Sync via Outbox
    await outboxService.enqueue("SYNC_STATS", {}, societyId);

    return { message: "Notice posted successfully" };
  }

  private async logExpense(data: z.infer<typeof ExpenseSchema>, userId: string, society_id: string) {
    const db = getDb();
    await db.collection("transactions").add({
      title: data.vendor,
      amount: data.amount,
      type: 'debit',
      category: data.category,
      note: data.note || "",
      society_id: society_id,
      addedBy: userId,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    // ❗ PRO FIX: Reliable Async Sync via Outbox
    await outboxService.enqueue("SYNC_STATS", {}, society_id);

    return { message: "Expense logged successfully" };
  }

  private async createComplaint(data: z.infer<typeof ComplaintSchema>, userId: string, society_id: string) {
    const db = getDb();
    await db.collection("issues").add({
      ...data,
      society_id: society_id,
      postedBy: userId,
      status: "open",
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
      updatedAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    // ❗ PRO FIX: Reliable Async Sync via Outbox
    await outboxService.enqueue("SYNC_STATS", {}, society_id);

    return { message: "Issue reported successfully" };
  }
}
