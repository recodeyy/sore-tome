const jwt = require("jsonwebtoken");

const JWT_SECRET = process.env.JWT_SECRET;

// Verifies the JWT token issued by our own POST /auth/login endpoint
function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Missing or invalid Authorization header" });
  }

  const token = authHeader.split("Bearer ")[1];

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = {
      uid: decoded.uid,
      phone: decoded.phone,
      name: decoded.name,
      role: decoded.role, // "resident" | "main_admin" | "superadmin" | "treasurer" | "secretary"
      society_id: decoded.society_id,
    };
    next();
  } catch (err) {
    if (err.name === "TokenExpiredError") {
      return res.status(401).json({ error: "Session expired. Please log in again." });
    }
    return res.status(401).json({ error: "Invalid token. Please log in again." });
  }
}

const { logger } = require("../src/shared/Logger");

// ... (authMiddleware remains same but ensures strict role extraction)

// Only allow admins and superadmins (legacy helper)
function adminOnly(req, res, next) {
  const role = req.user?.role;
  const isAuthorized = role === "superadmin" || role === "main_admin";
  
  if (!isAuthorized) {
    logger.warn({ userId: req.user?.uid, role, path: req.path }, "SEC-WARN: Unauthorized Admin Access Attempt");
    return res.status(403).json({ error: "Admin access required" });
  }
  next();
}

function mainAdminOnly(req, res, next) {
  const role = req.user?.role;
  if (role !== "main_admin") {
    logger.warn({ userId: req.user?.uid, role, path: req.path }, "SEC-WARN: Unauthorized Main Admin Access Attempt");
    return res.status(403).json({ error: "Main admin access required" });
  }
  next();
}

function canManageFunds(req, res, next) {
  const role = req.user?.role;
  const allowed = ["main_admin", "treasurer"];
  if (!allowed.includes(role)) {
    logger.warn({ userId: req.user?.uid, role, path: req.path }, "SEC-WARN: Unauthorized Funds Management Attempt");
    return res.status(403).json({ error: "Treasurer or admin access required" });
  }
  next();
}

function canManageContent(req, res, next) {
  const role = req.user?.role;
  const allowed = ["main_admin", "secretary"];
  if (!allowed.includes(role)) {
    logger.warn({ userId: req.user?.uid, role, path: req.path }, "SEC-WARN: Unauthorized Content Management Attempt");
    return res.status(403).json({ error: "Secretary or admin access required" });
  }
  next();
}

module.exports = { authMiddleware, adminOnly, mainAdminOnly, canManageFunds, canManageContent };

