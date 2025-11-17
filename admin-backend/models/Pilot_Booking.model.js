// models/PilotBooking.model.js
import mongoose from "mongoose";

const pilotBookingSchema = new mongoose.Schema(
  {
    pilotId: { type: String, required: true }, // store pilotId string (not ObjectId) to match HirePilot.pilotId
    pilotRef: { type: mongoose.Schema.Types.ObjectId, ref: "HirePilot" }, // optional DB ref
    buyerName: { type: String, required: true },
    buyerEmail: { type: String }, // optional if you don't have buyer email
    contact: { type: String, required: true },
    location: { type: String, required: true },
    date: { type: String, required: true }, // yyyy-mm-dd or ISO string
    startTime: { type: String, required: true },
    endTime: { type: String, required: true },
    status: {
      type: String,
      enum: ["pending", "confirmed", "cancelled", "completed"],
      default: "pending",
    },
    meta: { type: mongoose.Schema.Types.Mixed }, // any extra metadata
  },
  { timestamps: true }
);

export const PilotBooking =
  mongoose.models.PilotBooking || mongoose.model("PilotBooking", pilotBookingSchema);
