import DroneRental from "../models/Buyer_Booking_Drone_Rental.model.js";
import { Rental } from "../models/Seller_Drone_Rental.js"; // Seller side listings
import { Seller } from "../models/Seller.model.js";
import { createSellerNotification } from "../utils/createSellerNotification.js";
import { sendSellerStatusMail } from "../utils/emailService.js"; // optional if you want to alert seller by email

// Helper: lowercase-safe match builder
const buildMatch = (base = {}) => {
  const match = { ...base };
  if (typeof match.status === "string") match.status = match.status.toLowerCase();
  if (typeof match.paymentStatus === "string") match.paymentStatus = match.paymentStatus.toLowerCase();
  return match;
};

const droneRentalBookingResolvers = {
  Query: {
    // ✅ Get all rentals with drone info
    getAllDroneRentals: async () => {
      return DroneRental.aggregateWithDroneByRentalId({}, { createdAt: -1 });
    },

    // ✅ Filter by status
    getDroneRentalsByStatus: async (_, { status }) => {
      const valid = ["pending", "confirmed", "cancelled"];
      if (!valid.includes(String(status).toLowerCase())) throw new Error("Invalid status");
      return DroneRental.aggregateWithDroneByRentalId(buildMatch({ status }));
    },

    // ✅ Filter by payment status
    getDroneRentalsByPaymentStatus: async (_, { paymentStatus }) => {
      const valid = ["pending", "failed", "completed"];
      if (!valid.includes(String(paymentStatus).toLowerCase())) throw new Error("Invalid payment status");
      return DroneRental.aggregateWithDroneByRentalId(buildMatch({ paymentStatus }));
    },

    // ✅ Get one rental by ID
    getDroneRentalById: async (_, { drone_rental_id }) => {
      const docs = await DroneRental.aggregateWithDroneByRentalId({ drone_rental_id });
      if (!docs?.length) throw new Error(`Drone rental with ID ${drone_rental_id} not found`);
      return docs[0];
    },

    // ✅ Quick filters
    getPendingDroneRentals: async () =>
      DroneRental.aggregateWithDroneByRentalId({ status: "pending" }),

    getConfirmedDroneRentals: async () =>
      DroneRental.aggregateWithDroneByRentalId({ status: "confirmed" }),

    getCancelledDroneRentals: async () =>
      DroneRental.aggregateWithDroneByRentalId({ status: "cancelled" }),

    getCompletedDronePaymentRentals: async () =>
      DroneRental.aggregateWithDroneByRentalId({ paymentStatus: "completed" }),
  },

  Mutation: {
    // ✅ Create Drone Rental Booking
    createDroneRental: async (
      _,
      { name, email, phone, location, amount, rentalDate, rentalPeriod, rentalId }
    ) => {
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

      // 🔔 Notify the seller that a new rental booking is created
      try {
        await createSellerNotification({
          sellerId: drone.sellerId,
          title: `New Drone Rental Booking`,
          message: `Your drone "${drone.name}" has received a new rental booking from ${name}.`,
          type: "rental_booking",
          data: { rentalId, drone_rental_id: doc.drone_rental_id },
          url: `/seller/rentals/${rentalId}`,
        });
      } catch (err) {
        console.error("⚠️ Failed to create booking notification:", err);
      }

      return withDrone;
    },

    // ✅ Update Contact Info
    updateDroneRentalContact: async (_, { drone_rental_id, phone, location }) => {
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
    },

    // ✅ Update Rental Status + Notifications
    updateDroneRentalStatus: async (_, { drone_rental_id, status }, { pubsub }) => {
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

      // 🔍 Fetch the seller linked to the rental
      const rental = await Rental.findOne({ rentalId: updated.rentalId });
      const seller = rental
        ? await Seller.findOne({ customId: rental.sellerId })
        : null;

      // ✉️ Email the seller (optional)
      if (seller?.email) {
        try {
          await sendSellerStatusMail({
            to: seller.email,
            productType: "Drone Rental Booking",
            productName: rental?.name || "Drone",
            status,
          });
        } catch (err) {
          console.error("⚠️ sendSellerStatusMail failed:", err);
        }
      }

      // 🔔 Create in-app notification & push
      try {
        await createSellerNotification({
          sellerId: rental?.sellerId,
          title: `Rental ${status.toUpperCase()}`,
          message:
            status.toLowerCase() === "confirmed"
              ? `Your rental "${rental?.name}" has been confirmed successfully.`
              : status.toLowerCase() === "cancelled"
              ? `Your rental booking "${rental?.name}" was cancelled.`
              : `Rental status updated to ${status} for "${rental?.name}".`,
          type: "rental_status",
          data: { drone_rental_id, status },
          url: `/seller/rentals/${rental?.rentalId}`,
          pubsub,
        });
      } catch (err) {
        console.error("⚠️ createSellerNotification failed:", err);
      }

      return withDrone;
    },

    // ✅ Update Payment Status + Notification
    updateDronePaymentStatus: async (
      _,
      { drone_rental_id, paymentStatus },
      { pubsub }
    ) => {
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

      // 🔔 Payment notifications
      try {
        await createSellerNotification({
          sellerId: rental?.sellerId,
          title: `Payment ${paymentStatus.toUpperCase()} for "${rental?.name}"`,
          message:
            paymentStatus.toLowerCase() === "completed"
              ? `Payment completed successfully for your rental "${rental?.name}".`
              : paymentStatus.toLowerCase() === "failed"
              ? `Payment failed for your rental "${rental?.name}".`
              : `Payment status updated to ${paymentStatus}.`,
          type: "rental_payment",
          data: { drone_rental_id, paymentStatus },
          url: `/seller/rentals/${rental?.rentalId}`,
          pubsub,
        });
      } catch (err) {
        console.error("⚠️ createSellerNotification (payment) failed:", err);
      }

      return withDrone;
    },

    // ✅ Delete Rental
    deleteDroneRental: async (_, { drone_rental_id }) => {
      const deleted = await DroneRental.findOneAndDelete({ drone_rental_id });
      if (!deleted)
        throw new Error(`Drone rental with ID ${drone_rental_id} not found`);

      return { ...deleted.toObject(), drone: null };
    },
  },
};

export default droneRentalBookingResolvers;
