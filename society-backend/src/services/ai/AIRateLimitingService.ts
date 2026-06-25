import { redis } from "../../shared/Redis";
import { logger } from "../../shared/Logger";

export class AIRateLimitingService {
  private static instance: AIRateLimitingService;
  private redis = redis;

  private constructor() {}

  public static getInstance(): AIRateLimitingService {
    if (!AIRateLimitingService.instance) {
      AIRateLimitingService.instance = new AIRateLimitingService();
    }
    return AIRateLimitingService.instance;
  }

  /**
   * Sliding window rate limiting per user and per society.
   * Default: 100 requests / hour / user, 1000 / hour / society.
   */
  public async checkLimit(
    userId: string, 
    societyId: string, 
    options: { requestId: string }
  ): Promise<boolean> {
    const userLimit = 100;
    const societyLimit = 1000;
    const windowSeconds = 3600; // 1 hour

    const userKey = `rate:limit:user:${userId}`;
    const societyKey = `rate:limit:society:${societyId}`;

    // 1. User Level check
    const userRequests = await this.redis.zcard(userKey);
    if (userRequests >= userLimit) {
      logger.warn({ ...options, userId }, "AI Rate Limit: User Threshold Reached");
      return false;
    }

    // 2. Society Level check
    const societyRequests = await this.redis.zcard(societyKey);
    if (societyRequests >= societyLimit) {
      logger.warn({ ...options, societyId }, "AI Rate Limit: Society Threshold Reached");
      return false;
    }

    // 3. Update sliding window
    const now = Date.now();
    const expiry = now - windowSeconds * 1000;

    await this.redis.multi()
      .zremrangebyscore(userKey, 0, expiry)
      .zadd(userKey, now, now.toString())
      .expire(userKey, windowSeconds)
      .zremrangebyscore(societyKey, 0, expiry)
      .zadd(societyKey, now, now.toString())
      .expire(societyKey, windowSeconds)
      .exec();

    return true;
  }
}
