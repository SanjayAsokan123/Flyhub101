import mongoose from "mongoose";
import { Counter } from "./Counter.model.js";

const buyerSchema = new mongoose.Schema(
  {
    buyerId: { type: String, unique: true }, // auto-generated
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
  },
  { timestamps: true }
);

// Pre-save hook to generate buyerId
buyerSchema.pre("save", async function (next) {
  try {
    if (this.isNew && !this.buyerId) {
      const ret = await Counter.findOneAndUpdate(
        { name: "buyerId" },
        { $inc: { seq: 1 } },
        { new: true, upsert: true }
      );
      this.buyerId = `FLYHUBB${ret.seq}`;
    }
    next();
  } catch (err) {
    next(err);
  }
});

export default mongoose.models.buyer || mongoose.model("buyer", buyerSchema);

//
//import mongoose from "mongoose";
//
//const BuyerSchema = new mongoose.Schema({
//  id: { type: String, unique: true },
//  name: { type: String, required: true },
//  email: { type: String, required: true, unique: true },
//  phoneNumber: { type: String, required: true },
//  shippingAddresses: { type: [String], default: [] },
//  wishlist: { type: [Boolean], default: [] },
//  addToChart: { type: [Boolean], default: [] },
//  orders: [{ type: mongoose.Schema.Types.ObjectId, ref: 'order' }]
//}, { timestamps: true });
//
//// Counter schema for atomic increments per prefix
//const counterSchema = new mongoose.Schema({ _id: String, seq: { type: Number, default: 0 } });
//const Counter = mongoose.models.Counter || mongoose.model('Counter', counterSchema);
//
//async function getNextSequence(prefix) {
//  const ret = await Counter.findByIdAndUpdate(
//    prefix,
//    { $inc: { seq: 1 } },
//    { new: true, upsert: true }
//  ).lean();
//  return ret.seq;
//}
//
//BuyerSchema.pre('save', async function (next) {
//  try {
//    if (!this.id) {
//      const prefix = 'FLYHUBB';
//      const nextSeq = await getNextSequence(prefix);
//      this.id = `${prefix}${String(nextSeq).padStart(4, '0')}`;
//    }
//    next();
//  } catch (err) {
//    next(err);
//  }
//});
//
//export const Buyer = mongoose.models.Buyer || mongoose.model('Buyer', BuyerSchema);