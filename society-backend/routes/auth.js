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
const { db } = require("../src/shared/Database");

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = "1h";
const REFRESH_TOKEN_EXPIRES_IN = 7 * 24 * 60 * 60 * 1000; // 7 days in ms

const hashToken = (token) => crypto.createHash("sha256").update(token).digest("hex");

// ─── PHONE NORMALIZATION ────────────────────────────────────────────────────────
// BUGFIX: registration stored the phone verbatim (only spaces stripped) and login
// did an exact-match lookup, so a number registered as "+919876543210" could NOT
// be found when the user typed "9876543210" (or vice-versa) → "Invalid phone number
// or password" for admin/staff/resident alike. These helpers reconcile the common
// Indian formats (with/without +91, leading 0, punctuation) so login works no
// matter which form was stored, without needing a data migration.

/** Canonical storage form: "+91XXXXXXXXXX" for a 10-digit Indian number, else
 *  "+<digits>" for an already-international number, else the cleaned input. */
function canonicalPhone(raw) {
  if (!raw) return "";
  const cleaned = String(raw).trim().replace(/[\s\-().]/g, "");
  const digits = cleaned.replace(/\D/g, "");
  const last10 = digits.slice(-10);
  if (digits.length === 10) return "+91" + digits;
  if (digits.length === 12 && digits.startsWith("91")) return "+" + digits;
  if (digits.length === 11 && digits.startsWith("0")) return "+91" + last10;
  if (digits.length >= 10) return "+" + digits;
  return cleaned;
}

/** All plausible stored forms for a typed number, so a Firestore `in` lookup
 *  matches regardless of how the account was originally saved. Firestore caps
 *  `in` at 10 values, so we return at most 10. */
function phoneCandidates(raw) {
  const set = new Set();
  const add = (v) => { if (v && /\d/.test(v)) set.add(v); };
  const trimmed = String(raw || "").trim();
  const cleaned = trimmed.replace(/[\s\-().]/g, "");
  add(cleaned);
  const digits = cleaned.replace(/\D/g, "");
  add(digits);
  add("+" + digits);
  const last10 = digits.slice(-10);
  if (last10.length === 10) {
    add(last10);            // 9876543210
    add("0" + last10);      // 09876543210
    add("91" + last10);     // 919876543210
    add("+91" + last10);    // +919876543210
  }
  const candidates = Array.from(set).slice(0, 10);
  // Non-numeric identifiers (e.g. the "superadmin" username login) have no digit
  // candidates. Firestore `in` rejects an empty array, so fall back to an exact
  // match on the raw trimmed value to keep username-style logins working.
  return candidates.length ? candidates : [trimmed];
}

/** Normalize a free-typed society name to a stable partition key: trim, collapse
 *  internal whitespace and uppercase, so "Hubtown Sunkist", " hubtown  sunkist "
 *  all map to "HUBTOWN SUNKIST". Does not fix genuine misspellings. */
function canonicalSociety(raw) {
  return String(raw || "").trim().replace(/\s+/g, " ").toUpperCase();
}

function slugSociety(raw) {
  return String(raw || "").trim().toLowerCase().replace(/\s+/g, "-");
}

/**
 * Resolve client-supplied society text to an EXISTING tenant id when any
 * spelling variant of it already has users (slug > as-typed > legacy UPPER),
 * so a registration joins the society its admin/staff accounts already use
 * instead of minting a new spelling variant (the "HUBTOWN SUNKIST" vs
 * "hubtown-sunkist" split: admin and residents could never see each other).
 * Brand-new societies get the slug form — the seed/staff convention.
 */
async function resolveSocietyId(db, raw) {
  const exact = String(raw || "").trim().replace(/\s+/g, " ");
  if (!exact) return "";
  const candidates = [...new Set([slugSociety(exact), exact, canonicalSociety(exact)])];
  const snap = await db.collection("users").where("society_id", "in", candidates).limit(50).get();
  const present = new Set(snap.docs.map((d) => d.data().society_id));
  for (const c of candidates) if (present.has(c)) return c;
  return slugSociety(exact);
}

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
        const { name, phone, password, flatNumber, blockName } = req.body;

        // BUGFIX: store one canonical phone form and check duplicates across all
        // formats, so the account can always be found at login regardless of how
        // the number is typed later.
        const cleanPhone = canonicalPhone(phone);
        const db = getDb();

        // Join an existing society id when any spelling variant already has
        // users; otherwise mint the slug form. (Genuine typos, e.g. "SUNMIST"
        // vs "SUNKIST", still diverge — the real fix remains an app-side
        // society picker with stable IDs.)
        const society_id = await resolveSocietyId(db, req.body.society_id);

        // Check duplicate phone (across every equivalent format)
        const existing = await db.collection("users").where("phone", "in", phoneCandidates(phone)).limit(1).get();
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

// ─── HELPER FUNCTIONS FOR SEPARATE PORTALS & WORKSPACES ──────────────────────────
async function getUserDestinations(uid, phone) {
    const destinations = [];
    const cleanPhone = phone ? phone.replace(/\s+/g, "") : "";
    
    // 1. Query Postgres members
    try {
        const membersRes = await db.query(
            `SELECT m.*, sa.society_name 
             FROM members m 
             LEFT JOIN society_applications sa ON sa.society_id = m.society_id 
             WHERE m.user_id = $1 OR m.phone = $2`,
            [uid, cleanPhone]
        );
        for (const row of membersRes.rows) {
            if (["moved_out", "deactivated", "rejected"].includes(row.status)) {
                continue;
            }
            const normalizedRole = (row.role || "").trim().toLowerCase().replaceAll("-", "_");
            const isAdmin = ["main_admin", "admin", "secretary", "treasurer", "committee_member"].includes(normalizedRole);
            
            destinations.push({
                workspaceId: isAdmin ? `admin-${row.society_id}` : `resident-${row.society_id}-${row.id}`,
                type: isAdmin ? "admin" : "resident",
                role: row.role || (isAdmin ? "admin" : "resident_owner"),
                societyId: row.society_id,
                societyName: row.society_name || row.society_id || "My Society",
                unitId: row.unit_id || null,
                status: row.status
            });
        }
    } catch (err) {
        logger.warn({ uid, error: err.message }, "Failed to fetch pg memberships for workspaces");
    }

    // 2. Query Postgres staff
    try {
        const staffRes = await db.query(
            `SELECT s.*, sa.society_name 
             FROM staff s 
             LEFT JOIN society_applications sa ON sa.society_id = s.society_id 
             WHERE s.user_id = $1 OR s.phone = $2`,
            [uid, cleanPhone]
        );
        for (const row of staffRes.rows) {
            if (row.status === "terminated") {
                continue;
            }
            destinations.push({
                workspaceId: `staff-${row.society_id}-${row.id}`,
                type: "staff",
                role: row.role || "guard",
                societyId: row.society_id,
                societyName: row.society_name || row.society_id || "My Society",
                status: row.status === "active" ? "approved" : "suspended"
            });
        }
    } catch (err) {
        logger.warn({ uid, error: err.message }, "Failed to fetch pg staff for workspaces");
    }

    return destinations;
}

function addFirestoreDestinations(user, destinations) {
    const normalizedRole = (user.role || "").trim().toLowerCase().replaceAll("-", "_");

    if (["super_admin", "superadmin"].includes(normalizedRole)) {
        if (!destinations.some(d => d.type === "super-admin")) {
            destinations.push({
                workspaceId: "platform-super-admin",
                type: "super-admin",
                role: "super_admin",
                societyId: "platform",
                societyName: "SERO Platform Control",
                status: "approved"
            });
        }
        return;
    }

    // FIND-001 fix: Postgres members/staff are the source of truth for which
    // society a user belongs to. When the user already has ANY real Postgres
    // membership (member or staff), do NOT synthesize an extra Firestore-derived
    // admin/resident workspace from the (often stale) `users.society_id` field.
    // Doing so would surface a phantom workspace (e.g. demo-soc-1), force needless
    // workspace selection, and risk scoping the token to the wrong society.
    // Firestore-derived workspaces are kept ONLY for users with no Postgres
    // membership yet (e.g. a brand-new approved user) so they still have a
    // destination to land on.
    const hasPgMembership = destinations.some(d => d.type === "admin" || d.type === "resident" || d.type === "staff");
    if (hasPgMembership) {
        return;
    }

    if (["main_admin", "admin", "secretary", "treasurer", "committee_member"].includes(normalizedRole)) {
        if (user.society_id && !destinations.some(d => d.type === "admin" && d.societyId === user.society_id)) {
            destinations.push({
                workspaceId: `admin-${user.society_id}`,
                type: "admin",
                role: user.role,
                societyId: user.society_id,
                societyName: user.society_id || "My Society",
                status: user.status || "approved"
            });
        }
    } else if (["guard", "security_manager", "facility_manager", "supervisor", "maintenance_staff", "housekeeping_staff", "reception_staff", "parcel_desk_staff", "staff"].includes(normalizedRole)) {
        // Staff/security users whose login lives in Firestore but who have no
        // Postgres `staff` row yet (e.g. seeded demo guards) still need a staff
        // destination, otherwise the staff portal check returns PORTAL_MISMATCH.
        if (user.society_id && !destinations.some(d => d.type === "staff" && d.societyId === user.society_id)) {
            destinations.push({
                workspaceId: `staff-${user.society_id}`,
                type: "staff",
                role: user.role,
                societyId: user.society_id,
                societyName: user.society_id || "My Society",
                status: user.status || "approved"
            });
        }
    } else if (normalizedRole === "resident") {
        if (user.society_id && !destinations.some(d => d.type === "resident" && d.societyId === user.society_id)) {
            destinations.push({
                workspaceId: `resident-${user.society_id}`,
                type: "resident",
                role: "resident_owner",
                societyId: user.society_id,
                societyName: user.society_id || "My Society",
                status: user.status || "pending"
            });
        }
    }
}

// ─── FIREBASE / GOOGLE SIGN-IN + SIGN-UP ────────────────────────────────────────
// POST /auth/firebase
// Body: { idToken, portal? }
// Verifies a Firebase ID token (Google, Phone, etc.), provisions the user on
// first sign-in (sign-up), and issues the same app session as /auth/login.
router.post("/firebase", async (req, res) => {
    const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";
    const { idToken, portal } = req.body || {};

    if (!idToken || typeof idToken !== "string") {
        return res.status(400).json({ error: "Missing Firebase idToken" });
    }

    try {
        // 1. Verify the Firebase ID token with the Admin SDK (authoritative).
        let decoded;
        try {
            decoded = await getAdmin().auth().verifyIdToken(idToken);
        } catch (e) {
            logger.warn({ ip, error: e.message }, "SEC-FAIL: Invalid Firebase ID token");
            return res.status(401).json({ error: "Invalid or expired Google session" });
        }

        const email = (decoded.email || "").trim().toLowerCase();
        const cleanPhone = (decoded.phone_number || "").replace(/\s+/g, "");
        const displayName = decoded.name || (email ? email.split("@")[0] : "Member");
        const fDb = getDb();

        // 2. Find an existing user by email or phone.
        let snap = null;
        if (email) {
            snap = await fDb.collection("users").where("email", "==", email).limit(1).get();
        }
        if ((!snap || snap.empty) && cleanPhone) {
            snap = await fDb.collection("users").where("phone", "==", cleanPhone).limit(1).get();
        }

        let userDoc = snap && !snap.empty ? snap.docs[0] : null;
        let user;

        // 3. First-time Google user → sign up (no password; provisioned pending).
        if (!userDoc) {
            const userRef = fDb.collection("users").doc();
            const userData = {
                uid: userRef.id,
                name: displayName,
                email: email || null,
                phone: cleanPhone || null,
                password: null,            // social account — no local password
                authProvider: "google",
                firebaseUid: decoded.uid,
                flatNumber: "",
                blockName: "",
                society_id: null,
                role: "resident",
                status: "pending",         // requires admin approval, like /register
                createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
                residentType: "owner",
                maintenanceExempt: false,
                approvedAt: null,
                approvedBy: null,
                failedLoginAttempts: 0,
                lockUntil: null,
            };
            await userRef.set(userData);
            userDoc = await userRef.get();
            user = userDoc.data();

            await fDb.collection("notifications").add({
                type: "registration_request",
                title: "New Google sign-up",
                body: `${displayName} signed up with Google and is awaiting approval.`,
                targetRole: "main_admin",
                userId: userRef.id,
                read: false,
                createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
            });
        } else {
            user = userDoc.data();
            // Backfill the firebaseUid/provider link for existing accounts.
            if (!user.firebaseUid) {
                await userDoc.ref.update({ firebaseUid: decoded.uid, authProvider: user.authProvider || "google" });
            }
        }

        // 4. Status gates (mirror /login).
        if (user.status === "pending" && !portal) {
            return res.status(403).json({ error: "Your account is pending admin approval.", status: "pending" });
        }
        if (user.status === "rejected" && !portal) {
            return res.status(403).json({ error: "Your registration was not approved.", status: "rejected" });
        }

        // 5. Resolve destinations + portal check (mirror /login).
        const destinations = await getUserDestinations(userDoc.id, user.phone || "");
        addFirestoreDestinations(user, destinations);

        if (portal) {
            const matching = destinations.filter(d => d.type === portal);
            if (matching.length === 0) {
                return res.status(403).json({
                    success: false,
                    error: {
                        code: "PORTAL_MISMATCH",
                        message: "This account does not have access to the selected portal.",
                        allowedPortals: [...new Set(destinations.map(d => d.type))]
                    }
                });
            }
        }

        const filteredDestinations = portal ? destinations.filter(d => d.type === portal) : destinations;
        const requiresWorkspaceSelection = filteredDestinations.length > 1;

        let activeWorkspace = null;
        let finalRole = user.role;
        let finalSocietyId = user.society_id;
        if (!requiresWorkspaceSelection && filteredDestinations.length === 1) {
            activeWorkspace = filteredDestinations[0];
            finalRole = activeWorkspace.role;
            finalSocietyId = activeWorkspace.societyId;
        }
        // Firestore + Firebase custom-token claims reject `undefined` (platform/
        // admin accounts may have no society). Normalize to null.
        finalSocietyId = finalSocietyId ?? null;

        // 6. Issue app JWT + refresh token (same as /login).
        const token = jwt.sign(
            { uid: userDoc.id, phone: user.phone, role: finalRole, name: user.name, society_id: finalSocietyId },
            JWT_SECRET,
            { expiresIn: JWT_EXPIRES_IN }
        );
        const refreshToken = crypto.randomBytes(40).toString("hex");
        const refreshTokenHash = hashToken(refreshToken);
        await fDb.collection("refresh_tokens").doc(refreshTokenHash).set({
            userId: userDoc.id,
            expiresAt: getAdmin().firestore.Timestamp.fromDate(new Date(Date.now() + REFRESH_TOKEN_EXPIRES_IN)),
            revoked: false,
            createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
            role: finalRole,
            society_id: finalSocietyId
        });

        let firebaseToken = null;
        try {
            firebaseToken = await getAdmin().auth().createCustomToken(userDoc.id, { role: finalRole, society_id: finalSocietyId });
        } catch (e) {
            logger.warn({ userId: userDoc.id }, "Firebase custom token generation failed (non-fatal)");
        }

        logger.info({ ip, userId: userDoc.id }, "Firebase/Google sign-in successful");

        const { password: _pw, ...safeUser } = user;
        // Surface the active-workspace scope (staff/guard docs lack society_id).
        safeUser.society_id = safeUser.society_id ?? finalSocietyId ?? null;
        safeUser.role = finalRole ?? safeUser.role;
        const responseData = {
            token,
            refreshToken,
            firebaseToken,
            user: safeUser,
            requiresWorkspaceSelection,
            activeWorkspace,
            destinations: filteredDestinations
        };
        res.json({ success: true, data: responseData, ...responseData });

    } catch (err) {
        logger.error({ ip, error: err.message }, "Unhandled error during Firebase sign-in");
        res.status(500).json({ error: "Internal server error" });
    }
});

// ─── LOGIN ────────────────────────────────────────────────────────────────────
// POST /auth/login
// Body: { phone, password, portal }
// SECURITY: Strictly validated via Zod schemas.
const DUMMY_HASH = "$2a$10$K9pYpYpYpYpYpYpYpYpYpOu9pYpYpYpYpYpYpYpYpYpYpYpYpYpYp"; // Placeholder hash for timing safety
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

router.post("/login", validate(LoginSchema), async (req, res) => {
    const { phone, password, portal } = req.body;
    const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";

    try {
        const cleanPhone = phone.replace(/\s+/g, "");
        const fDb = getDb();

        // 1. Fetch user (one-shot lookup by phone or email)
        // BUGFIX: match across all common phone formats (with/without +91, leading
        // 0, punctuation) so a number stored in a different form still logs in.
        let snap;
        if (phone.includes("@")) {
            snap = await fDb.collection("users").where("email", "==", phone.trim().toLowerCase()).limit(1).get();
        } else {
            snap = await fDb.collection("users").where("phone", "in", phoneCandidates(phone)).limit(1).get();
        }
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
        if (user.status === "pending" && !portal) {
            return res.status(403).json({ 
                error: "Your account is pending admin approval. You will be notified once approved.",
                status: "pending"
            });
        }
        if (user.status === "rejected" && !portal) {
            return res.status(403).json({ 
                error: "Your registration was not approved. Please contact the society admin.",
                status: "rejected"
            });
        }

        // Reset security counters on success
        await userDoc.ref.update({ failedLoginAttempts: 0, lockUntil: null });

        // Resolve destinations and check portal mismatch
        const destinations = await getUserDestinations(userDoc.id, user.phone);
        addFirestoreDestinations(user, destinations);

        if (portal) {
            const matching = destinations.filter(d => d.type === portal);
            if (matching.length === 0) {
                logger.warn({ ip, userId: userDoc.id, portal }, "Portal mismatch detected");
                return res.status(403).json({
                    success: false,
                    error: {
                        code: "PORTAL_MISMATCH",
                        message: `This account does not have access to the selected portal.`,
                        allowedPortals: [...new Set(destinations.map(d => d.type))]
                    }
                });
            }
        }

        const filteredDestinations = portal ? destinations.filter(d => d.type === portal) : destinations;
        const requiresWorkspaceSelection = filteredDestinations.length > 1;

        let activeWorkspace = null;
        let finalRole = user.role;
        let finalSocietyId = user.society_id;

        if (!requiresWorkspaceSelection && filteredDestinations.length === 1) {
            activeWorkspace = filteredDestinations[0];
            finalRole = activeWorkspace.role;
            finalSocietyId = activeWorkspace.societyId;
        }
        // Firestore + Firebase custom-token claims reject `undefined` (platform/
        // admin accounts may have no society). Normalize to null.
        finalSocietyId = finalSocietyId ?? null;

        // 7. Issue JWT + Refresh Token (scoped if singular workspace resolved)
        const token = jwt.sign(
            { 
                uid: userDoc.id, 
                phone: user.phone, 
                role: finalRole, 
                name: user.name,
                society_id: finalSocietyId
            },
            JWT_SECRET,
            { expiresIn: JWT_EXPIRES_IN }
        );

        const refreshToken = crypto.randomBytes(40).toString("hex");
        const refreshTokenHash = hashToken(refreshToken);

        await fDb.collection("refresh_tokens").doc(refreshTokenHash).set({
            userId: userDoc.id,
            expiresAt: getAdmin().firestore.Timestamp.fromDate(new Date(Date.now() + REFRESH_TOKEN_EXPIRES_IN)),
            revoked: false,
            createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
            role: finalRole,
            society_id: finalSocietyId
        });

        logger.info({ ip, userId: userDoc.id }, "Login successful with refresh token");

        // Generate Firebase custom token so Flutter can sign into Firebase Auth
        let firebaseToken = null;
        try {
            firebaseToken = await getAdmin().auth().createCustomToken(userDoc.id, {
                role: finalRole,
                society_id: finalSocietyId,
            });
        } catch (e) {
            logger.warn({ userId: userDoc.id }, "Firebase custom token generation failed (non-fatal)");
        }

        const { password: _, ...safeUser } = user;
        // Surface the active-workspace scope (staff/guard docs lack society_id).
        safeUser.society_id = safeUser.society_id ?? finalSocietyId ?? null;
        safeUser.role = finalRole ?? safeUser.role;
        const responseData = {
            token,
            refreshToken,
            firebaseToken,
            user: safeUser,
            requiresWorkspaceSelection,
            activeWorkspace,
            destinations: filteredDestinations
        };
        res.json({
            success: true,
            data: responseData,
            ...responseData
        });

    } catch (err) {
        logger.error({ ip, error: err.message }, "Unhandled error during login");
        res.status(500).json({ error: "Internal server error" });
    }
});

// ─── WORKSPACE SELECTION ENDPOINTS ──────────────────────────────────────────────
router.post("/workspace/select", authMiddleware, async (req, res) => {
    const { workspaceId } = req.body;
    const uid = req.user.uid;
    const phone = req.user.phone;
    const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";

    try {
        const db = getDb();
        const userDoc = await db.collection("users").doc(uid).get();
        if (!userDoc.exists) {
            return res.status(404).json({ success: false, error: "User not found" });
        }
        const user = userDoc.data();

        const destinations = await getUserDestinations(uid, phone);
        addFirestoreDestinations(user, destinations);

        const activeWorkspace = destinations.find(d => d.workspaceId === workspaceId);
        if (!activeWorkspace) {
            logger.warn({ ip, userId: uid, workspaceId }, "SEC-WARN: Unauthorized workspace selection attempt");
            return res.status(403).json({ success: false, error: "Unauthorized access to selected workspace" });
        }

        // Issue new scoped JWT + custom token
        const token = jwt.sign(
            { 
                uid, 
                phone, 
                role: activeWorkspace.role, 
                name: user.name,
                society_id: activeWorkspace.societyId
            },
            JWT_SECRET,
            { expiresIn: JWT_EXPIRES_IN }
        );

        const refreshToken = crypto.randomBytes(40).toString("hex");
        const refreshTokenHash = hashToken(refreshToken);

        await db.collection("refresh_tokens").doc(refreshTokenHash).set({
            userId: uid,
            expiresAt: getAdmin().firestore.Timestamp.fromDate(new Date(Date.now() + REFRESH_TOKEN_EXPIRES_IN)),
            revoked: false,
            createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
            role: activeWorkspace.role,
            society_id: activeWorkspace.societyId
        });

        let firebaseToken = null;
        try {
            firebaseToken = await getAdmin().auth().createCustomToken(uid, {
                role: activeWorkspace.role,
                society_id: activeWorkspace.societyId,
            });
        } catch (e) {
            logger.warn({ userId: uid }, "Firebase custom token generation failed during workspace select");
        }

        logger.info({ ip, userId: uid, workspaceId }, "Workspace selected successfully");
        res.json({
            success: true,
            data: {
                token,
                refreshToken,
                firebaseToken,
                activeWorkspace
            }
        });

    } catch (err) {
        logger.error({ ip, error: err.message }, "Error during workspace selection");
        res.status(500).json({ error: "Internal server error" });
    }
});

router.post("/workspace/switch", authMiddleware, async (req, res) => {
    // Switch acts identically to select but is routed appropriately
    const { workspaceId } = req.body;
    const uid = req.user.uid;
    const phone = req.user.phone;
    const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";

    try {
        const db = getDb();
        const userDoc = await db.collection("users").doc(uid).get();
        if (!userDoc.exists) {
            return res.status(404).json({ success: false, error: "User not found" });
        }
        const user = userDoc.data();

        const destinations = await getUserDestinations(uid, phone);
        addFirestoreDestinations(user, destinations);

        const activeWorkspace = destinations.find(d => d.workspaceId === workspaceId);
        if (!activeWorkspace) {
            logger.warn({ ip, userId: uid, workspaceId }, "SEC-WARN: Unauthorized workspace switch attempt");
            return res.status(403).json({ success: false, error: "Unauthorized access to selected workspace" });
        }

        // Issue new scoped JWT + custom token
        const token = jwt.sign(
            { 
                uid, 
                phone, 
                role: activeWorkspace.role, 
                name: user.name,
                society_id: activeWorkspace.societyId
            },
            JWT_SECRET,
            { expiresIn: JWT_EXPIRES_IN }
        );

        const refreshToken = crypto.randomBytes(40).toString("hex");
        const refreshTokenHash = hashToken(refreshToken);

        await db.collection("refresh_tokens").doc(refreshTokenHash).set({
            userId: uid,
            expiresAt: getAdmin().firestore.Timestamp.fromDate(new Date(Date.now() + REFRESH_TOKEN_EXPIRES_IN)),
            revoked: false,
            createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
            role: activeWorkspace.role,
            society_id: activeWorkspace.societyId
        });

        let firebaseToken = null;
        try {
            firebaseToken = await getAdmin().auth().createCustomToken(uid, {
                role: activeWorkspace.role,
                society_id: activeWorkspace.societyId,
            });
        } catch (e) {
            logger.warn({ userId: uid }, "Firebase custom token generation failed during workspace switch");
        }

        logger.info({ ip, userId: uid, workspaceId }, "Workspace switched successfully");
        res.json({
            success: true,
            data: {
                token,
                refreshToken,
                firebaseToken,
                activeWorkspace
            }
        });

    } catch (err) {
        logger.error({ ip, error: err.message }, "Error during workspace switch");
        res.status(500).json({ error: "Internal server error" });
    }
});

// GET /auth/firebase-token — re-issue a Firebase custom token for an active JWT session
// Used on app restart so the Firestore SDK can re-authenticate.
router.get("/firebase-token", authMiddleware, async (req, res) => {
    try {
        const firebaseToken = await getAdmin().auth().createCustomToken(req.user.uid, {
            role: req.user.role,
            society_id: req.user.society_id,
        });
        res.json({ firebaseToken });
    } catch (err) {
        logger.error({ userId: req.user.uid, error: err.message }, "Firebase token re-issue failed");
        res.status(500).json({ error: "Could not issue Firebase token" });
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
            .get();

        const toMillis = (v) => (v && v.toMillis) ? v.toMillis() : 0;
        const users = snap.docs.map((doc) => {
            const { password, ...safe } = doc.data();
            return { id: doc.id, ...safe };
        }).sort((a, b) => toMillis(a.createdAt) - toMillis(b.createdAt));

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

        // Mirror the approval into the Postgres members directory. The admin
        // website's Members & Tenants (and finance/notification recipient
        // resolution) read Postgres `members`, while app registrations live in
        // Firestore `users` — without this upsert an approved resident never
        // appears on the website. Best-effort: a Postgres hiccup must not
        // block the approval itself.
        try {
            const { db: pg } = require("../src/shared/Database");
            await pg.query(
                `INSERT INTO members (society_id, user_id, name, phone, email, status, role)
                 SELECT $1, $2, $3, $4, $5, 'approved', $6
                  WHERE NOT EXISTS (SELECT 1 FROM members WHERE society_id = $1 AND user_id = $2)`,
                [societyId, req.params.uid, userData.name || "Resident",
                 userData.phone || null, userData.email || null, userData.role || "resident"]
            );
            await pg.query(
                `UPDATE members SET status = 'approved', updated_at = now()
                  WHERE society_id = $1 AND user_id = $2`,
                [societyId, req.params.uid]
            );
        } catch (e) {
            logger.warn({ uid: req.params.uid, error: e.message }, "Postgres members mirror failed (non-fatal)");
        }

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
                .limit(100)
                .get();
        } else {
            snap = await db
                .collection("notifications")
                .where("targetUserId", "==", req.user.uid)
                .where("society_id", "==", societyId)
                .limit(100)
                .get();
        }

        const toMillis = (v) => (v && v.toMillis) ? v.toMillis() : 0;
        const notifications = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }))
            .sort((a, b) => toMillis(b.createdAt) - toMillis(a.createdAt))
            .slice(0, 30);
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
