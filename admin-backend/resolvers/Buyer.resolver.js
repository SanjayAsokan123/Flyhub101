import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { Buyer } from "../models/Buyer.model.js";
import { BuyerNotification } from "../models/BuyerNotification.model.js";
import {
  createBuyerNotification,
  BUYER_NOTIFICATION_TOPIC,
} from "../utils/createBuyerNotification.js";

import { auth } from "../config/firebaseAdmin.js";
import {
  createLoginIndex,
  deleteLoginIndex,
  findLoginIndex,
} from "../utils/loginIndex.js";

import { withFilter } from "graphql-subscriptions";

/* ------------------------------ Helpers ------------------------------ */

function normalizePhone(input) {
  if (!input) return "";
  const cleaned = input.replace(/\D/g, "");
  if (cleaned.startsWith("91") && cleaned.length === 12) {
    return cleaned.substring(2);
  }
  return cleaned.length === 10 ? cleaned : "";
}

async function resolveAndPersistFirebaseUid(buyer) {
  try {
    if (buyer.firebaseUid) return buyer.firebaseUid;

    if (buyer.email && !buyer.firebaseUid) {
      try {
        const u = await auth.getUserByEmail(buyer.email);
        if (u?.uid) buyer.firebaseUid = u.uid;
      } catch {}
    }

    if (buyer.phoneNumber && !buyer.firebaseUid) {
      try {
        const u = await auth.getUserByPhoneNumber("+91" + buyer.phoneNumber);
        if (u?.uid) buyer.firebaseUid = u.uid;
      } catch {}
    }

    if (buyer.firebaseUid) {
      await buyer.save();

      await createLoginIndex({
        uid: buyer.firebaseUid,
        email: buyer.email,
        phone: buyer.phoneNumber,
        buyerId: buyer.buyerId,
      });
    }

    return buyer.firebaseUid;
  } catch (err) {
    console.error("resolve firebase uid error:", err);
    return null;
  }
}

/* ----------------------------- Resolvers ----------------------------- */

export const buyerResolvers = {
  Query: {
    buyers: async () => Buyer.find().sort({ createdAt: -1 }),

    buyer: async (_, { buyerId }) =>
      (await Buyer.findOne({ buyerId })) ||
      (await Buyer.findById(buyerId)),

    buyerNotifications: async (_, { buyerId }) =>
      BuyerNotification.find({ buyerId }).sort({ createdAt: -1 }),

    buyerByEmail: async (_, { email, username, phone, buyerId }) => {
      const normalizedPhone = normalizePhone(phone);

      const query = {
        $or: [
          email ? { email } : null,
          username ? { name: username } : null,
          phone ? { phoneNumber: normalizedPhone } : null,
          buyerId ? { buyerId } : null,
        ].filter(Boolean),
      };

      return Buyer.findOne(query);
    },

    getBuyerByLoginKey: async (_, { key }) => {
      const normalized = normalizePhone(key);

      return (
        (await Buyer.findOne({ email: key })) ||
        (await Buyer.findOne({ phoneNumber: normalized })) ||
        (await Buyer.findOne({ buyerId: key }))
      );
    },
  },

  Mutation: {
    signupBuyer: async (_, { name, email, phone, password, firebaseUid }, { pubsub }) => {
      try {
        const hashedPassword = await bcrypt.hash(password, 10);

        const buyer = await Buyer.create({
          name,
          email,
          phoneNumber: normalizePhone(phone),
          password: hashedPassword,
          firebaseUid,
        });

        await resolveAndPersistFirebaseUid(buyer);

        await createBuyerNotification({
          buyerId: buyer.buyerId,
          title: "New Buyer Registered",
          message: `Buyer "${buyer.name}" created an account.`,
          type: "buyer_signup",
          url: `/admin/buyers/${buyer.buyerId}`,
          data: { buyerId: buyer.buyerId },
          pubsub,
        });

        const token = jwt.sign(
          { buyerId: buyer.buyerId, email: buyer.email },
          process.env.JWT_SECRET,
          { expiresIn: "1d" }
        );

        return {
          id: buyer.id,
          buyerId: buyer.buyerId,
          name: buyer.name,
          email: buyer.email,
          phone: buyer.phoneNumber,
          createdAt: buyer.createdAt,
          token,
        };
      } catch (err) {
        console.error("Signup error:", err);
        throw new Error(err.message);
      }
    },

    loginBuyer: async (_, { input, password }) => {
      const normalized = normalizePhone(input);

      let buyer = null;

      const match = await findLoginIndex(
        input.includes("@") ? input : normalized
      );

      if (match?.uid) {
        buyer = await Buyer.findOne({ firebaseUid: match.uid });
      }

      if (!buyer) {
        buyer =
          (await Buyer.findOne({ email: input })) ||
          (await Buyer.findOne({ phoneNumber: normalized })) ||
          (await Buyer.findOne({ buyerId: input }));
      }

      if (!buyer) throw new Error("Buyer not found");

      const valid = await bcrypt.compare(password, buyer.password || "");
      if (!valid) throw new Error("Incorrect password");

      const token = jwt.sign(
        { buyerId: buyer.buyerId, email: buyer.email },
        process.env.JWT_SECRET,
        { expiresIn: "7d" }
      );

      return { ...buyer.toObject(), token };
    },

    loginBuyerGoogle: async (_, { firebaseUid }) => {
      const buyer = await Buyer.findOne({ firebaseUid });

      if (!buyer) {
        throw new Error("Buyer account not found. Please register first.");
      }

      const token = jwt.sign(
        { buyerId: buyer.buyerId, email: buyer.email },
        process.env.JWT_SECRET,
        { expiresIn: "7d" }
      );

      return { ...buyer.toObject(), token };
    },

    updateBuyer: async (_, { buyerId, input }) => {
      const data = {};

      if (input.name) data.name = input.name;
      if (input.email) data.email = input.email;
      if (input.phoneNumber)
        data.phoneNumber = normalizePhone(input.phoneNumber);
      if (input.password)
        data.password = await bcrypt.hash(input.password, 10);

      const updated = await Buyer.findOneAndUpdate({ buyerId }, data, {
        new: true,
      });

      if (!updated) throw new Error("Buyer not found");

      await resolveAndPersistFirebaseUid(updated);

      return updated;
    },

    deleteBuyer: async (_, { buyerId }) => {
      const buyer = await Buyer.findOne({ buyerId });
      if (!buyer) throw new Error("Buyer not found");

      if (buyer.firebaseUid) {
        try {
          await auth.deleteUser(buyer.firebaseUid);
          await deleteLoginIndex(buyer.firebaseUid);
        } catch (err) {
          console.warn("Firebase delete error:", err);
        }
      }

      await buyer.deleteOne();

      return "Buyer deleted successfully.";
    },

    markBuyerNotificationRead: async (_, { notificationId }) => {
      await BuyerNotification.findOneAndUpdate(
        { notificationId },
        { read: true }
      );
      return { success: true, message: "Notification marked as read" };
    },

    updateBuyerFcmToken: async (_, { buyerId, token }) => {
      const buyer = await Buyer.findOne({ buyerId });
      if (!buyer) throw new Error("Buyer not found");

      await buyer.addFcmToken(token);

      return {
        success: true,
        message: "Token updated",
        buyer,
      };
    },

    testPush: async (_, __, { pubsub }) => {
      return await createBuyerNotification({
        buyerId: "FLYHUBB0044",
        title: "Test Notification",
        message: "Subscription is working!",
        type: "test",
        pubsub,
      });
    },
  },

  /* --------------------------- Subscriptions --------------------------- */
Subscription: {
  buyerNotificationAdded: {
    subscribe: withFilter(
      (_, __, { pubsub }) =>
        pubsub.asyncIterator([BUYER_NOTIFICATION_TOPIC]),

      (payload, variables) => {
        console.log("🔍 Filtering subscription:");
        console.log("Payload buyerId:", payload.buyerNotificationAdded.buyerId);
        console.log("Requested buyerId:", variables.buyerId);

        return payload.buyerNotificationAdded.buyerId === variables.buyerId;
      }
    ),
  },
},
}
