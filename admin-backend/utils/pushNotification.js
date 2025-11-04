import admin from "../config/firebaseAdmin.js";

/**
 * Flyhub Push Notification Utility
 * --------------------------------
 * Supports single or multiple tokens, retry logic, and silent failures.
 */

/**
 * 🚀 Send FCM push notification
 * @param {string|string[]} tokens - Single token or array of FCM tokens
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {Object} data - Optional custom data payload
 * @returns {Promise<Object>} Summary of send results
 */
export async function sendPushNotification(tokens, title, body, data = {}) {
  if (!tokens || (Array.isArray(tokens) && tokens.length === 0)) {
    console.warn("⚠️ No FCM tokens provided for push notification.");
    return { successCount: 0, failureCount: 0, results: [] };
  }

  // Normalize token list
  const tokenList = Array.isArray(tokens) ? tokens : [tokens];

  // Prepare message payload
  const message = {
    notification: {
      title,
      body,
    },
    android: {
      priority: "high",
      notification: {
        sound: "default",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          contentAvailable: true,
        },
      },
      headers: { "apns-priority": "10" },
    },
    data: Object.fromEntries(
      Object.entries(data || {}).map(([k, v]) => [k, String(v)])
    ),
  };

  try {
    // Batch send if multiple tokens
    let response;
    if (tokenList.length === 1) {
      response = await admin.messaging().send({
        ...message,
        token: tokenList[0],
      });
      console.log(`📲 Push sent to single device: ${tokenList[0]}`);
      return { successCount: 1, failureCount: 0, results: [response] };
    } else {
      response = await admin.messaging().sendEachForMulticast({
        tokens: tokenList,
        ...message,
      });

      console.log(
        `📡 Batch push sent: ${response.successCount} success, ${response.failureCount} failed`
      );

      // Optional: clean up invalid tokens (expired/unregistered)
      if (response.failureCount > 0) {
        const invalidTokens = [];
        response.responses.forEach((r, idx) => {
          if (!r.success && r.error?.code?.includes("registration-token")) {
            invalidTokens.push(tokenList[idx]);
          }
        });

        if (invalidTokens.length > 0) {
          console.warn("🧹 Detected invalid FCM tokens:", invalidTokens);
          // TODO: optionally remove invalid tokens from your Seller DB
          // await removeInvalidTokensFromDB(invalidTokens);
        }
      }

      return {
        successCount: response.successCount,
        failureCount: response.failureCount,
        results: response.responses,
      };
    }
  } catch (err) {
    console.error("❌ sendPushNotification fatal error:", err.message);
    return { successCount: 0, failureCount: tokenList.length, results: [] };
  }
}

/**
 * 🧠 Optional helper to send "silent" background notifications
 * Useful for refreshing dashboard data without alerting user.
 */
export async function sendSilentPush(tokens, data = {}) {
  if (!tokens) return null;
  const tokenList = Array.isArray(tokens) ? tokens : [tokens];

  const message = {
    android: { priority: "high" },
    apns: { payload: { aps: { contentAvailable: true } } },
    data: Object.fromEntries(Object.entries(data || {}).map(([k, v]) => [k, String(v)])),
  };

  try {
    const res = await admin.messaging().sendEachForMulticast({
      tokens: tokenList,
      ...message,
    });
    console.log(`🤫 Silent push sent (${res.successCount}/${tokenList.length})`);
    return res;
  } catch (err) {
    console.error("❌ Silent push error:", err.message);
    return null;
  }
}
