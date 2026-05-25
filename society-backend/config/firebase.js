const admin = require("firebase-admin");

let db;

function initFirebase() {
  if (admin.apps.length > 0) return;

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || "config/serviceAccountKey.json";
  
  // Try loading from environment variables first
  let clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  let privateKey = process.env.FIREBASE_PRIVATE_KEY;

  let credential;

  if (clientEmail && privateKey) {
    // 1. Initialize via explicit environment variables
    credential = admin.credential.cert({
      projectId,
      clientEmail,
      privateKey: privateKey.replace(/\\n/g, "\n"),
    });
    console.log("✅ Firebase initialized via environment variables.");
  } else {
    // 2. Fallback check for production environments
    if (process.env.NODE_ENV === "production") {
      console.error("\n❌ CRITICAL ERROR: Missing Firebase environment credentials in Production!");
      throw new Error("Targeted Failure: Firebase Configuration Incomplete for Production");
    }

    // 3. Fallback to local untracked file if explicitly present in development
    const fs = require("fs");
    const path = require("path");
    const fullPath = path.isAbsolute(serviceAccountPath) 
      ? serviceAccountPath 
      : path.join(process.cwd(), serviceAccountPath);

    if (fs.existsSync(fullPath)) {
      credential = admin.credential.cert(fullPath);
      console.log(`✅ Firebase: Loading credentials from local file ${fullPath}`);
    } else {
      console.error("\n❌ CRITICAL ERROR: Missing Firebase credentials!");
      console.error("Provide FIREBASE_CLIENT_EMAIL and FIREBASE_PRIVATE_KEY environment variables, or save untracked config/serviceAccountKey.json locally.\n");
      throw new Error("Targeted Failure: Firebase Configuration Incomplete");
    }
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

