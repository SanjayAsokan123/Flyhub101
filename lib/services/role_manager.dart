import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// RoleManager – Manages roles & IDs for Buyer / Seller / Guest
class RoleManager {
  static const String _roleKey = "user_role";
  static const String _buyerIdKey = "buyer_id";
  static const String _sellerIdKey = "seller_id";

  static const String _defaultRole = "guest";

  static String? _cachedRole;
  static String? _cachedBuyerId;
  static String? _cachedSellerId;

  // ---------------------------------------------------------------------------
  // 🔥 ROLE MANAGEMENT
  // ---------------------------------------------------------------------------

  static Future<void> setLocalRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    final newRole = role.toLowerCase();

    if (_cachedRole == newRole) return;

    _cachedRole = newRole;
    await prefs.setString(_roleKey, newRole);
    debugPrint("🔹 [RoleManager] Role updated → $newRole");
  }

  static Future<String> getLocalRole() async {
    if (_cachedRole != null) return _cachedRole!;

    final prefs = await SharedPreferences.getInstance();
    _cachedRole = prefs.getString(_roleKey) ?? _defaultRole;
    return _cachedRole!;
  }

  static Future<void> clearRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    _cachedRole = null;

    await prefs.remove(_buyerIdKey);
    await prefs.remove(_sellerIdKey);
    _cachedBuyerId = null;
    _cachedSellerId = null;

    debugPrint("🧹 [RoleManager] Role + IDs cleared");
  }

  // ---------------------------------------------------------------------------
  // 🔥 BUYER ID MANAGEMENT
  // ---------------------------------------------------------------------------

  static Future<void> saveBuyerId(String buyerId) async {
    final prefs = await SharedPreferences.getInstance();
    _cachedBuyerId = buyerId;
    await prefs.setString(_buyerIdKey, buyerId);
    debugPrint("🟢 [RoleManager] BuyerID saved → $buyerId");
  }

  static Future<String?> getBuyerId() async {
    if (_cachedBuyerId != null) return _cachedBuyerId;
    final prefs = await SharedPreferences.getInstance();
    _cachedBuyerId = prefs.getString(_buyerIdKey);
    return _cachedBuyerId;
  }

  // ---------------------------------------------------------------------------
  // 🔥 SELLER ID MANAGEMENT
  // ---------------------------------------------------------------------------

  static Future<void> saveSellerId(String sellerId) async {
    final prefs = await SharedPreferences.getInstance();
    _cachedSellerId = sellerId;
    await prefs.setString(_sellerIdKey, sellerId);
    debugPrint("🟣 [RoleManager] SellerID saved → $sellerId");
  }

  static Future<String?> getSellerId() async {
    if (_cachedSellerId != null) return _cachedSellerId;
    final prefs = await SharedPreferences.getInstance();
    _cachedSellerId = prefs.getString(_sellerIdKey);
    return _cachedSellerId;
  }

  // ---------------------------------------------------------------------------
  // 🔥 FIRESTORE ROLE SYNC
  // ---------------------------------------------------------------------------

  static Future<void> syncFirestoreRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      await setLocalRole(_defaultRole);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final role =
      (doc.data()?["role"] ?? _defaultRole).toString().toLowerCase();

      await setLocalRole(role);

      if (role == "buyer" && doc.data()?["buyerId"] != null) {
        await saveBuyerId(doc.data()!["buyerId"]);
      }

      if (role == "seller" && doc.data()?["sellerId"] != null) {
        await saveSellerId(doc.data()!["sellerId"]);
      }

      debugPrint("✅ [RoleManager] Synced Firestore → Role: $role");
    } catch (e) {
      debugPrint("⚠️ [RoleManager] Firestore Sync Error: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 🔥 QUICK CHECK HELPERS
  // ---------------------------------------------------------------------------

  static Future<bool> isSeller() async =>
      (await getLocalRole()) == "seller";

  static Future<bool> isBuyer() async =>
      (await getLocalRole()) == "buyer";

  static Future<bool> isGuest() async =>
      (await getLocalRole()) == "guest";

  // ---------------------------------------------------------------------------
  // 🔥 DEBUG RESET
  // ---------------------------------------------------------------------------

  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _cachedRole = null;
    _cachedBuyerId = null;
    _cachedSellerId = null;

    debugPrint("🧹 [RoleManager] FULL RESET DONE");
  }
}
