import mongoose from "mongoose";

const counterSchema = new mongoose.Schema({
  _id: { type: String, required: true }, // ✅ must be string, not ObjectId
  seq: { type: Number, default: 0 }
});

export const Counter = mongoose.models.Counter || mongoose.model("Counter", counterSchema);
