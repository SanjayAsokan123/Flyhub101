import Accessory from "../models/Accessories.js";

export const accessoryResolvers = {
  Query: {
    accessories: async () => {
      const accessories = await Accessory.find();
      return accessories.map((a) => ({
        id: a._id.toString(),
        ...a._doc,
      }));
    },

    accessory: async (_, { id }) => {
      const a = await Accessory.findById(id);
      return a ? { id: a._id.toString(), ...a._doc } : null;
    },

    rejectedAccessories: async () => {
      const accessories = await Accessory.find({ status: "rejected" });
      return accessories.map((a) => ({
        id: a._id.toString(),
        ...a._doc,
      }));
    },
  },

  Mutation: {
   createAccessory: async (_, { input }) => {
     try {
       const accessory = new Accessory({
         ...input,
         status: "pending", // ✅ waiting for admin approval
       });

       const saved = await accessory.save();
       return {
         id: saved._id.toString(),
         ...saved._doc,
       };
     } catch (err) {
       console.error("❌ Error creating accessory:", err);
       throw new Error("Failed to create accessory");
     }
   },

approveAllPendingAccessories: async () => {
  try {
    const result = await Accessory.updateMany(
      { status: "pending" },
      { $set: { status: "approved" } }
    );
    return {
      success: true,
      count: result.modifiedCount || 0,
    };
  } catch (err) {
    console.error("❌ Error approving all pending accessories:", err);
    return { success: false, count: 0 };
  }
},


    updateAccessory: async (_, { id, input }) => {
      const updated = await Accessory.findByIdAndUpdate(id, input, { new: true });
      return updated ? { id: updated._id.toString(), ...updated._doc } : null;
    },

    updateAccessoryStatus: async (_, { id, status }) => {
      const updated = await Accessory.findByIdAndUpdate(id, { status }, { new: true });
      return updated ? { id: updated._id.toString(), ...updated._doc } : null;
    },

    deleteAccessory: async (_, { id }) => {
      const deleted = await Accessory.findByIdAndDelete(id);
      if (!deleted) throw new Error("Accessory not found");
      return { id: deleted._id.toString(), ...deleted._doc };
    },
  },
};
