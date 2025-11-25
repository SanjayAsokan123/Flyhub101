import { Seller } from "../models/Seller.model.js";
import { sendSellerStatusMail } from "../utils/emailService.js";
import { createSellerNotification } from "../utils/createSellerNotification.js";
import { createLoginIndex, deleteLoginIndex } from "../utils/loginIndex.js";
import { auth, firestore } from "../config/firebaseAdmin.js";

/**
 * Resolves firebaseUid for a seller by email or phone.
 * Persists to Mongo and creates loginIndex.
 */
async function resolveAndPersistFirebaseUid(seller) {
  try {
    if (seller.firebaseUid) return seller.firebaseUid;

    // 🔍 Try lookup by email
    if (seller.email) {
      try {
        const userRecord = await auth.getUserByEmail(seller.email);
        if (userRecord?.uid) seller.firebaseUid = userRecord.uid;
      } catch {}
    }

    // 🔍 Try lookup by phone
    if (!seller.firebaseUid && seller.phoneNumber) {
      try {
        const userRecord = await auth.getUserByPhoneNumber(
          seller.phoneNumber
        );
        if (userRecord?.uid) seller.firebaseUid = userRecord.uid;
      } catch {}
    }

    // 🟢 Persist UID + login index
    if (seller.firebaseUid) {
      await seller.save();
      try {
        await createLoginIndex({
          uid: seller.firebaseUid,
          email: seller.email,
          phone: seller.phoneNumber,
          sellerId: seller.customId,
        });
      } catch (err) {
        console.warn("⚠ loginIndex error:", err.message);
      }
      return seller.firebaseUid;
    }

    return null;
  } catch {
    return null;
  }
}

export const sellerResolvers = {
  // ======================================================
  // 🚀 QUERIES
  // ======================================================
  Query: {
    getSellers: async () => {
      return await Seller.find().sort({ createdAt: -1 });
    },

    getSeller: async (_, { customId }) => {
      const seller =
        (await Seller.findOne({ customId })) ||
        (await Seller.findById(customId));
      if (!seller) throw new Error("Seller not found");
      return seller;
    },

    getSellersByStatus: async (_, { status = "pending" }) => {
      const valid = ["pending", "approved", "rejected"];
      status = status.trim().toLowerCase();

      if (!valid.includes(status))
        throw new Error(`Status must be: ${valid.join(", ")}`);

      return await Seller.find({ status }).sort({ createdAt: -1 });
    },

    sellerByEmail: async (_, { email, username, phone, customId }) => {
      if (!email && !username && !phone && !customId)
        throw new Error("Need email OR username OR phone OR customId");

      const query = {
        $or: [
          email ? { email } : null,
          username ? { name: username } : null,
          phone ? { phoneNumber: phone } : null,
          customId ? { customId } : null,
        ].filter(Boolean),
      };

      const seller = await Seller.findOne(query);
      return seller;
    },
  },

  // ======================================================
  // 🚀 MUTATIONS
  // ======================================================
  Mutation: {
    createSeller: async (_, { input }, { pubsub }) => {
      const email = input.email?.trim();

      const exists = await Seller.findOne({
        $or: [{ firebaseUid: input.firebaseUid }, { email: input.email }],
      });

      // ---------------------------------------------------------
      // 🔁 If seller exists → Update
      // ---------------------------------------------------------
      if (exists) {
        const updated = await Seller.findByIdAndUpdate(
          exists._id,
          { ...input },
          { new: true }
        );

        if (!updated.firebaseUid) {
          await resolveAndPersistFirebaseUid(updated);
        } else {
          try {
            await createLoginIndex({
              uid: updated.firebaseUid,
              email: updated.email,
              phone: updated.phoneNumber,
              sellerId: updated.customId,
            });
          } catch {}
        }

        return updated;
      }

      // ---------------------------------------------------------
      // 🆕 New Seller
      // ---------------------------------------------------------
      const seller = new Seller({
        ...input,
        email,
        firebaseUid: input.firebaseUid || null,
        status: "pending",
      });

      const saved = await seller.save();
      await resolveAndPersistFirebaseUid(saved);

      await createSellerNotification({
        sellerId: "ADMIN",
        title: "New Seller Registered",
        message: `Seller "${saved.companyName}" awaits approval.`,
        type: "seller_created",
        data: { customId: saved.customId },
        url: `/admin/sellers/${saved.customId}`,
        pubsub,
      });

      return saved;
    },

    updateSeller: async (_, { customId, input }) => {
      const updated = await Seller.findOneAndUpdate(
        { customId },
        input,
        { new: true }
      );

      if (!updated) throw new Error("Seller not found");

      await resolveAndPersistFirebaseUid(updated);
      return updated;
    },

    // --------------------------------------------------------
    // 🔥 changeSellerStatus
    // --------------------------------------------------------
    changeSellerStatus: async (_, { customId, status }, { pubsub }) => {
      const valid = ["pending", "approved", "rejected"];
      status = status.trim().toLowerCase();

      if (!valid.includes(status))
        throw new Error(`Status must be: ${valid.join(", ")}`);

      const seller = await Seller.findOne({ customId });
      if (!seller) throw new Error("Seller not found");

      seller.status = status;
      await seller.save();

      const uid = await resolveAndPersistFirebaseUid(seller);

      // Update Firestore user doc (Flutter uses this)
      if (uid) {
        await firestore.collection("users").doc(uid).set(
          {
            status,
            sellerStatus: status,
            updatedFromAdmin: true,
          },
          { merge: true }
        );
      }

      // Email user
      try {
        await sendSellerStatusMail({
          to: seller.email,
          productType: "Seller Account",
          productName: seller.companyName,
          status,
        });
      } catch {}

      // Push notification
      await createSellerNotification({
        sellerId: seller.customId,
        title:
          status === "approved"
            ? "Seller Approved"
            : status === "rejected"
            ? "Seller Rejected"
            : "Status Updated",
        message:
          status === "approved"
            ? "Your seller account is approved."
            : status === "rejected"
            ? "Your seller account was rejected."
            : "Your status was updated.",
        type: "seller_status",
        data: { customId, status },
        url: "/seller/dashboard",
        pubsub,
      });

      return seller;
    },

    deleteSeller: async (_, { customId }, { pubsub }) => {
      const seller =
        (await Seller.findOne({ customId })) ||
        (await Seller.findById(customId));

      if (!seller) throw new Error("Seller not found");

      try {
        await deleteLoginIndex(
          seller.email,
          seller.phoneNumber,
          seller.customId
        );
      } catch {}

      if (seller.firebaseUid) {
        try {
          await auth.deleteUser(seller.firebaseUid);
        } catch {}
      }

      await seller.deleteOne();

      await createSellerNotification({
        sellerId: "ADMIN",
        title: "Seller Deleted",
        message: `Seller ${customId} deleted.`,
        type: "seller_deleted",
        data: { customId },
        url: `/admin/sellers`,
        pubsub,
      });

      return seller;
    },

    updateSellerFcmToken: async (_, { customId, token }) => {
      const seller = await Seller.findOne({ customId });
      if (!seller) throw new Error("Seller not found");

      await seller.addFcmToken(token);

      return {
        success: true,
        message: "Token updated",
        seller,
      };
    },
  },
};
