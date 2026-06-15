const express = require("express");
const router = express.Router();
const { getAllFlags, setFlag } = require("../utils/feature_flags");

const { authMiddleware, adminOnly } = require("../middleware/auth");
const { tenantMiddleware } = require("../middleware/tenantMiddleware");
const { AuditLogService } = require("../src/services/AuditLogService");

// ELITE: Feature Toggle System
// GET /admin/flags - Fetch all active toggles
router.get("/flags", authMiddleware, adminOnly, tenantMiddleware, (req, res) => {
  res.json(getAllFlags());
});

// POST /admin/flags/:name - Update a toggle
router.post("/flags/:name", authMiddleware, adminOnly, tenantMiddleware, async (req, res) => {
  const { name } = req.params;
  const { value } = req.body;
  
  if (setFlag(name, value)) {
    await AuditLogService.getInstance().logAdminAction(
      req.user,
      "Feature Flag Changed",
      `Set ${name} to ${value}`
    );
    res.json({ success: true, name, value });
  } else {
    res.status(404).json({ error: "Flag not found" });
  }
});

module.exports = router;
