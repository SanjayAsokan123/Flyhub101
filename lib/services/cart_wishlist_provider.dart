import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartWishlistProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Wishlist data
  List<Map<String, dynamic>> wishlistItems = [];
  Set<String> wishlistIds = {};

  // Cart data
  List<Map<String, dynamic>> cartItems = [];
  Set<String> cartIds = {};
  int _cartCount = 0;

  // Getters
  int get cartCount => _cartCount;
  List<String> get wishlistIdsList => wishlistIds.toList();

  CartWishlistProvider() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    print('=== PROVIDER INIT ===');
    await loadWishlistFromLocal();
    await loadCartFromLocal();

    // Sync with Firebase if user is logged in
    final user = _auth.currentUser;
    if (user != null) {
      await _syncWishlistWithFirebase();
      await _syncCartWithFirebase();
    }

    notifyListeners();
    print('Provider initialized with ${wishlistItems.length} wishlist items');
  }

  // ========== WISHLIST METHODS ==========
  Future<bool> toggleWishlist(Map<String, dynamic> item) async {
    try {
      final id = item['id']?.toString() ?? item['name']?.toString() ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      final isCurrentlyInWishlist = wishlistIds.contains(id);

      print('=== WISHLIST TOGGLE DEBUG ===');
      print('Item ID: $id');
      print('Item name: ${item['name']}');
      print('Item price: ${item['price']}');
      print('Item image: ${item['image']}');
      print('Currently in wishlist: $isCurrentlyInWishlist');
      print('Current wishlist items before: ${wishlistItems.length}');
      print('Current wishlist IDs before: $wishlistIds');

      if (isCurrentlyInWishlist) {
        // Remove from wishlist
        wishlistItems.removeWhere((element) => element['id'] == id);
        wishlistIds.remove(id);
        print('REMOVED from wishlist');
      } else {
        // Add to wishlist - ensure all required fields
        final wishlistItem = {
          'id': id,
          'name': item['name'] ?? 'Unknown Product',
          'price': item['price'] ?? 0.0,
          'image': item['image'] ?? '',
          'brand': item['brand'] ?? '',
          'category': item['category'] ?? '',
          'description': item['description'] ?? '',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          ...item, // Spread the original item to include all fields
        };
        wishlistItems.add(wishlistItem);
        wishlistIds.add(id);
        print('ADDED to wishlist: ${wishlistItem['name']}');
      }

      // Save to local storage
      await saveWishlistToLocal();
      print('Saved to local storage. Wishlist items: ${wishlistItems.length}');
      print('Current wishlist items after: ${wishlistItems.length}');
      print('Current wishlist IDs after: $wishlistIds');

      // Sync with Firebase if user is logged in
      final user = _auth.currentUser;
      if (user != null) {
        await _syncWishlistWithFirebase();
      }

      notifyListeners();
      print('Notified listeners - Wishlist items: ${wishlistItems.length}');
      print('==============================');

      return !isCurrentlyInWishlist;
    } catch (e) {
      print('❌ Error toggling wishlist: $e');
      return false;
    }
  }

  void addToWishlistById(String id) {
    if (!wishlistIds.contains(id)) {
      wishlistIds.add(id);
      notifyListeners();
    }
  }

  void removeFromWishlistById(String id) {
    if (wishlistIds.contains(id)) {
      wishlistIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> saveWishlistToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(wishlistItems);
      await prefs.setString('wishlist', jsonData);
      print('💾 Wishlist saved to local storage: ${wishlistItems.length} items');
    } catch (e) {
      print('❌ Error saving wishlist to local: $e');
    }
  }

  Future<void> loadWishlistFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('wishlist') ?? '[]';

      print('=== LOADING WISHLIST FROM LOCAL ===');
      print('Raw saved data: $saved');

      final List<dynamic> decoded = jsonDecode(saved);

      wishlistItems = List<Map<String, dynamic>>.from(decoded);
      wishlistIds = wishlistItems.map((item) => item['id']?.toString() ?? '').where((id) => id.isNotEmpty).toSet();

      print('✅ Loaded ${wishlistItems.length} items from local storage');
      print('📋 Item IDs: $wishlistIds');
      for (var item in wishlistItems) {
        print('   - ${item['name']} (ID: ${item['id']}) - ₹${item['price']}');
      }
      print('===================================');
    } catch (e) {
      print('❌ Error loading wishlist from local: $e');
      wishlistItems = [];
      wishlistIds = {};
    }
  }

  Future<void> _syncWishlistWithFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final wishlistRef = _firestore.collection('users').doc(user.uid).collection('wishlist');

      // Get current Firebase wishlist
      final snapshot = await wishlistRef.get();
      final firebaseIds = snapshot.docs.map((doc) => doc.id).toSet();

      // Batch write for efficiency
      final batch = _firestore.batch();

      // Remove items from Firebase that are not in local
      for (final id in firebaseIds) {
        if (!wishlistIds.contains(id)) {
          batch.delete(wishlistRef.doc(id));
        }
      }

      // Add/update local items to Firebase
      for (final item in wishlistItems) {
        final id = item['id']?.toString() ?? 'unknown';
        batch.set(wishlistRef.doc(id), {
          ...item,
          'syncedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('🔥 Synced ${wishlistItems.length} items with Firebase');
    } catch (e) {
      print('❌ Error syncing wishlist with Firebase: $e');
    }
  }

  // ========== CART METHODS ==========
  Future<void> updateCartCount(int count) async {
    _cartCount = count;
    notifyListeners();
  }

  Future<void> saveCartToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cart', jsonEncode(cartItems));
    } catch (e) {
      print('❌ Error saving cart to local: $e');
    }
  }

  Future<void> loadCartFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('cart') ?? '[]';
      final List<dynamic> decoded = jsonDecode(saved);

      cartItems = List<Map<String, dynamic>>.from(decoded);
      cartIds = cartItems.map((item) => item['id']?.toString() ?? '').where((id) => id.isNotEmpty).toSet();
      _cartCount = cartItems.length;
    } catch (e) {
      print('❌ Error loading cart from local: $e');
      cartItems = [];
      cartIds = {};
      _cartCount = 0;
    }
  }

  Future<void> _syncCartWithFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final cartRef = _firestore.collection('users').doc(user.uid).collection('cart');

      // Similar sync logic as wishlist
      final snapshot = await cartRef.get();
      final firebaseIds = snapshot.docs.map((doc) => doc.id).toSet();

      final batch = _firestore.batch();

      for (final id in firebaseIds) {
        if (!cartIds.contains(id)) {
          batch.delete(cartRef.doc(id));
        }
      }

      for (final item in cartItems) {
        final id = item['id']?.toString() ?? 'unknown';
        batch.set(cartRef.doc(id), {
          ...item,
          'syncedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('❌ Error syncing cart with Firebase: $e');
    }
  }

  // Clear all data (for logout)
  Future<void> clearAllData() async {
    wishlistItems.clear();
    wishlistIds.clear();

    cartItems.clear();
    cartIds.clear();
    _cartCount = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('wishlist');
    await prefs.remove('cart');

    notifyListeners();
  }

  // Debug method to check current state
  void debugPrintState() {
    print('=== PROVIDER STATE DEBUG ===');
    print('Wishlist Items: ${wishlistItems.length}');
    print('Wishlist IDs: $wishlistIds');
    print('Cart Items: ${cartItems.length}');
    print('Cart Count: $_cartCount');
    for (var item in wishlistItems) {
      print('Wishlist Item: ${item['name']} (ID: ${item['id']})');
    }
    print('============================');
  }
}