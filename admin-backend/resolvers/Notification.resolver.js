import { Notification } from "../models/Notification.model.js";
import GraphQLJSON from "graphql-type-json";
import { NOTIFICATION_TOPIC } from "../utils/createSellerNotification.js";

export const notificationResolvers = {
  JSON: GraphQLJSON,

  Query: {
    /**
     * 🟢 Get notifications for a seller or admin
     */
    notificationsBySeller: async (_, { sellerId, status = "all", limit = 50, skip = 0 }) => {
      try {
        if (!sellerId) throw new Error("sellerId required");

        const query = { sellerId };
        if (status === "unread") query.read = false;
        if (status === "read") query.read = true;

        const notifications = await Notification.find(query)
          .sort({ createdAt: -1 })
          .skip(skip)
          .limit(limit);

        return notifications.map((n) => ({
          ...n.toObject(),
          data: n.data || {},
          createdAt: n.createdAt.toISOString(),
        }));
      } catch (err) {
        console.error("❌ Error fetching notifications:", err);
        throw new Error("Failed to fetch notifications: " + err.message);
      }
    },

    /**
     * 🟣 Count unread notifications (for badge counters)
     */
    unreadNotificationCount: async (_, { sellerId }) => {
      try {
        if (!sellerId) throw new Error("sellerId required");
        return await Notification.countDocuments({ sellerId, read: false });
      } catch (err) {
        console.error("❌ Error counting notifications:", err);
        throw new Error("Failed to count notifications: " + err.message);
      }
    },
  },

  Mutation: {


  // Testing the notification
  createTestNotification: async (_, { sellerId, title, message, type = "test", url }, { pubsub }) => {
    try {
      const { createSellerNotification } = await import("../utils/createSellerNotification.js");
      const newNotif = await createSellerNotification({
        sellerId,
        title,
        message,
        type,
        url,
        data: { triggeredBy: "manual_test" },
        pubsub,
      });
      return newNotif;
    } catch (err) {
      console.error("❌ Error creating test notification:", err);
      throw new Error("Failed to create test notification: " + err.message);
    }
  },

    /**
     * ✅ Mark a single notification as read
     */
    markNotificationRead: async (_, { notificationId }) => {
      try {
        const updated = await Notification.findOneAndUpdate(
          { notificationId },
          { read: true },
          { new: true }
        );
        if (!updated) throw new Error("Notification not found");
        return updated;
      } catch (err) {
        console.error("❌ Error marking notification read:", err);
        throw new Error("Failed to mark notification as read: " + err.message);
      }
    },

    /**
     * ✅ Mark all notifications as read for a seller
     */
    markAllNotificationsRead: async (_, { sellerId }) => {
      try {
        if (!sellerId) throw new Error("sellerId required");
        await Notification.updateMany(
          { sellerId, read: false },
          { $set: { read: true } }
        );
        return true;
      } catch (err) {
        console.error("❌ Error marking all notifications read:", err);
        throw new Error("Failed to mark all notifications as read: " + err.message);
      }
    },

    /**
     * 🗑️ Delete all notifications (admin or seller cleanup)
     */
    deleteNotifications: async (_, { sellerId }) => {
      try {
        if (!sellerId) throw new Error("sellerId required");
        const result = await Notification.deleteMany({ sellerId });
        return result.deletedCount > 0;
      } catch (err) {
        console.error("❌ Error deleting notifications:", err);
        throw new Error("Failed to delete notifications: " + err.message);
      }
    },
  },

  Subscription: {
    /**
     * 🔔 Real-time notification subscription
     */
    notificationAdded: {
      subscribe: async (_, { sellerId }, { pubsub }) => {
        if (!pubsub) throw new Error("PubSub not available in context");

        console.log(`📡 Subscribed to notifications for seller: ${sellerId}`);
        return pubsub.asyncIterator(NOTIFICATION_TOPIC);
      },

      /**
       * 🧩 Filter and deliver only relevant notifications
       */
      resolve: (payload, args) => {
        const notification = payload.notificationAdded;

        // Deliver to specific seller/admin only
        if (args.sellerId && notification.sellerId !== args.sellerId) {
          return null;
        }

        // Clean up payload for client
        return {
          notificationId: notification.notificationId,
          sellerId: notification.sellerId,
          title: notification.title,
          message: notification.message,
          type: notification.type,
          read: notification.read,
          data: notification.data || {},
          createdAt: notification.createdAt.toISOString(),
        };
      },
    },
  },
};
