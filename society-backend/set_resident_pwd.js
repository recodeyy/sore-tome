const admin = require("firebase-admin");
const serviceAccount = require("./config/serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function run() {
  console.log("Updating resident phone and password in Firestore...");
  const passwordHash = "$2a$10$Wu/OJKVknM61IZOpjgtfTu3pmO3Y5pED/jH4fEC5IH5He/dYFrvMm";
  
  await db.collection("users").doc("8Lm9vDSenHMyIqcJlHAv").update({
    phone: "9876543200",
    password: passwordHash
  });
  
  console.log("Resident updated successfully!");
  process.exit(0);
}

run().catch(err => {
  console.error("Error updating resident:", err);
  process.exit(1);
});
