import fs from "fs";
import path from "path";
import { GraphQLUpload } from "graphql-upload";
import Seller from "../models/Seller.js";
import Buyer from "../models/Buyer.js";
import { sendEmail } from "../utils/emailService.js";

export const seller_buyer_Resolvers = {
  Upload: GraphQLUpload,

  Query: {
    getSellers: async (_, __, context) => {
      if (!context.firebaseUser)
        throw new Error("Unauthorized: Firebase token required");
      return await Seller.find();
    },

    getBuyers: async (_, __, context) => {
      if (!context.firebaseUser)
        throw new Error("Unauthorized: Firebase token required");
      return await Buyer.find();
    },

    getSellersByStatus: async (_, { status }, context) => {
      if (!context.firebaseUser)
        throw new Error("Unauthorized: Firebase token required");
      return await Seller.find({ status });
    },

    getDashboardStats: async (_, __, context) => {
      if (!context.firebaseUser)
        throw new Error("Unauthorized: Firebase token required");

      const [totalSellers, approvedSellers, pendingSellers, rejectedSellers, totalBuyers] =
        await Promise.all([
          Seller.countDocuments(),
          Seller.countDocuments({ status: "approved" }),
          Seller.countDocuments({ status: "pending" }),
          Seller.countDocuments({ status: "rejected" }),
          Buyer.countDocuments(),
        ]);

      return {
        totalSellers,
        approvedSellers,
        pendingSellers,
        rejectedSellers,
        totalBuyers,
      };
    },
  },

  Mutation: {
    // ✅ Register Seller (Firebase Auth required)
    registerSeller: async (_, { name, company, phone, email }, context) => {
      if (!context.firebaseUser)
        throw new Error("Unauthorized: Firebase token required");

      const { uid, email: firebaseEmail } = context.firebaseUser;
      const finalEmail = email || firebaseEmail;

      const existing = await Seller.findOne({ email: finalEmail });
      if (existing) throw new Error("Seller already exists!");

      const seller = new Seller({
        firebaseUid: uid,
        name,
        company,
        phone,
        email: finalEmail,
        status: "pending",
      });

      await seller.save();
      return seller;
    },

    // ✅ Register Buyer (Firebase Auth required)
    registerBuyer: async (_, { name, email, phone }, context) => {
      if (!context.firebaseUser)
        throw new Error("Unauthorized: Firebase token required");

      const { uid, email: firebaseEmail } = context.firebaseUser;
      const finalEmail = email || firebaseEmail;

      const existing = await Buyer.findOne({ email: finalEmail });
      if (existing) throw new Error("Buyer already exists!");

      const buyer = new Buyer({
        firebaseUid: uid,
        name,
        email: finalEmail,
        phone,
      });
      await buyer.save();
      return buyer;
    },

    // ✅ Admin approval / rejection
    changeSellerStatus: async (_, { id, status }, context) => {
      // Admins can still use JWT auth (for dashboard)
      const isAdmin =
        context.admin?.role === "admin" ||
        context.firebaseUser?.email?.endsWith("@flyhubadmin.com");
      if (!isAdmin) throw new Error("Unauthorized: Admin access required");

      const allowed = ["pending", "approved", "rejected"];
      if (!allowed.includes(status)) throw new Error("Invalid status value!");

      const seller = await Seller.findByIdAndUpdate(id, { status }, { new: true });
      if (!seller) throw new Error("Seller not found");

      // ✅ Email notifications
      let subject, message;
      if (status === "approved") {
        subject = "✅ Your Flyhub Seller Account Has Been Approved!";
        message = `<div style="font-family:Arial"><h2>Hi ${seller.name}</h2><p>Your seller account for <b>${seller.company}</b> has been approved.</p></div>`;
      } else if (status === "rejected") {
        subject = "❌ Your Flyhub Seller Application Was Rejected";
        message = `<div style="font-family:Arial"><p>Hello ${seller.name}, unfortunately your application was rejected.</p></div>`;
      } else {
        subject = "ℹ️ Seller Application Updated";
        message = `<p>Your status has been updated to ${status}</p>`;
      }

      await sendEmail(seller.email, subject, message);
      return seller;
    },

    // ✅ Upload Seller Documents (Firebase Seller only)
    uploadSellerDocuments: async (_, { id, input }, context) => {
      if (!context.firebaseUser)
        throw new Error("Unauthorized: Firebase token required");

      const seller = await Seller.findById(id);
      if (!seller) throw new Error("Seller not found");
      if (seller.firebaseUid !== context.firebaseUser.uid)
        throw new Error("Forbidden: Not your seller profile");

      const uploadDir = "./uploads";
      if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir);

      const fields = ["PANpdf", "gstpdf", "bankdetailspdf", "authorizedpdf"];
      for (const field of fields) {
        const file = input[field];
        if (file) {
          const { createReadStream, filename } = await file;
          const filePath = path.join(uploadDir, `${Date.now()}-${filename}`);
          await new Promise((resolve, reject) =>
            createReadStream()
              .pipe(fs.createWriteStream(filePath))
              .on("finish", resolve)
              .on("error", reject)
          );
          seller[field] = filePath.replace(/\\/g, "/").replace("./", "");
        }
      }
      await seller.save();
      return seller;
    },
  },
};
