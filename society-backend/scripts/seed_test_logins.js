/**
 * Seed Firestore login identities for the staff + super-admin TEST accounts
 * (password 123456). Dev/test only. Mirrors hash_and_set.js.
 *
 *   node scripts/seed_test_logins.js
 *
 * Pairs with the Postgres `staff` row seeded by seed_hubtown_sunmist-style insert.
 */
const admin = require("firebase-admin");
const bcrypt = require("bcryptjs");
const serviceAccount = require("../config/serviceAccountKey.json");

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function run() {
  const hash = await bcrypt.hash("123456", 10);

  // Staff / Security (guard). Society resolved from the Postgres `staff` row.
  await db.collection("users").doc("staff-guard-001").set(
    {
      name: "Ramesh (Gate Guard)",
      phone: "9000000001",
      password: hash,
      role: "guard",
      status: "active",
      failedLoginAttempts: 0,
      lockUntil: null,
    },
    { merge: true }
  );

  // Super Admin (platform). Role drives the platform workspace; no society.
  await db.collection("users").doc("superadmin-001").set(
    {
      name: "Platform Super Admin",
      phone: "superadmin",
      password: hash,
      role: "super_admin",
      status: "active",
      failedLoginAttempts: 0,
      lockUntil: null,
    },
    { merge: true }
  );

  console.log("Seeded Firestore logins: staff-guard-001 (9000000001), superadmin-001 (superadmin) — pwd 123456");
  process.exit(0);
}

run().catch((e) => {
  console.error("SEED LOGIN ERROR:", e.message);
  process.exit(1);
});
