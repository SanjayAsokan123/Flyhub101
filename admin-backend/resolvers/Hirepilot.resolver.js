import { HirePilot } from "../models/Hirepilot.model.js";
import { Seller } from "../models/Seller.model.js";
import { sendSellerStatusMail } from "../utils/emailService.js";
import { createSellerNotification } from "../utils/createSellerNotification.js";

// 🔗 Common lookup for seller info
const baseLookup = [
  {
    $lookup: {
      from: "sellers",
      localField: "sellerId",
      foreignField: "customId",
      as: "sellerDetails",
    },
  },
  { $unwind: { path: "$sellerDetails", preserveNullAndEmptyArrays: true } },
  {
    $project: {
      _id: 1,
      pilotId: 1,
      pilotName: 1,
      companyName: 1,
      location: 1,
      salary: 1,
      experience: 1,
      licenseNumber: 1,
      skills: 1,
      employmentType: 1,
      droneType: 1,
      contactEmail: 1,
      contactNumber: 1,
      status: 1,
      sellerId: 1,
      seller: {
        name: "$sellerDetails.name",
        email: "$sellerDetails.email",
        phoneNumber: "$sellerDetails.phoneNumber",
      },
    },
  },
];

export const hirePilotResolvers = {
  Query: {
    // ✅ All pilots
    hirePilots: async () => HirePilot.aggregate(baseLookup),

    // ✅ Pilot by ID
    hirePilot: async (_, { pilotId }) => {
      const result = await HirePilot.aggregate([
        { $match: { pilotId } },
        ...baseLookup,
      ]);
      return result[0] || null;
    },

    // ✅ Pilots by seller
    hirePilotsBySeller: async (_, { sellerId }) =>
      HirePilot.aggregate([{ $match: { sellerId } }, ...baseLookup]),

    // ✅ Filter by status
    hirePilotsByStatus: async (_, { status }) => {
      const validStatuses = ["pending", "approved", "rejected"];
      if (!validStatuses.includes(status.toLowerCase())) {
        throw new Error(`Invalid status. Must be one of: ${validStatuses.join(", ")}`);
      }
      return HirePilot.aggregate([
        { $match: { status: status.toLowerCase() } },
        ...baseLookup,
      ]);
    },
  },

  Mutation: {
    // ✅ Create new pilot (with notification)
    addHirePilot: async (_, { input }, { pubsub }) => {
      try {
        const seller = await Seller.findOne({ customId: input.sellerId });
        if (!seller) throw new Error("Seller not found");

        const newPilot = new HirePilot({
          ...input,
          status: "pending",
        });

        await newPilot.save();

        // 🔔 Notify seller of pending approval
        try {
          await createSellerNotification({
            sellerId: input.sellerId,
            title: "New Pilot Submitted",
            message: `Your pilot "${input.pilotName}" has been submitted and is pending approval.`,
            type: "hire_pilot_listing",
            data: { pilotId: newPilot.pilotId, status: "pending" },
            url: `/seller/pilots/${newPilot.pilotId}`,
            pubsub,
          });
        } catch (notifErr) {
          console.error("⚠️ createSellerNotification failed:", notifErr);
        }

        const result = await HirePilot.aggregate([
          { $match: { _id: newPilot._id } },
          ...baseLookup,
        ]);
        return result[0];
      } catch (error) {
        console.error("❌ Error creating pilot:", error);
        throw new Error("Failed to create pilot: " + error.message);
      }
    },

    // ✅ Update pilot info
    updateHirePilot: async (_, { pilotId, input }) => {
      try {
        const updated = await HirePilot.findOneAndUpdate(
          { pilotId },
          input,
          { new: true }
        );
        if (!updated) throw new Error("Pilot not found");

        const result = await HirePilot.aggregate([
          { $match: { pilotId } },
          ...baseLookup,
        ]);
        return result[0];
      } catch (error) {
        console.error("❌ Error updating pilot:", error);
        throw new Error("Failed to update pilot: " + error.message);
      }
    },

    // ✅ Delete pilot
    deleteHirePilot: async (_, { pilotId }, { pubsub }) => {
      try {
        const deleted = await HirePilot.findOneAndDelete({ pilotId });
        if (!deleted) throw new Error("Pilot not found");

        // 🔔 Notify seller
        try {
          await createSellerNotification({
            sellerId: deleted.sellerId,
            title: "Pilot Listing Deleted",
            message: `Your pilot "${deleted.pilotName}" has been deleted from Flyhub.`,
            type: "hire_pilot_deleted",
            data: { pilotId },
            url: `/seller/pilots`,
            pubsub,
          });
        } catch (notifErr) {
          console.error("⚠️ createSellerNotification failed:", notifErr);
        }

        return { id: deleted._id.toString(), ...deleted.toObject() };
      } catch (error) {
        console.error("❌ Error deleting pilot:", error);
        throw new Error("Failed to delete pilot: " + error.message);
      }
    },

    // ✅ Update pilot status (email + notifications)
    updateHirePilotStatus: async (_, { pilotId, status }, { pubsub }) => {
      try {
        const updated = await HirePilot.findOneAndUpdate(
          { pilotId },
          { status },
          { new: true }
        );
        if (!updated) throw new Error("Pilot not found");

        const seller = await Seller.findOne({ customId: updated.sellerId });

        // ✉️ Email Notification
        if (seller?.email) {
          try {
            await sendSellerStatusMail({
              to: seller.email,
              productType: "Hire Pilot",
              productName: updated.pilotName,
              status,
            });
          } catch (mailErr) {
            console.error("⚠️ sendSellerStatusMail failed:", mailErr);
          }
        }

        // 🔔 In-App + Push + Subscription Notification
        try {
          await createSellerNotification({
            sellerId: updated.sellerId,
            title: `Pilot ${status.toUpperCase()}: ${updated.pilotName}`,
            message:
              status.toLowerCase() === "approved"
                ? `Your pilot "${updated.pilotName}" has been approved and is now visible.`
                : status.toLowerCase() === "rejected"
                ? `Your pilot "${updated.pilotName}" was rejected. Please review and resubmit.`
                : `Pilot status updated to ${status} for "${updated.pilotName}".`,
            type: "hire_pilot_status",
            data: { pilotId, status },
            url: `/seller/pilots/${updated.pilotId}`,
            pubsub,
          });
        } catch (notifErr) {
          console.error("⚠️ createSellerNotification failed:", notifErr);
        }

        const result = await HirePilot.aggregate([
          { $match: { _id: updated._id } },
          ...baseLookup,
        ]);
        return result[0];
      } catch (err) {
        console.error("❌ Error updating pilot status:", err);
        throw new Error("Failed to update pilot status: " + err.message);
      }
    },
  },
};
