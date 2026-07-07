const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, canManageSecurity } = require("../middleware/auth");
const { tenantMiddleware } = require("../middleware/tenantMiddleware");
const { logger } = require("../src/shared/Logger");
const NotificationService = require("../services/notificationService");

/**
 * §10 triggers — push to every resident login of a flat (Firestore users are
 * the identity store for this legacy Firestore-backed visitors flow).
 * Best-effort: failures are logged, never surfaced to the gate operation.
 */
async function pushToFlatResidents(societyId, targetFlat, payload) {
  try {
    const db = getDb();
    const snap = await db.collection("users")
      .where("society_id", "==", societyId)
      .where("flatNumber", "==", targetFlat)
      .get();
    await Promise.all(snap.docs.map((doc) => NotificationService.sendToUser(doc.id, payload)));
    return snap.size;
  } catch (err) {
    logger.warn({ societyId, targetFlat, error: err.message }, "Visitor push to flat residents failed");
    return 0;
  }
}

// Gate operations (check-in/checkout) are performable by on-duty security
// staff (guards, security managers, supervisors, reception) AND society admins
// (super_admin, main_admin, admin, secretary). Using the shared canManageSecurity
// guard keeps this consistent with the rest of the app — the old local guardOnly
// only allowed `guard`/`main_admin`, which silently locked security managers and
// superadmins out of the core cross-role gate workflow.

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

    // No orderBy in the query (avoids composite index); sort in memory
    const snap = await query.limit(200).get();
    const toMillis = (v) => (v && v.toMillis) ? v.toMillis() : (v ? new Date(v).getTime() || 0 : 0);
    const visitors = snap.docs
      .map(doc => ({ id: doc.id, ...doc.data() }))
      .sort((a, b) => toMillis(b.entryTime) - toMillis(a.entryTime))
      .slice(0, 50);

    res.json({ visitors });
  } catch (err) {
    logger.error({ error: err.message }, "Error fetching visitors");
    res.status(500).json({ error: "Internal server error" });
  }
});

// POST /visitors/checkin -> Guard logs a new visitor
router.post("/checkin", authMiddleware, tenantMiddleware, canManageSecurity, async (req, res) => {
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

    // §10 trigger: staff-initiated visitor → real FCM push to the flat's residents.
    await pushToFlatResidents(req.societyId, targetFlat, {
      title: "Visitor at the gate",
      body: `${name} (${type}) is at the gate for Flat ${targetFlat}. Approve or deny?`,
      data: { type: "visitor_approval", visitorId: docRef.id, deeplink: `/visitors/${docRef.id}` },
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

    // §10 trigger: visitor approved → entry confirmation to the flat's residents
    // (skip echoing to the actor when a resident actioned it themselves).
    if (newStatus === "approved" && req.user.role !== "resident") {
      await pushToFlatResidents(req.societyId, visitor.targetFlat, {
        title: "Visitor entry approved",
        body: `${visitor.name} has been approved to enter for Flat ${visitor.targetFlat}.`,
        data: { type: "visitor_entry", visitorId: req.params.id, deeplink: `/visitors/${req.params.id}` },
      });
    }

    res.json({ message: `Visitor ${newStatus}` });
  } catch (err) {
    logger.error({ error: err.message }, "Error updating visitor action");
    res.status(500).json({ error: "Internal server error" });
  }
});

// PATCH /visitors/:id/checkout -> Guard marks visitor as left
router.patch("/:id/checkout", authMiddleware, tenantMiddleware, canManageSecurity, async (req, res) => {
  try {
    const db = getDb();
    const docRef = db.collection("visitors").doc(req.params.id);
    const doc = await docRef.get();

    if (!doc.exists || doc.data().society_id !== req.societyId) {
      return res.status(404).json({ error: "Visitor not found" });
    }

    const visitor = doc.data();
    await docRef.update({
      status: "checked_out",
      exitTime: getAdmin().firestore.FieldValue.serverTimestamp()
    });

    // §10 trigger: visitor exit → notify the flat's residents.
    if (visitor.targetFlat) {
      await pushToFlatResidents(req.societyId, visitor.targetFlat, {
        title: "Visitor checked out",
        body: `${visitor.name || "Your visitor"} has left the premises.`,
        data: { type: "visitor_exit", visitorId: req.params.id, deeplink: `/visitors/${req.params.id}` },
      });
    }

    res.json({ message: "Visitor checked out" });
  } catch (err) {
    logger.error({ error: err.message }, "Error checking out visitor");
    res.status(500).json({ error: "Internal server error" });
  }
});

module.exports = router;
