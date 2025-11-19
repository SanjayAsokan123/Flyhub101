// backend/utils/loginIndex.js
import { firestore } from "../config/firebaseAdmin.js";

/**
 * Create login index
 */
export async function createLoginIndex({
  uid,
  email,
  phone,
  sellerId,
  customId,
}) {
  if (!uid) throw new Error("❌ UID is required for loginIndex creation");

  const batch = firestore.batch();

  // Normalize phone
  const normalizePhone = (p) => {
    if (!p) return null;
    if (p.startsWith("+")) return p;
    if (/^\d{10}$/.test(p)) return `+91${p}`;
    return p;
  };

  if (email) {
    const id = `email_${email.toLowerCase()}`;
    batch.set(firestore.doc(`loginIndex/${id}`), {
      uid,
      key: email.toLowerCase(),
      keyType: "email",
    });
  }

  if (phone) {
    const p = normalizePhone(phone);
    const id = `phone_${p}`;
    batch.set(firestore.doc(`loginIndex/${id}`), {
      uid,
      key: p,
      keyType: "phone",
    });
  }

  if (sellerId) {
    const id = `sellerId_${sellerId}`;
    batch.set(firestore.doc(`loginIndex/${id}`), {
      uid,
      key: sellerId,
      keyType: "sellerId",
    });
  }

  if (customId) {
    const id = `customId_${customId}`;
    batch.set(firestore.doc(`loginIndex/${id}`), {
      uid,
      key: customId,
      keyType: "customId",
    });
  }

  await batch.commit();
  console.log(`✅ loginIndex created/updated for UID: ${uid}`);
}

/**
 * Delete login index entries
 * Removes:
 *   • email_xxx
 *   • phone_xxx
 *   • sellerId_xxx
 *   • customId_xxx
 */
export async function deleteLoginIndex(email, phone, customIdOrSellerId) {
  const batch = firestore.batch();

  if (email) {
    const id = `email_${email.toLowerCase()}`;
    batch.delete(firestore.doc(`loginIndex/${id}`));
  }

  if (phone) {
    const phoneNorm = phone.startsWith("+") ? phone : `+91${phone}`;
    const id = `phone_${phoneNorm}`;
    batch.delete(firestore.doc(`loginIndex/${id}`));
  }

  if (customIdOrSellerId) {
    const isSeller = customIdOrSellerId.startsWith("FLYHUBS");
    const isBuyer = customIdOrSellerId.startsWith("FLYHUBB");

    if (isSeller) {
      const id = `sellerId_${customIdOrSellerId}`;
      batch.delete(firestore.doc(`loginIndex/${id}`));
    }

    const id2 = `customId_${customIdOrSellerId}`;
    batch.delete(firestore.doc(`loginIndex/${id2}`));
  }

  await batch.commit();
  console.log(`🗑 loginIndex removed for: ${email || phone || customIdOrSellerId}`);
}

/**
 * Lookup loginIndex
 */
export async function findLoginIndex(input) {
  if (!input) return null;

  const keys = [
    `email_${input.toLowerCase()}`,
    `phone_${input}`,
    `customId_${input}`,
    `sellerId_${input}`,
  ];

  for (const docId of keys) {
    const snap = await firestore.doc(`loginIndex/${docId}`).get();
    if (snap.exists) return snap.data();
  }

  return null;
}
