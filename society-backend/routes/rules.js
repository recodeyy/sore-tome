const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, canManageContent } = require("../middleware/auth");
const { tenantMiddleware } = require("../middleware/tenantMiddleware");

// ─── RULES ────────────────────────────────────────────────────────────────────

// GET /rules — all society rules (Partitioned)
router.get("/", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const snap = await db.collection("rules")
      .where("society_id", "==", req.societyId)
      .orderBy("order", "asc")
      .get();
    const rules = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    res.json({ rules });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /rules — admin only: add a rule
// Body: { title, content, category, order? }
router.post("/", authMiddleware, tenantMiddleware, canManageContent, async (req, res) => {
  try {
    const { title, content, category = "general", order = 99 } = req.body;
    if (!title || !content)
      return res.status(400).json({ error: "title and content are required" });

    const db = getDb();
    const docRef = await db.collection("rules").add({
      society_id: req.societyId, // MANDATORY partition
      title,
      content,
      category, // "timings" | "parking" | "pets" | "noise" | "general"
      order,
      updatedBy: req.user.uid,
      updatedAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    res.status(201).json({ id: docRef.id, message: "Rule added" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /rules/:id — admin only: update a rule
router.put("/:id", authMiddleware, tenantMiddleware, canManageContent, async (req, res) => {
  try {
    const { title, content, category, order } = req.body;
    const db = getDb();
    const docRef = db.collection("rules").doc(req.params.id);
    const doc = await docRef.get();

    if (!doc.exists || doc.data().society_id !== req.societyId) {
      return res.status(404).json({ error: "Rule not found" });
    }

    const updates = { updatedAt: getAdmin().firestore.FieldValue.serverTimestamp(), updatedBy: req.user.uid };
    if (title) updates.title = title;
    if (content) updates.content = content;
    if (category) updates.category = category;
    if (order !== undefined) updates.order = order;

    await docRef.update(updates);
    res.json({ message: "Rule updated" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /rules/:id — admin only
router.delete("/:id", authMiddleware, tenantMiddleware, canManageContent, async (req, res) => {
  try {
    const db = getDb();
    const docRef = db.collection("rules").doc(req.params.id);
    const doc = await docRef.get();

    if (!doc.exists || doc.data().society_id !== req.societyId) {
      return res.status(404).json({ error: "Rule not found" });
    }

    await docRef.delete();
    res.json({ message: "Rule deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
