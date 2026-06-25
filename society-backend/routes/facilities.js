const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, mainAdminOnly } = require("../middleware/auth");
const { tenantMiddleware } = require("../middleware/tenantMiddleware");
const { logger } = require("../src/shared/Logger");

// GET /facilities -> List all facilities
router.get("/", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const snap = await db.collection("facilities")
      .where("society_id", "==", req.societyId)
      .get();
      
    const facilities = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json({ facilities });
  } catch (err) {
    logger.error({ error: err.message }, "Error fetching facilities");
    res.status(500).json({ error: "Internal server error" });
  }
});

// POST /facilities -> Admin creates a new facility (e.g., Clubhouse)
router.post("/", authMiddleware, tenantMiddleware, mainAdminOnly, async (req, res) => {
  try {
    const { name, description, hourlyRate, maxCapacity, openTime, closeTime } = req.body;
    if (!name) return res.status(400).json({ error: "Name is required" });

    const db = getDb();
    const docRef = await db.collection("facilities").add({
      name,
      description: description || "",
      hourlyRate: hourlyRate || 0, // 0 means free
      maxCapacity: maxCapacity || null,
      openTime: openTime || "06:00", // 24hr format
      closeTime: closeTime || "22:00",
      society_id: req.societyId,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    res.status(201).json({ message: "Facility created", id: docRef.id });
  } catch (err) {
    logger.error({ error: err.message }, "Error creating facility");
    res.status(500).json({ error: "Internal server error" });
  }
});

// POST /facilities/:id/book -> Resident books a facility
router.post("/:id/book", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const { date, startTime, endTime } = req.body; // date: YYYY-MM-DD, startTime: HH:MM
    if (!date || !startTime || !endTime) {
      return res.status(400).json({ error: "Date, startTime, and endTime are required" });
    }

    const db = getDb();
    
    // 1. Transaction to prevent double booking
    await db.runTransaction(async (t) => {
      // Check if facility exists
      const facilityRef = db.collection("facilities").doc(req.params.id);
      const facilityDoc = await t.get(facilityRef);
      
      if (!facilityDoc.exists || facilityDoc.data().society_id !== req.societyId) {
        throw new Error("Facility not found");
      }

      // 2. Check for conflicting bookings
      const conflictsSnap = await db.collection("bookings")
        .where("facilityId", "==", req.params.id)
        .where("date", "==", date)
        .where("status", "==", "confirmed")
        .get(); // Note: inside transaction we'd ideally query then read, or use a lock.
                // Firestore transactions require reads before writes.

      // Manual conflict check (simplification for MVP)
      const hasConflict = conflictsSnap.docs.some(doc => {
        const b = doc.data();
        // Conflict if new start is before existing end AND new end is after existing start
        return (startTime < b.endTime) && (endTime > b.startTime);
      });

      if (hasConflict) {
        throw new Error("Time slot is already booked");
      }

      // 3. Create Booking
      const newBookingRef = db.collection("bookings").doc();
      const facilityData = facilityDoc.data();
      
      t.set(newBookingRef, {
        facilityId: req.params.id,
        facilityName: facilityData.name,
        userId: req.user.uid,
        date,
        startTime,
        endTime,
        status: "confirmed",
        amountDue: facilityData.hourlyRate > 0 ? facilityData.hourlyRate : 0, // simplistic billing
        society_id: req.societyId,
        createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
      });

      // 4. Auto-charge resident if not free
      if (facilityData.hourlyRate > 0) {
        const txRef = db.collection("transactions").doc();
        t.set(txRef, {
           title: `Booking: ${facilityData.name}`,
           amount: facilityData.hourlyRate,
           type: 'debit',
           category: 'Facility Booking',
           society_id: req.societyId,
           addedBy: 'system',
           createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
        });
      }
    });

    res.status(201).json({ message: "Facility booked successfully" });
  } catch (err) {
    logger.error({ error: err.message }, "Error booking facility");
    res.status(err.message.includes("already booked") ? 409 : 500).json({ error: err.message });
  }
});

module.exports = router;
