// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartWishlistProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Set<String> _wishlistIds = {};
  Set<String> _cartIds = {};
  int _wishlistCount = 0;
  int _cartCount = 0;

  Set<String> get wishlistIds => _wishlistIds;
  Set<String> get cartIds => _cartIds;

  int get wishlistCount => _wishlistCount;
  int get cartCount => _cartCount;

  CartWishlistProvider() {
    _initializeSync();
  }

  // -------------------------------------------------------
  // 🔥 INITIAL SYNC
  // -------------------------------------------------------
  Future<void> _initializeSync() async {
    final user = _auth.currentUser;

    if (user == null) {
      await _loadLocalData();
    } else {
      _listenFirestoreUpdates();
    }
  }

  // -------------------------------------------------------
  // 🔁 REAL-TIME FIRESTORE LISTENERS
  // -------------------------------------------------------
  void _listenFirestoreUpdates() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Wishlist listener
    _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .snapshots()
        .listen((snapshot) {
      _wishlistIds = snapshot.docs.map((d) => d.id).toSet();
      _wishlistCount = _wishlistIds.length;
      notifyListeners();
    });

    // Cart listener
    _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .snapshots()
        .listen((snapshot) {
      _cartIds = snapshot.docs.map((d) => d.id).toSet();
      _cartCount = _cartIds.length;
      notifyListeners();
    });
  }

  // -------------------------------------------------------
  // 💾 LOCAL DATA FOR GUEST USERS
  // -------------------------------------------------------
  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();

    final wishlist = prefs.getString('wishlist') ?? '[]';
    final cart = prefs.getString('cart') ?? '[]';

    try {
      final wishlistList =
      List<Map<String, dynamic>>.from(jsonDecode(wishlist));
      final cartList = List<Map<String, dynamic>>.from(jsonDecode(cart));

      _wishlistIds = wishlistList.map((e) => e['id'].toString()).toSet();
      _cartIds = cartList.map((e) => e['id'].toString()).toSet();

      _wishlistCount = _wishlistIds.length;
      _cartCount = _cartIds.length;
    } catch (_) {
      _wishlistIds = {};
      _cartIds = {};
      _wishlistCount = 0;
      _cartCount = 0;
    }

    notifyListeners();
  }

  // -------------------------------------------------------
  // 💖 TOGGLE WISHLIST
  // -------------------------------------------------------
  Future<bool> toggleWishlist(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final id = item['id']?.toString() ?? item['name'];
    final user = _auth.currentUser;

    if (user == null) {
      // Guest user — store locally
      final saved = prefs.getString('wishlist') ?? '[]';
      final localList =
      List<Map<String, dynamic>>.from(jsonDecode(saved));
      final exists = localList.any((i) => i['id'] == id);

      if (exists) {
        localList.removeWhere((i) => i['id'] == id);
      } else {
        localList.add(item);
      }

      await prefs.setString('wishlist', jsonEncode(localList));

      _wishlistIds = localList.map((e) => e['id'].toString()).toSet();
      _wishlistCount = _wishlistIds.length;
      notifyListeners();
      return !exists;
    }

    // Logged-in user — Firestore
    final ref = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(id);

    final exists = _wishlistIds.contains(id);

    if (exists) {
      await ref.delete();
      _wishlistIds.remove(id);
    } else {
      await ref.set({
        ...item,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _wishlistIds.add(id);
    }

    _wishlistCount = _wishlistIds.length;
    notifyListeners();
    return !exists;
  }

  // -------------------------------------------------------
  // 🛒 ADD TO CART
  // -------------------------------------------------------
  Future<bool> addToCart(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final id = item['id']?.toString() ?? item['name'];
    final user = _auth.currentUser;

    if (user == null) {
      // Guest — local save
      final saved = prefs.getString('cart') ?? '[]';
      final localList =
      List<Map<String, dynamic>>.from(jsonDecode(saved));
      final exists = localList.any((i) => i['id'] == id);

      if (exists) return false;

      localList.add({...item, 'quantity': 1});
      await prefs.setString('cart', jsonEncode(localList));

      _cartIds = localList.map((e) => e['id'].toString()).toSet();
      _cartCount = _cartIds.length;
      notifyListeners();
      return true;
    }

    // Firebase user
    final ref = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(id);

    final exists = _cartIds.contains(id);
    if (exists) return false;

    await ref.set({
      ...item,
      'quantity': 1,
      'addedAt': FieldValue.serverTimestamp(),
    });

    _cartIds.add(id);
    _cartCount = _cartIds.length;
    notifyListeners();
    return true;
  }

  // -------------------------------------------------------
  // 🔄 UPDATE COUNTS FROM EXTERNAL SCREENS
  // -------------------------------------------------------
  void updateWishlistCount(int count) {
    _wishlistCount = count;
    notifyListeners();
  }

  void updateCartCount(int count) {
    _cartCount = count;
    notifyListeners();
  }

  // -------------------------------------------------------
  // 🧹 RESET
  // -------------------------------------------------------
  void reset() {
    _wishlistIds.clear();
    _cartIds.clear();
    _wishlistCount = 0;
    _cartCount = 0;
    notifyListeners();
  }
}
