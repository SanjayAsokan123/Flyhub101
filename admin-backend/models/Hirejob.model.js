import mongoose from "mongoose";
import { Seller } from "./Seller.model.js";

const hireJobSchema = new mongoose.Schema(
  {
    jobId: { type: String }, // Auto-generated per seller
    jobName: { type: String, required: true },
    companyName: { type: String, required: true },
    jobType: String,
    experience: String,
    location: String,
    salary: String,
    description: String,
    requirement: String,
    email: String, // will be populated from Seller
    phoneNumber: String, // will be populated from Seller
    status: { type: String, default: "pending" },
    sellerId: { type: String, required: true }, // stores Seller.customId
  },
  { timestamps: true }
);

// Auto-generate jobId per seller
hireJobSchema.pre("save", async function (next) {
  try {
    if (this.isNew && !this.jobId && this.sellerId) {
      const seller = await Seller.findOne({ customId: this.sellerId });
      if (!seller) throw new Error("Seller not found");

      const count = await mongoose.models.HireJob.countDocuments({
        sellerId: this.sellerId,
      });
      const jobNumber = String(count + 1).padStart(3, "0");
      this.jobId = `${seller.customId}J${jobNumber}`;

      // populate email and phoneNumber from Seller
      this.email = seller.email;
      this.phoneNumber = seller.phoneNumber;
    }
    next();
  } catch (err) {
    next(err);
  }
});

export const HireJob =
  mongoose.models.HireJob || mongoose.model("HireJob", hireJobSchema);
