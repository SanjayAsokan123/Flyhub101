import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// 🧩 RoleManager
/// Centralized service to manage user roles in FlyHub.
/// Handles syncing between local cache and Firestore.
///
/// Supported roles:
/// - "buyer"
/// - "seller"
/// - "guest"
class RoleManager {
  static const String _roleKey = "user_role";
  static const String _defaultRole = "guest";

  static String? _cachedRole; // In-memory cache

  /// ✅ Save role locally (with cache + loop prevention)
  static Future<void> setLocalRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    final newRole = role.toLowerCase();

    if (_cachedRole == newRole) {
      debugPrint("🔸 [RoleManager] Role unchanged ($_cachedRole) — skipped save");
      return;
    }

    _cachedRole = newRole;
    await prefs.setString(_roleKey, newRole);
    debugPrint("🔹 [RoleManager] Local role saved → $newRole");
  }

  /// ✅ Get saved role (fallback = "guest")
  static Future<String> getLocalRole() async {
    if (_cachedRole != null) {
      return _cachedRole!;
    }

    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(_roleKey) ?? _defaultRole;
    _cachedRole = role;
    debugPrint("🔹 [RoleManager] Loaded local role → $role");
    return role;
  }

  /// ✅ Clear saved role (on logout)
  static Future<void> clearRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    _cachedRole = null;
    debugPrint("🧹 [RoleManager] Local role cleared (logout)");
  }

  /// ✅ One-way sync: Firestore → Local
  static Future<void> syncFirestoreRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      await setLocalRole(_defaultRole);
      debugPrint("⚠️ [RoleManager] No user logged in — defaulted to guest");
      return;
    }

    try {
      final docRef =
      FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        debugPrint("⚠️ [RoleManager] No Firestore doc found — defaulting to guest");
        await setLocalRole(_defaultRole);
        return;
      }

      final role =
      (snapshot.data()?['role'] ?? _defaultRole).toString().toLowerCase();

      if (_cachedRole != role) {
        await setLocalRole(role);
        debugPrint("✅ [RoleManager] Synced Firestore role → $role");
      } else {
        debugPrint("🔸 [RoleManager] Firestore role unchanged ($role)");
      }
    } catch (e) {
      debugPrint("⚠️ [RoleManager] Error syncing Firestore role: $e");
    }
  }

  /// ✅ Update both Firestore + local cache (only if changed)
  static Future<void> updateRole(String newRole) async {
    final user = FirebaseAuth.instance.currentUser;
    final normalizedRole = newRole.toLowerCase();

    if (user == null) {
      debugPrint("⚠️ [RoleManager] No user found — saving locally as $normalizedRole");
      await setLocalRole(normalizedRole);
      return;
    }

    try {
      final docRef =
      FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await docRef.get();
      final firestoreRole =
      (docSnapshot.data()?['role'] ?? _defaultRole).toString().toLowerCase();

      if (firestoreRole != normalizedRole) {
        await docRef.set({
          'role': normalizedRole,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint("✅ [RoleManager] Firestore role updated → $normalizedRole");
      } else {
        debugPrint("🔸 [RoleManager] Firestore already set to $normalizedRole — skipped");
      }

      await setLocalRole(normalizedRole);
    } catch (e) {
      debugPrint("⚠️ [RoleManager] Error updating Firestore role: $e");
    }
  }

  /// 🧠 Quick role checks
  static Future<bool> isSeller() async =>
      (await getLocalRole()).toLowerCase() == "seller";

  static Future<bool> isBuyer() async =>
      (await getLocalRole()).toLowerCase() == "buyer";

  static Future<bool> isGuest() async =>
      (await getLocalRole()).toLowerCase() == "guest";

  /// 🧩 Force clear all (debug/dev use)
  static Future<void> resetAll() async {
    _cachedRole = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    debugPrint("🧹 [RoleManager] Full reset completed (local + cache)");
  }
}
