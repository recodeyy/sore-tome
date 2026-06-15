// @ts-ignore
import { getDb, getAdmin } from "../../config/firebase";
import { db } from "../shared/Database";
import { redis } from "../shared/Redis";
import { logger } from "../shared/Logger";

export class DashboardService {
  private static instance: DashboardService;
  private pool = db;
  private redis = redis;

  private constructor() {}

  public static getInstance(): DashboardService {
    if (!DashboardService.instance) {
      DashboardService.instance = new DashboardService();
    }
    return DashboardService.instance;
  }

  public async getDashboardStats(societyId: string) {
    if (!societyId) {
      throw new Error("Tenant context (societyId) required for dashboard stats");
    }

    const cacheKey = `admin:dashboard:${societyId}`;
    
    // Attempt cache fetch
    try {
      const cached = await this.redis.get(cacheKey);
      if (cached) return JSON.parse(cached);
    } catch (e) {
      logger.warn("Redis unreachable, fetching from source.");
    }

    const db = getDb();

    // 1. Fetch Pending Approvals Count (Filtered by societyId)
    const pendingSnap = await db.collection("users")
      .where("society_id", "==", societyId)
      .where("status", "==", "pending")
      .get();
    const pendingApprovalsCount = pendingSnap.size;

    // 2. Fetch Top Issues (Sorted by Priority, Filtered by societyId)
    const issuesSnap = await db.collection("issues")
      .where("society_id", "==", societyId)
      .where("status", "==", "open")
      .orderBy("priority", "desc") // Relies on Composite Index: (society_id + status + priority)
      .limit(3)
      .get();
    
    const topIssues = issuesSnap.docs.map((doc: any) => ({ 
      id: doc.id, 
      ...doc.data() 
    }));

    // 3. Recent Updates (Filtered by societyId)
    const noticesSnap = await db.collection("notices")
      .where("society_id", "==", societyId)
      .orderBy("createdAt", "desc")
      .limit(3)
      .get();
    
    const eventsSnap = await db.collection("events")
      .where("society_id", "==", societyId)
      .orderBy("createdAt", "desc")
      .limit(3)
      .get();

    const recentUpdates = [
      ...noticesSnap.docs.map((d: any) => ({ type: 'notice', id: d.id, ...d.data() })),
      ...eventsSnap.docs.map((d: any) => ({ type: 'event', id: d.id, ...d.data() }))
    ].sort((a: any, b: any) => {
        const timeA = a.createdAt?.toDate()?.getTime() || 0;
        const timeB = b.createdAt?.toDate()?.getTime() || 0;
        return timeB - timeA;
    }).slice(0, 4);

    // 4. Financial Summary (Filtered by societyId)
    const transSnap = await db.collection("transactions")
      .where("society_id", "==", societyId)
      .get();
    let totalCollected = 0;
    let totalSpent = 0;
    transSnap.forEach((doc: any) => {
      const d = doc.data();
      if (d.type === "credit") totalCollected += d.amount;
      if (d.type === "debit") totalSpent += d.amount;
    });

    // 5. Society Settings (Society-Specific ID)
    const settingsSnap = await db.collection("society_settings").doc(societyId).get();
    const settings = settingsSnap.exists ? settingsSnap.data() : { target: 200000, currency: "Rs" };
    const target = settings.target > 0 ? settings.target : 1; 

    // 6. Active Residents (Filtered by societyId)
    const activeResidentsSnap = await db.collection("users")
      .where("society_id", "==", societyId)
      .where("status", "==", "approved")
      .get();
    const activeResidentsCount = activeResidentsSnap.size;

    const stats = {
      pendingApprovalsCount,
      topIssues,
      recentUpdates,
      financials: {
        totalCollected,
        totalSpent,
        balance: totalCollected - totalSpent,
        target: settings.target,
        currency: settings.currency,
        percentage: Math.min(100, Math.round((totalCollected / target) * 100))
      },
      activeResidentsCount,
      updatedAt: new Date().toISOString()
    };

    await this.redis.setex(cacheKey, 300, JSON.stringify(stats)); 
    return stats;
  }

}
