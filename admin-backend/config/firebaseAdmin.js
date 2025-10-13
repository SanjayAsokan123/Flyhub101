// config/firebaseAdmin.js
import admin from "firebase-admin";
import dotenv from "dotenv";
import fs from "fs";

dotenv.config();

// 🔹 Load Firebase Admin credentials from environment or service account file
const serviceAccountPath = process.env.FIREBASE_ADMIN_CREDENTIALS;

// Option 1️⃣: Use serviceAccount JSON file path from .env
if (serviceAccountPath && fs.existsSync(serviceAccountPath)) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccountPath),
  });
}
// Option 2️⃣: Use environment variables (for production servers)
else if (process.env.FIREBASE_PRIVATE_KEY) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process
        .env
        .FIREBASE_PRIVATE_KEY
        .replace(/\\n/g, "\n"), // Handle escaped newlines
    }),
  });
} else {
  console.warn("⚠️ Firebase Admin SDK not configured properly");
}

export default admin;
