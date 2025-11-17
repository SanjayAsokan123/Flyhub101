// admin-backend/routes/sellerAuth.js
import express from "express";
import bcrypt from "bcryptjs";
import rateLimit from "express-rate-limit";
import Seller from "../models/Seller.js";
import { auth } from "../config/firebaseAdmin.js";

const router = express.Router();

// Prevent brute-force login attempts
const limiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  message: { error: "Too many attempts, please wait and try again." }
});

/**
 * SELLER ID LOGIN
 * POST /auth/sellerid
 * Body: { sellerId, password }
 */
router.post("/sellerid", limiter, async (req, res) => {
  try {
    const { sellerId, password } = req.body;

    if (!sellerId || !password) {
      return res.status(400).json({ error: "Seller ID & password required." });
    }

    // Find seller by customId
    const seller = await Seller.findOne({ customId: sellerId });
    if (!seller) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    // Check bcrypt password hash
    if (!seller.passwordHash) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    const match = await bcrypt.compare(password, seller.passwordHash);
    if (!match) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    // Ensure seller has a Firebase Auth UID
    let uid = seller.firebaseUid;
    if (!uid) {
      // Create Firebase user if missing
      const firebaseUser = await auth.createUser({
        email: seller.email || undefined,
        displayName: seller.companyName || seller.customId,
        disabled: false,
      });

      uid = firebaseUser.uid;

      // Update seller doc
      seller.firebaseUid = uid;
      await seller.save();
    }

    // Generate Firebase Custom Token
    const token = await auth.createCustomToken(uid, {
      role: "seller",
      sellerId: seller.customId,
    });

    return res.json({ success: true, token });

  } catch (err) {
    console.error("🔥 SellerID Login Error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

export default router;
