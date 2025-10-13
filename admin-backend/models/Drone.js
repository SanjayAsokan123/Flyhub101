import mongoose from "mongoose";

const droneSchema = new mongoose.Schema({
  name: { type: String, required: true },
  brand: { type: String, required: true },
  uin: { type: String },
  price: { type: Number, required: true },
  description: { type: String, required: true },
  image: { type: String },
  status: { type: String, default: "pending" },
});

export default mongoose.model("Drone", droneSchema);
