import mongoose from "mongoose";

const rentalSchema = new mongoose.Schema(
  {
    drone_rental_id: { type: String, unique: true, index: true },

    name: { type: String, required: true },
    email: { type: String, required: true },
    phone: { type: String, required: true },
    location: { type: String, required: true },

    amount: { type: Number, required: true },

    status: {
      type: String,
      enum: ["pending", "confirmed", "cancelled"],
      default: "pending",
    },

    rentalDate: { type: Date, required: true },

    rentalPeriod: {
      startDate: { type: Date, required: true },
      endDate: { type: Date, required: true },
    },

    paymentStatus: {
      type: String,
      enum: ["pending", "failed", "completed"],
      default: "pending",
    },

    rentalId: { type: String, required: true }, // Link to seller rental listing
  },
  { timestamps: true }
);

//
// ------------------------------------------------------------
// AUTO-GENERATE drone_rental_id (DR1, DR2, DR3...)
// ------------------------------------------------------------
rentalSchema.pre("save", async function (next) {
  if (this.drone_rental_id) return next();

  const last = await this.constructor
    .findOne({ drone_rental_id: { $regex: /^DR\d+$/ } })
    .sort({ drone_rental_id: -1 });

  if (last?.drone_rental_id) {
    const num = parseInt(last.drone_rental_id.replace("DR", ""), 10);
    this.drone_rental_id = `DR${num + 1}`;
  } else {
    this.drone_rental_id = "DR1";
  }

  next();
});


rentalSchema.statics.aggregateWithDroneByRentalId = function (
  match = {},
  sort = { createdAt: -1 }
) {
  return this.aggregate([
    { $match: match },

    {
      $lookup: {
        from: "seller_dronerentals", // FINAL FIXED COLLECTION NAME
        localField: "rentalId",
        foreignField: "rentalId",
        as: "rental",
      },
    },

    { $unwind: { path: "$rental", preserveNullAndEmptyArrays: true } },

    {
      $project: {
        drone_rental_id: 1,
        name: 1,
        email: 1,
        phone: 1,
        location: 1,
        amount: 1,
        status: 1,
        rentalDate: 1,
        rentalPeriod: 1,
        paymentStatus: 1,
        createdAt: 1,
        updatedAt: 1,

        drone: {
          rentalId: "$rental.rentalId",
          name: "$rental.name",
          brand: "$rental.brand",
          location: "$rental.location",
          pricePerHour: "$rental.pricePerHour",
          pricePerDay: "$rental.pricePerDay",
        },
      },
    },

    { $sort: sort },
  ]);
};

const DroneRental = mongoose.model("DroneRental", rentalSchema);
export default DroneRental;
