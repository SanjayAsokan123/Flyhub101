import { BuyerNotification } from "../models/BuyerNotification.model.js";
import { Buyer } from "../models/Buyer.model.js";
import { sendPushNotification } from "./pushNotification.js";
import { v4 as uuidv4 } from "uuid";

export const BUYER_NOTIFICATION_TOPIC = "BUYER_NOTIFICATION_ADDED";

export async function createBuyerNotification({
  buyerId,
  title,
  message,
  type = "buyer_status_update",
  data = {},
  url = null,
  pubsub = null,
}) {
  try {
    const buyer = await Buyer.findOne({ buyerId });

    const notification = await BuyerNotification.create({
      notificationId: uuidv4(),
      buyerId,
      title,
      message,
      type,
      url,
      data,
      read: false,
    });

    if (buyer) {
      const tokens = [
        ...(buyer.fcmTokens || []),
        ...(buyer.fcmToken ? [buyer.fcmToken] : []),
      ];

      if (tokens.length > 0) {
        await Promise.all(tokens.map((t) => sendPushNotification(t, title, message)));
      }
    }

    if (pubsub) {
      await pubsub.publish(BUYER_NOTIFICATION_TOPIC, {
        buyerNotificationAdded: {
          ...notification.toObject(),
          createdAt: notification.createdAt.toISOString(),
        },
      });
    }

    return notification;
  } catch (err) {
    throw new Error("Failed to create buyer notification: " + err.message);
  }
}
