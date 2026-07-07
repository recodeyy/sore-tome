/**
 * Seed Firestore login identities for the Hubtown Sunkist demo accounts
 * (password 123456). Dev/demo only. Mirrors hash_and_set.js / seed_test_logins.js.
 *
 * Pairs with the Postgres rows seeded by scripts/seed_hubtown_sunkist.js:
 * the Firestore doc id equals the Postgres members/staff user_id, so
 * POST /auth/login resolves the correct workspace via getUserDestinations.
 *
 *   node scripts/seed_hubtown_sunkist_logins.js
 *
 * Logins (password 123456):
 *   admin    9200000001  → portal "admin"     (sunkist-admin-001, main_admin)
 *   resident 9200000002  → portal "resident"  (sunkist-res-001, A-1402)
 *   guard    9200000003  → portal "staff"     (sunkist-guard-001, guard)
 */
const admin = require("firebase-admin");
const bcrypt = require("bcryptjs");
const serviceAccount = require("../config/serviceAccountKey.json");

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const SOC = "hubtown-sunkist";

async function run() {
  const hash = await bcrypt.hash("123456", 10);
  const now = admin.firestore.FieldValue.serverTimestamp();

  const users = [
    {
      id: "sunkist-admin-001",
      doc: { uid: "sunkist-admin-001", name: "Sunkist Main Admin", phone: "9200000001", role: "main_admin" },
    },
    {
      id: "sunkist-res-001",
      doc: { uid: "sunkist-res-001", name: "Avinash (A-1402)", phone: "9200000002", role: "resident", flatNumber: "A-1402" },
    },
    {
      id: "sunkist-guard-001",
      doc: { uid: "sunkist-guard-001", name: "Bahadur (Gate Guard)", phone: "9200000003", role: "guard" },
    },
  ];

  for (const u of users) {
    await db.collection("users").doc(u.id).set(
      {
        ...u.doc,
        society_id: SOC,
        password: hash,
        status: "approved",
        failedLoginAttempts: 0,
        lockUntil: null,
        createdAt: now,
        updatedAt: now,
      },
      { merge: true }
    );
    console.log(`Seeded Firestore login ${u.id} (${u.doc.phone}, ${u.doc.role})`);
  }

  console.log("Done. Password for all three: 123456");
  process.exit(0);
}

run().catch((e) => {
  console.error("SEED LOGIN ERROR:", e.message);
  process.exit(1);
});
