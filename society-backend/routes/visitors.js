const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware } = require("../middleware/auth");
const { tenantMiddleware } = require("../middleware/tenantMiddleware");
const { logger } = require("../src/shared/Logger");

// Middleware to restrict access to guards
function guardOnly(req, res, next) {
  if (req.user.role !== "guard" && req.user.role !== "main_admin") {
    return res.status(403).json({ error: "Access denied. Guard or Admin role required." });
  }
  next();
}

// GET /visitors -> Get visitors for the society
// Guards/Admins see all for today. Residents see only their own.
router.get("/", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const societyId = req.societyId;
    let query = db.collection("visitors").where("society_id", "==", societyId);

    // If resident, only show visitors for their flat
    if (req.user.role === "resident") {
      // Fetch user's flat number first
      const userDoc = await db.collection("users").doc(req.user.uid).get();
      if (!userDoc.exists) return res.status(404).json({ error: "User profile not found" });
      const flatNumber = userDoc.data().flatNumber;
      query = query.where("targetFlat", "==", flatNumber);
    } else {
      // Guards see today's visitors (simplification for MVP: get all pending/active)
      // In production, you'd filter by entryTime >= startOfDay
    }

    const snap = await query.orderBy("entryTime", "desc").limit(50).get();
    const visitors = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    res.json({ visitors });
  } catch (err) {
    logger.error({ error: err.message }, "Error fetching visitors");
    res.status(500).json({ error: "Internal server error" });
  }
});

// POST /visitors/checkin -> Guard logs a new visitor
router.post("/checkin", authMiddleware, tenantMiddleware, guardOnly, async (req, res) => {
  try {
    const { name, type, targetFlat, vehicleNumber, phone } = req.body;
    if (!name || !type || !targetFlat) {
      return res.status(400).json({ error: "Name, type, and targetFlat are required." });
    }

    const db = getDb();
    const visitorData = {
      name,
      type, // 'delivery', 'guest', 'cab', 'maid'
      targetFlat,
      vehicleNumber: vehicleNumber || "",
      phone: phone || "",
      status: "pending", // pending, approved, denied, checked_out
      entryTime: getAdmin().firestore.FieldValue.serverTimestamp(),
      exitTime: null,
      society_id: req.societyId,
      loggedBy: req.user.uid,
    };

    const docRef = await db.collection("visitors").add(visitorData);

    // AI V2.4: Trigger Push Notification to the resident
    await db.collection("notifications").add({
      type: "visitor_approval",
      title: "Visitor at the Gate",
      body: `${name} (${type}) is at the gate for Flat ${targetFlat}.`,
      targetFlat: targetFlat, // Need to broadcast to all users in this flat
      society_id: req.societyId,
      visitorId: docRef.id,
      read: false,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    res.status(201).json({ message: "Visitor logged. Waiting for approval.", id: docRef.id });
  } catch (err) {
    logger.error({ error: err.message }, "Error checking in visitor");
    res.status(500).json({ error: "Internal server error" });
  }
});

// PATCH /visitors/:id/action -> Resident approves or denies
router.patch("/:id/action", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const { action } = req.body; // 'approve' or 'deny'
    if (action !== "approve" && action !== "deny") {
      return res.status(400).json({ error: "Invalid action. Use 'approve' or 'deny'." });
    }

    const db = getDb();
    const docRef = db.collection("visitors").doc(req.params.id);
    const doc = await docRef.get();

    if (!doc.exists || doc.data().society_id !== req.societyId) {
      return res.status(404).json({ error: "Visitor not found" });
    }

    const visitor = doc.data();

    // Verify resident owns the flat
    if (req.user.role === "resident") {
      const userDoc = await db.collection("users").doc(req.user.uid).get();
      if (userDoc.data().flatNumber !== visitor.targetFlat) {
        return res.status(403).json({ error: "You can only approve visitors for your own flat." });
      }
    }

    const newStatus = action === "approve" ? "approved" : "denied";
    await docRef.update({
      status: newStatus,
      actionedBy: req.user.uid,
      actionedAt: getAdmin().firestore.FieldValue.serverTimestamp()
    });

    res.json({ message: `Visitor ${newStatus}` });
  } catch (err) {
    logger.error({ error: err.message }, "Error updating visitor action");
    res.status(500).json({ error: "Internal server error" });
  }
});

// PATCH /visitors/:id/checkout -> Guard marks visitor as left
router.patch("/:id/checkout", authMiddleware, tenantMiddleware, guardOnly, async (req, res) => {
  try {
    const db = getDb();
    const docRef = db.collection("visitors").doc(req.params.id);
    const doc = await docRef.get();

    if (!doc.exists || doc.data().society_id !== req.societyId) {
      return res.status(404).json({ error: "Visitor not found" });
    }

    await docRef.update({
      status: "checked_out",
      exitTime: getAdmin().firestore.FieldValue.serverTimestamp()
    });

    res.json({ message: "Visitor checked out" });
  } catch (err) {
    logger.error({ error: err.message }, "Error checking out visitor");
    res.status(500).json({ error: "Internal server error" });
  }
});

module.exports = router;
