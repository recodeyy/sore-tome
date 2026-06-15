const express = require("express");
const router = express.Router();
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, adminOnly, mainAdminOnly } = require("../middleware/auth");
const { AuditLogService } = require("../src/services/AuditLogService");
const { redis } = require("../src/shared/Redis");
const { logger } = require("../src/shared/Logger");

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = "1h";
const REFRESH_TOKEN_EXPIRES_IN = 7 * 24 * 60 * 60 * 1000; // 7 days in ms

const hashToken = (token) => crypto.createHash("sha256").update(token).digest("hex");

const { validate } = require("../src/middleware/validate");
const { RegisterSchema, LoginSchema, RefreshTokenSchema } = require("../src/shared/schemas");

// ─── REFRESH TOKEN ────────────────────────────────────────────────────────────
// POST /auth/refresh
router.post("/refresh", validate(RefreshTokenSchema), async (req, res) => {
    const { refreshToken } = req.body;
    const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";

    try {
        const db = getDb();
        const tokenHash = hashToken(refreshToken);
        
        // ❗ SEC FIX: Check Redis Blacklist first for instant revocation
        const isBlacklisted = await redis.get(`blacklist:${tokenHash}`);
        if (isBlacklisted) {
            return res.status(401).json({ error: "Session revoked" });
        }

        const tokenDoc = await db.collection("refresh_tokens").doc(tokenHash).get();
        if (!tokenDoc.exists) {
            return res.status(401).json({ error: "Invalid refresh token" });
        }

        const tokenData = tokenDoc.data();

        // 🚨 REUSE DETECTION & AUTOMATIC LOGOUT
        if (tokenData.revoked) {
            logger.alert({ ip, userId: tokenData.userId }, "SEC-CRITICAL: Refresh token reuse detected! Revoking all sessions.");
            const allTokens = await db.collection("refresh_tokens").where("userId", "==", tokenData.userId).get();
            const batch = db.batch();
            allTokens.forEach(doc => batch.delete(doc.ref));
            await batch.commit();
            return res.status(401).json({ error: "Session compromised. Please log in again." });
        }

        // ❗ SEC FIX: Fetch FRESH user data from DB (Don't trust JWT/Stored role)
        const userDoc = await db.collection("users").doc(tokenData.userId).get();
        if (!userDoc.exists || userDoc.data().status !== "approved") {
            return res.status(401).json({ error: "User unauthorized or no longer exists" });
        }
        const user = userDoc.data();

        // 🔁 TOKEN ROTATION
        const batch = db.batch();
        batch.update(tokenDoc.ref, { revoked: true }); // Invalidate old token in Firestore

        const newRefreshToken = crypto.randomBytes(40).toString("hex");
        const newRefreshTokenHash = hashToken(newRefreshToken);

        batch.set(db.collection("refresh_tokens").doc(newRefreshTokenHash), {
            userId: userDoc.id,
            expiresAt: getAdmin().firestore.Timestamp.fromDate(new Date(Date.now() + REFRESH_TOKEN_EXPIRES_IN)),
            revoked: false,
            createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
            society_id: user.society_id
        });

        await batch.commit();
        
        // Add old token to Redis Blacklist (Short TTL)
        await redis.setex(`blacklist:${tokenHash}`, 3600, "1");

        const newAccessToken = jwt.sign(
            { 
                uid: userDoc.id, 
                phone: user.phone, 
                role: user.role, 
                name: user.name,
                society_id: user.society_id
            },
            JWT_SECRET,
            { expiresIn: JWT_EXPIRES_IN }
        );

        logger.info({ ip, userId: userDoc.id }, "Token rotated successfully");
        res.json({ token: newAccessToken, refreshToken: newRefreshToken });

    } catch (err) {
        logger.error({ ip, error: err.message }, "Error during token refresh");
        res.status(500).json({ error: "Internal server error" });
    }
});

// POST /auth/logout
router.post("/logout", validate(RefreshTokenSchema), async (req, res) => {
    try {
        const { refreshToken } = req.body;
        const db = getDb();
        const tokenHash = hashToken(refreshToken);
        
        // ❗ SEC FIX: Immediate Blacklist with TTL (7 Days)
        await redis.setex(`blacklist:${tokenHash}`, 7 * 24 * 3600, "revoke");
        await db.collection("refresh_tokens").doc(tokenHash).delete();
        
        res.json({ message: "Logged out successfully" });
    } catch (err) {
        res.status(500).json({ error: "Logout failed" });
    }
});

// ─── LOGOUT ALL ───────────────────────────────────────────────────────────────
// POST /auth/logout-all
router.post("/logout-all", authMiddleware, async (req, res) => {
    try {
        const db = getDb();
        const allTokens = await db.collection("refresh_tokens")
            .where("userId", "==", req.user.uid)
            .get();
        
        const batch = db.batch();
        allTokens.forEach(doc => batch.delete(doc.ref));
        await batch.commit();

        logger.info({ userId: req.user.uid }, "All sessions revoked");
        res.json({ message: "All sessions revoked successfully" });
    } catch (err) {
        res.status(500).json({ error: "Operation failed" });
    }
});

// ─── REGISTER ─────────────────────────────────────────────────────────────────
// POST /auth/register
// Body: { name, phone, password, flatNumber, blockName? }
// SECURITY: Strictly validated via Zod schemas.
router.post("/register", validate(RegisterSchema), async (req, res) => {
    try {
        const { name, phone, password, flatNumber, blockName, society_id } = req.body;

        const cleanPhone = phone.replace(/\s+/g, "");
        const db = getDb();

        // Check duplicate phone
        const existing = await db.collection("users").where("phone", "==", cleanPhone).limit(1).get();
        if (!existing.empty) {
            return res.status(409).json({ error: "This phone number is already registered" });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const userRef = db.collection("users").doc();
        const userData = {
            uid: userRef.id,
            name,
            phone: cleanPhone,
            password: hashedPassword,
            flatNumber,
            blockName: blockName || "",
            society_id, // Partition ID
            role: "resident",
            status: "pending",       // pending | approved | rejected
            createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
            residentType: "owner",
            maintenanceExempt: false,
            approvedAt: null,
            approvedBy: null,
            // ── Phase 1.5: Attack Protection ────────────────
            failedLoginAttempts: 0,
            lockUntil: null,
        };

        await userRef.set(userData);

        // Notification for admins
        await db.collection("notifications").add({
            type: "registration_request",
            title: "New registration request",
            body: `${name} from Flat ${flatNumber}${blockName ? ", Block " + blockName : ""} wants to join.`,
            targetRole: "main_admin",
            userId: userRef.id,
            read: false,
            createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
        });

        res.status(201).json({
            message: "Registration submitted. Please wait for admin approval before logging in.",
        });
    } catch (err) {
        logger.error({ ip: req.ip, error: err.message }, "Register error");
        res.status(500).json({ error: "Internal server error" });
    }
});

// ─── LOGIN ────────────────────────────────────────────────────────────────────
// POST /auth/login
// Body: { phone, password }
// SECURITY: Strictly validated via Zod schemas.
const DUMMY_HASH = "$2a$10$K9pYpYpYpYpYpYpYpYpYpOu9pYpYpYpYpYpYpYpYpYpYpYpYpYpYp"; // Placeholder hash for timing safety
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

router.post("/login", validate(LoginSchema), async (req, res) => {
    const { phone, password } = req.body;
    const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";

    try {
        const cleanPhone = phone.replace(/\s+/g, "");
        const db = getDb();

        // 1. Fetch user (one-shot lookup)
        const snap = await db.collection("users").where("phone", "==", cleanPhone).limit(1).get();
        const userDoc = snap.empty ? null : snap.docs[0];
        const user = userDoc ? userDoc.data() : null;

        // 2. Account Lockout Check
        if (user && user.lockUntil) {
            const lockUntil = user.lockUntil.toDate ? user.lockUntil.toDate() : new Date(user.lockUntil);
            if (new Date() < lockUntil) {
                logger.warn({ ip, userId: userDoc.id }, "SEC-FAIL: Login attempt on locked account");
                return res.status(401).json({ error: "Invalid phone number or password" }); // Masked lockout
            }
        }

        // 3. Progressive Delay Check
        if (user && user.failedLoginAttempts >= 3) {
            const delay = user.failedLoginAttempts === 3 ? 5000 : 30000;
            logger.info({ ip, userId: userDoc.id, attempts: user.failedLoginAttempts }, `SEC-WARN: Applying progressive delay of ${delay}ms`);
            await sleep(delay);
        }

        // 4. Constant-time Style Password Comparison
        const hashToCompare = user ? user.password : DUMMY_HASH;
        const passwordMatch = await bcrypt.compare(password, hashToCompare);

        // 5. Handle Failure
        if (!user || !passwordMatch) {
            if (user) {
                const newAttempts = (user.failedLoginAttempts || 0) + 1;
                const updates = { failedLoginAttempts: newAttempts };
                
                if (newAttempts >= 5) {
                    const lockTime = new Date(Date.now() + 15 * 60 * 1000); // 15 mins lock
                    updates.lockUntil = getAdmin().firestore.Timestamp.fromDate(lockTime);
                    logger.alert({ ip, userId: userDoc.id }, "SEC-ALERT: Account locked due to repeated failures");
                }
                
                await userDoc.ref.update(updates);
            }

            logger.warn({ ip, phone: cleanPhone }, "SEC-FAIL: Login attempt failed");
            return res.status(401).json({ error: "Invalid phone number or password" });
        }

        // 6. Verify Status ONLY after successful password match
        if (user.status === "pending") {
            return res.status(403).json({ 
                error: "Your account is pending admin approval. You will be notified once approved.",
                status: "pending"
            });
        }
        if (user.status === "rejected") {
            return res.status(403).json({ 
                error: "Your registration was not approved. Please contact the society admin.",
                status: "rejected"
            });
        }

        // Reset security counters on success
        await userDoc.ref.update({ failedLoginAttempts: 0, lockUntil: null });

        // 7. Issue JWT + Refresh Token
        const token = jwt.sign(
            { 
                uid: userDoc.id, 
                phone: user.phone, 
                role: user.role, 
                name: user.name,
                society_id: user.society_id
            },
            JWT_SECRET,
            { expiresIn: JWT_EXPIRES_IN }
        );

        const refreshToken = crypto.randomBytes(40).toString("hex");
        const refreshTokenHash = hashToken(refreshToken);

        await db.collection("refresh_tokens").doc(refreshTokenHash).set({
            userId: userDoc.id,
            expiresAt: getAdmin().firestore.Timestamp.fromDate(new Date(Date.now() + REFRESH_TOKEN_EXPIRES_IN)),
            revoked: false,
            createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
        });

        logger.info({ ip, userId: userDoc.id }, "Login successful with refresh token");

        const { password: _, ...safeUser } = user;
        res.json({ token, refreshToken, user: safeUser });

    } catch (err) {
        logger.error({ ip, error: err.message }, "Unhandled error during login");
        res.status(500).json({ error: "Internal server error" });
    }
});

// GET /auth/pending
router.get("/pending", authMiddleware, mainAdminOnly, async (req, res) => {
    try {
        const db = getDb();
        const societyId = req.user.society_id;
        
        // ❗ SEC FIX: Strict multi-tenant isolation
        const snap = await db
            .collection("users")
            .where("status", "==", "pending")
            .where("society_id", "==", societyId)
            .orderBy("createdAt", "asc")
            .get();

        const users = snap.docs.map((doc) => {
            const { password, ...safe } = doc.data();
            return { id: doc.id, ...safe };
        });

        res.json({ pending: users, count: users.length });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ─── ADMIN: APPROVE USER ──────────────────────────────────────────────────────
// POST /auth/approve/:uid
router.post("/approve/:uid", authMiddleware, mainAdminOnly, async (req, res) => {
    try {
        const db = getDb();
        const societyId = req.user.society_id;
        const userRef = db.collection("users").doc(req.params.uid);
        const userDoc = await userRef.get();

        if (!userDoc.exists) return res.status(404).json({ error: "User not found" });
        
        const userData = userDoc.data();
        
        // ❗ SEC FIX: Multi-tenant Assertion
        if (userData.society_id !== societyId && req.user.role !== "superadmin") {
            logger.fatal({ admin: req.user.uid, target: req.params.uid }, "SEC-CRITICAL: Cross-tenant approval attempt!");
            return res.status(403).json({ error: "Access Denied: User belongs to a different society." });
        }

        if (userData.status === "approved") {
            return res.status(400).json({ error: "User is already approved" });
        }

        await userRef.update({
            status: "approved",
            approvedAt: getAdmin().firestore.FieldValue.serverTimestamp(),
            approvedBy: req.user.uid,
        });

        await db.collection("notifications").add({
            type: "registration_approved",
            title: "Registration approved!",
            body: `Welcome to the society, ${userData.name}! You can now log in to the app.`,
            targetUserId: req.params.uid,
            society_id: societyId, // ❗ FIX: Ensures visibility in filtered feed
            read: false,
            createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
        });

        // Log the action
        await AuditLogService.getInstance().logAdminAction(
            req.user,
            "User Approved",
            `Approved ${userData.name} (Flat ${userData.flatNumber})`
        );

        // AI V2.4: Send push notification to the approved user
        const NotificationService = require("../services/notificationService");
        await NotificationService.sendToUser(req.params.uid, {
          title: "Registration Approved!",
          body: `Welcome ${userData.name}! Your account for ${userData.society_id} is now active.`,
          data: { type: "approval" }
        });

        res.json({ message: `${userData.name} has been approved and notified.` });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ─── ADMIN: REJECT USER ───────────────────────────────────────────────────────
// POST /auth/reject/:uid
router.post("/reject/:uid", authMiddleware, mainAdminOnly, async (req, res) => {
    try {
        const { reason } = req.body;
        const db = getDb();
        const societyId = req.user.society_id;
        const userRef = db.collection("users").doc(req.params.uid);
        const userDoc = await userRef.get();

        if (!userDoc.exists) return res.status(404).json({ error: "User not found" });
        
        const userData = userDoc.data();

        // ❗ SEC FIX: Multi-tenant Assertion
        if (userData.society_id !== societyId && req.user.role !== "superadmin") {
            logger.fatal({ admin: req.user.uid, target: req.params.uid }, "SEC-CRITICAL: Cross-tenant rejection attempt!");
            return res.status(403).json({ error: "Access Denied: User belongs to a different society." });
        }

        // ✅ BUG-01 FIX: Actually update the user status to 'rejected'
        await userRef.update({
            status: "rejected",
            rejectedAt: getAdmin().firestore.FieldValue.serverTimestamp(),
            rejectedBy: req.user.uid,
        });

        await db.collection("notifications").add({
            type: "registration_rejected",
            title: "Registration not approved",
            body: reason
                ? `Your registration was not approved. Reason: ${reason}`
                : "Your registration was not approved. Please contact the admin for more information.",
            targetUserId: req.params.uid,
            society_id: societyId, // ❗ FIX: Ensures visibility in filtered feed
            read: false,
            createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
        });

        // Log the action
        await AuditLogService.getInstance().logAdminAction(
            req.user,
            "User Rejected",
            `Rejected ${userData.name} (Flat ${userData.flatNumber}). Reason: ${reason || 'Not specified'}`
        );

        res.json({ message: `${userData.name}'s registration has been rejected.` });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// GET /auth/notifications
router.get("/notifications", authMiddleware, async (req, res) => {
    try {
        const db = getDb();
        const societyId = req.user.society_id;
        let snap;

        if (["superadmin", "main_admin", "treasurer", "secretary"].includes(req.user.role)) {
            // ❗ SEC FIX: Multi-tenant assertion
            snap = await db
                .collection("notifications")
                .where("targetRole", "==", "main_admin")
                .where("society_id", "==", societyId)
                .orderBy("createdAt", "desc")
                .limit(30)
                .get();
        } else {
            snap = await db
                .collection("notifications")
                .where("targetUserId", "==", req.user.uid)
                .where("society_id", "==", societyId)
                .orderBy("createdAt", "desc")
                .limit(30)
                .get();
        }

        const notifications = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
        res.json({ notifications });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ─── MARK NOTIFICATION AS READ ────────────────────────────────────────────────
// PATCH /auth/notifications/:id/read
router.patch("/notifications/:id/read", authMiddleware, async (req, res) => {
    try {
        const db = getDb();
        const docRef = db.collection("notifications").doc(req.params.id);
        const doc = await docRef.get();

        if (!doc.exists) return res.status(404).json({ error: "Notification not found" });

        // ✅ BUG-06 FIX: Correct ownership check — user must own the notification OR be an admin in the same society
        const data = doc.data();
        const isOwner = data.targetUserId === req.user.uid;
        const isAdmin = ["main_admin", "superadmin", "secretary"].includes(req.user.role) && data.society_id === req.user.society_id;

        if (!isOwner && !isAdmin) {
            logger.warn({ userId: req.user.uid, notificationId: req.params.id }, "SEC-WARN: Unauthorized notification mark-read attempt");
            return res.status(403).json({ error: "Unauthorized access to notification" });
        }

        await docRef.update({ read: true });
        res.json({ message: "Marked as read" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
