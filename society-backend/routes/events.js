const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, canManageContent } = require("../middleware/auth");
const { tenantMiddleware } = require("../middleware/tenantMiddleware");
const { AuditLogService } = require("../src/services/AuditLogService");

// GET /events — upcoming events (Partitioned)
router.get("/", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const snap = await db.collection("events")
      .where("society_id", "==", req.societyId)
      .orderBy("date", "asc")
      .limit(20)
      .get();
    const events = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    res.json({ events });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /events — admin only: create an event
// Body: { title, description, date (ISO string), location? }
router.post("/", authMiddleware, tenantMiddleware, canManageContent, async (req, res) => {
  try {
    const { title, description, date, location } = req.body;
    if (!title || !date)
      return res.status(400).json({ error: "title and date are required" });

    const db = getDb();
    const docRef = await db.collection("events").add({
      society_id: req.societyId, // MANDATORY partition
      title,
      description: description || "",
      date: new Date(date),
      location: location || "Society premises",
      createdBy: req.user.uid,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });
    
    // Log the action
    await AuditLogService.getInstance().logAdminAction(
      req.user,
      "Event Created",
      `Created event: "${title}"`
    );

    res.status(201).json({ id: docRef.id, message: "Event created" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /events/:id — admin only
router.delete("/:id", authMiddleware, tenantMiddleware, canManageContent, async (req, res) => {
  try {
    const db = getDb();
    const docRef = db.collection("events").doc(req.params.id);
    const doc = await docRef.get();

    if (!doc.exists || doc.data().society_id !== req.societyId) {
       return res.status(404).json({ error: "Event not found" });
    }

    await docRef.delete();
    
    // Log the action
    await AuditLogService.getInstance().logAdminAction(
      req.user,
      "Event Deleted",
      `Deleted event ID: ${req.params.id}`
    );

    res.json({ message: "Event deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
