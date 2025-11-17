import mongoose from "mongoose";
import { Counter } from "./Counter.model.js";

/**
 * 🧾 Seller Schema
 * Supports:
 *  - Custom sequential IDs (FLYHUBS0001)
 *  - Firebase UID linking
 *  - Multi-device FCM token support
 *  - Shipping & pickup addresses
 *  - Auto status tracking
 */

const SellerSchema = new mongoose.Schema(
  {
    // -----------------------------
    // 🔹 Identity Fields
    // -----------------------------
    firebaseUid: { type: String, index: true, sparse: true },

    customId: { type: String, unique: true, sparse: true },

    // -----------------------------
    // 🔹 Company & Contact Info
    // -----------------------------
    companyName: { type: String, default: "Pending Company" },

    PANnumber: { type: String, default: "PENDING" },

    gstNumber: { type: String, default: "" },

    address: { type: String, default: "Pending Address" },

    email: {
      type: String,
      unique: true,
      lowercase: true,
      sparse: true,
    },

    phoneNumber: {
      type: String,
      sparse: true,
    },

    name: { type: String, default: "" },

    // -----------------------------
    // 🔹 Banking / Tax Details
    // -----------------------------
    bankName: { type: String, default: "" },
    bankAccountNumber: { type: String, default: "" },
    bankIFCnumber: { type: String, default: "" },
    companyPan: { type: String, default: "" },
    authorized: { type: String, default: "" },

    // -----------------------------
    // 🔹 Address Lists
    // -----------------------------
    shippingAddresses: { type: [String], default: [] },
    pickupAddresses: { type: [String], default: [] },

    // -----------------------------
    // 🔹 Status Tracking
    // -----------------------------
    status: {
      type: String,
      enum: ["pending", "approved", "rejected", "suspended"],
      default: "pending",
    },

    // -----------------------------
    // 🔹 Linked drones
    // -----------------------------
    Drones: [{ type: mongoose.Schema.Types.ObjectId, ref: "Drone" }],

    // -----------------------------
    // 🔹 Notifications (FCM)
    // -----------------------------
    fcmTokens: {
      type: [String],
      default: [],
    },

    fcmToken: {
      type: String,
      default: null,
    },
  },

  { timestamps: true }
);

/**
 * 🔢 Generate custom sequential ID
 */
async function getNextSequence(prefix) {
  const ret = await Counter.findByIdAndUpdate(
    prefix,
    { $inc: { seq: 1 } },
    { new: true, upsert: true }
  ).lean();
  return ret.seq;
}

/**
 * 🧠 Auto-generate customId for new sellers
 */
SellerSchema.pre("save", async function (next) {
  try {
    if (this.isNew && !this.customId) {
      const prefix = "FLYHUBS";
      const nextSeq = await getNextSequence(prefix);
      this.customId = `${prefix}${String(nextSeq).padStart(4, "0")}`;
    }
    next();
  } catch (err) {
    next(err);
  }
});

/**
 * 📱 Add new FCM token
 */
SellerSchema.methods.addFcmToken = async function (token) {
  if (token && !this.fcmTokens.includes(token)) {
    this.fcmTokens.push(token);
    this.fcmToken = token; // keep legacy compatibility
    await this.save();
  }
};

/**
 * 🧹 Remove expired/invalid FCM tokens
 */
SellerSchema.methods.removeFcmTokens = async function (tokensToRemove = []) {
  if (!Array.isArray(tokensToRemove) || tokensToRemove.length === 0) return;
  this.fcmTokens = this.fcmTokens.filter((t) => !tokensToRemove.includes(t));
  if (tokensToRemove.includes(this.fcmToken)) this.fcmToken = null;
  await this.save();
};

/**
 * 🎯 Utility to generate next seller customId manually
 */
export async function generateSellerCustomId() {
  const prefix = "FLYHUBS";
  const nextSeq = await getNextSequence(prefix);
  return `${prefix}${String(nextSeq).padStart(4, "0")}`;
}

export const Seller =
  mongoose.models.Seller || mongoose.model("Seller", SellerSchema);
