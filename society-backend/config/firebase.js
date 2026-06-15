const admin = require("firebase-admin");

let db;

function initFirebase() {
  if (admin.apps.length > 0) return;

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  
  // Try loading from environment variables first
  let clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  let privateKey = process.env.FIREBASE_PRIVATE_KEY;

  let credential;

  if (clientEmail && privateKey) {
    // 1. Initialize via explicit environment variables
    credential = admin.credential.cert({
      projectId,
      clientEmail,
      privateKey: privateKey.includes("\\n") 
        ? privateKey.replace(/\\n/g, "\n") 
        : privateKey,
    });
  } else if (serviceAccountPath) {
    // 2. Initialize via service account JSON file (Best for local dev)
    const path = require("path");
    const fullPath = path.isAbsolute(serviceAccountPath) 
      ? serviceAccountPath 
      : path.join(process.cwd(), serviceAccountPath);
    
    credential = admin.credential.cert(fullPath);
    console.log(`✅ Firebase: Loading credentials from ${serviceAccountPath}`);
  }

  if (!credential) {
    console.error("\n❌ CRITICAL ERROR: Missing Firebase credentials!");
    console.error("Provide FIREBASE_CLIENT_EMAIL/PRIVATE_KEY or FIREBASE_SERVICE_ACCOUNT_PATH\n");
    throw new Error("Targeted Failure: Firebase Configuration Incomplete");
  }

  try {
    admin.initializeApp({
      credential,
      storageBucket: process.env.FIREBASE_STORAGE_BUCKET || (projectId ? `${projectId}.appspot.com` : undefined),
    });

    db = admin.firestore();
    console.log("✅ Firebase connected successfully");
  } catch (err) {
    console.error("❌ Firebase initialization failed:", err.message);
    throw err;
  }
}

function getDb() {
  if (!db) throw new Error("Firebase not initialized. Call initFirebase() first.");
  return db;
}

function getStorage() {
  return admin.storage();
}

function getAdmin() {
  return admin;
}

module.exports = { initFirebase, getDb, getStorage, getAdmin };

