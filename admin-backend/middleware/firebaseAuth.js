// middleware/firebaseAuth.js
import admin from "../config/firebaseAdmin.js";

export const verifyFirebaseToken = async (req, res, next) => {
  const authHeader = req.headers.authorization || "";
  if (!authHeader.startsWith("Bearer ")) {
    req.firebaseUser = null;
    return next();
  }

  const token = authHeader.split(" ")[1];
  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.firebaseUser = decodedToken;
    return next();
  } catch (error) {
    console.error("❌ Firebase token verification failed:", error.message);
    req.firebaseUser = null;
    return next();
  }
};
