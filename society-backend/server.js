require("dotenv").config();
const Sentry = require("@sentry/node");
const { logger } = require("./src/shared/Logger");

// ─── Suppress pg-connection-string SSL deprecation warning ────────────────────
process.on('warning', (warning) => {
  if (warning.name === 'Warning' && warning.message && warning.message.includes('sslmode')) {
    return;
  }
  console.warn(warning.name, warning.message);
});

// ─── Init Sentry ─────────────────────────────────────────────────────────────
Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 1.0,
});

const express = require("express");
const rateLimit = require("express-rate-limit");
const helmet = require("helmet");
const cors = require("cors");
const { initFirebase } = require("./config/firebase");
const standardLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, 
  max: 100, 
  message: { error: "Too many requests from this IP, please try again after 15 minutes" },
  standardHeaders: true,
  legacyHeaders: false,
  validate: { default: false },
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, 
  max: 5, 
  message: { error: "Too many login/signup attempts, please try again after 15 minutes" },
  standardHeaders: true,
  legacyHeaders: false,
  validate: { default: false },
});

const aiLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, 
  max: 10, 
  message: { error: "AI request limit reached. Please wait a moment." },
  standardHeaders: true,
  legacyHeaders: false,
  validate: { default: false },
});

// ─── Init Firebase ─────────────────────────────────────────────────────────────
initFirebase();

// ─── Init Cron Jobs ────────────────────────────────────────────────────────────
const { VisitorCronJob } = require("./src/services/cron/VisitorCronJob");
const { FinanceReportCronJob } = require("./src/services/cron/FinanceReportCronJob");
VisitorCronJob.init();
FinanceReportCronJob.init();

const app = express();

const { contextMiddleware } = require("./middleware/ContextMiddleware");
const { abuseProtection } = require("./middleware/abuseProtection");
const { sanitizeInput } = require("./middleware/sanitize");

// ─── Trust Proxy ─────────────────────────────────────────────────────────────
app.set("trust proxy", 1); // Enable IP sensing behind load balancers/proxies

// ─── Middleware ────────────────────────────────────────────────────────────────
app.use(contextMiddleware); // Enterprise tracing & log context
app.use(helmet());
app.use(abuseProtection);
app.use(sanitizeInput);

// 🛡️ Phase 3: Global Protection
app.use(express.json({ 
  limit: "10kb",
  verify: (req, res, buf) => {
    if (req.originalUrl.includes('/webhook')) {
      req.rawBody = buf.toString();
    }
  }
})); // Prevents payload-based DoS
app.use("/auth/login", authLimiter);
app.use("/auth/register", authLimiter);

// ─── CORS Configuration ──────────────────────────────────────────────────────
const allowedOrigins = (process.env.CORS_ORIGINS || "http://localhost:3000,http://localhost:3001").split(",");
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (like mobile apps or curl)
    if (!origin) return callback(null, true);
    if (allowedOrigins.indexOf(origin) !== -1 || process.env.NODE_ENV === 'development') {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With", "x-health-check-secret"]
}));

// ─── API Versioning & Routing ─────────────────────────────────────────────────
const v1Router = express.Router();

v1Router.use("/auth", require("./routes/auth"));
v1Router.use("/users", standardLimiter, require("./routes/users"));
v1Router.use("/notices", standardLimiter, require("./routes/notices"));
v1Router.use("/issues", standardLimiter, require("./routes/issues"));
v1Router.use("/funds", standardLimiter, require("./routes/funds"));
v1Router.use("/rules", standardLimiter, require("./routes/rules"));
v1Router.use("/events", standardLimiter, require("./routes/events"));
v1Router.use("/visitors", standardLimiter, require("./routes/visitors"));
v1Router.use("/staff", standardLimiter, require("./routes/staff"));
v1Router.use("/facilities", standardLimiter, require("./routes/facilities"));
v1Router.use("/polls", standardLimiter, require("./routes/polls"));
v1Router.use("/ai", aiLimiter, require("./src/routes/ai").default);
v1Router.use("/admin", standardLimiter, require("./src/routes/admin_dashboard").default);
v1Router.use("/admin", standardLimiter, require("./src/routes/admin_access").default);
v1Router.use("/channels", standardLimiter, require("./routes/channels"));
v1Router.use("/admin", standardLimiter, require("./routes/admin_flags"));

// 🚀 MOUNT V1
app.use("/api/v1", v1Router);

// 🛡️ MOUNT LEGACY FALLBACK (WITH DEPRECATION DATA)
app.use("/", (req, res, next) => {
  // Scoped Deprecation Headers ONLY for non-versioned routes
  if (!req.originalUrl.startsWith("/api/")) {
    res.setHeader("X-API-Deprecated", "true");
    res.setHeader("X-API-Version", "v1");
    // Optionally log this so we can track legacy client migration
    // req.log.warn({ path: req.path }, "LEGACY-API: Request hit unversioned route");
  }
  next();
}, v1Router);


// ─── Health check ─────────────────────────────────────────────────────────────
const { HealthService } = require("./src/services/HealthService");

app.get("/health", (req, res) => {
  res.json({ status: "ok", app: "Society Backend", timestamp: new Date().toISOString() });
});

app.get("/health/deep", async (req, res) => {
  const secret = req.headers["x-health-check-secret"];
  if (!secret || secret !== process.env.HEALTH_CHECK_SECRET) {
    logger.warn({ ip: req.ip }, "Unauthorized deep health check attempt");
    return res.status(401).json({ error: "Unauthorized" });
  }

  try {
    const report = await HealthService.performDeepCheck();
    res.status(report.status === "ok" ? 200 : 503).json(report);
  } catch (err) {
    res.status(500).json({ status: "error", message: "Health check failed", requestId: req.requestId });
  }
});



// ─── 404 handler ──────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: `Route ${req.method} ${req.path} not found` });
});

const crypto = require("crypto");

const { errorHandler } = require("./middleware/errorHandler");

// ─── Global error handler ─────────────────────────────────────────────────────
// Sentry error handler must be before any other error middleware
Sentry.setupExpressErrorHandler(app);

app.use(errorHandler);



// ─── Start ────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3001;
const server = app.listen(PORT, () => {
  console.log(`\n🏘️  Society Backend running on port ${PORT}`);
  console.log(`📋 Routes: /users /notices /issues /funds /rules /events /ai`);
  console.log(`🤖 AI chatbot: POST /ai/chat\n`);
});

// ─── Graceful Shutdown ────────────────────────────────────────────────────────
const { dbManager } = require("./src/shared/Database");
const { redisManager } = require("./src/shared/Redis");

async function shutdown(signal) {
  logger.info(`Received ${signal}. Shutting down gracefully...`);
  
  server.close(async () => {
    logger.info("Express server closed");
    
    try {
      await dbManager.close();
      await redisManager.close();
      logger.info("All connections closed. Exiting.");
      process.exit(0);
    } catch (err) {
      logger.error({ error: err.message }, "Error during graceful shutdown");
      process.exit(1);
    }
  });

  // Force exit after 10s if graceful shutdown fails
  setTimeout(() => {
    logger.error("Could not close connections in time, forceful exit");
    process.exit(1);
  }, 10000);
}

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));
