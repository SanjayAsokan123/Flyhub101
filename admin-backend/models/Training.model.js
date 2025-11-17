import mongoose from "mongoose";

const trainingSchema = new mongoose.Schema(
  {
    // 🏷️ Course Title
    title: {
      type: String,
      required: [true, "Course title is required"],
      trim: true,
      minlength: [3, "Title must be at least 3 characters long"],
    },

    // 💰 Base Fee
    amount: {
      type: Number,
      required: [true, "Base amount is required"],
      min: [0, "Amount cannot be negative"],
    },

    // 🧾 GST Percentage
    gst: {
      type: Number,
      required: [true, "GST percentage is required"],
      min: [0, "GST cannot be negative"],
      max: [100, "GST cannot exceed 100%"],
    },

    // 📅 Duration in Days
    days: {
      type: Number,
      required: [true, "Number of days is required"],
      min: [1, "Training must be at least 1 day long"],
    },

    // 🖼️ Optional image URL (Firebase or local path)
    imagePath: {
      type: String,
      default: "",
      trim: true,
    },

    // 🧠 Short Overview
    shortDescription: {
      type: String,
      default: "",
      maxlength: [300, "Short description cannot exceed 300 characters"],
    },

    // 📘 Full Description
    fullDescription: {
      type: String,
      default: "",
    },

    // 🧮 Auto-calculated total = amount + GST
    totalAmount: {
      type: Number,
      default: 0,
      min: [0, "Total amount cannot be negative"],
    },
  },
  { timestamps: true }
);

//
// ============================================================
// 🧮 Auto-calculate totalAmount before saving
// ============================================================
trainingSchema.pre("save", function (next) {
  if (this.amount != null && this.gst != null) {
    this.totalAmount = this.amount + (this.amount * this.gst) / 100;
  }
  next();
});

//
// ============================================================
// 🔁 Auto-calculate totalAmount when updated
// ============================================================
trainingSchema.pre("findOneAndUpdate", function (next) {
  const update = this.getUpdate();
  if (update.amount != null && update.gst != null) {
    update.totalAmount = update.amount + (update.amount * update.gst) / 100;
  }
  next();
});

//
// ============================================================
// ⚡ Indexing for Performance (optional but recommended)
// ============================================================
trainingSchema.index({ title: "text", shortDescription: "text" });

//
// ============================================================
// ✅ Export Model
// ============================================================
export const Training = mongoose.model("Training", trainingSchema);
