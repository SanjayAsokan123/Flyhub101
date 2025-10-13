import mongoose from "mongoose";

const sellerSchema = new mongoose.Schema(
  {
    name: { type: String },
    company: { type: String },
    phone: { type: String },
    email: { type: String },
    status: {
      type: String,
      enum: ["pending", "approved", "rejected"],
      default: "pending",
    },
  },
  { timestamps: true }
);

const Seller = mongoose.model("Seller", sellerSchema);
export default Seller;
