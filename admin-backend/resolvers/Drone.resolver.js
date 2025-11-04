import { Drone } from "../models/Drone.model.js";
import { Seller } from "../models/Seller.model.js";
import { sendSellerStatusMail } from "../utils/emailService.js";
import { createSellerNotification } from "../utils/createSellerNotification.js";

export const droneResolvers = {
  Query: {
    // ✅ Get all drones with seller info
    drones: async () => {
      try {
        const drones = await Drone.aggregate([
          {
            $lookup: {
              from: "sellers",
              localField: "sellerId",
              foreignField: "customId",
              as: "sellerInfo",
            },
          },
          { $unwind: "$sellerInfo" },
          {
            $project: {
              droneId: 1,
              name: 1,
              brand: 1,
              uin: 1,
              price: 1,
              description: 1,
              image: 1,
              status: 1,
              wishlist: 1,
              sellerId: 1,
              "sellerInfo.email": 1,
              "sellerInfo.phoneNumber": 1,
            },
          },
        ]);
        return drones;
      } catch (err) {
        console.error("❌ Error fetching drones:", err);
        throw new Error("Failed to fetch drones");
      }
    },

    // ✅ Approved drones for a seller
    approvedDrones: async (_, { sellerId }) => Drone.find({ sellerId, status: "approved" }),

    // ✅ Pending drones for a seller
    pendingDrones: async (_, { sellerId }) => Drone.find({ sellerId, status: "pending" }),

    // ✅ Rejected drones for a seller
    rejectedDrones: async (_, { sellerId }) => Drone.find({ sellerId, status: "rejected" }),
  },

  Mutation: {
    // ✅ Create a new drone
    createDrone: async (_, { input }, { pubsub }) => {
      try {
        const seller = await Seller.findOne({ customId: input.sellerId });
        if (!seller) throw new Error("Seller not found");

        const newDrone = new Drone({
          droneId: input.droneId,
          name: input.name,
          brand: input.brand,
          uin: input.uin,
          price: input.price,
          description: input.description,
          image: input.image,
          status: "pending", // default
          sellerId: input.sellerId,
        });

        const savedDrone = await newDrone.save();

        // 🔔 Notify seller of new drone listing
        try {
          await createSellerNotification({
            sellerId: input.sellerId,
            title: "Drone Listing Submitted",
            message: `Your drone "${input.name}" has been submitted and is pending review.`,
            type: "drone_listing",
            data: { uin: input.uin, status: "pending" },
            url: `/seller/drones/${input.uin}`,
            pubsub,
          });
        } catch (notifErr) {
          console.error("⚠️ createSellerNotification failed:", notifErr);
        }

        return {
          ...savedDrone.toObject(),
          sellerInfo: {
            email: seller.email,
            phoneNumber: seller.phoneNumber,
          },
        };
      } catch (err) {
        console.error("❌ Error creating drone:", err);
        throw new Error("Failed to create drone: " + err.message);
      }
    },

    // ✅ Update drone status with email + notification + push + subscription
    updateDroneStatus: async (_, { uin, status }, { pubsub }) => {
      try {
        const updated = await Drone.findOneAndUpdate({ uin }, { status }, { new: true });
        if (!updated) throw new Error("Drone not found");

        const seller = await Seller.findOne({ customId: updated.sellerId });
        if (!seller) throw new Error("Seller not found for this drone");

        // ✉️ Send email to seller
        if (seller.email) {
          try {
            await sendSellerStatusMail({
              to: seller.email,
              productType: "Drone",
              productName: updated.name,
              status,
            });
          } catch (mailErr) {
            console.error("⚠️ sendSellerStatusMail failed:", mailErr);
          }
        }

        // 🔔 Create in-app + push notification + broadcast
        try {
          await createSellerNotification({
            sellerId: updated.sellerId,
            title: `Drone ${status.toUpperCase()}: ${updated.name}`,
            message:
              status.toLowerCase() === "approved"
                ? `Your drone "${updated.name}" has been approved and is now live.`
                : status.toLowerCase() === "rejected"
                ? `Your drone "${updated.name}" was rejected. Please review and resubmit.`
                : `Drone status updated to ${status} for "${updated.name}".`,
            type: "drone_status",
            data: { uin: updated.uin, status },
            url: `/seller/drones/${updated.uin}`,
            pubsub,
          });
        } catch (notifErr) {
          console.error("⚠️ createSellerNotification failed:", notifErr);
        }

        return {
          ...updated.toObject(),
          sellerInfo: {
            email: seller.email,
            phoneNumber: seller.phoneNumber,
          },
        };
      } catch (err) {
        console.error("❌ Error updating drone status:", err);
        throw new Error("Failed to update drone status: " + err.message);
      }
    },

    // ✅ Delete drone by UIN
    deleteDrone: async (_, { uin }, { pubsub }) => {
      try {
        const deleted = await Drone.findOneAndDelete({ uin });
        if (!deleted) throw new Error("Drone not found");

        const seller = await Seller.findOne({ customId: deleted.sellerId });

        // 🔔 Notify seller that drone was deleted
        try {
          await createSellerNotification({
            sellerId: deleted.sellerId,
            title: `Drone Deleted`,
            message: `Your drone "${deleted.name}" has been removed from Flyhub.`,
            type: "drone_deleted",
            data: { uin },
            url: `/seller/drones`,
            pubsub,
          });
        } catch (notifErr) {
          console.error("⚠️ createSellerNotification failed:", notifErr);
        }

        return {
          ...deleted.toObject(),
          sellerInfo: seller
            ? { email: seller.email, phoneNumber: seller.phoneNumber }
            : null,
        };
      } catch (err) {
        console.error("❌ Error deleting drone:", err);
        throw new Error("Failed to delete drone");
      }
    },
  },
};
