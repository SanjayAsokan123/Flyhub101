import { Seller } from "../models/Seller.model.js";
import { sendSellerStatusMail } from "../utils/emailService.js";
import { createSellerNotification } from "../utils/createSellerNotification.js";

/**
 * 🧠 Seller Resolvers
 * Supports:
 *  - Unified seller lookup by email, username, phone, or customId
 *  - Auto-creation of new sellers for Firebase/Auth sync
 *  - CRUD + FCM token registration
 */

export const sellerResolvers = {
  Query: {
    /**
     * 🟢 Fetch all sellers
     */
    getSellers: async () => {
      try {
        return await Seller.find().sort({ createdAt: -1 });
      } catch (err) {
        console.error("❌ Error fetching sellers:", err);
        throw new Error("Failed to fetch sellers: " + err.message);
      }
    },

    /**
     * 🟢 Fetch single seller by customId or _id
     */
    getSeller: async (_, { customId }) => {
      try {
        let seller = await Seller.findOne({ customId });
        if (!seller) seller = await Seller.findById(customId);
        if (!seller) throw new Error("Seller not found");
        return seller;
      } catch (err) {
        console.error("❌ Error fetching seller:", err);
        throw new Error("Failed to fetch seller: " + err.message);
      }
    },

    /**
     * 🟡 Fetch sellers by status
     */
    getSellersByStatus: async (_, { status = "pending" }) => {
      try {
        const validStatuses = ["pending", "approved", "rejected"];
        const queryStatus = validStatuses.includes(status.toLowerCase())
          ? status.toLowerCase()
          : "pending";
        return await Seller.find({ status: queryStatus }).sort({
          createdAt: -1,
        });
      } catch (err) {
        console.error("❌ Error fetching sellers by status:", err);
        throw new Error("Failed to fetch sellers by status: " + err.message);
      }
    },

    /**
     * 🟣 Fetch seller by email / username / phone / customId
     */
    sellerByEmail: async (_, { email, username, phone, customId }) => {
      try {
        if (!email && !username && !phone && !customId) {
          throw new Error(
            "At least one of email, username, phone, or customId is required"
          );
        }

        // 🔍 Find seller by any of the identifiers
        let seller = await Seller.findOne({
          $or: [
            email ? { email } : null,
            username ? { name: username } : null,
            phone ? { phoneNumber: phone } : null,
            customId ? { customId } : null,
          ].filter(Boolean),
        });

        // 🆕 Auto-create if not found (Firebase/Google sign-in case)
        if (!seller) {
          console.log(
            "⚠️ Seller not found, creating new record for:",
            email || username || phone || customId
          );

          seller = new Seller({
            email:
              email ||
              `${username || phone || customId}@flyhubplaceholder.com`,
            name: username || (email ? email.split("@")[0] : "New Seller"),
            companyName: "Pending Registration",
            PANnumber: "PENDING",
            address: "Pending Address",
            phoneNumber: phone || "0000000000",
            status: "pending",
            shippingAddresses: [],
            pickupAddresses: [],
          });

          await seller.save();
          console.log(`✅ New seller auto-created: ${seller.customId}`);
        }

        return seller;
      } catch (err) {
        console.error("❌ Error fetching seller:", err);
        throw new Error("Failed to fetch or create seller: " + err.message);
      }
    },
  },

  Mutation: {
    /**
     * 🟢 Create a new seller (admin or registration form)
     */
    createSeller: async (_, { input }, { pubsub }) => {
      try {
        const existing = await Seller.findOne({ email: input.email });
        if (existing)
          throw new Error("Seller with this email already exists");

        const seller = new Seller({
          ...input,
          shippingAddresses: input.shippingAddresses || [],
          pickupAddresses: input.pickupAddresses || [],
          status: "pending",
        });

        const savedSeller = await seller.save();
        console.log(`✅ Seller created: ${savedSeller.customId}`);

        // 🔔 Notify Admins of new seller registration
        await createSellerNotification({
          sellerId: "ADMIN",
          title: "🆕 New Seller Registered",
          message: `A new seller "${savedSeller.name}" has registered and is awaiting approval.`,
          type: "seller_created",
          data: { customId: savedSeller.customId },
          url: `/admin/sellers/${savedSeller.customId}`,
          pubsub,
        });

        return savedSeller;
      } catch (err) {
        console.error("❌ Error creating seller:", err);
        throw new Error("Failed to create seller: " + err.message);
      }
    },

    /**
     * ✏️ Update existing seller details
     */
    updateSeller: async (_, { customId, input }) => {
      try {
        const updated = await Seller.findOneAndUpdate(
          { customId },
          { ...input },
          { new: true }
        );

        if (!updated)
          throw new Error(`Seller with ID ${customId} not found`);

        console.log(`✅ Seller updated: ${customId}`);
        return updated;
      } catch (err) {
        console.error("❌ Error updating seller:", err);
        throw new Error("Failed to update seller: " + err.message);
      }
    },

    /**
     * 🔄 Change seller status (pending → approved / rejected)
     */
    changeSellerStatus: async (_, { customId, status }, { pubsub }) => {
      try {
        const validStatuses = ["pending", "approved", "rejected"];
        if (!validStatuses.includes(status.toLowerCase()))
          throw new Error(
            "Invalid status. Must be pending, approved, or rejected."
          );

        const seller = await Seller.findOne({ customId });
        if (!seller) throw new Error("Seller not found");

        seller.status = status.toLowerCase();
        await seller.save();

        console.log(`✅ Seller ${customId} status changed to ${status}`);

        // 📨 Send email to seller
        if (seller.email) {
          await sendSellerStatusMail({
            to: seller.email,
            productType: "Seller Account",
            productName: seller.companyName || seller.name,
            status,
          });
        }

        // 🔔 Notify Seller
        await createSellerNotification({
          sellerId: seller.customId,
          title:
            status === "approved"
              ? "✅ Seller Account Approved"
              : status === "rejected"
              ? "❌ Seller Account Rejected"
              : "ℹ️ Seller Status Updated",
          message:
            status === "approved"
              ? "Congratulations! Your seller account has been approved."
              : status === "rejected"
              ? "Your seller account was rejected. Contact support."
              : `Your account is now marked as "${status}".`,
          type: "seller_status",
          data: { customId, status },
          url: `/seller/dashboard`,
          pubsub,
        });

        // 🔔 Notify Admins
        await createSellerNotification({
          sellerId: "ADMIN",
          title: `📣 Seller Status Changed`,
          message: `Seller "${seller.name}" (${customId}) marked as ${status}.`,
          type: "seller_status_admin",
          data: { customId, status },
          url: `/admin/sellers/${customId}`,
          pubsub,
        });

        return seller;
      } catch (err) {
        console.error("❌ Error changing seller status:", err);
        throw new Error("Failed to change seller status: " + err.message);
      }
    },

    /**
     * 🗑️ Delete a seller account
     */
    deleteSeller: async (_, { customId }, { pubsub }) => {
      try {
        const deleted =
          (await Seller.findOneAndDelete({ customId })) ||
          (await Seller.findByIdAndDelete(customId));

        if (!deleted)
          throw new Error("Seller not found or already deleted");

        console.log("🗑️ Seller deleted:", customId);

        await createSellerNotification({
          sellerId: "ADMIN",
          title: "🗑️ Seller Deleted",
          message: `Seller "${deleted.name}" (ID: ${customId}) has been removed.`,
          type: "seller_deleted",
          data: { customId },
          url: `/admin/sellers`,
          pubsub,
        });

        return deleted;
      } catch (err) {
        console.error("❌ Error deleting seller:", err);
        throw new Error("Failed to delete seller: " + err.message);
      }
    },

    /**
     * 📲 Register or update FCM token
     */
    updateSellerFcmToken: async (_, { customId, token }) => {
      try {
        if (!customId || !token)
          throw new Error("customId and token are required");

        const seller = await Seller.findOne({ customId });
        if (!seller) throw new Error("Seller not found");

        await seller.addFcmToken(token);
        console.log(`📱 FCM token added for seller ${customId}`);

        return {
          success: true,
          message: "Token registered successfully",
          seller,
        };
      } catch (err) {
        console.error("❌ Error updating FCM token:", err);
        return {
          success: false,
          message: "Failed to register FCM token: " + err.message,
        };
      }
    },
  },
};
