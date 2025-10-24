import 'dart:convert';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/cart_wishlist_provider.dart';
import '../../services/role_manager.dart';

class MyCartPage extends StatefulWidget {
  const MyCartPage({super.key});

  @override
  State<MyCartPage> createState() => _MyCartPageState();
}

class _MyCartPageState extends State<MyCartPage> {
  final Color themeColor = const Color(0xFF1A0A5B);
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> cartItems = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _cartListener;

  bool isLoading = true;
  String role = "guest";

  @override
  void initState() {
    super.initState();
    _initializeCart();
  }

  @override
  void dispose() {
    _cartListener?.cancel();
    super.dispose();
  }

  /// ✅ Detect user role and initialize appropriate cart source
  Future<void> _initializeCart() async {
    final user = _auth.currentUser;
    role = await RoleManager.getLocalRole() ?? "guest";

    if (user == null) {
      await _loadLocalCart();

      if (mounted) setState(() => isLoading = false);
      return;
    }

    // 🔄 Firestore sync
    _cartListener = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .snapshots()
        .listen((snapshot) async {
      final data = snapshot.docs.map((e) => e.data()).toList();
      if (!mounted) return;

      setState(() {
        cartItems = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });

      // 💾 Keep local backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cart', jsonEncode(cartItems));

      // 🔔 Update global badge instantly

    }, onError: (e) {
      debugPrint("⚠️ Cart stream error: $e");
    });
  }

  /// 🧩 Load offline cart (Guest)
  Future<void> _loadLocalCart() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('cart') ?? '[]';
    try {
      cartItems = List<Map<String, dynamic>>.from(jsonDecode(saved));
    } catch (_) {
      cartItems = [];
    }
  }

  /// 💾 Save offline cart
  Future<void> _saveLocalCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cart', jsonEncode(cartItems));
  }

  /// ➕ Increase quantity
  Future<void> _increaseQuantity(int index) async {
    cartItems[index]['quantity'] = (cartItems[index]['quantity'] ?? 1) + 1;
    setState(() {});
    await _updateCart();
  }

  /// ➖ Decrease quantity
  Future<void> _decreaseQuantity(int index) async {
    if ((cartItems[index]['quantity'] ?? 1) > 1) {
      cartItems[index]['quantity']--;
      setState(() {});
      await _updateCart();
    }
  }

  /// 🔁 Update Firestore or local storage
  Future<void> _updateCart() async {
    await _saveLocalCart();


    final user = _auth.currentUser;
    if (user != null) {
      final userCart = _firestore.collection('users').doc(user.uid).collection('cart');
      for (var item in cartItems) {
        final id = item['id']?.toString() ?? item['name'];
        await userCart.doc(id).set({
          ...item,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  /// ❌ Remove single item
  Future<void> _removeItem(int index) async {
    final item = cartItems[index];
    setState(() => cartItems.removeAt(index));
    await _updateCart();

    // ✅ Instant global badge update


    final user = _auth.currentUser;
    if (user != null) {
      final id = item['id']?.toString() ?? item['name'];
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(id)
          .delete();
    }
  }

  /// 🧹 Clear entire cart
  Future<void> _clearCart() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Clear Cart"),
        content: const Text("Are you sure you want to empty your cart?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Clear")),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => cartItems.clear());
    await _saveLocalCart();



    final user = _auth.currentUser;
    if (user != null) {
      final batch = _firestore.batch();
      final docs = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();
      for (var doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  /// 💰 Price calculations
  double get subtotal =>
      cartItems.fold(0.0, (sum, e) => sum + (e['price'] ?? 0) * (e['quantity'] ?? 1));
  double get discount => subtotal * 0.1;
  double get total => subtotal - discount;

  /// 🧾 Main UI
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfff2f2f2),
      appBar: AppBar(
        title: Text("My Cart 🛒",
            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(color: themeColor),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever_outlined, color: Colors.red),
              onPressed: _clearCart,
            )
        ],
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text("Your cart is empty 🛍️"))
          : Column(
        children: [
          Expanded(child: _buildCartList()),
          _priceSummary(),
        ],
      ),
    );
  }

  /// 🧱 Cart item cards
  Widget _buildCartList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final item = cartItems[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    item['image'] ?? 'https://via.placeholder.com/150',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'] ?? "Unnamed Item",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text("₹${item['price'] ?? 0}",
                          style: TextStyle(
                              color: themeColor, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _qtyButton(Icons.remove,
                                  () => _decreaseQuantity(index)),
                          Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                                "${item['quantity'] ?? 1}",
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                          _qtyButton(Icons.add,
                                  () => _increaseQuantity(index)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () => _removeItem(index))
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: themeColor, size: 18),
        ),
      ),
    );
  }

  /// 💸 Price summary section
  Widget _priceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Price Details",
              style: TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const Divider(),
          _priceRow("Subtotal", subtotal),
          _priceRow("Discount (10%)", -discount, color: Colors.green),
          const Divider(),
          _priceRow("Total Amount", total, isBold: true),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Proceeding to checkout... 💳")),
              );
            },
            icon: const Icon(Icons.payment),
            label: const Text("Checkout"),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          )
        ],
      ),
    );
  }

  Widget _priceRow(String title, double value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            "₹${value.toStringAsFixed(2)}",
            style: TextStyle(
                color: color ?? themeColor,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
