const dotenv = require("dotenv");
const path = require("path");

// Load local environment files if present
dotenv.config({ path: path.join(__dirname, "../.env") });

const { getDb, getAdmin } = require("../config/firebase");
const bcrypt = require("bcryptjs");

async function seed() {
  const db = getDb();
  const password = process.env.DEMO_USER_PASSWORD || "SeroDemoPassword123!";
  const hashedPassword = await bcrypt.hash(password, 10);

  console.log("🌱 Seeding Demo Society and User Accounts...");

  // 1. Create Demo Society
  await db.collection("societies").doc("SERO_DEMO").set({
    id: "SERO_DEMO",
    name: "Sero Demo Society",
    createdAt: new Date(),
  }, { merge: true });
  console.log("✅ Seeded Society 'SERO_DEMO' ('Sero Demo Society')");

  // 2. Define Demo Accounts
  const users = [
    {
      uid: "demo_resident_uid",
      name: "Demo Resident",
      phone: "+919999999991",
      role: "resident",
      flatNumber: "A-101",
      residentType: "owner",
    },
    {
      uid: "demo_admin_uid",
      name: "Demo Admin",
      phone: "+919999999992",
      role: "main_admin",
      flatNumber: "Admin-Office",
      residentType: "owner",
    },
    {
      uid: "demo_guard_uid",
      name: "Demo Guard",
      phone: "+919999999993",
      role: "guard",
      flatNumber: "Gate-1",
      residentType: "owner",
    },
  ];

  // 3. Insert and Update user documents in Firestore
  for (const u of users) {
    await db.collection("users").doc(u.uid).set({
      uid: u.uid,
      name: u.name,
      phone: u.phone,
      password: hashedPassword,
      society_id: "SERO_DEMO",
      role: u.role,
      status: "approved",
      flatNumber: u.flatNumber,
      blockName: "Demo Block",
      residentType: u.residentType,
      createdAt: new Date(),
      failedLoginAttempts: 0,
      lockUntil: null,
    }, { merge: true });
    console.log(`✅ Seeded User: ${u.name} (${u.phone}) with role: ${u.role}`);
  }

  console.log("🎉 Seeding completed successfully!");
  process.exit(0);
}

seed().catch(err => {
  console.error("❌ Seeding failed:", err);
  process.exit(1);
});
