const { redisManager } = require("../src/shared/Redis");
const { logger } = require("../src/shared/Logger");

/**
 * Distributed, identity-aware rate limiter backed by Redis.
 * Keys by authenticated user when available, otherwise IP — so residents
 * sharing one apartment NAT/Wi-Fi aren't blocked by a single IP quota.
 * Fails open if Redis is unreachable (availability over strictness).
 */
function createRateLimiter({ windowMs, max, prefix, message }) {
  const windowSec = Math.ceil(windowMs / 1000);

  return async function rateLimiter(req, res, next) {
    // LOAD-TEST: bypass rate limiting so the generator isn't throttled.
    if (process.env.LOADTEST_MODE === "true") return next();
    if (!redisManager.isConnected) return next();

    const identity = req.user?.uid ? `u:${req.user.uid}` : `ip:${req.ip || "unknown"}`;
    const key = `rl:${prefix}:${identity}`;
    const redis = redisManager.getClient();

    try {
      const count = await redis.incr(key);
      if (count === 1) await redis.expire(key, windowSec);

      res.setHeader("RateLimit-Limit", max);
      res.setHeader("RateLimit-Remaining", Math.max(0, max - count));

      if (count > max) {
        const ttl = await redis.ttl(key);
        res.setHeader("Retry-After", ttl > 0 ? ttl : windowSec);
        return res.status(429).json(message || { error: "Too many requests, please try again later." });
      }
      next();
    } catch (err) {
      logger.error({ error: err.message }, "RateLimiter error - failing open");
      next();
    }
  };
}

module.exports = { createRateLimiter };
