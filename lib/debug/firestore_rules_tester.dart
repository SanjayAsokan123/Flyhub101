import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🧪 Firestore Rules Tester
/// Run this function once to validate all key Firestore paths.
Future<void> runFirestoreRulesTest() async {
  final firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  print("⚙️ Running Firestore Rules Test...");
  print("👤 User: ${user?.email ?? 'Guest'} (${user?.uid ?? 'No Auth'})\n");

  // --------------------------
  // 1️⃣ Test /users/{uid}
  // --------------------------
  try {
    final uid = user?.uid ?? "guest_${DateTime.now().millisecondsSinceEpoch}";
    await firestore.collection("users").doc(uid).set({
      'email': user?.email ?? "guest@example.com",
      'role': user != null ? "buyer" : "guest",
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    print("✅ [PASS] /users/$uid write succeeded");
  } catch (e) {
    print("❌ [FAIL] /users/{uid} write: $e");
  }

  // --------------------------
  // 2️⃣ Test /users/{uid}/wishlist
  // --------------------------
  try {
    final uid = user?.uid ?? "guest_test";
    await firestore
        .collection("users")
        .doc(uid)
        .collection("wishlist")
        .doc("test_item")
        .set({
      "name": "Test Drone",
      "price": 1000,
      "addedAt": FieldValue.serverTimestamp(),
    });
    print("✅ [PASS] /users/$uid/wishlist/ write succeeded");
  } catch (e) {
    print("❌ [FAIL] /users/{uid}/wishlist/ write: $e");
  }

  // --------------------------
  // 3️⃣ Test /users/{uid}/cart
  // --------------------------
  try {
    final uid = user?.uid ?? "guest_test";
    await firestore
        .collection("users")
        .doc(uid)
        .collection("cart")
        .doc("test_cart")
        .set({
      "name": "Sample Drone",
      "quantity": 1,
      "price": 999,
      "addedAt": FieldValue.serverTimestamp(),
    });
    print("✅ [PASS] /users/$uid/cart/ write succeeded");
  } catch (e) {
    print("❌ [FAIL] /users/{uid}/cart/ write: $e");
  }

  // --------------------------
  // 4️⃣ Test /marketplace/
  // --------------------------
  try {
    await firestore.collection("marketplace").doc("test_market_item").set({
      "name": "Pro Drone X",
      "price": 50000,
      "status": "active",
      "type": "drones",
      "createdAt": FieldValue.serverTimestamp(),
    });
    print("✅ [PASS] /marketplace/ write succeeded (seller only)");
  } catch (e) {
    print("⚠️ [EXPECTED for buyer/guest] /marketplace/ write blocked: $e");
  }

  // --------------------------
  // 5️⃣ Test /devices/
  // --------------------------
  try {
    await firestore.collection("devices").doc("test_device").set({
      "model": "Pixel 8",
      "platform": "android",
      "version": "14",
      "vCode": "1.0.0",
      "timestamp": FieldValue.serverTimestamp(),
    });
    print("✅ [PASS] /devices/ write succeeded");
  } catch (e) {
    print("❌ [FAIL] /devices/ write: $e");
  }

  print("\n🧩 Firestore Rules Test Completed.");
}
