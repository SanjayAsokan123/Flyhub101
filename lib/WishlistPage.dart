import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/role_manager.dart';
import '../../services/cart_wishlist_provider.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> wishlistItems = [];
  Stream<QuerySnapshot<Map<String, dynamic>>>? _wishlistStream;

  bool isLoading = true;
  String role = "guest";

  @override
  void initState() {
    super.initState();
    _initWishlist();
  }

  /// ✅ Detect role and load appropriate wishlist
  Future<void> _initWishlist() async {
    role = await RoleManager.getLocalRole() ?? "guest";
    final user = _auth.currentUser;

    if (user == null) {
      await _loadLocalWishlist();

    } else {
      _wishlistStream = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .orderBy('createdAt', descending: true)
          .snapshots();

      _wishlistStream!.listen((snapshot) async {
        final data = snapshot.docs.map((d) => d.data()).toList();
        setState(() => wishlistItems = List<Map<String, dynamic>>.from(data));

        // 🔄 Keep offline backup
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('wishlist', jsonEncode(wishlistItems));

        // ✅ Update global provider badge

      });
    }

    if (mounted) setState(() => isLoading = false);
  }

  /// 🧩 Load offline wishlist
  Future<void> _loadLocalWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('wishlist') ?? '[]';
    try {
      wishlistItems = List<Map<String, dynamic>>.from(jsonDecode(saved));
    } catch (_) {
      wishlistItems = [];
    }
  }

  /// 💾 Save local wishlist
  Future<void> _saveLocalWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wishlist', jsonEncode(wishlistItems));

  }

  /// 🗑 Remove single item
  Future<void> _removeItem(int index) async {
    final item = wishlistItems[index];
    final id = item['id']?.toString() ?? item['name'];
    setState(() => wishlistItems.removeAt(index));
    await _saveLocalWishlist();

    // ✅ Update global count


    if (role != "guest") {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('wishlist')
            .doc(id)
            .delete();
      }
    }
  }

  /// 🛒 Move to cart (works offline/online)
  Future<void> _moveToCart(int index) async {
    final item = wishlistItems[index];
    final prefs = await SharedPreferences.getInstance();
    final id = item['id']?.toString() ?? item['name'];

    // ✅ Local cart update
    final savedCart = prefs.getString('cart') ?? '[]';
    final localCart = List<Map<String, dynamic>>.from(jsonDecode(savedCart));
    if (!localCart.any((e) => e['id'] == id)) {
      localCart.add({...item, 'quantity': 1});
      await prefs.setString('cart', jsonEncode(localCart));
    }

    // ✅ Firestore sync
    final user = _auth.currentUser;
    if (user != null) {
      final wishlistRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc(id);
      final cartRef =
      _firestore.collection('users').doc(user.uid).collection('cart').doc(id);

      final batch = _firestore.batch();
      batch.delete(wishlistRef);
      batch.set(cartRef, {
        ...item,
        'quantity': 1,
        'addedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    }

    // ✅ Remove locally and update badge
    setState(() => wishlistItems.removeAt(index));
    await _saveLocalWishlist();


    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("✅ '${item['name']}' moved to cart!"),
      backgroundColor: Colors.green,
    ));
  }

  /// 🧹 Clear all
  Future<void> _clearWishlist() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Clear Wishlist"),
        content: const Text("Remove all items from wishlist?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Clear")),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => wishlistItems.clear());
    await _saveLocalWishlist();

    // ✅ Reset global badge


    if (role != "guest") {
      final user = _auth.currentUser;
      if (user != null) {
        final docs = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('wishlist')
            .get();
        final batch = _firestore.batch();
        for (var d in docs.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
    }
  }

  // 🧾 UI
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wishlist 💖"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (wishlistItems.isNotEmpty)
            IconButton(
                onPressed: _clearWishlist,
                icon: const Icon(Icons.delete_forever_outlined, color: Colors.red))
        ],
      ),
      body: (user != null && _wishlistStream != null)
          ? StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _wishlistStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Your wishlist is empty 💔"));
          }
          final docs = snapshot.data!.docs;
          wishlistItems = docs.map((e) => e.data()).toList();
          return _buildWishlistList();
        },
      )
          : _buildWishlistList(),
    );
  }

  Widget _buildWishlistList() {
    if (wishlistItems.isEmpty) {
      return const Center(child: Text("Your wishlist is empty 💔"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: wishlistItems.length,
      itemBuilder: (context, index) {
        final item = wishlistItems[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item['image'] ?? 'https://via.placeholder.com/100',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(item['name'] ?? "Unnamed Item",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text("₹${item['price'] ?? 0}",
                style: const TextStyle(color: Colors.grey)),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'cart') _moveToCart(index);
                if (value == 'remove') _removeItem(index);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'cart',
                  child: Row(
                    children: [
                      Icon(Icons.shopping_cart),
                      SizedBox(width: 6),
                      Text("Move to Cart")
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 6),
                      Text("Remove")
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
