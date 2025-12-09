import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/env.dart';
import '../../services/role_manager.dart';
import '../AddressPage.dart';

class MyCartPage extends StatefulWidget {
  const MyCartPage({super.key});

  @override
  State<MyCartPage> createState() => _MyCartPageState();
}

class _MyCartPageState extends State<MyCartPage> {
  List<dynamic> cartItems = [];
  bool isLoading = true;

  String? buyerId;

  // buyerId loading states
  bool _loadingBuyerId = false;
  String? _buyerIdError;

  final String graphUrl = EnvConfig.baseUrl;

  final Color themeColor = const Color(0xFF1A0A5B);

  @override
  void initState() {
    super.initState();
    _initializeCart();
  }

  // ---------------------------------------------------------
  // 🔵 NEW: Initialize sequence (get buyerId → load cart)
  // ---------------------------------------------------------
  Future<void> _initializeCart() async {
    await _loadBuyerId();
    if (buyerId != null) {
      await loadCart();
    }
  }

  // ---------------------------------------------------------
  // 🔵 NEW: Fetch buyerId from MongoDB using Firebase UID
  // ---------------------------------------------------------
  Future<void> _loadBuyerId() async {
    setState(() => _loadingBuyerId = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() => _buyerIdError = "Not logged in");
        return;
      }

      final firebaseUid = user.uid;

      const String query = r'''
        query getBuyerfirebaseUidCart($firebaseUid: String!) {
          getBuyerfirebaseUidCart(firebaseUid: $firebaseUid) {
            buyerId
            firebaseUid
            name
            email
          }
        }
      ''';

      final res = await http.post(
        Uri.parse(graphUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "query": query,
          "variables": {"firebaseUid": firebaseUid}
        }),
      );

      final data = jsonDecode(res.body);

      if (data["errors"] != null) {
        setState(() => _buyerIdError = data["errors"].toString());
        return;
      }

      final db = data["data"]["getBuyerfirebaseUidCart"];

      if (db != null && db["buyerId"] != null) {
        buyerId = db["buyerId"];
        await RoleManager.saveBuyerId(buyerId!);
      } else {
        setState(() => _buyerIdError = "Buyer profile not found");
      }
    } catch (e) {
      setState(() => _buyerIdError = e.toString());
    } finally {
      setState(() => _loadingBuyerId = false);
    }
  }

  // ---------------------------------------------------------
  // 🔵 GRAPHQL HELPER
  // ---------------------------------------------------------
  Future<dynamic> _graphQL(String query, Map<String, dynamic> variables) async {
    final response = await http.post(
      Uri.parse(EnvConfig.baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "query": query,
        "variables": variables,
      }),
    );

    final body = jsonDecode(response.body);

    if (body["errors"] != null) {
      print("GRAPHQL ERROR: ${body["errors"]}");
      return null;
    }

    return body["data"];
  }

  // ---------------------------------------------------------
  // 🔵 LOAD CART DATA
  // ---------------------------------------------------------
  Future<void> loadCart() async {
    if (buyerId == null) return;

    const query = r"""
      query GetCart($buyerId: String!) {
        getCart(buyerId: $buyerId) {
          id
          productId
          quantity
          product {
            name
            price
            image
            brand
            description
            category
          }
        }
      }
    """;

    final data = await _graphQL(query, {"buyerId": buyerId});

    setState(() {
      cartItems = data?["getCart"] ?? [];
      isLoading = false;
    });
  }

  // ---------------------------------------------------------
  // 🔵 UPDATE QTY
  // ---------------------------------------------------------
  Future<void> _updateQty(String productId, int qty) async {
    const query = r"""
      mutation UpdateCartQty($buyerId: String!, $productId: String!, $quantity: Int!) {
        updateCartQty(buyerId: $buyerId, productId: $productId, quantity: $quantity) {
          id
        }
      }
    """;

    await _graphQL(query, {
      "buyerId": buyerId,
      "productId": productId,
      "quantity": qty,
    });

    loadCart();
  }

  // ---------------------------------------------------------
  // 🔵 REMOVE ITEM
  // ---------------------------------------------------------
  Future<void> _removeItem(String productId) async {
    const query = r"""
      mutation RemoveFromCart($buyerId: String!, $productId: String!) {
        removeFromCart(buyerId: $buyerId, productId: $productId)
      }
    """;

    await _graphQL(query, {
      "buyerId": buyerId,
      "productId": productId,
    });

    loadCart();
  }

  // ---------------------------------------------------------
  // 🔵 PRICE CALCULATIONS
  // ---------------------------------------------------------
  double get subtotal =>
      cartItems.fold(0.0,
              (sum, item) => sum + (item["product"]["price"] * item["quantity"]));

  double get discount => subtotal * 0.10;

  double get deliveryFee => subtotal > 500 ? 0 : 40;

  double get total => subtotal - discount + deliveryFee;

  // ---------------------------------------------------------
  // 🔵 UI STATES
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loadingBuyerId) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: themeColor),
        ),
      );
    }

    if (_buyerIdError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red),
              SizedBox(height: 12),
              Text("Failed to load buyer ID",
                  style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text(_buyerIdError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadBuyerId,
                child: Text("Retry"),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
          ? _buildEmptyCart()
          : _buildCartBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text("My Cart",
          style:
          TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: IconThemeData(color: themeColor),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, color: themeColor, size: 90),
          SizedBox(height: 20),
          Text("Your cart is empty",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("Add items to get started",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCartBody() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index];
              return _cartTile(item);
            },
          ),
        ),
        _priceDetails(),
      ],
    );
  }

  Widget _cartTile(dynamic item) {
    final product = item["product"];
    final qty = item["quantity"];
    final productId = item["productId"];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          _productImage(product["image"]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product["name"],
                    maxLines: 2,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 6),
                Text("₹${product["price"]}",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeColor)),
                SizedBox(height: 12),
                _qtySelector(productId, qty),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _removeItem(productId),
          )
        ],
      ),
    );
  }

  Widget _productImage(String? url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url ?? "",
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(width: 90, height: 90, color: Colors.grey.shade200),
      ),
    );
  }

  Widget _qtySelector(String productId, int qty) {
    return Container(
      decoration:
      BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.remove),
            onPressed:
            qty > 1 ? () => _updateQty(productId, qty - 1) : null,
          ),
          Text("$qty", style: TextStyle(fontSize: 16)),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _updateQty(productId, qty + 1),
          ),
        ],
      ),
    );
  }

  Widget _priceDetails() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4)),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _priceRow("Subtotal", "₹${subtotal.toStringAsFixed(2)}"),
          _priceRow("Discount (10%)", "- ₹${discount.toStringAsFixed(2)}",
              color: Colors.green),
          _priceRow("Delivery Fee",
              deliveryFee == 0 ? "FREE" : "₹${deliveryFee.toStringAsFixed(2)}",
              color: deliveryFee == 0 ? Colors.green : Colors.black),
          Divider(height: 20),
          _priceRow("Total", "₹${total.toStringAsFixed(2)}",
              isBold: true, fontSize: 18),
          SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: EdgeInsets.symmetric(vertical: 14)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddressPage(
                      total: total,
                      orderData: {
                        "type": "cart",
                        "cartItems": cartItems.map((item) {
                          final p = item["product"];
                          return {
                            "productId": item["productId"],
                            "category": p["category"],
                            "quantity": item["quantity"],
                          };
                        }).toList(),
                      },
                    ),
                  ),
                );
              },
              child: Text("Proceed to Checkout",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value,
      {bool isBold = false, double fontSize = 15, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
              fontSize: fontSize,
              color: color ?? Colors.black,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ))
      ]),
    );
  }
}
