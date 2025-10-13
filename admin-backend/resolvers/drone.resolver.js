import Drone from "../models/Drone.js";

export const droneResolvers = {
  Query: {
    drones: async () => {
      const drones = await Drone.find();
      return drones.map((d) => ({
        id: d._id.toString(),
        ...d._doc,
      }));
    },

    drone: async (_, { id }) => {
      const d = await Drone.findById(id);
      return d ? { id: d._id.toString(), ...d._doc } : null;
    },

    rejectedDrones: async () => {
      const rejected = await Drone.find({ status: "rejected" });
      return rejected.map((d) => ({ id: d._id.toString(), ...d._doc }));
    },

    // 🏠 Home API for FlyHub App
    homeRequest: async () => {
      return [
        {
          template: "template_1",
          items: [
            {
              cname: "Rentals",
              image: "https://flyhub.in/assets/icons/rentals.png",
              click_url: "rentals",
            },
            {
              cname: "Training",
              image: "https://flyhub.in/assets/icons/training.png",
              click_url: "training",
            },
            {
              cname: "Add Drone",
              image: "https://flyhub.in/assets/icons/add_drone.png",
              click_url: "add_drone",
            },
            {
              cname: "Drone Services",
              image: "https://flyhub.in/assets/icons/services.png",
              click_url: "drone_services",
            },
            {
              cname: "Maintenance",
              image: "https://flyhub.in/assets/icons/maintenance.png",
              click_url: "maintenance",
            },
          ],
        },
      ];
    },
  },

  Mutation: {
    createDrone: async (_, { input }) => {
      try {
        const drone = new Drone({
          ...input,
          status: "pending", // ✅ new drones wait for admin approval
        });

        const saved = await drone.save();
        return {
          id: saved._id.toString(),
          ...saved._doc,
        };
      } catch (err) {
        console.error("❌ Error creating drone:", err);
        throw new Error("Failed to create drone");
      }
    },

approveAllPendingDrones: async () => {
  try {
    const result = await Drone.updateMany(
      { status: "pending" },
      { $set: { status: "approved" } }
    );
    return {
      success: true,
      count: result.modifiedCount || 0,
    };
  } catch (err) {
    console.error("❌ Error approving all pending drones:", err);
    return { success: false, count: 0 };
  }
},


    updateDrone: async (_, { id, input }) => {
      const updated = await Drone.findByIdAndUpdate(id, input, { new: true });
      return updated ? { id: updated._id.toString(), ...updated._doc } : null;
    },

    updateDroneStatus: async (_, { id, status }) => {
      const updated = await Drone.findByIdAndUpdate(id, { status }, { new: true });
      return updated ? { id: updated._id.toString(), ...updated._doc } : null;
    },

    deleteDrone: async (_, { id }) => {
      const deleted = await Drone.findByIdAndDelete(id);
      if (!deleted) throw new Error("Drone not found");
      return { id: deleted._id.toString(), ...deleted._doc };
    },
  },
};
