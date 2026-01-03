import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// RoleManager – Manages roles & IDs for Buyer / Seller / Guest
class RoleManager {
  static const String _roleKey = "user_role";
  static const String _buyerIdKey = "buyer_id";
  static const String _sellerIdKey = "seller_id";
  static const String _userIdKey = "user_id"; // NEW: for Firebase UID
  static const String _defaultRole = "guest";
  static String? _cachedRole;
  static String? _cachedBuyerId;
  static String? _cachedSellerId;
  static String? _cachedUserId; // NEW

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
    await prefs.remove(_userIdKey); // NEW
    _cachedRole = null;
    _cachedUserId = null; // NEW

    await prefs.remove(_buyerIdKey);
    await prefs.remove(_sellerIdKey);
    _cachedBuyerId = null;
    _cachedSellerId = null;

    debugPrint("🧹 [RoleManager] Role + IDs cleared");
  }

  // ---------------------------------------------------------------------------
  // 🔥 USER ID CACHE (NEW - REQUIRED BY main.dart)
  // ---------------------------------------------------------------------------

  static Future<void> cacheUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    _cachedUserId = userId;
    await prefs.setString(_userIdKey, userId);
    debugPrint("👤 [RoleManager] UserID cached → $userId");
  }

  static Future<String?> getCachedUserId() async {
    if (_cachedUserId != null) return _cachedUserId;
    final prefs = await SharedPreferences.getInstance();
    _cachedUserId = prefs.getString(_userIdKey);
    return _cachedUserId;
  }

  // ---------------------------------------------------------------------------
  // 🔥 SET BUYER ROLE (NEW - REQUIRED BY main.dart)
  // ---------------------------------------------------------------------------

  static Future<void> setBuyerRole(String buyerId) async {
    final prefs = await SharedPreferences.getInstance();

    // Set role to buyer
    _cachedRole = "buyer";
    await prefs.setString(_roleKey, "buyer");

    // Save buyer ID
    _cachedBuyerId = buyerId;
    await prefs.setString(_buyerIdKey, buyerId);

    // Cache user ID from Firebase if available
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await cacheUserId(user.uid);
    }

    debugPrint("🟢 [RoleManager] Set buyer role → ID: $buyerId");
  }

  // ---------------------------------------------------------------------------
  // 🔥 SET SELLER ROLE (NEW - for consistency)
  // ---------------------------------------------------------------------------

  static Future<void> setSellerRole(String sellerId) async {
    final prefs = await SharedPreferences.getInstance();

    // Set role to seller
    _cachedRole = "seller";
    await prefs.setString(_roleKey, "seller");

    // Save seller ID
    _cachedSellerId = sellerId;
    await prefs.setString(_sellerIdKey, sellerId);

    // Cache user ID from Firebase if available
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await cacheUserId(user.uid);
    }

    debugPrint("🟣 [RoleManager] Set seller role → ID: $sellerId");
  }

  // ---------------------------------------------------------------------------
  // 🔥 GET CACHED ROLE (NEW - for fallback)
  // ---------------------------------------------------------------------------

  static Future<String?> getCachedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
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
  // 🔥 FIRESTORE ROLE SYNC - IMPROVED WITH FALLBACK
  // ---------------------------------------------------------------------------

  static Future<void> syncFirestoreRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      await setLocalRole(_defaultRole);
      return;
    }

    try {
      // Cache user ID first
      await cacheUserId(user.uid);

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final role = (doc.data()?["role"] ?? _defaultRole).toString().toLowerCase();

      // IMPORTANT: If user is logged in but Firestore says "guest", default to "buyer"
      final finalRole = (user != null && role == "guest") ? "buyer" : role;

      await setLocalRole(finalRole);

      if (finalRole == "buyer") {
        final buyerId = doc.data()?["buyerId"]?.toString() ?? user.uid;
        await saveBuyerId(buyerId);
      }

      if (finalRole == "seller") {
        final sellerId = doc.data()?["sellerId"]?.toString() ?? user.uid;
        await saveSellerId(sellerId);
      }

      debugPrint("✅ [RoleManager] Synced Firestore → Role: $finalRole");
    } catch (e) {
      debugPrint("⚠ [RoleManager] Firestore Sync Error: $e");

      // Fallback: If Firestore fails, check if we have cached role
      final cachedRole = await getCachedRole();
      if (cachedRole != null && cachedRole != "guest") {
        await setLocalRole(cachedRole);
        debugPrint("📋 [RoleManager] Using cached role after sync error: $cachedRole");
      } else if (user != null) {
        // Default to buyer if logged in
        await setBuyerRole(user.uid);
        debugPrint("🔄 [RoleManager] Defaulted to buyer role after error");
      }
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
    _cachedUserId = null;

    debugPrint("🧹 [RoleManager] FULL RESET DONE");
  }
}