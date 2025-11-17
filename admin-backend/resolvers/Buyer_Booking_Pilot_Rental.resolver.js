import PilotRental from "../models/Buyer_Booking_Pilot_Rental.model.js";
import HirePilot from "../models/Hirepilot.model.js";
import { Seller } from "../models/Seller.model.js";
import { createSellerNotification } from "../utils/createSellerNotification.js";
import { sendSellerStatusMail } from "../utils/emailService.js";

/**
 * Helper — Safely build Mongo match object
 */
const buildMatch = (base = {}) => {
  const match = { ...base };
  if (typeof match.status === "string") match.status = match.status.toLowerCase();
  if (typeof match.paymentStatus === "string") match.paymentStatus = match.paymentStatus.toLowerCase();
  return match;
};

const rentalBookingResolvers = {
  // ============================================================
  // 📊 QUERIES
  // ============================================================
  Query: {
    getAllPilotRentals: async () =>
      PilotRental.aggregateWithPilotByRentalId({}, { createdAt: -1 }),

    getPilotRentalsByStatus: async (_, { status }) => {
      const valid = ["pending", "confirmed", "cancelled"];
      if (!valid.includes(String(status).toLowerCase())) throw new Error("Invalid status");
      return PilotRental.aggregateWithPilotByRentalId(buildMatch({ status }));
    },

    getPilotRentalsByPaymentStatus: async (_, { paymentStatus }) => {
      const valid = ["pending", "failed", "completed"];
      if (!valid.includes(String(paymentStatus).toLowerCase()))
        throw new Error("Invalid payment status");
      return PilotRental.aggregateWithPilotByRentalId(buildMatch({ paymentStatus }));
    },

    getPilotRentalById: async (_, { pilot_rental_id }) => {
      const docs = await PilotRental.aggregateWithPilotByRentalId({ pilot_rental_id });
      if (!docs?.length) throw new Error(`Pilot rental with ID ${pilot_rental_id} not found`);
      return docs[0];
    },

    // ✅ Quick filters
    getPendingRentals: async () =>
      PilotRental.aggregateWithPilotByRentalId({ status: "pending" }),
    getConfirmedRentals: async () =>
      PilotRental.aggregateWithPilotByRentalId({ status: "confirmed" }),
    getCancelledRentals: async () =>
      PilotRental.aggregateWithPilotByRentalId({ status: "cancelled" }),
    getCompletedPaymentRentals: async () =>
      PilotRental.aggregateWithPilotByRentalId({ paymentStatus: "completed" }),
  },

  // ============================================================
  // ⚙️ MUTATIONS
  // ============================================================
  Mutation: {
    /**
     * 🟢 Create Pilot Rental Booking
     */
    createPilotRental: async (
      _,
      { name, email, phone, location, amount, rentalDate, rentalPeriod, pilotId },
      { pubsub }
    ) => {
      try {
        // 1️⃣ Verify pilot existence
        const pilot = await HirePilot.findOne({ pilotId }).select("_id sellerId pilotName");
        if (!pilot) throw new Error("Pilot not found with the provided pilotId");

        // 2️⃣ Create rental booking
        const doc = await PilotRental.create({
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
          pilotId,
        });

        // 3️⃣ Fetch detailed info
        const [withPilot] = await PilotRental.aggregateWithPilotByRentalId({
          pilot_rental_id: doc.pilot_rental_id,
        });

        // 4️⃣ Notify the pilot’s seller
        await createSellerNotification({
          sellerId: pilot.sellerId,
          title: `🧾 New Pilot Rental Booking`,
          message: `Your pilot "${pilot.pilotName}" has received a new booking from ${name}.`,
          type: "pilot_rental_booking",
          data: { pilotId, pilot_rental_id: doc.pilot_rental_id },
          url: `/seller/pilots/${pilotId}`,
          pubsub,
        });

        return withPilot;
      } catch (err) {
        console.error("❌ Error creating pilot rental:", err);
        throw new Error("Failed to create pilot rental: " + err.message);
      }
    },

    /**
     * 📞 Update Contact Info
     */
    updatePilotRentalContact: async (_, { pilot_rental_id, phone, location }) => {
      try {
        const patch = {};
        if (phone) patch.phone = phone;
        if (location) patch.location = location;
        if (!Object.keys(patch).length)
          throw new Error("At least one field (phone or location) is required");

        const updated = await PilotRental.findOneAndUpdate(
          { pilot_rental_id },
          { $set: patch },
          { new: true, runValidators: true }
        );
        if (!updated) throw new Error(`Pilot rental with ID ${pilot_rental_id} not found`);

        const [withPilot] = await PilotRental.aggregateWithPilotByRentalId({ pilot_rental_id });
        return withPilot;
      } catch (err) {
        console.error("❌ Error updating pilot rental contact:", err);
        throw new Error("Failed to update contact info: " + err.message);
      }
    },

    /**
     * 🔄 Update Rental Status + Notify Seller
     */
    updatePilotRentalStatus: async (_, { pilot_rental_id, status }, { pubsub }) => {
      try {
        const valid = ["pending", "confirmed", "cancelled"];
        if (!valid.includes(String(status).toLowerCase())) throw new Error("Invalid status");

        const updated = await PilotRental.findOneAndUpdate(
          { pilot_rental_id },
          { $set: { status: status.toLowerCase() } },
          { new: true, runValidators: true }
        );
        if (!updated) throw new Error(`Pilot rental with ID ${pilot_rental_id} not found`);

        const [withPilot] = await PilotRental.aggregateWithPilotByRentalId({ pilot_rental_id });

        const pilot = await HirePilot.findOne({ pilotId: updated.pilotId });
        const seller = pilot ? await Seller.findOne({ customId: pilot.sellerId }) : null;

        // ✉️ Email seller
        if (seller?.email) {
          await sendSellerStatusMail({
            to: seller.email,
            productType: "Pilot Rental Booking",
            productName: pilot?.pilotName || "Pilot",
            status,
          });
        }

        // 🔔 In-app Notification
        await createSellerNotification({
          sellerId: pilot?.sellerId,
          title: `Pilot Rental ${status.toUpperCase()}`,
          message:
            status === "confirmed"
              ? `Your pilot "${pilot?.pilotName}" rental has been confirmed.`
              : status === "cancelled"
              ? `Your pilot "${pilot?.pilotName}" rental was cancelled.`
              : `Rental status updated to ${status} for "${pilot?.pilotName}".`,
          type: "pilot_rental_status",
          data: { pilot_rental_id, status },
          url: `/seller/pilots/${pilot?.pilotId}`,
          pubsub,
        });

        return withPilot;
      } catch (err) {
        console.error("❌ Error updating rental status:", err);
        throw new Error("Failed to update rental status: " + err.message);
      }
    },

    /**
     * 💰 Update Payment Status + Notify Seller
     */
    updatePaymentStatus: async (_, { pilot_rental_id, paymentStatus }, { pubsub }) => {
      try {
        const valid = ["pending", "failed", "completed"];
        if (!valid.includes(String(paymentStatus).toLowerCase()))
          throw new Error("Invalid payment status");

        const updated = await PilotRental.findOneAndUpdate(
          { pilot_rental_id },
          { $set: { paymentStatus: paymentStatus.toLowerCase() } },
          { new: true, runValidators: true }
        );
        if (!updated) throw new Error(`Pilot rental with ID ${pilot_rental_id} not found`);

        const [withPilot] = await PilotRental.aggregateWithPilotByRentalId({ pilot_rental_id });

        const pilot = await HirePilot.findOne({ pilotId: updated.pilotId });
        const seller = pilot ? await Seller.findOne({ customId: pilot.sellerId }) : null;

        await createSellerNotification({
          sellerId: pilot?.sellerId,
          title: `💰 Payment ${paymentStatus.toUpperCase()} for "${pilot?.pilotName}"`,
          message:
            paymentStatus === "completed"
              ? `Payment completed successfully for pilot "${pilot?.pilotName}".`
              : paymentStatus === "failed"
              ? `Payment failed for pilot "${pilot?.pilotName}".`
              : `Payment status updated to ${paymentStatus}.`,
          type: "pilot_payment",
          data: { pilot_rental_id, paymentStatus },
          url: `/seller/pilots/${pilot?.pilotId}`,
          pubsub,
        });

        return withPilot;
      } catch (err) {
        console.error("❌ Error updating payment status:", err);
        throw new Error("Failed to update payment status: " + err.message);
      }
    },

    /**
     * 🗑️ Delete Pilot Rental
     */
    deletePilotRental: async (_, { pilot_rental_id }) => {
      try {
        const deleted = await PilotRental.findOneAndDelete({ pilot_rental_id });
        if (!deleted) throw new Error(`Pilot rental with ID ${pilot_rental_id} not found`);
        return { ...deleted.toObject(), pilot: null };
      } catch (err) {
        console.error("❌ Error deleting rental:", err);
        throw new Error("Failed to delete pilot rental: " + err.message);
      }
    },
  },
};

export default rentalBookingResolvers;
