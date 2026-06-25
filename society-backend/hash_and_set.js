const admin = require("firebase-admin");
const bcrypt = require("bcryptjs");
const serviceAccount = require("./config/serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function run() {
  console.log("Hashing password...");
  const password = "123456";
  const salt = await bcrypt.genSalt(10);
  const hash = await bcrypt.hash(password, salt);
  console.log(`Password: ${password} => Hash: ${hash}`);

  console.log("Updating resident and admin in Firestore...");
  
  // Update resident (taiyo)
  await db.collection("users").doc("8Lm9vDSenHMyIqcJlHAv").update({
    phone: "9876543200",
    password: hash,
    failedLoginAttempts: 0,
    lockUntil: null
  });
  console.log("Resident 8Lm9vDSenHMyIqcJlHAv updated.");

  // Update admin (admin-001)
  await db.collection("users").doc("admin-001").update({
    phone: "admin",
    password: hash,
    failedLoginAttempts: 0,
    lockUntil: null
  });
  console.log("Admin admin-001 updated.");

  console.log("Done!");
  process.exit(0);
}

run().catch(err => {
  console.error("Error:", err);
  process.exit(1);
});
