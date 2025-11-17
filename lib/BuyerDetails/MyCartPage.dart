import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../AddressPage.dart';
import '../../services/role_manager.dart';

class MyCartPage extends StatefulWidget {
  const MyCartPage({super.key});

  @override
  State<MyCartPage> createState() => _MyCartPageState();
}

class _MyCartPageState extends State<MyCartPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> cartItems = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _cartListener;

  bool isLoading = true;
  String role = "guest";

  late AnimationController _animationController;

  final Color themeColor = const Color(0xFF1A0A5B);
  final Color accentColor = const Color(0xFF6C5CE7);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeCart();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cartListener?.cancel();
    super.dispose();
  }

  // 🧠 Detect role and load appropriate cart
  Future<void> _initializeCart() async {
    final user = _auth.currentUser;
    role = await RoleManager.getLocalRole() ?? "guest";

    if (user == null) {
      await _loadLocalCart();
      setState(() => isLoading = false);
      return;
    }

    // 🔄 Firestore listener
    _cartListener = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .snapshots()
        .listen((snapshot) async {
      final data = snapshot.docs.map((e) => e.data()).toList();
      setState(() {
        cartItems = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });

      // 💾 Backup locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cart', jsonEncode(cartItems));
    }, onError: (e) {
      debugPrint("⚠️ Firestore cart stream error: $e");
    });
  }

  Future<void> _loadLocalCart() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('cart') ?? '[]';
    try {
      cartItems = List<Map<String, dynamic>>.from(jsonDecode(saved));
    } catch (_) {
      cartItems = [];
    }
  }

  Future<void> _saveLocalCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cart', jsonEncode(cartItems));
  }

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

  // ➕ Increase quantity
  Future<void> _increaseQuantity(int index) async {
    cartItems[index]['quantity'] = (cartItems[index]['quantity'] ?? 1) + 1;
    setState(() {});
    await _updateCart();
  }

  // ➖ Decrease quantity
  Future<void> _decreaseQuantity(int index) async {
    if ((cartItems[index]['quantity'] ?? 1) > 1) {
      cartItems[index]['quantity']--;
      setState(() {});
      await _updateCart();
    }
  }

  Future<void> _removeItem(int index) async {
    final item = cartItems[index];
    setState(() => cartItems.removeAt(index));
    await _updateCart();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item["name"]} removed from cart'),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            setState(() => cartItems.insert(index, item));
            _updateCart();
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // Cloud delete if logged in
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

  Future<void> _clearCart() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Clear Cart"),
        content: const Text("Are you sure you want to empty your cart?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Clear")),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => cartItems.clear());
    await _saveLocalCart();

    final user = _auth.currentUser;
    if (user != null) {
      final batch = _firestore.batch();
      final docs = await _firestore.collection('users').doc(user.uid).collection('cart').get();
      for (var doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  // 💰 Price calculations
  double get subtotal =>
      cartItems.fold(0.0, (sum, e) => sum + (e['price'] ?? 0) * (e['quantity'] ?? 1));
  double get discount => subtotal * 0.1;
  double get deliveryFee => cartItems.isEmpty ? 0 : (subtotal > 500 ? 0 : 40);
  double get total => subtotal - discount + deliveryFee;

  void _checkout() {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Your cart is empty!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddressPage(total: total)),
    );
  }

  // 🧾 Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("My Cart",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: themeColor, fontSize: 20)),
            if (cartItems.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("${cartItems.length}",
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever_outlined, color: Colors.red),
              onPressed: _clearCart,
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
        children: [
          if (subtotal > 0 && subtotal < 500) _freeDeliveryBanner(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: cartItems.length,
              itemBuilder: (context, i) => _buildCartCard(cartItems[i], i),
            ),
          ),
          _buildPriceDetails(),
        ],
      ),
    );
  }

  Widget _freeDeliveryBanner() => Container(
    margin: const EdgeInsets.all(12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      gradient: LinearGradient(
          colors: [accentColor.withOpacity(0.1), accentColor.withOpacity(0.05)]),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: accentColor.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Icon(Icons.local_shipping_outlined, color: accentColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "Add ₹${(500 - subtotal).toStringAsFixed(2)} more for FREE delivery!",
            style: TextStyle(color: themeColor, fontWeight: FontWeight.w500),
          ),
        )
      ],
    ),
  );

  Widget _buildEmptyCart() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
        const SizedBox(height: 20),
        Text("Your cart is empty",
            style: TextStyle(fontSize: 20, color: Colors.grey.shade700)),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.shopping_bag_outlined),
          label: const Text("Start Shopping"),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );

  Widget _buildCartCard(Map<String, dynamic> item, int index) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3))
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item['image'] ?? '',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'] ?? "Unnamed Item",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text("₹${item['price'] ?? 0}",
                        style: TextStyle(
                            color: themeColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _qtyBtn(Icons.remove, () => _decreaseQuantity(index)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text("${item['quantity'] ?? 1}",
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        _qtyBtn(Icons.add, () => _increaseQuantity(index)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                  onPressed: () => _removeItem(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.grey)),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionBtn(Icons.favorite_border, "Save", Colors.pink,
                      () => debugPrint("Saved")),
              _actionBtn(Icons.shopping_bag_outlined, "Buy Now", Colors.green,
                      () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AddressPage(
                              total: (item['price'] ?? 0) *
                                  (item['quantity'] ?? 1))))),
            ],
          )
        ],
      ),
    ),
  );

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 18, color: themeColor),
    ),
  );

  Widget _actionBtn(IconData icon, String text, Color color, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))
      ],
    ),
  );

  Widget _buildPriceDetails() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2))
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Price Details",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: themeColor, fontSize: 16)),
          const SizedBox(height: 10),
          _priceRow("Subtotal", subtotal),
          _priceRow("Discount (10%)", -discount, color: Colors.green),
          _priceRow("Delivery Fee", deliveryFee,
              color: deliveryFee == 0 ? Colors.green : null),
          const Divider(),
          _priceRow("Total", total, isBold: true),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _checkout,
            icon: const Icon(Icons.payment),
            label: const Text("Proceed to Checkout"),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _priceRow(String title, double value,
      {bool isBold = false, Color? color}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text("₹${value.toStringAsFixed(2)}",
              style: TextStyle(
                  color: color ?? themeColor,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      );
}
