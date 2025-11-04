// resolvers/accessoryResolvers.js
import { Accessory } from "../models/Accessories.model.js";
import { Seller } from "../models/Seller.model.js";
import { sendSellerStatusMail } from "../utils/emailService.js";
import { createSellerNotification } from "../utils/createSellerNotification.js";

export const accessoryResolvers = {
  Query: {
    // ✅ Fetch all accessories
    accessories: async () => {
      try {
        const accessories = await Accessory.find();
        return Promise.all(
          accessories.map(async (a) => {
            const seller = await Seller.findOne({ customId: a.sellerId });
            return {
              ...a.toObject(),
              sellerInfo: seller
                ? { email: seller.email, phoneNumber: seller.phoneNumber }
                : null,
            };
          })
        );
      } catch (error) {
        console.error("❌ Error fetching accessories:", error);
        throw new Error("Failed to fetch accessories");
      }
    },

    // ✅ Fetch one accessory
    accessory: async (_, { accessoryId }) => {
      try {
        const a = await Accessory.findOne({ accessoryId });
        if (!a) throw new Error("Accessory not found");

        const seller = await Seller.findOne({ customId: a.sellerId });
        return {
          ...a.toObject(),
          sellerInfo: seller
            ? { email: seller.email, phoneNumber: seller.phoneNumber }
            : null,
        };
      } catch (error) {
        console.error("❌ Error fetching accessory:", error);
        throw new Error("Failed to fetch accessory");
      }
    },

    // ✅ Status-based queries
    rejectedAccessories: async () => Accessory.find({ status: "rejected" }),
    approvedAccessories: async (_, { sellerId }) =>
      Accessory.find({ sellerId, status: "approved" }),
    pendingAccessories: async (_, { sellerId }) =>
      Accessory.find({ sellerId, status: "pending" }),
  },

  Mutation: {
    // ✅ Create Accessory
    createAccessory: async (_, { input }) => {
      try {
        const seller = await Seller.findOne({ customId: input.sellerId });
        if (!seller) throw new Error("Seller not found");

        const newAccessory = new Accessory({
          name: input.name,
          brand: input.brand,
          category: input.category,
          price: input.price,
          description: input.description,
          image: input.image,
          quantity: input.quantity || 1,
          status: "pending",
          sellerId: input.sellerId,
        });

        const saved = await newAccessory.save();
        return {
          ...saved.toObject(),
          sellerInfo: {
            email: seller.email,
            phoneNumber: seller.phoneNumber,
          },
        };
      } catch (err) {
        console.error("❌ Error creating accessory:", err);
        throw new Error("Failed to create accessory: " + err.message);
      }
    },

    // ✅ Update Accessory
    updateAccessory: async (_, { accessoryId, input }) => {
      try {
        const updated = await Accessory.findOneAndUpdate(
          { accessoryId },
          input,
          { new: true }
        );
        if (!updated) throw new Error("Accessory not found");

        const seller = await Seller.findOne({ customId: updated.sellerId });
        return {
          ...updated.toObject(),
          sellerInfo: seller
            ? { email: seller.email, phoneNumber: seller.phoneNumber }
            : null,
        };
      } catch (err) {
        console.error("❌ Error updating accessory:", err);
        throw new Error("Failed to update accessory");
      }
    },

    // ✅ Update Accessory Status + Notify (email + push + in-app + subscription)
    updateAccessoryStatus: async (_, { accessoryId, status }, { pubsub }) => {
      try {
        const updated = await Accessory.findOneAndUpdate(
          { accessoryId },
          { status },
          { new: true }
        );
        if (!updated) throw new Error("Accessory not found");

        const seller = await Seller.findOne({ customId: updated.sellerId });

        // 1) Send email (existing)
        if (seller?.email) {
          try {
            await sendSellerStatusMail({
              to: seller.email,
              productType: "Accessory",
              productName: updated.name,
              status,
            });
          } catch (mailErr) {
            console.error("⚠️ sendSellerStatusMail failed:", mailErr);
          }
        }

        // 2) Create in-app notification & send push + publish to clients
        try {
          await createSellerNotification({
            sellerId: updated.sellerId,
            title: `Accessory ${status.toUpperCase()}: ${updated.name}`,
            message:
              status.toLowerCase() === "approved"
                ? `Your accessory "${updated.name}" has been approved and is live on Flyhub.`
                : status.toLowerCase() === "rejected"
                ? `Your accessory "${updated.name}" was rejected. Please check details and re-submit.`
                : `Status updated to ${status} for "${updated.name}"`,
            type: "accessory_status",
            data: { accessoryId: updated.accessoryId, status },
            url: `/seller/accessories/${updated.accessoryId}`, // optional deep-link
            pubsub, // publish event for frontend subscription
          });
        } catch (notifErr) {
          console.error("⚠️ createSellerNotification failed:", notifErr);
        }

        return {
          ...updated.toObject(),
          sellerInfo: seller
            ? { email: seller.email, phoneNumber: seller.phoneNumber }
            : null,
        };
      } catch (err) {
        console.error("❌ Error updating accessory status:", err);
        throw new Error("Failed to update accessory status");
      }
    },

    // ✅ Delete Accessory
    deleteAccessory: async (_, { accessoryId }) => {
      try {
        const deleted = await Accessory.findOneAndDelete({ accessoryId });
        if (!deleted) throw new Error("Accessory not found");

        const seller = await Seller.findOne({ customId: deleted.sellerId });
        return {
          ...deleted.toObject(),
          sellerInfo: seller
            ? { email: seller.email, phoneNumber: seller.phoneNumber }
            : null,
        };
      } catch (err) {
        console.error("❌ Error deleting accessory:", err);
        throw new Error("Failed to delete accessory");
      }
    },
  },
};
