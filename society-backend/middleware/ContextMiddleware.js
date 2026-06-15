const crypto = require("crypto");
const { logger } = require("../src/shared/Logger");

/**
 * Enterprise Context Middleware
 * 1. Generates a unique requestId for every request.
 * 2. Instruments the response to log total processing time.
 * 3. Injects requestId into response headers for tracing.
 */
function contextMiddleware(req, res, next) {
  const requestId = req.headers["x-request-id"] || crypto.randomUUID();
  const startTime = process.hrtime();

  // Attach to request and response objects
  req.requestId = requestId;
  res.setHeader("X-Request-ID", requestId);

  // Use a child logger to automatically include requestId in every log from this request context
  req.log = logger.child({ requestId });

  // On finish, log the completion and response time
  res.on("finish", () => {
    const diff = process.hrtime(startTime);
    const durationMs = (diff[0] * 1e3 + diff[1] * 1e-6).toFixed(2);
    
    req.log.info({
      method: req.method,
      url: req.originalUrl,
      status: res.statusCode,
      responseTime: `${durationMs}ms`,
      userId: req.user?.uid || "unauthenticated"
    }, "Request Completed");
  });

  next();
}

module.exports = { contextMiddleware };
