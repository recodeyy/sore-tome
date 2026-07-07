const admin = require("firebase-admin");
const path = require("path");

const serviceAccount = require("./config/serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function run() {
  console.log("Fetching users from Firestore...");
  const snap = await db.collection("users").get();
  console.log(`Found ${snap.size} users:`);
  snap.docs.forEach(doc => {
    console.log(doc.id, "=>", doc.data());
  });
  process.exit(0);
}

run().catch(err => {
  console.error("Error running script:", err);
  process.exit(1);
});
