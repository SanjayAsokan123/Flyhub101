import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import Buyer from "../models/Buyer.model.js";
import { createSellerNotification } from "../utils/createSellerNotification.js";

export const buyerResolvers = {
  Query: {
    // ✅ Fetch all buyers
    buyers: async () => await Buyer.find(),

    // ✅ Fetch single buyer by ID
    buyer: async (_, { id }) => await Buyer.findById(id),
  },

  Mutation: {
    // 🟢 Signup / Create Buyer Account
    signup: async (_, { name, email, password }, { pubsub }) => {
      const existingBuyer = await Buyer.findOne({ email });
      if (existingBuyer) throw new Error("Buyer already exists with this email.");

      const hashedPassword = await bcrypt.hash(password, 10);
      const newBuyer = new Buyer({
        name,
        email,
        password: hashedPassword,
      });
      await newBuyer.save();

      // ✅ Generate JWT Token
      const token = jwt.sign(
        { buyerId: newBuyer.id, email: newBuyer.email },
        process.env.JWT_SECRET,
        { expiresIn: "1d" }
      );

      // 🔔 Optional: Notify admin (or system log) about new buyer registration
      try {
        await createSellerNotification({
          sellerId: "SYSTEM", // Optional system ID
          title: "New Buyer Registered",
          message: `Buyer "${name}" just signed up on Flyhub.`,
          type: "buyer_signup",
          data: { buyerId: newBuyer.id, email },
          url: `/admin/buyers/${newBuyer.id}`,
          pubsub,
        });
      } catch (err) {
        console.error("⚠️ createSellerNotification failed:", err);
      }

      return {
        id: newBuyer.id,
        name: newBuyer.name,
        email: newBuyer.email,
        token,
      };
    },

    // 🔵 Login Buyer
    login: async (_, { email, password }, { pubsub }) => {
      const buyer = await Buyer.findOne({ email });
      if (!buyer) throw new Error("Buyer not found.");

      const isPasswordValid = await bcrypt.compare(password, buyer.password);
      if (!isPasswordValid) throw new Error("Invalid password.");

      const token = jwt.sign(
        { buyerId: buyer.id, email: buyer.email },
        process.env.JWT_SECRET,
        { expiresIn: "1d" }
      );

      // 🔔 Optional: Notify (for analytics or admin monitoring)
      try {
        await createSellerNotification({
          sellerId: "SYSTEM",
          title: "Buyer Login",
          message: `Buyer "${buyer.name}" has logged in.`,
          type: "buyer_login",
          data: { buyerId: buyer.id, email },
          url: `/admin/buyers/${buyer.id}`,
          pubsub,
        });
      } catch (err) {
        console.error("⚠️ createSellerNotification failed:", err);
      }

      return {
        id: buyer.id,
        name: buyer.name,
        email: buyer.email,
        token,
      };
    },

    // ✏️ Update Buyer
    updateBuyer: async (_, { buyerId, name, email, password }) => {
      const updateData = {};
      if (name) updateData.name = name;
      if (email) updateData.email = email;
      if (password) updateData.password = await bcrypt.hash(password, 10);

      const updatedBuyer = await Buyer.findOneAndUpdate(
        { _id: buyerId },
        updateData,
        { new: true }
      );

      if (!updatedBuyer) throw new Error(`Buyer with ID ${buyerId} not found.`);
      return updatedBuyer;
    },

    // 🗑 Delete Buyer
    deleteBuyer: async (_, { buyerId }, { pubsub }) => {
      const deletedBuyer = await Buyer.findOneAndDelete({ _id: buyerId });
      if (!deletedBuyer) throw new Error(`Buyer with ID ${buyerId} not found.`);

      // 🔔 Notify admin/system about account deletion
      try {
        await createSellerNotification({
          sellerId: "SYSTEM",
          title: "Buyer Account Deleted",
          message: `Buyer "${deletedBuyer.name}" deleted their account.`,
          type: "buyer_deleted",
          data: { buyerId },
          url: `/admin/buyers`,
          pubsub,
        });
      } catch (err) {
        console.error("⚠️ createSellerNotification failed:", err);
      }

      return `Buyer with ID ${buyerId} deleted successfully.`;
    },
  },
};
