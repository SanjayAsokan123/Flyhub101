import RentalDrone from "../models/Rental.js";

export const rentalResolvers = {
  Query: {
    rentalDrones: async () => await RentalDrone.find(),
    rentalDrone: async (_, { id }) => await RentalDrone.findById(id),
    rejectedRentalDrones: async () => await RentalDrone.find({ status: "Rejected" }),
    pendingRentalDrones: async () => await RentalDrone.find({ status: "Pending" }),
  },

  Mutation: {
    createRentalDrone: async (_, { input }) => {
      const newDrone = new RentalDrone({
        ...input,
        status: input.status || "Pending",
      });
      return await newDrone.save();
    },

    updateRentalDrone: async (_, { id, input }) =>
      await RentalDrone.findByIdAndUpdate(id, input, { new: true }),

    updateRentalDroneStatus: async (_, { id, status }) =>
      await RentalDrone.findByIdAndUpdate(id, { status }, { new: true }),

    deleteRentalDrone: async (_, { id }) =>
      await RentalDrone.findByIdAndDelete(id),

    approveAllPendingRentalDrones: async () => {
      const result = await RentalDrone.updateMany(
        { status: "Pending" },
        { status: "Approved" }
      );
      return { success: true, count: result.modifiedCount };
    },
  },
};
