// backend/resolvers/buyerResolvers.js
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { Buyer } from "../models/Buyer.model.js";
import { createSellerNotification } from "../utils/createSellerNotification.js";
import { auth } from "../config/firebaseAdmin.js";
import { createLoginIndex, findLoginIndex } from "../utils/loginIndex.js";



export const buyerResolvers = {
  Query: {
    buyers: async () => await Buyer.find().sort({ createdAt: -1 }),

    buyer: async (_, { id }) => {
      const buyer = await Buyer.findById(id);
      if (!buyer) throw new Error(`Buyer ${id} not found`);
      return buyer;
    },
  },

  Mutation: {
    signupBuyer: async (
      _,
      { name, email, phone, password, firebaseUid },
      { pubsub }
    ) => {
      try {
        const existing = await Buyer.findOne({ email });
        if (existing) throw new Error("Buyer with this email already exists.");

        const hashedPassword = await bcrypt.hash(password, 10);

        const buyer = await Buyer.create({
          name,
          email,
          phoneNumber: phone,
          password: hashedPassword,
          firebaseUid,
        });

        // Login index mapping
        await createLoginIndex({
          uid: firebaseUid,
          email,
          phone,
          customId: buyer.buyerId,
        });

        // JWT
        const token = jwt.sign(
          { buyerId: buyer.id, email: buyer.email },
          process.env.JWT_SECRET,
          { expiresIn: "1d" }
        );

        // Notification
        await createSellerNotification({
          sellerId: "SYSTEM",
          title: "🆕 New Buyer Registered",
          message: `Buyer "${buyer.name}" created an account.`,
          type: "buyer_signup",
          data: { buyerId: buyer.buyerId, email },
          url: `/admin/buyers/${buyer.id}`,
          pubsub,
        });

        // ✅ RETURN createdAt as well
        return {
          id: buyer.id,
          buyerId: buyer.buyerId,
          name: buyer.name,
          email: buyer.email,
          phone: buyer.phoneNumber,
          createdAt: buyer.createdAt,  // <-- ADDED
          token,
        };
      } catch (err) {
        console.error("❌ Buyer signup failed:", err);
        throw new Error("Signup failed: " + err.message);
      }
    },

    // ------------------------------------------------------------
    // 🔵 BUYER LOGIN
    // ------------------------------------------------------------
    loginBuyer: async (_, { input, password }) => {
      try {
        let buyer = null;

        const loginMatch = await findLoginIndex(input);
        if (loginMatch?.uid) {
          buyer = await Buyer.findOne({ firebaseUid: loginMatch.uid });
        }

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

        const valid = await bcrypt.compare(password, buyer.password || "");
        if (!valid) throw new Error("Incorrect password");

        const token = jwt.sign(
          { buyerId: buyer.id, email: buyer.email },
          process.env.JWT_SECRET,
          { expiresIn: "1d" }
        );

        // ✅ Include createdAt
        return {
          id: buyer.id,
          buyerId: buyer.buyerId,
          name: buyer.name,
          email: buyer.email,
          phone: buyer.phoneNumber,
          createdAt: buyer.createdAt,  // <-- ADDED
          token,
        };
      } catch (err) {
        console.error("❌ Login failed:", err);
        throw new Error("Login failed: " + err.message);
      }
    },

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

        // ✅ Include createdAt
        return {
          id: buyer.id,
          buyerId: buyer.buyerId,
          name: buyer.name,
          email: buyer.email,
          phone: buyer.phoneNumber,
          createdAt: buyer.createdAt,  // <-- ADDED
          token,
        };
      } catch (err) {
        console.error("❌ OTP login failed:", err);
        throw new Error("OTP login failed: " + err.message);
      }
    },

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
