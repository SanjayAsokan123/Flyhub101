import Part from "../models/Parts.js";

export const partResolvers = {
  Query: {
    parts: async () => {
      const parts = await Part.find();
      return parts.map((p) => ({
        id: p._id.toString(),
        ...p._doc,
      }));
    },

    part: async (_, { id }) => {
      const p = await Part.findById(id);
      return p ? { id: p._id.toString(), ...p._doc } : null;
    },

    rejectedParts: async () => {
      const parts = await Part.find({ status: "rejected" });
      return parts.map((p) => ({
        id: p._id.toString(),
        ...p._doc,
      }));
    },
  },

  Mutation: {
    createPart: async (_, { input }) => {
      try {
        const part = new Part({
          ...input,
          status: "pending", // ✅ waiting for admin approval
        });

        const saved = await part.save();
        return {
          id: saved._id.toString(),
          ...saved._doc,
        };
      } catch (err) {
        console.error("❌ Error creating part:", err);
        throw new Error("Failed to create part");
      }
    },

approveAllPendingParts: async () => {
  try {
    const result = await Part.updateMany(
      { status: "pending" },
      { $set: { status: "approved" } }
    );
    return {
      success: true,
      count: result.modifiedCount || 0,
    };
  } catch (err) {
    console.error("❌ Error approving all pending parts:", err);
    return { success: false, count: 0 };
  }
},


    updatePart: async (_, { id, input }) => {
      const updated = await Part.findByIdAndUpdate(id, input, { new: true });
      return updated ? { id: updated._id.toString(), ...updated._doc } : null;
    },

    updatePartStatus: async (_, { id, status }) => {
      const updated = await Part.findByIdAndUpdate(id, { status }, { new: true });
      return updated ? { id: updated._id.toString(), ...updated._doc } : null;
    },

    deletePart: async (_, { id }) => {
      const deleted = await Part.findByIdAndDelete(id);
      if (!deleted) throw new Error("Part not found");
      return { id: deleted._id.toString(), ...deleted._doc };
    },
  },
};
