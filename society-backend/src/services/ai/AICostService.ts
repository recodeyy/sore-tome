import { db } from "../../shared/Database";
import { redis } from "../../shared/Redis";
import { logger } from "../../shared/Logger";

export class AICostService {
  private static instance: AICostService;
  private pool = db;
  private redis = redis;

  private constructor() {}

  public static getInstance(): AICostService {
    if (!AICostService.instance) {
      AICostService.instance = new AICostService();
    }
    return AICostService.instance;
  }

  /**
   * Tracks cost at both user, society, and audit levels.
   */
  public async trackCost(data: {
    userId: string;
    societyId: string;
    requestId: string;
    tokens: number;
    cost: number;
  }) {
    // 1. Audit Log (PostgreSQL)
    const sql = `
      INSERT INTO ai_costs (user_id, society_id, request_id, tokens, cost_usd)
      VALUES ($1, $2, $3, $4, $5)
    `;
    
    try {
      await this.pool.query(sql, [data.userId, data.societyId, data.requestId, data.tokens, data.cost]);

      // 2. Rolling Usage (Redis - 30 day window)
      const societyKey = `cost:society:${data.societyId}:month`;
      const userKey = `cost:user:${data.userId}:month`;

      await this.redis.incrbyfloat(societyKey, data.cost);
      await this.redis.incrbyfloat(userKey, data.cost);
      await this.redis.expire(societyKey, 3600 * 24 * 30);
      await this.redis.expire(userKey, 3600 * 24 * 30);

      logger.info({ 
        requestId: data.requestId, 
        cost: data.cost, 
        societyId: data.societyId 
      }, "AI Cost Tracked Successfully");

    } catch (err: any) {
      logger.error({ requestId: data.requestId, error: err.message }, "AI Cost Tracking Failed");
    }
  }

  public async getSocietyMonthlyCost(societyId: string): Promise<number> {
    if (!societyId) return 0;

    const key = `cost:society:${societyId}:month`;
    const lockKey = `lock:rebuild:cost:${societyId}`;
    
    // 1. Primary path: Redis
    const cached = await this.redis.get(key);
    if (cached !== null) return parseFloat(cached);

    // 2. Cache Miss: Attempt rebuild from PostgreSQL with Distributed Lock
    const lockAcquired = await this.redis.set(lockKey, "true", "EX", 30, "NX");
    
    if (!lockAcquired) {
      // Someone else is already rebuilding. Wait briefly and retry once or return 0.
      await new Promise(resolve => setTimeout(resolve, 1000));
      const retryCached = await this.redis.get(key);
      return retryCached ? parseFloat(retryCached) : 0;
    }

    // Lock Acquired: Start Rebuild
    let lockExtensionInterval: NodeJS.Timeout | null = null;
    try {
      // 2.1 Lock Auto-Extension (Every 10s during rebuild)
      lockExtensionInterval = setInterval(async () => {
        await this.redis.expire(lockKey, 30);
      }, 10000);

      // 2.2 Rebuild from PostgreSQL
      logger.info({ societyId }, "Rebuilding AI cost cache from PostgreSQL source");
      const sql = `
        SELECT COALESCE(SUM(cost_usd), 0) as total 
        FROM ai_costs 
        WHERE society_id = $1 
        AND created_at >= NOW() - INTERVAL '30 days'
      `;
      const result = await this.pool.query(sql, [societyId]);
      const total = parseFloat(result.rows[0].total);

      // 2.3 Repopulate Redis (30 day TTL)
      await this.redis.set(key, total, "EX", 3600 * 24 * 30);
      
      return total;
    } catch (err: any) {
      logger.error({ societyId, error: err.message }, "Failed to rebuild AI cost cache");
      return 0;
    } finally {
      if (lockExtensionInterval) clearInterval(lockExtensionInterval);
      await this.redis.del(lockKey);
    }
  }

}
