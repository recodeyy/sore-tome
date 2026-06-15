// @ts-ignore
import Redlock, { Lock } from "redlock";
import { redis } from "./Redis.js";
import { logger } from "./Logger.js";

/**
 * Enterprise Distributed Lock Service (v5.2)
 * - Prevents race conditions across multiple node instances.
 * - ❗ REDIS DEGRADED MODE: Falls back to local memory locking if Redis is down.
 */
class LockService {
  private static instance: LockService;
  private redlock: Redlock;
  private localLocks: Set<string> = new Set();

  private constructor() {
    this.redlock = new Redlock(
      [redis],
      {
        driftFactor: 0.01,
        retryCount: 0,
        retryDelay: 200,
        retryJitter: 200,
        automaticExtensionThreshold: 500,
      }
    );

    this.redlock.on("error", (error: any) => {
      logger.error({ error: error.message }, "Redlock Internal Error");
    });
  }

  public static getInstance(): LockService {
    if (!LockService.instance) {
      LockService.instance = new LockService();
    }
    return LockService.instance;
  }

  /**
   * Executes a task only if a distributed lock can be acquired.
   * ❗ Fallback: Uses local memory locking if Redis is unavailable.
   */
  public async runWithLock<T>(
    resourceId: string,
    ttlMs: number,
    task: () => Promise<T>
  ): Promise<T> {
    const resource = `lock:${resourceId}`;
    let isRedisAvailable = false;

    try {
      // 1. Connectivity Check (Fast Path)
      isRedisAvailable = (redis as any).status === "ready";

      if (isRedisAvailable) {
        const lock = await this.redlock.acquire([resource], ttlMs);
        try {
          return await task();
        } finally {
          await lock.release().catch((e: any) => logger.warn({ error: e.message }, "Lock release failed"));
        }
      }
    } catch (err: any) {
      if (err.name !== "ExecutionError") { // Redlock rejection is expected
        logger.error({ error: err.message }, "Redis connection failed during lock acquisition");
      }
      // If it's a Redis error (not a lock-contested error), fall through to local fallback
      if (err.name === "ExecutionError") throw new Error(`Resource Busy: ${resourceId}`);
    }

    // 2. Local Fallback (Degraded Mode)
    const deploymentMode = process.env.DEPLOYMENT_MODE || "single";
    
    if (deploymentMode !== "single") {
      logger.fatal({ resourceId }, "REDIS-DOWN: Manual fallback disabled in multi-node mode");
      throw new Error(`System Busy: Distributed lock service is currently unavailable.`);
    }

    logger.warn({ resourceId }, "REDIS-DEGRADED: Using local memory lock (Single-Instance Mode)");
    
    if (this.localLocks.has(resource)) {
      throw new Error(`System Busy (Local Lock): ${resourceId}`);
    }

    this.localLocks.add(resource);
    const timeout = setTimeout(() => this.localLocks.delete(resource), ttlMs);

    try {
      return await task();
    } finally {
      clearTimeout(timeout);
      this.localLocks.delete(resource);
    }
  }
}

export const lockService = LockService.getInstance();
