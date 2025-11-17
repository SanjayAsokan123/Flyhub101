// backend/resolvers/buyerResolvers.js
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { Buyer } from "../models/Buyer.model.js";
import { createSellerNotification } from "../utils/createSellerNotification.js";
import { auth } from "../config/firebaseAdmin.js";
import { createLoginIndex, findLoginIndex } from "../utils/loginIndex.js";

/**
 * BUYER GraphQL RESOLVERS (FINAL)
 * Features:
 * - Email/Phone/BuyerID login
 * - OTP login via Firebase UID
 * - Auto loginIndex creation
 * - Full JWT support
 */

export const buyerResolvers = {
  // ============================================================
  // 📊 QUERIES
  // ============================================================
  Query: {
    buyers: async () => await Buyer.find().sort({ createdAt: -1 }),

    buyer: async (_, { id }) => {
      const buyer = await Buyer.findById(id);
      if (!buyer) throw new Error(`Buyer ${id} not found`);
      return buyer;
    },
  },

  // ============================================================
  // ⚙ MUTATIONS
  // ============================================================
  Mutation: {
    // ------------------------------------------------------------
    // 🟢 BUYER SIGNUP (Email + Password + Phone + OTP)
    // ------------------------------------------------------------
    signupBuyer: async (
      _,
      { name, email, phone, password, firebaseUid },
      { pubsub }
    ) => {
      try {
        // Prevent duplicate email
        const existing = await Buyer.findOne({ email });
        if (existing) throw new Error("Buyer with this email already exists.");

        const hashedPassword = await bcrypt.hash(password, 10);

        // Create buyer in MongoDB
        const buyer = await Buyer.create({
          name,
          email,
          phoneNumber: phone,
          password: hashedPassword,
          firebaseUid,
        });

        // Create loginIndex mapping for email, phone, buyerId
        await createLoginIndex({
          uid: firebaseUid,
          email,
          phone,
          customId: buyer.buyerId, // FLYHUBB0001
        });

        // JWT Token
        const token = jwt.sign(
          { buyerId: buyer.id, email: buyer.email },
          process.env.JWT_SECRET,
          { expiresIn: "1d" }
        );

        // System notification
        await createSellerNotification({
          sellerId: "SYSTEM",
          title: "🆕 New Buyer Registered",
          message: `Buyer "${buyer.name}" created an account.`,
          type: "buyer_signup",
          data: { buyerId: buyer.buyerId, email },
          url: `/admin/buyers/${buyer.id}`,
          pubsub,
        });

        return {
          id: buyer.id,
          buyerId: buyer.buyerId,
          name: buyer.name,
          email: buyer.email,
          phone: buyer.phoneNumber,
          token,
        };
      } catch (err) {
        console.error("❌ Buyer signup failed:", err);
        throw new Error("Signup failed: " + err.message);
      }
    },

    // ------------------------------------------------------------
    // 🔵 BUYER LOGIN (Email / Phone / BuyerID)
    // ------------------------------------------------------------
    loginBuyer: async (_, { input, password }) => {
      try {
        let buyer = null;

        // 1️⃣ Try loginIndex lookup (fastest + cross-platform)
        const loginMatch = await findLoginIndex(input);
        if (loginMatch && loginMatch.uid) {
          buyer = await Buyer.findOne({ firebaseUid: loginMatch.uid });
        }

        // 2️⃣ Fallback: direct DB search
        if (!buyer) {
          if (input.includes("@")) {
            buyer = await Buyer.findOne({ email: input });
          } else if (/^\d{10}$/.test(input)) {
            buyer = await Buyer.findOne({ phoneNumber: input });
          } else {
            buyer = await Buyer.findOne({ buyerId: input });
          }
        }

        if (!buyer) throw new Error("Buyer not found");

        // Validate password
        const valid = await bcrypt.compare(password, buyer.password || "");
        if (!valid) throw new Error("Incorrect password");

        const token = jwt.sign(
          { buyerId: buyer.id, email: buyer.email },
          process.env.JWT_SECRET,
          { expiresIn: "1d" }
        );

        return {
          id: buyer.id,
          buyerId: buyer.buyerId,
          name: buyer.name,
          email: buyer.email,
          phone: buyer.phoneNumber,
          token,
        };
      } catch (err) {
        console.error("❌ Login failed:", err);
        throw new Error("Login failed: " + err.message);
      }
    },

    // ------------------------------------------------------------
    // 🔵 OTP LOGIN (Phone Only + Firebase UID)
    // ------------------------------------------------------------
    loginBuyerOtp: async (_, { firebaseUid }) => {
      try {
        const buyer = await Buyer.findOne({ firebaseUid });
        if (!buyer)
          throw new Error("Phone number not registered. Please sign up first.");

        const token = jwt.sign(
          { buyerId: buyer.id, email: buyer.email },
          process.env.JWT_SECRET,
          { expiresIn: "1d" }
        );

        return {
          id: buyer.id,
          buyerId: buyer.buyerId,
          name: buyer.name,
          email: buyer.email,
          phone: buyer.phoneNumber,
          token,
        };
      } catch (err) {
        console.error("❌ OTP login failed:", err);
        throw new Error("OTP login failed: " + err.message);
      }
    },

    // ------------------------------------------------------------
    // ✏ UPDATE BUYER PROFILE
    // ------------------------------------------------------------
    updateBuyer: async (_, { buyerId, name, email, phone, password }) => {
      try {
        const data = {};
        if (name) data.name = name;
        if (email) data.email = email;
        if (phone) data.phoneNumber = phone;
        if (password) data.password = await bcrypt.hash(password, 10);

        const updated = await Buyer.findByIdAndUpdate(buyerId, data, {
          new: true,
          runValidators: true,
        });

        if (!updated) throw new Error("Buyer not found");

        return updated;
      } catch (err) {
        throw new Error("Update failed: " + err.message);
      }
    },

    // ------------------------------------------------------------
    // 🗑 DELETE BUYER
    // ------------------------------------------------------------
    deleteBuyer: async (_, { buyerId }, { pubsub }) => {
      try {
        const deleted = await Buyer.findByIdAndDelete(buyerId);
        if (!deleted) throw new Error("Buyer not found");

        await createSellerNotification({
          sellerId: "SYSTEM",
          title: "🗑 Buyer Deleted",
          message: `Buyer "${deleted.name}" deleted account.`,
          type: "buyer_deleted",
          data: { buyerId },
          pubsub,
        });

        return "Buyer deleted successfully.";
      } catch (err) {
        throw new Error("Delete failed: " + err.message);
      }
    },
  },
};
