import mongoose from "mongoose";
import { Counter } from "./Counter.model.js";

const BuyerSchema = new mongoose.Schema(
  {
    buyerId: {
      type: String,
      unique: true,
      index: true,
      sparse: true,
    },

    firebaseUid: {
      type: String,
      index: true,
      sparse: true,
    },

    name: {
      type: String,
      trim: true,
    },

    email: {
      type: String,
      unique: true,
      sparse: true,
      lowercase: true,
      trim: true,
    },

    phoneNumber: {
      type: String,
      trim: true,
      index: true,
      sparse: true,
    },

    password: {
      type: String,
      default: null,
    },

    shippingAddresses: {
      type: [String],
      default: [],
    },

    wishlist: {
      type: [String],
      default: [],
    },

    cart: {
      type: [String],
      default: [],
    },

    orders: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Order",
      },
    ],

    fcmToken: { type: String, default: null },
    fcmTokens: { type: [String], default: [] },
  },
  { timestamps: true }
);

// AUTO-GENERATE buyerId → FLYHUBB0001, FLYHUBB0002...
async function getNextSequence(prefix) {
  const ret = await Counter.findByIdAndUpdate(
    prefix,
    { $inc: { seq: 1 } },
    { new: true, upsert: true }
  ).lean();

  return ret.seq;
}

BuyerSchema.pre("save", async function (next) {
  try {
    if (this.isNew && !this.buyerId) {
      const prefix = "FLYHUBB";
      const seq = await getNextSequence(prefix);
      this.buyerId = `${prefix}${String(seq).padStart(4, "0")}`;
    }
    next();
  } catch (err) {
    next(err);
  }
});

BuyerSchema.methods.addFcmToken = async function (token) {
  if (!token) return;

  const tokens = new Set(this.fcmTokens || []);
  tokens.add(token);

  this.fcmTokens = Array.from(tokens);
  this.fcmToken = token;

  await this.save();
  return this;
};

BuyerSchema.methods.removeFcmToken = async function (token) {
  this.fcmTokens = (this.fcmTokens || []).filter((t) => t !== token);

  this.fcmToken = this.fcmTokens.length > 0 ? this.fcmTokens[0] : null;

  await this.save();
  return this;
};

export const Buyer =
  mongoose.models.Buyer || mongoose.model("Buyer", BuyerSchema);
