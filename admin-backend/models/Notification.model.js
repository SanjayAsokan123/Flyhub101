// models/Notification.model.js
import mongoose from "mongoose";

const NotificationSchema = new mongoose.Schema({
  notificationId: { type: String, required: true, unique: true }, // you may use uuid
  sellerId: { type: String, required: true, index: true }, // Seller.customId
  title: { type: String, required: true },
  message: { type: String, required: true },
  type: { type: String, default: "status_update" }, // e.g. status_update, general, order
  data: { type: Object, default: {} }, // optional extra payload
  url: { type: String, default: null }, // optional deep link / frontend url
  read: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
});

export const Notification = mongoose.model("Notification", NotificationSchema);
