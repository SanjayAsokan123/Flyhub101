import DroneRental from "../models/Buyer_Booking_Drone_Rental.model.js";
import { Rental } from "../models/Seller_Drone_Rental.js"; // Seller-side listings
import { Seller } from "../models/Seller.model.js";
import { createSellerNotification } from "../utils/createSellerNotification.js";
import { sendSellerStatusMail } from "../utils/emailService.js";

/**
 * Helper — Builds case-insensitive match object
 */
const buildMatch = (base = {}) => {
  const match = { ...base };
  if (typeof match.status === "string") match.status = match.status.toLowerCase();
  if (typeof match.paymentStatus === "string")
    match.paymentStatus = match.paymentStatus.toLowerCase();
  return match;
};

const droneRentalBookingResolvers = {
  // ============================================================
  // 📊 QUERIES
  // ============================================================
  Query: {
    // ✅ Fetch all drone rentals with linked drone details
    getAllDroneRentals: async () =>
      DroneRental.aggregateWithDroneByRentalId({}, { createdAt: -1 }),

    // ✅ Filter by rental status
    getDroneRentalsByStatus: async (_, { status }) => {
      const valid = ["pending", "confirmed", "cancelled"];
      if (!valid.includes(String(status).toLowerCase()))
        throw new Error("Invalid status");
      return DroneRental.aggregateWithDroneByRentalId(buildMatch({ status }));
    },

    // ✅ Filter by payment status
    getDroneRentalsByPaymentStatus: async (_, { paymentStatus }) => {
      const valid = ["pending", "failed", "completed"];
      if (!valid.includes(String(paymentStatus).toLowerCase()))
        throw new Error("Invalid payment status");
      return DroneRental.aggregateWithDroneByRentalId(buildMatch({ paymentStatus }));
    },

    // ✅ Fetch a single rental by ID
    getDroneRentalById: async (_, { drone_rental_id }) => {
      const docs = await DroneRental.aggregateWithDroneByRentalId({ drone_rental_id });
      if (!docs?.length)
        throw new Error(`Drone rental with ID ${drone_rental_id} not found`);
      return docs[0];
    },

    // ✅ Quick query shortcuts
    getPendingDroneRentals: async () =>
      DroneRental.aggregateWithDroneByRentalId({ status: "pending" }),
    getConfirmedDroneRentals: async () =>
      DroneRental.aggregateWithDroneByRentalId({ status: "confirmed" }),
    getCancelledDroneRentals: async () =>
      DroneRental.aggregateWithDroneByRentalId({ status: "cancelled" }),
    getCompletedDronePaymentRentals: async () =>
      DroneRental.aggregateWithDroneByRentalId({ paymentStatus: "completed" }),
  },

  // ============================================================
  // ⚙️ MUTATIONS
  // ============================================================
  Mutation: {
    /**
     * 🟢 Create a new drone rental booking
     */
    createDroneRental: async (
      _,
      { name, email, phone, location, amount, rentalDate, rentalPeriod, rentalId },
      { pubsub }
    ) => {
      try {
        const drone = await Rental.findOne({ rentalId }).select("_id sellerId name");
        if (!drone) throw new Error("Drone not found with the provided rentalId");

        const doc = await DroneRental.create({
          name,
          email,
          phone,
          location,
          amount,
          rentalDate: new Date(rentalDate),
          rentalPeriod: {
            startDate: new Date(rentalPeriod.startDate),
            endDate: new Date(rentalPeriod.endDate),
          },
          rentalId,
        });

        const [withDrone] = await DroneRental.aggregateWithDroneByRentalId({
          drone_rental_id: doc.drone_rental_id,
        });

        // 🔔 Notify the seller
        await createSellerNotification({
          sellerId: drone.sellerId,
          title: "📦 New Drone Rental Booking",
          message: `Your drone "${drone.name}" has been booked by ${name}.`,
          type: "rental_booking",
          data: { rentalId, drone_rental_id: doc.drone_rental_id },
          url: `/seller/rentals/${rentalId}`,
          pubsub,
        });

        return withDrone;
      } catch (err) {
        console.error("❌ Error creating drone rental:", err);
        throw new Error("Failed to create drone rental: " + err.message);
      }
    },

    /**
     * 📞 Update contact info (phone, location)
     */
    updateDroneRentalContact: async (_, { drone_rental_id, phone, location }) => {
      try {
        const patch = {};
        if (phone) patch.phone = phone;
        if (location) patch.location = location;
        if (!Object.keys(patch).length)
          throw new Error("At least one field (phone or location) is required");

        const updated = await DroneRental.findOneAndUpdate(
          { drone_rental_id },
          { $set: patch },
          { new: true, runValidators: true }
        );
        if (!updated)
          throw new Error(`Drone rental with ID ${drone_rental_id} not found`);

        const [withDrone] = await DroneRental.aggregateWithDroneByRentalId({
          drone_rental_id,
        });
        return withDrone;
      } catch (err) {
        console.error("❌ Error updating drone rental contact:", err);
        throw new Error("Failed to update contact info: " + err.message);
      }
    },

    /**
     * 🔄 Update rental status (pending / confirmed / cancelled)
     */
    updateDroneRentalStatus: async (_, { drone_rental_id, status }, { pubsub }) => {
      try {
        const valid = ["pending", "confirmed", "cancelled"];
        if (!valid.includes(String(status).toLowerCase()))
          throw new Error("Invalid status");

        const updated = await DroneRental.findOneAndUpdate(
          { drone_rental_id },
          { $set: { status: status.toLowerCase() } },
          { new: true, runValidators: true }
        );
        if (!updated)
          throw new Error(`Drone rental with ID ${drone_rental_id} not found`);

        const [withDrone] = await DroneRental.aggregateWithDroneByRentalId({
          drone_rental_id,
        });

        const rental = await Rental.findOne({ rentalId: updated.rentalId });
        const seller = rental
          ? await Seller.findOne({ customId: rental.sellerId })
          : null;

        // ✉️ Email the seller
        if (seller?.email) {
          await sendSellerStatusMail({
            to: seller.email,
            productType: "Drone Rental Booking",
            productName: rental?.name || "Drone",
            status,
          });
        }

        // 🔔 Notify the seller
        await createSellerNotification({
          sellerId: rental?.sellerId,
          title: `Drone Rental ${status.toUpperCase()}`,
          message:
            status === "confirmed"
              ? `Your rental "${rental?.name}" has been confirmed.`
              : status === "cancelled"
              ? `Your rental booking "${rental?.name}" was cancelled.`
              : `Rental status updated to ${status} for "${rental?.name}".`,
          type: "rental_status",
          data: { drone_rental_id, status },
          url: `/seller/rentals/${rental?.rentalId}`,
          pubsub,
        });

        return withDrone;
      } catch (err) {
        console.error("❌ Error updating drone rental status:", err);
        throw new Error("Failed to update drone rental status: " + err.message);
      }
    },

    /**
     * 💰 Update payment status (pending / failed / completed)
     */
    updateDronePaymentStatus: async (_, { drone_rental_id, paymentStatus }, { pubsub }) => {
      try {
        const valid = ["pending", "failed", "completed"];
        if (!valid.includes(String(paymentStatus).toLowerCase()))
          throw new Error("Invalid payment status");

        const updated = await DroneRental.findOneAndUpdate(
          { drone_rental_id },
          { $set: { paymentStatus: paymentStatus.toLowerCase() } },
          { new: true, runValidators: true }
        );
        if (!updated)
          throw new Error(`Drone rental with ID ${drone_rental_id} not found`);

        const [withDrone] = await DroneRental.aggregateWithDroneByRentalId({
          drone_rental_id,
        });

        const rental = await Rental.findOne({ rentalId: updated.rentalId });
        const seller = rental
          ? await Seller.findOne({ customId: rental.sellerId })
          : null;

        // 🔔 Notify seller about payment update
        await createSellerNotification({
          sellerId: rental?.sellerId,
          title: `Payment ${paymentStatus.toUpperCase()} for "${rental?.name}"`,
          message:
            paymentStatus === "completed"
              ? `Payment completed successfully for "${rental?.name}".`
              : paymentStatus === "failed"
              ? `Payment failed for "${rental?.name}".`
              : `Payment status updated to ${paymentStatus}.`,
          type: "rental_payment",
          data: { drone_rental_id, paymentStatus },
          url: `/seller/rentals/${rental?.rentalId}`,
          pubsub,
        });

        return withDrone;
      } catch (err) {
        console.error("❌ Error updating payment status:", err);
        throw new Error("Failed to update payment status: " + err.message);
      }
    },

    /**
     * 🗑️ Delete drone rental booking
     */
    deleteDroneRental: async (_, { drone_rental_id }) => {
      try {
        const deleted = await DroneRental.findOneAndDelete({ drone_rental_id });
        if (!deleted)
          throw new Error(`Drone rental with ID ${drone_rental_id} not found`);

        return { ...deleted.toObject(), drone: null };
      } catch (err) {
        console.error("❌ Error deleting drone rental:", err);
        throw new Error("Failed to delete drone rental: " + err.message);
      }
    },
  },
};

export default droneRentalBookingResolvers;
