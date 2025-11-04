import mongoose from "mongoose";
import { Seller } from "./Seller.model.js";

const accessorySchema = new mongoose.Schema(
  {
    accessoryId: { type: String, unique: true }, // Auto-generated like SELLER0001A0001
    name: { type: String, required: true },
    brand: { type: String, required: true },
    category: { type: String },
    price: { type: Number, required: true },
    description: { type: String, required: true },
    image: { type: String },
    quantity: { type: Number, default: 1 },
    status: { type: String, default: "pending" }, // pending / approved / rejected
    wishlist: [
      {
        userId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "User",
          required: true,
        },
        addedAt: { type: Date, default: Date.now },
      },
    ],
    sellerId: { type: String, required: true }, // stores Seller.customId
  },
  { timestamps: true }
);

// 🆔 Pre-save Hook to generate Accessory ID
accessorySchema.pre("save", async function (next) {
  try {
    if (this.isNew && !this.accessoryId && this.sellerId) {
      const seller = await Seller.findOne({ customId: this.sellerId });
      if (!seller) throw new Error("Seller not found");

      const count = await mongoose.models.Accessory.countDocuments({
        sellerId: this.sellerId,
      });

      const accessoryNumber = String(count + 1).padStart(4, "0");
      this.accessoryId = `${seller.customId}A${accessoryNumber}`;
    }
    next();
  } catch (err) {
    next(err);
  }
});

export const Accessory =
  mongoose.models.Accessory || mongoose.model("Accessory", accessorySchema);
