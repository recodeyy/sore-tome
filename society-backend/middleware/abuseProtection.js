const { redisManager } = require("../src/shared/Redis");
const { logger } = require("../src/shared/Logger");

/**
 * Middleware to track and block abusive IPs based on suspicious activity.
 * Suspect activity includes hitting multiple 404s or consecutive validation failures.
 */
async function abuseProtection(req, res, next) {
  const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";
  
  // 1. Fail-Safe: If Redis is down, we must NOT block valid traffic
  if (!redisManager.isConnected) {
    logger.warn({ ip, path: req.path }, "AbuseProtection: Redis down, skipping check (Fail-Safe)");
    return next();
  }

  // 2. Whitelist Check
  const whitelist = (process.env.ABUSE_WHITELIST || "").split(",").map(i => i.trim());
  if (whitelist.includes(ip)) {
    return next();
  }

  const redis = redisManager.getClient();
  const blockKey = `block:ip:${ip}`;
  
  try {
    // 3. Check if already blocked
    const isBlocked = await redis.get(blockKey);
    if (isBlocked) {
      logger.alert({ ip, path: req.path }, "SEC-ALERT: Blocked IP attempted access");
      return res.status(403).json({ 
        error: "Access denied due to suspicious activity",
        code: "IP_BLOCKED",
        requestId: req.requestId
      });
    }

    // Capture response to track results
    const originalJson = res.json;
    res.json = function(data) {
      // Increase abuse score on 400 or 404 errors
      if (res.statusCode === 400 || res.statusCode === 404) {
        trackAbuse(ip, 1);
      }
      // Heavier penalty for 401/403 (unauthorized/forbidden)
      if (res.statusCode === 401 || res.statusCode === 403) {
        trackAbuse(ip, 2);
      }
      return originalJson.apply(res, arguments);
    };

    next();
  } catch (err) {
    next(err);
  }
}

async function trackAbuse(ip, weight) {
  const redis = redisManager.getClient();
  const scoreKey = `abuse:score:${ip}`;
  const blockKey = `block:ip:${ip}`;

  try {
    const score = await redis.incrby(scoreKey, weight);
    await redis.expire(scoreKey, 300); // 5 minute rolling window (Principal Engineering V2)

    if (score >= 20) { // Threshold for blocking (e.g., 10 unauthorized attempts)
      logger.fatal({ ip, score }, "SEC-CRITICAL: IP auto-blocked for abuse");
      await redis.set(blockKey, "true", "EX", 86400); // 24 hour block
    }
  } catch (err) {
    logger.error({ ip, error: err.message }, "Abuse tracking failed");
  }
}


module.exports = { abuseProtection };
