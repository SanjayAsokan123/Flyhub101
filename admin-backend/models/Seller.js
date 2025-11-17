// admin-backend/models/Seller.js
import mongoose from "mongoose";
import { Counter } from "./Counter.model.js";

const SellerSchema = new mongoose.Schema(
  {
    // Unique seller identifier
    customId: { type: String, unique: true, sparse: true },

    // Firebase Auth UID (linked to Auth user)
    firebaseUid: { type: String, index: true, sparse: true },

    // Company & Contact Info
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

    // Banking / Tax Details
    bankName: { type: String },
    bankAccountNumber: { type: String },
    bankIFCnumber: { type: String },
    companyPan: { type: String },
    authorized: { type: String },

    // Address Lists
    shippingAddresses: { type: [String], default: [] },
    pickupAddresses: { type: [String], default: [] },

    // Auth-related fields
    // NOTE: Do NOT store plaintext passwords. If you migrated older records,
    // remove plainPassword after hashing into passwordHash.
    passwordHash: { type: String, select: false }, // bcrypt hash (hidden by default)
    // optional temporary field that migration can remove:
    plainPassword: { type: String, select: false, default: undefined },

    // Role / Status
    role: { type: String, default: "seller" },
    status: {
      type: String,
      enum: ["pending", "approved", "rejected", "suspended"],
      default: "pending",
    },

    // Drones linked
    Drones: [{ type: mongoose.Schema.Types.ObjectId, ref: "Drone" }],

    // Notification Tokens (for multi-device support)
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

// Counter helper
async function getNextSequence(prefix) {
  const ret = await Counter.findByIdAndUpdate(
    prefix,
    { $inc: { seq: 1 } },
    { new: true, upsert: true }
  ).lean();
  return ret.seq;
}

// generate sequential customId
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

SellerSchema.methods.addFcmToken = async function (token) {
  if (token && !this.fcmTokens.includes(token)) {
    this.fcmTokens.push(token);
    this.fcmToken = token;
    await this.save();
  }
};

SellerSchema.methods.removeFcmTokens = async function (tokensToRemove = []) {
  if (!Array.isArray(tokensToRemove) || tokensToRemove.length === 0) return;
  this.fcmTokens = this.fcmTokens.filter((t) => !tokensToRemove.includes(t));
  if (tokensToRemove.includes(this.fcmToken)) this.fcmToken = null;
  await this.save();
};

export async function generateSellerCustomId() {
  const prefix = "FLYHUBS";
  const nextSeq = await getNextSequence(prefix);
  return `${prefix}${String(nextSeq).padStart(4, "0")}`;
}

export const Seller =
  mongoose.models.Seller || mongoose.model("Seller", SellerSchema);

export default Seller;
