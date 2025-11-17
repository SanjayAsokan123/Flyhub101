// backend/utils/loginIndex.js

import { firestore } from "../config/firebaseAdmin.js";

/**
 * loginIndex System
 * ---------------------------------------
 * Maps ANY login input → Firebase UID
 *
 * Supports:
 *  • email
 *  • phone
 *  • seller customId  → "FLYHUBS0002"
 *  • buyer buyerId    → "FLYHUBB0005"
 *
 * Structure in Firestore:
 * loginIndex/email_xyz →  { uid, key, keyType }
 * loginIndex/phone_9876543210 → { uid, key, keyType }
 * loginIndex/customId_FLYHUBB0003 → { uid, key, keyType }
 * loginIndex/sellerId_FLYHUBS0007 → { uid, key, keyType }
 */

export async function createLoginIndex({
  uid,
  email,
  phone,
  sellerId,
  customId, // buyerId OR seller customId
}) {
  if (!uid) throw new Error("❌ UID is required for loginIndex creation");

  const batch = firestore.batch();

  // Normalize phone → +91XXXXXXXXXX
  const normalizePhone = (p) => {
    if (!p) return null;
    if (p.startsWith("+")) return p;
    if (/^\d{10}$/.test(p)) return `+91${p}`;
    return p;
  };

  // ------------------------------------------------------
  // EMAIL → loginIndex/email_xxx
  // ------------------------------------------------------
  if (email) {
    const docId = `email_${email.toLowerCase()}`;
    const ref = firestore.doc(`loginIndex/${docId}`);

    batch.set(
      ref,
      {
        uid,
        key: email.toLowerCase(),
        keyType: "email",
      },
      { merge: true }
    );
  }

  // ------------------------------------------------------
  // PHONE → loginIndex/phone_xxx
  // ------------------------------------------------------
  if (phone) {
    const phoneNorm = normalizePhone(phone);
    const docId = `phone_${phoneNorm}`;
    batch.set(
      firestore.doc(`loginIndex/${docId}`),
      {
        uid,
        key: phoneNorm,
        keyType: "phone",
      },
      { merge: true }
    );
  }

  // ------------------------------------------------------
  // SELLER ID → loginIndex/sellerId_FLYHUBS0003
  // ------------------------------------------------------
  if (sellerId) {
    const docId = `sellerId_${sellerId}`;
    batch.set(
      firestore.doc(`loginIndex/${docId}`),
      {
        uid,
        key: sellerId,
        keyType: "sellerId",
      },
      { merge: true }
    );
  }

  // ------------------------------------------------------
  // BUYER CUSTOM ID → loginIndex/customId_FLYHUBB0001
  // ALSO works for seller customId
  // ------------------------------------------------------
  if (customId) {
    const docId = `customId_${customId}`;
    batch.set(
      firestore.doc(`loginIndex/${docId}`),
      {
        uid,
        key: customId,
        keyType: "customId",
      },
      { merge: true }
    );
  }

  await batch.commit();
  console.log(`✅ loginIndex created/updated for UID: ${uid}`);
}

/**
 * Lookup loginIndex:
 *   input → uid
 * Supports reverse lookup for:
 *   • email
 *   • phone
 *   • buyerId
 *   • seller customId
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
    const ref = firestore.doc(`loginIndex/${docId}`);
    const snap = await ref.get();
    if (snap.exists) return snap.data();
  }

  return null;
}
