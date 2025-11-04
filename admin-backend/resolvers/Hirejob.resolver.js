import { HireJob } from "../models/Hirejob.model.js";
import { Seller } from "../models/Seller.model.js";
import { sendSellerStatusMail } from "../utils/emailService.js";
import { createSellerNotification } from "../utils/createSellerNotification.js";

export const jobResolvers = {
  Query: {
    // ✅ Fetch all jobs
    jobs: async () => await HireJob.find().sort({ createdAt: -1 }),

    // ✅ Fetch single job by ID
    job: async (_, { jobId }) => await HireJob.findOne({ jobId }),

    // ✅ Filter jobs by status
    approvedJobs: async (_, { sellerId }) =>
      HireJob.find({ sellerId, status: "approved" }),
    pendingJobs: async (_, { sellerId }) =>
      HireJob.find({ sellerId, status: "pending" }),
    rejectedJobs: async (_, { sellerId }) =>
      HireJob.find({ sellerId, status: "rejected" }),
  },

  Mutation: {
    // ✅ Add a new job
    addJob: async (_, { input }, { pubsub }) => {
      const seller = await Seller.findOne({ customId: input.sellerId });
      if (!seller) throw new Error("Seller not found");

      const count = await HireJob.countDocuments({ sellerId: input.sellerId });
      const jobNumber = String(count + 1).padStart(3, "0");
      const jobId = `${seller.customId}J${jobNumber}`;

      const job = new HireJob({
        ...input,
        jobId,
        email: seller.email,
        phoneNumber: seller.phoneNumber,
      });

      const savedJob = await job.save();

      // 🔔 Notify seller on new job submission
      try {
        await createSellerNotification({
          sellerId: input.sellerId,
          title: "Job Posted for Review",
          message: `Your job post "${input.jobName}" has been submitted and is awaiting approval.`,
          type: "job_listing",
          data: { jobId, status: "pending" },
          url: `/seller/jobs/${jobId}`,
          pubsub,
        });
      } catch (notifErr) {
        console.error("⚠️ createSellerNotification failed:", notifErr);
      }

      return savedJob;
    },

    // ✅ Update existing job details
    updateJob: async (_, { jobId, input }) =>
      await HireJob.findOneAndUpdate({ jobId }, input, { new: true }),

    // ✅ Update Job Status + Email + Notifications + Push + Realtime
    updateStatus: async (_, { jobId, status }, { pubsub }) => {
      try {
        const updated = await HireJob.findOneAndUpdate(
          { jobId },
          { status },
          { new: true }
        );
        if (!updated) throw new Error("Job not found");

        const seller = await Seller.findOne({ customId: updated.sellerId });
        if (!seller) throw new Error("Seller not found for this job");

        // ✉️ Email Seller
        if (seller.email) {
          try {
            await sendSellerStatusMail({
              to: seller.email,
              productType: "Job",
              productName: updated.jobName,
              status,
            });
          } catch (mailErr) {
            console.error("⚠️ sendSellerStatusMail failed:", mailErr);
          }
        }

        // 🔔 In-App Notification
        try {
          await createSellerNotification({
            sellerId: updated.sellerId,
            title: `Job ${status.toUpperCase()}: ${updated.jobName}`,
            message:
              status.toLowerCase() === "approved"
                ? `Your job "${updated.jobName}" has been approved and is now live.`
                : status.toLowerCase() === "rejected"
                ? `Your job "${updated.jobName}" was rejected. Please review and resubmit.`
                : `Job status updated to ${status} for "${updated.jobName}".`,
            type: "job_status",
            data: { jobId, status },
            url: `/seller/jobs/${jobId}`,
            pubsub,
          });
        } catch (notifErr) {
          console.error("⚠️ createSellerNotification failed:", notifErr);
        }

        return {
          ...updated.toObject(),
          sellerInfo: seller
            ? { email: seller.email, phoneNumber: seller.phoneNumber }
            : null,
        };
      } catch (err) {
        console.error("❌ Error updating job status:", err);
        throw new Error("Failed to update job status");
      }
    },

    // ✅ Delete a job
    deleteJob: async (_, { jobId }, { pubsub }) => {
      const deleted = await HireJob.findOneAndDelete({ jobId });
      if (!deleted) throw new Error("Job not found");

      // 🔔 Notify seller on deletion
      try {
        await createSellerNotification({
          sellerId: deleted.sellerId,
          title: `Job Deleted`,
          message: `Your job "${deleted.jobName}" has been removed from Flyhub.`,
          type: "job_deleted",
          data: { jobId },
          url: `/seller/jobs`,
          pubsub,
        });
      } catch (notifErr) {
        console.error("⚠️ createSellerNotification failed:", notifErr);
      }

      const seller = await Seller.findOne({ customId: deleted.sellerId });
      return {
        ...deleted.toObject(),
        sellerInfo: seller
          ? { email: seller.email, phoneNumber: seller.phoneNumber }
          : null,
      };
    },
  },
};
