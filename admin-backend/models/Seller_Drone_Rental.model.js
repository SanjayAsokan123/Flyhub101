import mongoose from "mongoose";

const SellerDroneRentalSchema = new mongoose.Schema({
  sellerId: { type: String, required: true },
  name: { type: String, required: true },
  phone: { type: String, required: true },
  location: { type: String, required: true },
  price: { type: String, required: true },
  status: {
    type: String,
    enum: ["arrived", "completed", "rejected"],
    default: "arrived",
  }
}, { timestamps: true });

export const SellerDroneRental = mongoose.model("SellerDroneRental", SellerDroneRentalSchema);
