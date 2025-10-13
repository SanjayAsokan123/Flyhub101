import mongoose from "mongoose";

const accessorySchema = new mongoose.Schema({
  name: { type: String, required: true },
  brand: { type: String, required: true },
  price: { type: Number, required: true },
  description: { type: String, required: true },
  image: { type: String },
  status: { type: String, default: "pending" }, // pending/approved/rejected
});

export default mongoose.model("Accessory", accessorySchema);
