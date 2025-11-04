import { Regulatory } from "../models/Regulatory.model.js";
import { createSellerNotification } from "../utils/createSellerNotification.js";

export const regulatoryResolvers = {
  Query: {
    /**
     * 🟢 Fetch a single regulatory record by ID
     */
    regulatory: async (_, { id }) => {
      const record = await Regulatory.findById(id);
      if (!record) throw new Error("Regulatory record not found");

      return {
        ...record.toObject(),
        id: record._id.toString(),
        title: record.title || "Untitled Regulation",
        imagePath: record.imagePath || "N/A",
        shortDescription:
          record.shortDescription || "No short description provided.",
        fullDescription:
          record.fullDescription || "No detailed description available.",
      };
    },

    /**
     * 🟢 Fetch all regulatory records (latest first)
     */
    regulatoryAll: async () => {
      const records = await Regulatory.find().sort({ createdAt: -1 });
      return records.map((r) => ({
        ...r.toObject(),
        id: r._id.toString(),
        title: r.title || "Untitled Regulation",
        imagePath: r.imagePath || "N/A",
        shortDescription:
          r.shortDescription || "No short description provided.",
        fullDescription:
          r.fullDescription || "No detailed description available.",
      }));
    },
  },

  Mutation: {
    /**
     * 🟢 Create a new regulatory record
     * Adds admin notification (real-time + in-app)
     */
    createRegulatory: async (_, { input }, { pubsub }) => {
      const sanitizedInput = {
        title: input.title?.trim() || "Untitled Regulation",
        date: input.date || new Date().toISOString().split("T")[0],
        imagePath: input.imagePath?.trim() || "N/A",
        shortDescription:
          input.shortDescription?.trim() || "No short description provided.",
        fullDescription:
          input.fullDescription?.trim() || "No detailed description available.",
      };

      const newRecord = new Regulatory(sanitizedInput);
      await newRecord.save();

      // 🔔 Notify admin dashboards or content managers
      try {
        await createSellerNotification({
          sellerId: "ADMIN", // pseudo-id for admin broadcast
          title: "📜 New Regulation Added",
          message: `A new regulatory update "${sanitizedInput.title}" has been published.`,
          type: "regulatory_create",
          data: { id: newRecord._id.toString() },
          url: `/admin/regulatory/${newRecord._id}`,
          pubsub,
        });
      } catch (notifErr) {
        console.error("⚠️ Notification creation failed:", notifErr);
      }

      return {
        ...newRecord.toObject(),
        id: newRecord._id.toString(),
      };
    },

    /**
     * ✏️ Update an existing regulatory record
     * Triggers dashboard update notifications
     */
    updateRegulatory: async (_, { id, input }, { pubsub }) => {
      const updatedRecord = await Regulatory.findByIdAndUpdate(
        id,
        { ...input },
        { new: true, runValidators: true }
      );

      if (!updatedRecord) throw new Error("Regulatory record not found");

      // 🔔 Notify dashboard listeners (e.g., editors, compliance team)
      try {
        await createSellerNotification({
          sellerId: "ADMIN",
          title: "📢 Regulation Updated",
          message: `Regulation "${updatedRecord.title}" has been modified.`,
          type: "regulatory_update",
          data: { id },
          url: `/admin/regulatory/${id}`,
          pubsub,
        });
      } catch (notifErr) {
        console.error("⚠️ Update notification error:", notifErr);
      }

      return {
        ...updatedRecord.toObject(),
        id: updatedRecord._id.toString(),
      };
    },

    /**
     * 🗑 Delete a regulatory record
     * Notifies admins and compliance teams
     */
    deleteRegulatory: async (_, { id }, { pubsub }) => {
      const deletedRecord = await Regulatory.findByIdAndDelete(id);
      if (!deletedRecord) throw new Error("Regulatory record not found");

      try {
        await createSellerNotification({
          sellerId: "ADMIN",
          title: "❌ Regulation Deleted",
          message: `Regulatory record "${deletedRecord.title}" has been removed.`,
          type: "regulatory_delete",
          data: { id },
          url: `/admin/regulatory`,
          pubsub,
        });
      } catch (notifErr) {
        console.error("⚠️ Delete notification error:", notifErr);
      }

      return {
        ...deletedRecord.toObject(),
        id: deletedRecord._id.toString(),
      };
    },
  },
};
