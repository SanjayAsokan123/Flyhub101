import mongoose from "mongoose";

const partSchema = new mongoose.Schema({
  name: { type: String, required: true },
  brand: { type: String, required: true },
  uin: { type: String },
  price: { type: Number, required: true },
  description: { type: String, required: true },
  image: { type: String },
  status: { type: String, default: "pending" }, // pending/approved/rejected
});

export default mongoose.model("Part", partSchema);
