import mongoose from "mongoose";
import { Counter } from "./Counter.model.js";

/**
 * 🧾 Seller Schema
 * Supports:
 *  - Custom sequential IDs (FLYHUBS0001)
 *  - Multi-device FCM token support
 *  - Shipping & pickup addresses
 *  - Auto status tracking
 */

const SellerSchema = new mongoose.Schema(
  {
    // 🔹 Unique seller identifier
    customId: { type: String, unique: true, sparse: true },

    // 🔹 Company & Contact Info
    companyName: { type: String, required: true },
    PANnumber: { type: String, required: true },
    gstNumber: { type: String },
    address: { type: String, required: true },
email: {
  type: String,
  required: true,
  unique: true,
  lowercase: true,
},

    phoneNumber: { type: String, required: true },
    name: { type: String },

    // 🔹 Banking / Tax Details
    bankName: { type: String },
    bankAccountNumber: { type: String },
    bankIFCnumber: { type: String },
    companyPan: { type: String },
    authorized: { type: String },

    // 🔹 Address Lists
    shippingAddresses: { type: [String], default: [] },
    pickupAddresses: { type: [String], default: [] },

    // 🔹 Status Tracking
    status: {
      type: String,
      enum: ["pending", "approved", "rejected", "suspended"],
      default: "pending",
    },

    // 🔹 Drones Linked
    Drones: [{ type: mongoose.Schema.Types.ObjectId, ref: "Drone" }],

    // 🔹 Notification Tokens (for multi-device support)
    fcmTokens: {
      type: [String],
      default: [],
    },

    // 🔹 Legacy single-token field (optional)
    fcmToken: {
      type: String,
      default: null,
    },

    // 🔹 Timestamps
  },
  { timestamps: true }
);

/**
 * 🔢 Atomic counter increment for sequential customId
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
 * 🧠 Pre-save hook to generate unique seller customId
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
 * 🧩 Add a new FCM token safely (no duplicates)
 */
SellerSchema.methods.addFcmToken = async function (token) {
  if (token && !this.fcmTokens.includes(token)) {
    this.fcmTokens.push(token);
    this.fcmToken = token; // keep legacy compatibility
    await this.save();
  }
};

/**
 * 🧹 Remove invalid or expired FCM tokens
 */
SellerSchema.methods.removeFcmTokens = async function (tokensToRemove = []) {
  if (!Array.isArray(tokensToRemove) || tokensToRemove.length === 0) return;
  this.fcmTokens = this.fcmTokens.filter((t) => !tokensToRemove.includes(t));
  if (tokensToRemove.includes(this.fcmToken)) this.fcmToken = null;
  await this.save();
};

/**
 * 🧾 Manually generate next customId
 */
export async function generateSellerCustomId() {
  const prefix = "FLYHUBS";
  const nextSeq = await getNextSequence(prefix);
  return `${prefix}${String(nextSeq).padStart(4, "0")}`;
}

export const Seller =
  mongoose.models.Seller || mongoose.model("Seller", SellerSchema);
