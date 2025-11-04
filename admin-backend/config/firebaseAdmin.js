// config/firebaseAdmin.js
import admin from "firebase-admin";
import dotenv from "dotenv";
import fs from "fs";

dotenv.config();

if (!admin.apps.length) {
  try {
    let credentials;

    const serviceAccountPath = process.env.FIREBASE_ADMIN_CREDENTIALS;

    // ✅ Option 1: Load from JSON file path (local dev)
    if (serviceAccountPath && fs.existsSync(serviceAccountPath)) {
      console.log(`🔑 Using Firebase Admin credentials from: ${serviceAccountPath}`);
      const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, "utf8"));
      credentials = admin.credential.cert(serviceAccount);
    }
    // ✅ Option 2: Use environment variables (for cloud)
    else if (process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
      console.log("🌍 Using Firebase credentials from environment variables");
      credentials = admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, "\n"),
      });
    }

    if (!credentials) {
      console.warn("⚠️ Firebase Admin credentials missing — push notifications won't work.");
    } else {
      admin.initializeApp({ credential: credentials });
      console.log("🔥 Firebase Admin initialized successfully");
    }
  } catch (error) {
    console.error("❌ Firebase Admin initialization failed:", error);
  }
} else {
  console.log("ℹ️ Firebase Admin already initialized");
}

export default admin;
