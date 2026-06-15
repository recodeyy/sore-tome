const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, mainAdminOnly } = require("../middleware/auth");
const { tenantMiddleware } = require("../middleware/tenantMiddleware");
const { AuditLogService } = require("../src/services/AuditLogService");

// POST /users/register — called after Firebase phone OTP success
// Flutter sends this after first login to save user profile in Firestore
// Body: { name, flatNumber, phone, society_id }
router.post("/register", authMiddleware, async (req, res) => {
  try {
    const { name, flatNumber, phone, society_id } = req.body;
    if (!name || !flatNumber)
      return res.status(400).json({ error: "name and flatNumber are required" });

    const db = getDb();
    const userRef = db.collection("users").doc(req.user.uid);
    const existing = await userRef.get();

    if (existing.exists) {
      return res.status(200).json({ message: "User already registered", user: existing.data() });
    }

    const userData = {
      uid: req.user.uid,
      name,
      flatNumber,
      phone: phone || "",
      society_id: society_id || "main_society", // Fallback for legacy if not provided
      role: "resident", // default role
      residentType: "owner", // owner | tenant | guest
      status: "pending",
      maintenanceExempt: false,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    };

    await userRef.set(userData);
    res.status(201).json({ message: "User registered", user: userData });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /users/me — get own profile
router.get("/me", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const doc = await db.collection("users").doc(req.user.uid).get();
    if (!doc.exists) return res.status(404).json({ error: "Profile not found. Please register." });
    // ✅ BUG-17 FIX: Strip sensitive fields before returning user data
    const { password, passwordHash, ...safeUser } = doc.data();
    res.json(safeUser);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /users — admin only: list all users IN THEIR SOCIETY
router.get("/", authMiddleware, tenantMiddleware, mainAdminOnly, async (req, res) => {
  try {
    const db = getDb();
    const societyId = req.societyId;
    
    const snap = await db.collection("users")
      .where("society_id", "==", societyId)
      .orderBy("flatNumber", "asc")
      .get();
      
    const users = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    res.json({ users, total: users.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /users/bulk-import — main_admin only: bulk import residents via CSV
const { parse } = require("csv-parse/sync");
// Note: Requires multer, which is defined later in this file. We'll reuse the upload var.
// We need to define multer here since we are using it above its original declaration.
const multer = require("multer");
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });

router.post("/bulk-import", authMiddleware, tenantMiddleware, mainAdminOnly, upload.single("file"), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: "No CSV file uploaded" });
    const isDryRun = req.query.dryRun === "true";

    const rawRecords = parse(req.file.buffer, {
      columns: true,
      skip_empty_lines: true,
      trim: true,
    });

    const db = getDb();
    const societyId = req.societyId;
    
    // Fetch existing users to check flat uniqueness
    const snap = await db.collection("users").where("society_id", "==", societyId).get();
    const existingFlats = new Set(snap.docs.map(d => d.data().flatNumber));

    const results = {
      totalRows: rawRecords.length,
      validRows: 0,
      invalidRows: 0,
      errors: [],
      success: 0
    };

    const validRecords = [];
    const newFlatsInFile = new Set();

    // AI-like Fuzzy Header Mapping Helper
    const findField = (row, possibleKeys) => {
      const keys = Object.keys(row);
      for (const k of keys) {
        const normalizedKey = k.toLowerCase().replace(/[^a-z0-9]/g, '');
        if (possibleKeys.includes(normalizedKey)) return row[k];
      }
      return null;
    };

    rawRecords.forEach((row, index) => {
      const rowNum = index + 2; 

      // Fuzzy matching for headers
      const name = findField(row, ['name', 'fullname', 'residentname', 'resident']);
      let flatNumber = findField(row, ['flatnumber', 'flatno', 'unitno', 'unitnumber', 'flat', 'unit']);
      const phone = findField(row, ['phone', 'phonenumber', 'mobile', 'contactno', 'contact']);
      const email = findField(row, ['email', 'emailaddress']);
      let residentType = findField(row, ['residenttype', 'type', 'role']);

      if (!name || !flatNumber) {
        results.invalidRows++;
        results.errors.push(`Row ${rowNum}: Could not find a valid Name or Flat Number column.`);
        return;
      }

      // Format cleanups
      flatNumber = flatNumber.toString().trim().toUpperCase();
      if (residentType) residentType = residentType.toLowerCase().trim();

      // Intelligent Collision Handling
      let finalResidentType = residentType || "owner";
      
      // If flat already exists in DB, or we already processed this flat in this CSV file, 
      // they automatically become a family member instead of throwing an error.
      if (existingFlats.has(flatNumber) || newFlatsInFile.has(flatNumber)) {
         finalResidentType = "family_member";
      }

      newFlatsInFile.add(flatNumber);
      results.validRows++;
      
      validRecords.push({
        name,
        flatNumber,
        phone: phone ? phone.toString().replace(/[^0-9+]/g, '') : "",
        email: email || "",
        society_id: societyId,
        role: "resident",
        residentType: finalResidentType,
        status: "approved", 
        maintenanceExempt: false,
        createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
      });
    });

    if (isDryRun) {
      return res.json({ dryRun: true, ...results });
    }

    if (validRecords.length > 0) {
      let batch = db.batch();
      let count = 0;

      validRecords.forEach((record) => {
        const ref = db.collection("users").doc(); // Generates auto-ID, wait, auth UID?
        // Note: For bulk import, we create the user document without Auth UID yet.
        // They will claim it later using phone OTP, which will link to this flatNumber.
        // For Sero, a user claiming a flat needs to match phone or be approved.
        record.uid = ref.id; // temporary UID
        batch.set(ref, record);
        count++;

        if (count % 450 === 0) {
          batch.commit();
          batch = db.batch();
        }
      });
      if (count % 450 !== 0) {
        await batch.commit();
      }
      results.success = count;
      
      await AuditLogService.getInstance().logAdminAction(
        req.user,
        "Bulk Residents Imported",
        `Imported ${count} residents via CSV into society ${societyId}`
      );
    }

    res.json({ dryRun: false, ...results });
  } catch (err) {
    res.status(500).json({ error: "CSV Parsing Error: " + err.message });
  }
});

// PATCH /users/:uid — main_admin can edit any user's details
router.patch("/:uid", authMiddleware, tenantMiddleware, mainAdminOnly, async (req, res) => {
  try {
    const { name, flatNumber, blockName, role, status, residentType, maintenanceExempt } = req.body;
    const db = getDb();
    
    const admin = getAdmin();
    let updatesApplied = false;

    // 🛡️ SEC FIX: Use Transaction for safe concurrent updates
    const finalUpdates = await db.runTransaction(async (transaction) => {
      const userRef = db.collection("users").doc(req.params.uid);
      const userDoc = await transaction.get(userRef);
      
      if (!userDoc.exists || userDoc.data().society_id !== req.societyId) {
        throw new Error("User not found in your society");
      }

      const updates = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };

      // 🛡️ SEC FIX: Prevent Privilege Escalation & Self-Modification
      if (role && userDoc.data().role !== role) {
        if (role === 'superadmin' && req.user.role !== 'superadmin') {
          throw new Error("Cannot assign superadmin role.");
        }
        if (req.user.uid === req.params.uid) {
          throw new Error("Cannot change your own role.");
        }
        updates.role = role;
      }

      if (name) updates.name = name;
      if (flatNumber) updates.flatNumber = flatNumber;
      if (blockName !== undefined) updates.blockName = blockName;
      if (status) updates.status = status;
      if (residentType) updates.residentType = residentType;
      if (maintenanceExempt !== undefined) updates.maintenanceExempt = maintenanceExempt;

      transaction.update(userRef, updates);
      updatesApplied = true;
      return updates;
    });

    if (!updatesApplied) {
      return res.status(400).json({ error: "Update failed" });
    }

    const updates = finalUpdates;

    // 🛡️ SEC FIX: Force session revocation if role was changed
    if (updates.role) {
      await admin.auth().setCustomUserClaims(req.params.uid, { role: updates.role });
      
      // Destroy all active refresh tokens for this user
      const allTokens = await db.collection("refresh_tokens").where("userId", "==", req.params.uid).get();
      const batch = db.batch();
      allTokens.forEach(doc => batch.delete(doc.ref));
      await batch.commit();
      
      // Note: For perfect security, we would also push the user's active JWTs to Redis blacklist here.
      // But deleting refresh tokens ensures they are booted within 1 hour maximum, or on next app restart.
    }

    // Log the action for administrative accountability
    await AuditLogService.getInstance().logAdminAction(
      req.user,
      "Resident Updated",
      `Modified details for User ID: ${req.params.uid}. Fields: ${Object.keys(req.body).join(", ")}`
    );

    res.json({ message: "User updated successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Phase 2: Profile Photo Upload ────────────────
const { getStorage } = require("../config/firebase");
// multer and upload are already defined above

// POST /users/me/photo
router.post("/me/photo", authMiddleware, upload.single("photo"), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: "No file uploaded" });

    const db = getDb();
    const bucket = getStorage().bucket();
    const fileName = `profiles/${req.user.uid}_${Date.now()}.jpg`;
    const file = bucket.file(fileName);

    await file.save(req.file.buffer, {
      metadata: { contentType: req.file.mimetype },
      public: true,
    });

    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;

    await db.collection("users").doc(req.user.uid).update({
      photoUrl: publicUrl,
      updatedAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    res.json({ photoUrl: publicUrl, message: "Profile photo updated" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
