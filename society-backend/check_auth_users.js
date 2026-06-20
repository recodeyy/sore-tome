const admin = require("firebase-admin");
const serviceAccount = require("./config/serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function run() {
  console.log("Fetching Auth users from Firebase...");
  const listUsersResult = await admin.auth().listUsers();
  console.log(`Found ${listUsersResult.users.length} auth users:`);
  listUsersResult.users.forEach(userRecord => {
    console.log(userRecord.uid, "=>", userRecord.email, userRecord.phoneNumber, userRecord.displayName);
  });
  process.exit(0);
}

run().catch(err => {
  console.error("Error:", err);
  process.exit(1);
});
