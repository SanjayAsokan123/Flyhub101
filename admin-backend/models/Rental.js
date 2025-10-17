import mongoose from "mongoose";

const rentalSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    brand: { type: String, required: true },
    uin: { type: String },
    price: { type: Number, required: true },
    description: { type: String },
    image: { type: String },
    duration: { type: String, default: "Per Day" },
    with_pilot: { type: Boolean, default: false },
    insurance: { type: Boolean, default: false },
    available_today: { type: Boolean, default: true },
    status: { type: String, default: "Pending" },
  },
  { timestamps: true }
);

// ✅ Export as default
const RentalDrone = mongoose.model("RentalDrone", rentalSchema);
export default RentalDrone;
