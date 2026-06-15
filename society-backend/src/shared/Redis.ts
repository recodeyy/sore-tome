import IORedis from "ioredis";
import { logger } from "./Logger";

class RedisClient {
  private static instance: RedisClient;
  private client: IORedis;
  private isConnected: boolean = false;

  private constructor() {
    const redisUrl = process.env.REDIS_URL || "redis://localhost:6379";
    
    this.client = new IORedis(redisUrl, {
      maxRetriesPerRequest: null,
      retryStrategy: (times: number) => Math.min(times * 100, 3000),
      keepAlive: 10000,
      tls: redisUrl.startsWith("rediss://") ? {} : undefined,
    });

    this.client.on("error", (err) => {
      if (this.isConnected) {
        logger.warn({ error: err.message }, "Redis connection unreachable - caching disabled");
        this.isConnected = false;
      }
    });

    this.client.on("connect", () => {
      if (!this.isConnected) {
        logger.info("✅ Redis connected (Singleton)");
        this.isConnected = true;
      }
    });
  }

  public static getInstance(): RedisClient {
    if (!RedisClient.instance) {
      RedisClient.instance = new RedisClient();
    }
    return RedisClient.instance;
  }

  public getClient(): IORedis {
    return this.client;
  }

  public async close() {
    await this.client.quit();
    logger.info("Redis connection closed");
  }
}

export const redis = RedisClient.getInstance().getClient();
export const redisManager = RedisClient.getInstance();
