import { Rental } from "../models/Rental.model.js";
import { Seller } from "../models/Seller.model.js";
import { sendSellerStatusMail } from "../utils/emailService.js";
import { createSellerNotification } from "../utils/createSellerNotification.js";

export const rentalResolvers = {
  Query: {
    // 🟢 Fetch all rentals with seller info
    rentals: async () => {
      try {
        return await Rental.getWithSellerInfo();
      } catch (error) {
        console.error("❌ Error fetching rentals:", error);
        throw new Error("Failed to fetch rentals: " + error.message);
      }
    },

    // 🟢 Fetch rental by ID
    rental: async (_, { rentalId }) => {
      try {
        const rental = await Rental.findOne({ rentalId });
        if (!rental) throw new Error("Rental not found");

        const seller = await Seller.findOne({ customId: rental.sellerId });
        return {
          ...rental.toObject(),
          sellerInfo: {
            email: seller?.email || null,
            phoneNumber: seller?.phoneNumber || null,
          },
        };
      } catch (error) {
        console.error("❌ Error fetching rental:", error);
        throw new Error("Failed to fetch rental: " + error.message);
      }
    },

    // 🟡 Rentals filtered by status
    approvedRentals: async (_, { sellerId }) =>
      Rental.find({ sellerId, status: "approved" }),
    pendingRentals: async (_, { sellerId }) =>
      Rental.find({ sellerId, status: "pending" }),
    rejectedRentals: async (_, { sellerId }) =>
      Rental.find({ sellerId, status: "rejected" }),
  },

  Mutation: {
    /**
     * 🟢 Create new rental listing
     */
    createRental: async (_, { input }, { pubsub }) => {
      try {
        const {
          name,
          brand,
          location,
          pricePerHour,
          pricePerDay,
          description,
          image,
          quantity,
          sellerId,
        } = input;

        if (!name || !sellerId)
          throw new Error("Missing required fields: name, sellerId");

        const seller = await Seller.findOne({ customId: sellerId });
        if (!seller) throw new Error(`Seller with ID ${sellerId} not found`);

        const newRental = new Rental({
          name,
          brand,
          location,
          pricePerHour,
          pricePerDay,
          description,
          image,
          quantity: quantity || 1,
          status: "pending",
          sellerId,
        });

        const saved = await newRental.save();

        // 🔔 Notify seller about submission
        await createSellerNotification({
          sellerId,
          title: "🚁 New Rental Submitted",
          message: `Your rental listing "${name}" has been submitted for admin approval.`,
          type: "rental_submission",
          data: { rentalId: saved.rentalId },
          url: `/seller/rentals/${saved.rentalId}`,
          pubsub,
        });

        return {
          ...saved.toObject(),
          sellerInfo: {
            email: seller.email,
            phoneNumber: seller.phoneNumber,
          },
        };
      } catch (error) {
        console.error("❌ Error creating rental:", error);
        throw new Error("Failed to create rental: " + error.message);
      }
    },

    /**
     * ✏️ Update rental listing
     */
    updateRental: async (_, { rentalId, input }) => {
      try {
        const updated = await Rental.findOneAndUpdate({ rentalId }, input, {
          new: true,
        });
        if (!updated) throw new Error("Rental not found");

        const seller = await Seller.findOne({ customId: updated.sellerId });

        return {
          ...updated.toObject(),
          sellerInfo: {
            email: seller?.email || null,
            phoneNumber: seller?.phoneNumber || null,
          },
        };
      } catch (error) {
        console.error("❌ Error updating rental:", error);
        throw new Error("Failed to update rental: " + error.message);
      }
    },

    /**
     * 🟡 Update rental approval status
     * Sends email + in-app notification
     */
    updateRentalStatus: async (_, { rentalId, status }, { pubsub }) => {
      try {
        const updated = await Rental.findOneAndUpdate(
          { rentalId },
          { status },
          { new: true }
        );
        if (!updated) throw new Error("Rental not found");

        const seller = await Seller.findOne({ customId: updated.sellerId });

        // 📨 Email notification
        if (seller?.email) {
          await sendSellerStatusMail({
            to: seller.email,
            productType: "Rental",
            productName: updated.name,
            status,
          });
        }

        // 🔔 In-app / pubsub notification
        await createSellerNotification({
          sellerId: updated.sellerId,
          title:
            status === "approved"
              ? "✅ Rental Approved"
              : status === "rejected"
              ? "❌ Rental Rejected"
              : "ℹ️ Rental Status Updated",
          message:
            status === "approved"
              ? `Your rental "${updated.name}" has been approved and listed in the marketplace.`
              : status === "rejected"
              ? `Your rental "${updated.name}" was rejected. Please review and resubmit.`
              : `Your rental "${updated.name}" is now marked as "${status}".`,
          type: "rental_status",
          data: { rentalId, status },
          url: `/seller/rentals/${rentalId}`,
          pubsub,
        });

        return {
          ...updated.toObject(),
          sellerInfo: {
            email: seller?.email || null,
            phoneNumber: seller?.phoneNumber || null,
          },
        };
      } catch (err) {
        console.error("❌ Error updating rental status:", err);
        throw new Error("Failed to update rental status: " + err.message);
      }
    },

    /**
     * 🗑 Delete rental listing
     */
    deleteRental: async (_, { rentalId }, { pubsub }) => {
      try {
        const deleted = await Rental.findOneAndDelete({ rentalId });
        if (!deleted) throw new Error("Rental not found");

        const seller = await Seller.findOne({ customId: deleted.sellerId });

        // 🔔 Notify seller
        await createSellerNotification({
          sellerId: deleted.sellerId,
          title: "🗑️ Rental Deleted",
          message: `Your rental "${deleted.name}" has been removed from the system.`,
          type: "rental_deleted",
          data: { rentalId },
          url: `/seller/rentals`,
          pubsub,
        });

        return {
          ...deleted.toObject(),
          sellerInfo: {
            email: seller?.email || null,
            phoneNumber: seller?.phoneNumber || null,
          },
        };
      } catch (error) {
        console.error("❌ Error deleting rental:", error);
        throw new Error("Failed to delete rental: " + error.message);
      }
    },
  },
};
