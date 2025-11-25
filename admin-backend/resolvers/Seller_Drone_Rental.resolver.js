import { SellerDroneRental } from "../models/Seller_Drone_Rental.model.js";

export const SellerDroneRentalResolvers = {

  // ============================
  // QUERIES
  // ============================
  Query: {
    getSellerArrivedBookings: async (_, { sellerId }) => {
      return await SellerDroneRental.find({ sellerId, status: "arrived" })
        .sort({ createdAt: -1 });
    },

    getSellerCompletedBookings: async (_, { sellerId }) => {
      return await SellerDroneRental.find({ sellerId, status: "completed" })
        .sort({ createdAt: -1 });
    },
  },

  // ============================
  // MUTATIONS
  // ============================
  Mutation: {
    approveSellerDroneRental: async (_, { rentalId }) => {
      return await SellerDroneRental.findByIdAndUpdate(
        rentalId,
        { status: "completed" },
        { new: true }
      );
    },

    rejectSellerDroneRental: async (_, { rentalId }) => {
      return await SellerDroneRental.findByIdAndUpdate(
        rentalId,
        { status: "rejected" },
        { new: true }
      );
    },
  },
};
