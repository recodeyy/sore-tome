const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, mainAdminOnly } = require("../middleware/auth");
const { tenantMiddleware } = require("../middleware/tenantMiddleware");
const { logger } = require("../src/shared/Logger");

// Middleware to restrict access to guards
function guardOnly(req, res, next) {
  if (req.user.role !== "guard" && req.user.role !== "main_admin" && req.user.role !== "secretary") {
    return res.status(403).json({ error: "Access denied." });
  }
  next();
}

// GET /staff -> List all registered staff for the society
router.get("/", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const snap = await db.collection("staff")
      .where("society_id", "==", req.societyId)
      .get();
      
    const staff = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json({ staff });
  } catch (err) {
    logger.error({ error: err.message }, "Error fetching staff");
    res.status(500).json({ error: "Internal server error" });
  }
});

// POST /staff -> Admin registers a new staff member (Maid/Driver)
router.post("/", authMiddleware, tenantMiddleware, mainAdminOnly, async (req, res) => {
  try {
    const { name, type, phone, workingFlats } = req.body;
    if (!name || !type) {
      return res.status(400).json({ error: "Name and type are required." });
    }

    const db = getDb();
    const staffData = {
      name,
      type, // 'maid', 'driver', 'cook', 'cleaner'
      phone: phone || "",
      workingFlats: workingFlats || [], // Array of flat numbers they work in
      status: "active",
      society_id: req.societyId,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    };

    const docRef = await db.collection("staff").add(staffData);
    res.status(201).json({ message: "Staff registered successfully", id: docRef.id });
  } catch (err) {
    logger.error({ error: err.message }, "Error registering staff");
    res.status(500).json({ error: "Internal server error" });
  }
});

// POST /staff/:id/checkin -> Guard scans QR/selects staff to check them in
router.post("/:id/checkin", authMiddleware, tenantMiddleware, guardOnly, async (req, res) => {
  try {
    const db = getDb();
    const staffDoc = await db.collection("staff").doc(req.params.id).get();
    
    if (!staffDoc.exists || staffDoc.data().society_id !== req.societyId) {
      return res.status(404).json({ error: "Staff not found" });
    }

    const attendanceData = {
      staffId: req.params.id,
      staffName: staffDoc.data().name,
      staffType: staffDoc.data().type,
      entryTime: getAdmin().firestore.FieldValue.serverTimestamp(),
      exitTime: null,
      society_id: req.societyId,
      loggedBy: req.user.uid,
    };

    const docRef = await db.collection("staff_attendance").add(attendanceData);
    
    // Auto-notify all flats this staff works in
    const workingFlats = staffDoc.data().workingFlats || [];
    if (workingFlats.length > 0) {
      workingFlats.forEach(flat => {
         db.collection("notifications").add({
            type: "staff_entry",
            title: "Staff Entry",
            body: `Your ${staffDoc.data().type} (${staffDoc.data().name}) has entered the society.`,
            targetFlat: flat,
            society_id: req.societyId,
            read: false,
            createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
          });
      });
    }

    res.status(201).json({ message: "Staff checked in successfully", attendanceId: docRef.id });
  } catch (err) {
    logger.error({ error: err.message }, "Error checking in staff");
    res.status(500).json({ error: "Internal server error" });
  }
});

module.exports = router;
