const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, canManageContent } = require("../middleware/auth");
const { tenantMiddleware } = require("../middleware/tenantMiddleware");
const { AuditLogService } = require("../src/services/AuditLogService");
const { logger } = require("../src/shared/Logger");
const { validate } = require("../src/middleware/validate");
const { CreateIssueSchema, UpdateIssueStatusSchema } = require("../src/shared/schemas");

// GET /issues — all issues (Filtered by societyId, Admin sees all in society, Residents see their own + open ones)
router.get("/", authMiddleware, tenantMiddleware, async (req, res) => {
  const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";
  try {
    const db = getDb();
    const { status } = req.query; 
    const societyId = req.societyId;

    let query = db.collection("issues").where("society_id", "==", societyId);
    
    if (req.user.role === "resident") {
      // Residents see: (PostedBy == Me) OR (Status == open)
      // Firestore doesn't support OR natively in a scalable way without multiple queries or IN clause
      // We'll perform two targeted indexed queries and merge to ensure O(log N) performance
      const [mySnap, openSnap] = await Promise.all([
        db.collection("issues")
          .where("society_id", "==", societyId)
          .where("postedBy", "==", req.user.uid)
          .orderBy("createdAt", "desc")
          .limit(50)
          .get(),
        db.collection("issues")
          .where("society_id", "==", societyId)
          .where("status", "==", "open")
          .orderBy("createdAt", "desc")
          .limit(50)
          .get()
      ]);

      const map = new Map();
      [...mySnap.docs, ...openSnap.docs].forEach(doc => {
        if (!map.has(doc.id)) {
          const data = doc.data();
          if (!status || data.status === status) {
            map.set(doc.id, {
              id: doc.id,
              ...data,
              createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : null,
            });
          }
        }
      });
      // Final merge and sort (Limited to 50 for performance)
      const issues = Array.from(map.values())
        .sort((a,b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
        .slice(0, 50);
      return res.json({ issues });
    } 

    // Admin Path: Strict server-side filtering
    query = query.orderBy("createdAt", "desc");
    if (status) query = query.where("status", "==", status);
    
    const snap = await query.limit(50).get();
    const issues = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : null,
      };
    });

    res.json({ issues });
  } catch (err) {
    logger.error({ ip, error: err.message }, "Error fetching issues");
    res.status(500).json({ error: "Internal server error" });
  }
});

// GET /issues/:id — single issue (SECURE: Tenant + Ownership/Admin check)
router.get("/:id", authMiddleware, tenantMiddleware, async (req, res) => {
  const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";
  try {
    const db = getDb();
    const doc = await db.collection("issues").doc(req.params.id).get();
    
    // Mask existence: if not exists OR wrong society, return 404
    if (!doc.exists || doc.data().society_id !== req.societyId) {
      return res.status(404).json({ error: "Issue not found" });
    }

    const data = doc.data();
    const isOwner = data.postedBy === req.user.uid;
    const isAdmin = ["main_admin", "secretary"].includes(req.user.role);

    if (!isOwner && !isAdmin) {
      logger.warn({ ip, userId: req.user.uid, issueId: req.params.id, societyId: req.societyId }, "SEC-WARN: Unauthorized society-internal IDOR attempt");
      return res.status(404).json({ error: "Issue not found" }); 
    }

    res.json({ 
      id: doc.id, 
      ...data,
      createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : null,
      updatedAt: data.updatedAt ? data.updatedAt.toDate().toISOString() : null
    });
  } catch (err) {
    logger.error({ ip, error: err.message }, "Error fetching single issue");
    res.status(500).json({ error: "Internal server error" });
  }
});

// POST /issues — any resident can report an issue
router.post("/", authMiddleware, tenantMiddleware, validate(CreateIssueSchema), async (req, res) => {
  const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";
  try {
    const { title, description, category, priority } = req.body;
    const db = getDb();
    const docRef = await db.collection("issues").add({
      society_id: req.societyId, // MANDATORY: Multi-tenancy partition
      title,
      description,
      category,
      priority: priority || "medium",
      status: "open",
      postedBy: req.user.uid,
      postedByName: req.user.name || "Resident",
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
      updatedAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    res.status(201).json({ id: docRef.id, message: "Issue reported" });
  } catch (err) {
    logger.error({ ip, error: err.message }, "Error reporting issue");
    res.status(500).json({ error: "Internal server error" });
  }
});

// PATCH /issues/:id/status — admin only: update issue status
router.patch("/:id/status", authMiddleware, tenantMiddleware, canManageContent, validate(UpdateIssueStatusSchema), async (req, res) => {
  try {
    const { status, adminNote, priority } = req.body;
    const db = getDb();
    const docRef = db.collection("issues").doc(req.params.id);
    const doc = await docRef.get();

    if (!doc.exists || doc.data().society_id !== req.societyId) {
       return res.status(404).json({ error: "Issue not found" });
    }

    const updates = {
      updatedAt: getAdmin().firestore.FieldValue.serverTimestamp(),
      resolvedBy: req.user.uid,
    };
    if (status) updates.status = status;
    if (adminNote !== undefined) updates.adminNote = adminNote;
    if (priority) updates.priority = priority;

    await docRef.update(updates);

    await AuditLogService.getInstance().log({
       type: 'administrative',
       action: "Issue Updated",
       actorId: req.user.uid,
       actorName: req.user.name || "Admin",
       details: `Changed issue status to "${status}"`,
       society_id: req.societyId,
       metadata: { issueId: req.params.id }
    });

    // AI V2.4: Notify the issue owner
    const NotificationService = require("../services/notificationService");
    await NotificationService.sendToUser(doc.data().postedBy, {
      title: "Issue Update",
      body: `Your issue "${doc.data().title}" is now ${status}.`,
      data: { type: "issue", id: req.params.id }
    });

    res.json({ message: "Issue status updated successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /issues/:id — admin only or issue owner (Scoped by societyId)
router.delete("/:id", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const docRef = db.collection("issues").doc(req.params.id);
    const doc = await docRef.get();
    
    if (!doc.exists || doc.data().society_id !== req.societyId) {
       return res.status(404).json({ error: "Issue not found" });
    }

    const isOwner = doc.data().postedBy === req.user.uid;
    const isAdmin = ["main_admin", "secretary"].includes(req.user.role);
    if (!isOwner && !isAdmin) return res.status(404).json({ error: "Issue not found" });

    await docRef.delete();
    res.json({ message: "Issue deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
