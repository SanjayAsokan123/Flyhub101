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

    rentalId: { type: String, required: true }, // Link to rental drone listing
  },
  { timestamps: true }
);

// ✅ Auto-generate drone_rental_id like DR1, DR2, DR3...
rentalSchema.pre("save", async function (next) {
  if (this.drone_rental_id) return next();

  const last = await this.constructor.findOne().sort({ drone_rental_id: -1 });

  if (last?.drone_rental_id) {
    const num = parseInt(last.drone_rental_id.replace("DR", ""), 10);
    this.drone_rental_id = `DR${num + 1}`;
  } else {
    this.drone_rental_id = "DR1";
  }
  next();
});

// Buyer_booking_Drone_rental.model.js
rentalSchema.statics.aggregateWithDroneByRentalId = function (match = {}, sort = { createdAt: -1 }) {
  return this.aggregate([
    { $match: match },
    {
      $lookup: {
        from: "rentals",                 // : correct collection name
        localField: "rentalId",
        foreignField: "rentalId",
        as: "rental"
      }
    },
    { $unwind: { path: "$rental", preserveNullAndEmptyArrays: true } }, // : unwind the joined array
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
        drone: {                         // : match GraphQL "drone" field
          rentalId: "$rental.rentalId",
          name: "$rental.name",
          brand: "$rental.brand",
          location: "$rental.location",
          pricePerHour: "$rental.pricePerHour", // : use $ field paths (number)
          pricePerDay: "$rental.pricePerDay"    // : use $ field paths (number)
        }
      }
    },
    { $sort: sort }
  ]);
};


// ✅ Model Export
const DroneRental = mongoose.model("DroneRental", rentalSchema);
export default DroneRental;