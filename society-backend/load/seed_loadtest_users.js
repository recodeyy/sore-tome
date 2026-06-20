// Seed throwaway load-test users that match the k6 auth_ramp defaults exactly.
//
// These accounts exist ONLY to let the load suite log in and obtain real JWTs.
// They are NObody's real account: phone = `${PHONE_PREFIX}${n}` (zero-padded),
// all sharing one password, flagged `isLoadTest: true` so they can be wiped.
//
// Convention MUST match load/k6_auth_ramp.js defaults:
//   PHONE_PREFIX=+9190000  PHONE_PAD=5  PASSWORD=LoadTest@123
// → +919000000000 .. +919000009999  (status: approved, role: resident)
//
// Usage:
//   node load/seed_loadtest_users.js                 # seed USER_COUNT users
//   node load/seed_loadtest_users.js --cleanup       # delete all isLoadTest users
//   USER_COUNT=10000 SOCIETY_ID=loadtest-society node load/seed_loadtest_users.js
//
// SAFETY: refuses to run when NODE_ENV=production unless --force is passed.
// Point it at a STAGING Firebase project (config/serviceAccountKey.json), never prod.

const admin = require("firebase-admin");
const bcrypt = require("bcryptjs");

const args = process.argv.slice(2);
const CLEANUP = args.includes("--cleanup");
const FORCE = args.includes("--force");
const countArg = args.find((a) => a.startsWith("--count="));
const COUNT_OVERRIDE = countArg ? parseInt(countArg.split("=")[1], 10) : null;

if (process.env.NODE_ENV === "production" && !FORCE) {
  console.error("❌ Refusing to seed load-test users with NODE_ENV=production. Use a staging project, or pass --force if you are certain.");
  process.exit(1);
}

const serviceAccount = require("../config/serviceAccountKey.json");
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// Must mirror k6_auth_ramp.js.
const PHONE_PREFIX = process.env.PHONE_PREFIX || "+9190000";
const PHONE_PAD = parseInt(process.env.PHONE_PAD || "5", 10);
const USER_COUNT = COUNT_OVERRIDE || parseInt(process.env.USER_COUNT || "1000", 10);
const PASSWORD = process.env.PASSWORD || "LoadTest@123";
const SOCIETY_ID = process.env.SOCIETY_ID || "loadtest-society";

const phoneFor = (n) => PHONE_PREFIX + String(n).padStart(PHONE_PAD, "0");
const BATCH = 400; // Firestore batch limit is 500; stay under.

async function cleanup() {
  console.log("Deleting all isLoadTest users…");
  let total = 0;
  // Page through the flagged users and delete in batches.
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const snap = await db.collection("users").where("isLoadTest", "==", true).limit(BATCH).get();
    if (snap.empty) break;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    total += snap.size;
    console.log(`  deleted ${total}…`);
  }
  console.log(`✅ Cleanup complete. Removed ${total} load-test users.`);
}

async function seed() {
  console.log(`Seeding ${USER_COUNT} load-test users: ${phoneFor(0)} .. ${phoneFor(USER_COUNT - 1)}`);
  const passwordHash = await bcrypt.hash(PASSWORD, 10);
  let written = 0;

  for (let start = 0; start < USER_COUNT; start += BATCH) {
    const batch = db.batch();
    const end = Math.min(start + BATCH, USER_COUNT);
    for (let n = start; n < end; n++) {
      const phone = phoneFor(n);
      const ref = db.collection("users").doc(`loadtest_${phone}`); // deterministic id → idempotent re-seed
      batch.set(ref, {
        uid: `loadtest_${phone}`,
        name: `LoadTest User ${n}`,
        phone,                       // EXACT string k6 sends as login phone
        password: passwordHash,
        flatNumber: `LT-${n}`,
        blockName: "LT",
        society_id: SOCIETY_ID,
        role: "resident",
        status: "approved",          // approved → login succeeds without portal
        residentType: "owner",
        maintenanceExempt: false,
        failedLoginAttempts: 0,
        lockUntil: null,
        isLoadTest: true,            // marker for --cleanup
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    written += end - start;
    console.log(`  seeded ${written}/${USER_COUNT}…`);
  }
  console.log(`✅ Seeded ${written} users. Password: "${PASSWORD}" | society_id: "${SOCIETY_ID}"`);
  console.log(`Run load with:  k6 run -e BASE_URL=<staging> -e PHONE_PREFIX=${PHONE_PREFIX} -e USER_COUNT=${USER_COUNT} -e PASSWORD='${PASSWORD}' load/k6_10k.js`);
}

(CLEANUP ? cleanup() : seed())
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("Error:", err.message);
    process.exit(1);
  });
