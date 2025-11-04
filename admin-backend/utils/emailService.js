// ================================
// 📧 Email Service (Flyhub)
// ================================
import nodemailer from "nodemailer";
import dotenv from "dotenv";

// ✅ Load .env from project root (one level above /utils)
dotenv.config({ path: "../.env" });

let transporter;

/**
 * ✅ Initialize or reuse transporter
 */
const getTransporter = () => {
  if (!transporter) {
    console.log("===================================");
    console.log("Attempting to create transporter with:");
    console.log("USER:", process.env.EMAIL_USER || "❌ NOT SET");
    console.log(
      "PASS:",
      process.env.EMAIL_PASS
        ? "********" + process.env.EMAIL_PASS.slice(-4)
        : "❌ NOT SET"
    );
    console.log("===================================");

    transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });
  }
  return transporter;
};

/**
 * ✅ Sends status update mail to sellers
 * @param {Object} params - Email data
 * @param {string} params.to - Receiver email address
 * @param {string} params.productType - Type of product (Drone, Part, etc.)
 * @param {string} params.productName - Name of the product
 * @param {string} params.status - Status (approved, rejected, etc.)
 */
export async function sendSellerStatusMail({
  to,
  productType,
  productName,
  status,
}) {
  const subject = `Your ${productType} "${productName}" was ${status}`;
  const html = `
    <div style="font-family:Arial, sans-serif; padding:20px; border-radius:10px; background:#f9f9f9;">
      <h2 style="color:#1a73e8;">FlyHub Notification</h2>
      <p>Hello Seller,</p>
      <p>Your <strong>${productType}</strong> "<strong>${productName}</strong>" has been
      <span style="color:${status === "approved" ? "green" : "red"}; font-weight:bold;">${status}</span> by the admin.</p>
      <p>Please log in to your <a href="https://flyhub.in/seller-dashboard" target="_blank">Seller Dashboard</a> for more details.</p>
      <hr style="margin:20px 0;"/>
      <p style="font-size:12px; color:#555;">Thank you,<br/>FlyHub Admin Team</p>
    </div>
  `;

  try {
    await getTransporter().sendMail({
      from: `"Flyhub Admin" <${process.env.EMAIL_USER}>`,
      to,
      subject,
      html,
    });
    console.log(`✅ Seller status email sent to ${to}`);
  } catch (err) {
    console.error("❌ Error sending mail:", err);
    throw new Error("Failed to send status email.");
  }
}

// ================================
// 🧪 TEST MODE (run manually)
// ================================
if (import.meta.url === `file://${process.argv[1]}`) {
  console.log("🧪 Running test email...");
  const transporter = getTransporter();
  transporter.verify(async (error, success) => {
    if (error) {
      console.error("❌ Mail transporter error:", error);
    } else {
      console.log("✅ Mail server ready to send!");
      try {
        await sendSellerStatusMail({
          to: process.env.EMAIL_USER, // send test mail to yourself
          productType: "Drone",
          productName: "Greenmist Agri X1",
          status: "approved",
        });
      } catch (e) {
        console.error("❌ Test email failed:", e.message);
      }
    }
  });
}
