import mongoose from "mongoose";
import { Counter } from "./Counter.model.js";

/**
 * 🧾 Buyer Schema (FINAL)
 * Features:
 *  - Sequential buyerId (FLYHUBB0001)
 *  - Firebase UID support
 *  - Email / Phone / BuyerID unified login
 *  - loginIndex cross-mapping
 *  - Shipping, wishlist, cart, orders
 */

const BuyerSchema = new mongoose.Schema(
  {
    // -------------------------------------------------
    // 🔹 Firebase UID (used for OTP login)
    // -------------------------------------------------
    firebaseUid: {
      type: String,
      index: true,
      sparse: true,
      trim: true
    },

    // -------------------------------------------------
    // 🔹 Unique Buyer Code (FLYHUBB0001)
    // -------------------------------------------------
    buyerId: {
      type: String,
      unique: true,
      sparse: true,
      index: true,
    },

    // -------------------------------------------------
    // 🔹 Name
    // -------------------------------------------------
    name: {
      type: String,
      trim: true,
      default: "",
    },

    // -------------------------------------------------
    // 🔹 Email (unique, used for login)
    // -------------------------------------------------
    email: {
      type: String,
      unique: true,
      sparse: true,
      lowercase: true,
      trim: true,
    },

    // -------------------------------------------------
    // 🔹 Phone (OTP login)
    // -------------------------------------------------
    phoneNumber: {
      type: String,
      trim: true,
      sparse: true,
      index: true,
    },

    // -------------------------------------------------
    // 🔹 Password (optional because OTP works too)
    // -------------------------------------------------
    password: {
      type: String,
      default: null, // buyer may register with OTP only
    },

    // -------------------------------------------------
    // 🔹 Shipping Addresses
    // -------------------------------------------------
    shippingAddresses: {
      type: [String],
      default: [],
    },

    // -------------------------------------------------
    // 🔹 Wishlist
    // -------------------------------------------------
    wishlist: {
      type: [String],
      default: [],
    },

    // -------------------------------------------------
    // 🔹 Cart
    // -------------------------------------------------
    cart: {
      type: [String],
      default: [],
    },

    // -------------------------------------------------
    // 🔹 Orders
    // -------------------------------------------------
    orders: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Order",
      },
    ],
  },

  { timestamps: true }
);

/**
 * 🔢 Get sequential number for new buyerId
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
 * 🧠 Auto-generate buyerId → FLYHUBB0001
 */
BuyerSchema.pre("save", async function (next) {
  try {
    if (this.isNew && !this.buyerId) {
      const prefix = "FLYHUBB";
      const nextSeq = await getNextSequence(prefix);
      this.buyerId = `${prefix}${String(nextSeq).padStart(4, "0")}`;
    }
    next();
  } catch (err) {
    next(err);
  }
});

export const Buyer =
  mongoose.models.Buyer || mongoose.model("Buyer", BuyerSchema);
