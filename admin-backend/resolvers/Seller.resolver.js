// backend/resolvers/sellerResolvers.js

import { Seller } from "../models/Seller.model.js";
import { sendSellerStatusMail } from "../utils/emailService.js";
import { createSellerNotification } from "../utils/createSellerNotification.js";
import { createLoginIndex, deleteLoginIndex } from "../utils/loginIndex.js";
import { auth } from "../config/firebaseAdmin.js";

export const sellerResolvers = {
  // ============================================================
  // 📊 QUERIES
  // ============================================================
  Query: {
    /**
     * 🟢 Fetch all sellers
     */
    getSellers: async () => {
      try {
        return await Seller.find().sort({ createdAt: -1 });
      } catch (err) {
        throw new Error(`Error fetching sellers: ${err.message}`);
      }
    },

    /**
     * 🟢 Fetch seller by customId or _id
     */
    getSeller: async (_, { customId }) => {
      try {
        let seller =
          (await Seller.findOne({ customId })) ||
          (await Seller.findById(customId));

        if (!seller) throw new Error("Seller not found");
        return seller;
      } catch (err) {
        throw new Error(`Error fetching seller: ${err.message}`);
      }
    },

    /**
     * 🟡 Fetch sellers by status
     */
    getSellersByStatus: async (_, { status = "pending" }) => {
      try {
        const valid = ["pending", "approved", "rejected"];
        const normalized = status.toLowerCase();

        if (!valid.includes(normalized))
          throw new Error(`Status must be: ${valid.join(", ")}`);

        return await Seller.find({ status: normalized }).sort({
          createdAt: -1,
        });
      } catch (err) {
        throw new Error(`Error filtering sellers: ${err.message}`);
      }
    },

    /**
     * 🟣 Unified seller lookup (email/phone/username/customId)
     * Auto-creates minimal pending seller if not found.
     */
    sellerByEmail: async (_, { email, username, phone, customId }) => {
      try {
        if (!email && !username && !phone && !customId)
          throw new Error(
            "Provide email OR phone OR username OR customId to search"
          );

        const query = {
          $or: [
            email ? { email } : null,
            username ? { name: username } : null,
            phone ? { phoneNumber: phone } : null,
            customId ? { customId } : null,
          ].filter(Boolean),
        };

        let seller = await Seller.findOne(query);

        // ------------------------------
        // 🆕 Auto-create minimal seller
        // ------------------------------
        if (!seller) {
          const autoEmail =
            email ||
            (username ? `${username}@autogen.flyhub` : null) ||
            (phone ? `${phone}@autogen.flyhub` : null);

          seller = new Seller({
            email: autoEmail,
            name: username || "New Seller",
            companyName: "Pending Store",
            PANnumber: "PENDING",
            address: "Pending Address",
            phoneNumber: phone || "0000000000",
            gstNumber: "",
            shippingAddresses: [],
            pickupAddresses: [],
            status: "pending",
          });

          await seller.save();

          // loginIndex entry
          await createLoginIndex({
            uid: null,
            email: seller.email,
            phone: seller.phoneNumber,
            sellerId: seller.customId,
          });
        }

        return seller;
      } catch (err) {
        throw new Error(`Lookup failed: ${err.message}`);
      }
    },
  },

  // ============================================================
  // 🔧 MUTATIONS
  // ============================================================
  Mutation: {
    /**
     * 🟢 Create seller (Registration Form)
     */
    createSeller: async (_, { input }, { pubsub }) => {
      try {
        const exists = await Seller.findOne({ email: input.email });
        if (exists) throw new Error("Seller already exists with this email");

        const seller = new Seller({
          ...input,
          shippingAddresses: input.shippingAddresses || [],
          pickupAddresses: input.pickupAddresses || [],
          status: "pending",
        });

        const savedSeller = await seller.save();

        // 🔗 loginIndex map
        await createLoginIndex({
          uid: savedSeller.firebaseUid || null,
          email: savedSeller.email,
          phone: savedSeller.phoneNumber,
          sellerId: savedSeller.customId,
        });

        // 🔔 Notify admin
        await createSellerNotification({
          sellerId: "ADMIN",
          title: "🆕 New Seller Registered",
          message: `Seller "${savedSeller.companyName}" is awaiting approval.`,
          type: "seller_created",
          data: { customId: savedSeller.customId },
          url: `/admin/sellers/${savedSeller.customId}`,
          pubsub,
        });

        return savedSeller;
      } catch (err) {
        throw new Error(`Create seller failed: ${err.message}`);
      }
    },

    /**
     * ✏️ Update seller
     */
    updateSeller: async (_, { customId, input }) => {
      try {
        const updated = await Seller.findOneAndUpdate(
          { customId },
          input,
          { new: true, runValidators: true }
        );

        if (!updated) throw new Error("Seller not found");
        return updated;
      } catch (err) {
        throw new Error(`Update failed: ${err.message}`);
      }
    },

    /**
     * 🔄 Change seller status (Approval / Rejection)
     */
    changeSellerStatus: async (_, { customId, status }, { pubsub }) => {
      try {
        const validStatuses = ["pending", "approved", "rejected"];
        const normalized = status.toLowerCase();

        if (!validStatuses.includes(normalized))
          throw new Error(
            `Status must be one of: ${validStatuses.join(", ")}`
          );

        const seller = await Seller.findOne({ customId });
        if (!seller) throw new Error("Seller not found");

        seller.status = normalized;
        await seller.save();

        // ✉ Send email
        try {
          await sendSellerStatusMail({
            to: seller.email,
            productType: "Seller Account",
            productName: seller.companyName,
            status: normalized,
          });
        } catch (err) {
          console.log("⚠ Email error:", err.message);
        }

        // 🔔 Seller notification
        await createSellerNotification({
          sellerId: seller.customId,
          title:
            normalized === "approved"
              ? "✅ Seller Account Approved"
              : normalized === "rejected"
              ? "❌ Seller Account Rejected"
              : "ℹ️ Status Updated",
          message:
            normalized === "approved"
              ? "Your seller account is approved!"
              : normalized === "rejected"
              ? "Your account was rejected. Contact support."
              : "Your account status changed.",
          type: "seller_status",
          data: { customId, status: normalized },
          url: `/seller/dashboard`,
          pubsub,
        });

        // 🔔 Admin notification
        await createSellerNotification({
          sellerId: "ADMIN",
          title: "📣 Seller Status Updated",
          message: `Seller ${customId} → ${normalized}`,
          type: "seller_status_admin",
          data: { customId, status: normalized },
          url: `/admin/sellers/${customId}`,
          pubsub,
        });

        return seller;
      } catch (err) {
        throw new Error(`Status update failed: ${err.message}`);
      }
    },

    /**
     * 🗑 DELETE seller (also delete loginIndex + Firebase UID)
     */
    deleteSeller: async (_, { customId }, { pubsub }) => {
      try {
        const seller =
          (await Seller.findOne({ customId })) ||
          (await Seller.findById(customId));

        if (!seller) throw new Error("Seller does not exist");

        // Delete loginIndex
        await deleteLoginIndex(seller.email, seller.phoneNumber, seller.customId);

        // Delete Firebase Auth user if exists
        if (seller.firebaseUid) {
          try {
            await auth.deleteUser(seller.firebaseUid);
          } catch (err) {
            console.log("⚠ Firebase UID delete error:", err.message);
          }
        }

        // Delete Seller record
        await seller.deleteOne();

        await createSellerNotification({
          sellerId: "ADMIN",
          title: "🗑 Seller Deleted",
          message: `Seller ${customId} removed.`,
          type: "seller_deleted",
          data: { customId },
          url: `/admin/sellers`,
          pubsub,
        });

        return seller;
      } catch (err) {
        throw new Error(`Delete failed: ${err.message}`);
      }
    },

    /**
     * 📲 Update FCM token
     */
    updateSellerFcmToken: async (_, { customId, token }) => {
      try {
        const seller = await Seller.findOne({ customId });
        if (!seller) throw new Error("Seller not found");

        await seller.addFcmToken(token);

        return {
          success: true,
          message: "Token updated",
          seller,
        };
      } catch (err) {
        return {
          success: false,
          message: `FCM error: ${err.message}`,
        };
      }
    },
  },
};
