import { Notification } from "../models/Notification.model.js";
import { Seller } from "../models/Seller.model.js";
import { sendPushNotification } from "./pushNotification.js";
import { sendSellerStatusMail } from "./emailService.js";
import { v4 as uuidv4 } from "uuid";

// GraphQL PubSub topic constant
export const NOTIFICATION_TOPIC = "NOTIFICATION_ADDED";

/**
 * 🔔 Create and dispatch a notification across DB, Push, Email, and GraphQL PubSub
 *
 * @param {Object} params
 * @param {String} params.sellerId - Target seller ID or "ADMIN"
 * @param {String} params.title - Notification title
 * @param {String} params.message - Notification message
 * @param {String} [params.type="status_update"] - Type tag (e.g. "approved", "rejected", etc.)
 * @param {Object} [params.data={}] - Additional payload metadata
 * @param {String} [params.url] - Optional deep link / dashboard path
 * @param {Object} [params.pubsub] - Optional PubSub instance for GraphQL subscriptions
 */
export async function createSellerNotification({
  sellerId,
  title,
  message,
  type = "status_update",
  data = {},
  url = null,
  pubsub = null,
}) {
  if (!sellerId || !title || !message) {
    throw new Error("❌ sellerId, title, and message are required for notification creation");
  }

  try {
    // 🔍 Fetch seller data (skip if ADMIN)
    const seller = sellerId !== "ADMIN" ? await Seller.findOne({ customId: sellerId }) : null;
    const targetName = seller?.name || seller?.companyName || "Admin";

    // 🧾 Save to database
    const notification = new Notification({
      notificationId: uuidv4(),
      sellerId,
      title,
      message,
      type,
      data,
      url,
      read: false,
    });

    const saved = await notification.save();
    console.log(`✅ Notification saved for ${sellerId}: ${title}`);

    // 📲 Push notification (if tokens exist)
    try {
      const fcmTokens = [
        ...(seller?.fcmToken ? [seller.fcmToken] : []),
        ...(Array.isArray(seller?.fcmTokens) ? seller.fcmTokens : []),
      ];

      if (fcmTokens.length > 0) {
        await Promise.all(
          fcmTokens.map((token) =>
            sendPushNotification(token, title, message, {
              ...data,
              notificationId: saved.notificationId,
            })
          )
        );
        console.log(`📲 Push sent to ${fcmTokens.length} device(s)`);
      } else {
        console.log(`⚠️ No FCM token found for ${sellerId}`);
      }
    } catch (pushErr) {
      console.error("⚠️ Push notification error:", pushErr.message);
    }

    // ✉️ Optional email for critical system messages
    if (["approved", "rejected"].includes(type) && seller?.email) {
      try {
        await sendSellerStatusMail({
          to: seller.email,
          productType: data?.productType || "Account Update",
          productName: data?.productName || title,
          status: message,
        });
        console.log(`📧 Email alert sent to ${seller.email}`);
      } catch (mailErr) {
        console.warn("⚠️ Email fallback failed:", mailErr.message);
      }
    }

    // 📡 Publish to GraphQL subscription
    if (pubsub) {
      try {
        const payload = {
          notificationAdded: {
            notificationId: saved.notificationId,
            sellerId: saved.sellerId,
            title: saved.title,
            message: saved.message,
            type: saved.type,
            data: saved.data,
            url: saved.url,
            read: saved.read,
            createdAt: saved.createdAt.toISOString(),
          },
        };

        await pubsub.publish(NOTIFICATION_TOPIC, payload);
        console.log(`📡 PubSub broadcasted → ${sellerId}`);
      } catch (pubErr) {
        console.error("⚠️ PubSub publish error:", pubErr.message);
      }
    }

    return saved;
  } catch (err) {
    console.error("❌ createSellerNotification fatal error:", err.message);
    throw new Error("Failed to create and dispatch notification: " + err.message);
  }
}
