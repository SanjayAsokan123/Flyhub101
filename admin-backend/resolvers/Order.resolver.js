import { Order } from "../models/Order.model.js";
import { Drone } from "../models/Drone.model.js";
import { Part } from "../models/Parts.model.js";
import { Accessory } from "../models/Accessories.model.js";
import { Seller } from "../models/Seller.model.js";
import { sendSellerStatusMail } from "../utils/emailService.js";
import { createSellerNotification } from "../utils/createSellerNotification.js";

/**
 * Dynamically fetch product details by type
 */
async function getProductDetails(productId, type) {
  switch (type?.toLowerCase()) {
    case "drone":
      return await Drone.findOne({ droneId: productId }).select("name price sellerId -_id");
    case "part":
      return await Part.findOne({ partId: productId }).select("name price sellerId -_id");
    case "accessory":
      return await Accessory.findOne({ accessoryId: productId }).select("name price sellerId -_id");
    default:
      return null;
  }
}

export const orderResolvers = {
  Query: {
    // ✅ Get all orders
    orders: async () => {
      return await Order.find().sort({ createdAt: -1 });
    },

    // ✅ Get specific order
    order: async (_, { orderId }) => {
      const order = await Order.findOne({ orderId });
      if (!order) throw new Error("Order not found");
      return order;
    },
  },

  Mutation: {
    /**
     * 🟢 Create a new order (with full notification system)
     */
    createOrder: async (_, { buyerData, items, paymentData }, { pubsub }) => {
      if (!buyerData?.buyerId) throw new Error("buyerId is required");
      if (!items?.length) throw new Error("Order must contain at least one item");

      // 🧩 Fetch product info for each item
      const detailedItems = await Promise.all(
        items.map(async (item) => {
          const product = await getProductDetails(item.productId, item.type);
          return {
            productId: item.productId,
            type: item.type,
            name: product?.name || "Unknown Product",
            price: product?.price || 0,
            quantity: item.quantity || 1,
            sellerId: product?.sellerId || null,
          };
        })
      );

      // 💰 Calculate total
      const totalAmount = detailedItems.reduce((sum, i) => sum + i.price * i.quantity, 0);

      // 🧾 Create order
      const order = new Order({
        orderId: `FHO-${Date.now().toString().slice(-8)}`,
        buyer: buyerData,
        items: detailedItems,
        totalAmount,
        payment: {
          ...paymentData,
          status: paymentData?.status || "pending",
        },
      });

      await order.save();

      // 🔔 Notifications: Send for each unique seller
      const sellerIds = [...new Set(detailedItems.map((i) => i.sellerId).filter(Boolean))];
      const sellers = await Seller.find({ customId: { $in: sellerIds } });

      for (const seller of sellers) {
        try {
          // 📨 Email to seller
          if (seller.email) {
            await sendSellerStatusMail({
              to: seller.email,
              productType: "Order",
              productName: `New Order from ${buyerData.name}`,
              status: "new",
            });
          }

          // 🔔 In-App + Push Notification for seller
          await createSellerNotification({
            sellerId: seller.customId,
            title: "🛒 New Order Received",
            message: `You have a new order from ${buyerData.name}. Total ₹${totalAmount}.`,
            type: "new_order",
            data: { orderId: order.orderId, total: totalAmount },
            url: `/seller/orders/${order.orderId}`,
            pubsub,
          });
        } catch (err) {
          console.error("⚠️ Seller notification error:", err);
        }
      }

      // 🔔 Buyer confirmation
      try {
        await createSellerNotification({
          sellerId: buyerData.buyerId,
          title: "✅ Order Confirmed",
          message: `Your order #${order.orderId} was placed successfully. Total ₹${totalAmount}.`,
          type: "buyer_order_confirmed",
          data: { orderId: order.orderId },
          url: `/buyer/orders/${order.orderId}`,
          pubsub,
        });
      } catch (err) {
        console.error("⚠️ Buyer notification error:", err);
      }

      return order;
    },

    /**
     * ✏️ Update buyer address or phone
     */
    updateOrder: async (_, { orderId, address, phone }) => {
      const updateFields = {};
      if (address) updateFields["buyer.address"] = address;
      if (phone) updateFields["buyer.phone"] = phone;

      const updatedOrder = await Order.findOneAndUpdate(
        { orderId },
        updateFields,
        { new: true }
      );
      if (!updatedOrder) throw new Error("Order not found");
      return updatedOrder;
    },

    /**
     * 🗑 Delete an order by ID
     */
    deleteOrder: async (_, { orderId }, { pubsub }) => {
      const deletedOrder = await Order.findOneAndDelete({ orderId });
      if (!deletedOrder) throw new Error("Order not found");

      // 🔔 Optional Notification to Buyer
      try {
        await createSellerNotification({
          sellerId: deletedOrder.buyer.buyerId,
          title: "Order Deleted",
          message: `Your order #${orderId} has been cancelled or deleted.`,
          type: "order_deleted",
          data: { orderId },
          url: `/buyer/orders`,
          pubsub,
        });
      } catch (err) {
        console.error("⚠️ Order deletion notification failed:", err);
      }

      return deletedOrder;
    },
  },
};
