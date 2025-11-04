import { Part } from "../models/Parts.model.js";
import { Seller } from "../models/Seller.model.js";
import { sendSellerStatusMail } from "../utils/emailService.js";
import { createSellerNotification } from "../utils/createSellerNotification.js";

export const partResolvers = {
  Query: {
    // ✅ Fetch all parts with seller info
    parts: async () => {
      try {
        const allParts = await Part.find();
        const sellerIds = [...new Set(allParts.map((p) => p.sellerId))];
        const sellers = await Seller.find({ customId: { $in: sellerIds } });
        const sellerMap = Object.fromEntries(
          sellers.map((s) => [s.customId, { email: s.email, phoneNumber: s.phoneNumber }])
        );

        return allParts.map((part) => ({
          ...part.toObject(),
          sellerInfo: sellerMap[part.sellerId] || null,
        }));
      } catch (err) {
        console.error("❌ Error fetching parts:", err);
        throw new Error("Failed to fetch parts");
      }
    },

    // ✅ Approved parts for a seller
    approvedParts: async (_, { sellerId }) =>
      Part.find({ sellerId, status: "approved" }),

    // ✅ Pending parts for a seller
    pendingParts: async (_, { sellerId }) =>
      Part.find({ sellerId, status: "pending" }),

    // ✅ Rejected parts for a seller
    rejectedParts: async (_, { sellerId }) =>
      Part.find({ sellerId, status: "rejected" }),

    // ✅ Fetch single part
    part: async (_, { partId }) => {
      try {
        const part = await Part.findOne({ partId });
        if (!part) throw new Error("Part not found");
        const seller = await Seller.findOne({ customId: part.sellerId });

        return {
          ...part.toObject(),
          sellerInfo: seller
            ? { email: seller.email, phoneNumber: seller.phoneNumber }
            : null,
        };
      } catch (err) {
        console.error("❌ Error fetching part:", err);
        throw new Error("Failed to fetch part");
      }
    },
  },

  Mutation: {
    // 🟢 Create a new part
    createPart: async (_, { input }, { pubsub }) => {
      try {
        const seller = await Seller.findOne({ customId: input.sellerId });
        if (!seller) throw new Error("Seller not found");

        const newPart = new Part({
          ...input,
          status: "pending",
        });

        const saved = await newPart.save();

        // 🔔 Optional: Notify seller
        try {
          await createSellerNotification({
            sellerId: input.sellerId,
            title: "🧩 New Part Submitted",
            message: `Your part "${input.name}" has been submitted for admin approval.`,
            type: "part_submission",
            data: { partId: saved.partId },
            url: `/seller/parts/${saved.partId}`,
            pubsub,
          });
        } catch (notifErr) {
          console.error("⚠️ Notification error:", notifErr);
        }

        return {
          ...saved.toObject(),
          sellerInfo: {
            email: seller.email,
            phoneNumber: seller.phoneNumber,
          },
        };
      } catch (err) {
        console.error("❌ Error creating part:", err);
        throw new Error("Failed to create part: " + err.message);
      }
    },

    // ✏️ Update part details
    updatePart: async (_, { partId, input }) => {
      try {
        const updated = await Part.findOneAndUpdate({ partId }, input, { new: true });
        if (!updated) throw new Error("Part not found");

        const seller = await Seller.findOne({ customId: updated.sellerId });
        return {
          ...updated.toObject(),
          sellerInfo: seller
            ? { email: seller.email, phoneNumber: seller.phoneNumber }
            : null,
        };
      } catch (err) {
        console.error("❌ Error updating part:", err);
        throw new Error("Failed to update part");
      }
    },

    // ✅ Update Part Status + Notifications
    updatePartStatus: async (_, { partId, status }, { pubsub }) => {
      try {
        const updated = await Part.findOneAndUpdate(
          { partId },
          { status },
          { new: true }
        );
        if (!updated) throw new Error("Part not found");

        const seller = await Seller.findOne({ customId: updated.sellerId });
        if (seller?.email) {
          await sendSellerStatusMail({
            to: seller.email,
            productType: "Part",
            productName: updated.name,
            status,
          });
        }

        // 🔔 Create real-time + in-app notification
        try {
          await createSellerNotification({
            sellerId: updated.sellerId,
            title: `🧩 Part ${status === "approved" ? "Approved" : "Status Updated"}`,
            message:
              status === "approved"
                ? `Your part "${updated.name}" has been approved and listed on Flyhub.`
                : `Your part "${updated.name}" status changed to "${status}".`,
            type: "part_status",
            data: { partId, status },
            url: `/seller/parts/${partId}`,
            pubsub,
          });
        } catch (notifErr) {
          console.error("⚠️ Notification creation failed:", notifErr);
        }

        return {
          ...updated.toObject(),
          sellerInfo: seller
            ? { email: seller.email, phoneNumber: seller.phoneNumber }
            : null,
        };
      } catch (err) {
        console.error("❌ Error updating part status:", err);
        throw new Error("Failed to update part status");
      }
    },

    // 🗑 Delete part
    deletePart: async (_, { partId }, { pubsub }) => {
      try {
        const deleted = await Part.findOneAndDelete({ partId });
        if (!deleted) throw new Error("Part not found");

        const seller = await Seller.findOne({ customId: deleted.sellerId });

        // 🔔 Notify seller
        try {
          await createSellerNotification({
            sellerId: deleted.sellerId,
            title: "🗑️ Part Deleted",
            message: `Your part "${deleted.name}" has been removed from the marketplace.`,
            type: "part_deleted",
            data: { partId },
            url: `/seller/parts`,
            pubsub,
          });
        } catch (notifErr) {
          console.error("⚠️ Delete notification error:", notifErr);
        }

        return {
          ...deleted.toObject(),
          sellerInfo: seller
            ? { email: seller.email, phoneNumber: seller.phoneNumber }
            : null,
        };
      } catch (err) {
        console.error("❌ Error deleting part:", err);
        throw new Error("Failed to delete part");
      }
    },
  },
};
