import { ReturnRequest } from "../models/Return.model.js";
import { Seller } from "../models/Seller.model.js";
import { Order } from "../models/Order.model.js";
import { createSellerNotification } from "../utils/createSellerNotification.js";
import { sendSellerStatusMail } from "../utils/emailService.js";

// Helper: Generate unique return ID
async function generateReturnId() {
  const count = await ReturnRequest.countDocuments();
  return `FHR${count + 1}`; // Flyhub Return ID
}

export const returnResolvers = {
  Query: {
    /**
     * 🟢 Fetch all return requests (latest first)
     */
    returnRequests: async () => {
      try {
        const returns = await ReturnRequest.find().sort({ createdAt: -1 });

        const populated = await Promise.all(
          returns.map(async (ret) => {
            const order = await Order.findOne({ orderId: ret.orderId });
            if (!order) return ret;

            const item = order.items.find((i) => i.productId === ret.productId);
            const sellerId = item?.sellerId;

            const seller = sellerId
              ? await Seller.findOne({ customId: sellerId }).select(
                  "customId name phoneNumber email address"
                )
              : null;

            return {
              ...ret.toObject(),
              seller: seller
                ? {
                    sellerId: seller.customId,
                    name: seller.name,
                    phone: seller.phoneNumber,
                    email: seller.email,
                    address: seller.address,
                  }
                : null,
              buyer: order.buyer || null,
            };
          })
        );

        return populated;
      } catch (err) {
        console.error("❌ Error fetching return requests:", err);
        throw new Error("Failed to fetch return requests");
      }
    },

    /**
     * 🟢 Fetch return requests by status
     */
    returnRequestsByStatus: async (_, { status }) => {
      const validStatuses = ["requested", "approved", "rejected", "completed"];
      if (!validStatuses.includes(status))
        throw new Error(`Invalid status. Must be one of: ${validStatuses.join(", ")}`);

      const returns = await ReturnRequest.find({ status }).sort({ createdAt: -1 });
      return returns;
    },
  },

  Mutation: {
    /**
     * 🟡 Buyer creates a return request
     */
    requestReturn: async (_, { data }, { pubsub }) => {
      try {
        const order = await Order.findOne({ orderId: data.orderId });
        if (!order) throw new Error("Order not found");

        const item = order.items.find((i) => i.productId === data.productId);
        if (!item) throw new Error("Product not found in order");

        const sellerId = item.sellerId;
        const buyerId = order.buyer?.buyerId || null;
        const returnId = await generateReturnId();

        const newReturn = await ReturnRequest.create({
          returnId,
          ...data,
          sellerId,
          buyerId,
          status: "requested",
        });

        const seller = await Seller.findOne({ customId: sellerId }).select(
          "customId name phoneNumber email address"
        );

        // 🔔 Notify seller
        await createSellerNotification({
          sellerId,
          title: "📦 New Return Request",
          message: `A buyer has requested a return for product "${item.name}".`,
          type: "return_request",
          data: { returnId, orderId: data.orderId, productId: data.productId },
          url: `/seller/returns/${returnId}`,
          pubsub,
        });

        return {
          ...newReturn.toObject(),
          seller: seller
            ? {
                sellerId: seller.customId,
                name: seller.name,
                phone: seller.phoneNumber,
                email: seller.email,
                address: seller.address,
              }
            : null,
          buyer: order.buyer || null,
        };
      } catch (err) {
        console.error("❌ Error creating return request:", err);
        throw new Error("Failed to create return request: " + err.message);
      }
    },

    /**
     * ✏️ Update return request status (by admin or seller)
     */
    updateReturnStatus: async (_, { returnId, status }, { pubsub }) => {
      try {
        const validStatuses = ["requested", "approved", "rejected", "completed"];
        if (!validStatuses.includes(status))
          throw new Error(`Invalid status. Must be one of: ${validStatuses.join(", ")}`);

        const updated = await ReturnRequest.findOneAndUpdate(
          { returnId },
          { status },
          { new: true }
        );
        if (!updated) throw new Error("Return request not found");

        const seller = await Seller.findOne({ customId: updated.sellerId });

        // 📨 Send email to seller if available
        if (seller?.email) {
          await sendSellerStatusMail({
            to: seller.email,
            productType: "Return Request",
            productName: updated.productName || "Product",
            status,
          });
        }

        // 🔔 Create notification for seller
        await createSellerNotification({
          sellerId: updated.sellerId,
          title:
            status === "approved"
              ? "✅ Return Approved"
              : status === "rejected"
              ? "❌ Return Rejected"
              : status === "completed"
              ? "📬 Return Completed"
              : "ℹ️ Return Status Updated",
          message: `Return request ${updated.returnId} is now marked as "${status}".`,
          type: "return_status",
          data: { returnId, status },
          url: `/seller/returns/${returnId}`,
          pubsub,
        });

        return updated;
      } catch (err) {
        console.error("❌ Error updating return status:", err);
        throw new Error("Failed to update return status: " + err.message);
      }
    },

    /**
     * 🗑 Delete return request
     */
    deleteReturn: async (_, { returnId }, { pubsub }) => {
      try {
        const deleted = await ReturnRequest.findOneAndDelete({ returnId });
        if (!deleted) throw new Error("Return request not found");

        // 🔔 Notify seller about deletion
        await createSellerNotification({
          sellerId: deleted.sellerId,
          title: "🗑️ Return Deleted",
          message: `Return request ${deleted.returnId} has been deleted from the system.`,
          type: "return_deleted",
          data: { returnId },
          url: `/seller/returns`,
          pubsub,
        });

        return deleted;
      } catch (err) {
        console.error("❌ Error deleting return:", err);
        throw new Error("Failed to delete return: " + err.message);
      }
    },
  },
};
