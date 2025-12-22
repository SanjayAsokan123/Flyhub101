import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/env.dart';
import '../../services/role_manager.dart';
import '../orders/AddressPage.dart';
import '../Login/BuyerRegisterPage.dart';
import '../Login/BuyerLoginPage.dart'; // Import BuyerLoginPage

class MyCartPage extends StatefulWidget {
  const MyCartPage({super.key});

  @override
  State<MyCartPage> createState() => _MyCartPageState();
}

class _MyCartPageState extends State<MyCartPage> with SingleTickerProviderStateMixin {
  List<dynamic> cartItems = [];
  bool isLoading = true;
  String? buyerId;

  // Animation controller for smooth transitions
  late AnimationController _animationController;

  // buyerId loading states
  bool _loadingBuyerId = false;
  String? _buyerIdError;

  final String graphUrl = EnvConfig.baseUrl;

  // Theme colors matching the first example
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
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listen for when the page becomes visible again (e.g., when returning from registration)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ModalRoute<dynamic>? route = ModalRoute.of(context);
      if (route != null && route.isCurrent) {
        // If we're returning from registration page, try to load buyer ID again
        if (_buyerIdError != null) {
          _initializeCart();
        }
      }
    });
  }

  Map<String, dynamic> mapCartItemToOrderItem(Map<String, dynamic> cart) {
    return {
      "productId": cart["productId"],   // MUST exist
      "category": cart["category"],     // "drone" | "part" | etc
      "quantity": cart["quantity"] ?? 1,
    };
  }

  // ---------------------------------------------------------
  // 🔵 NEW: Initialize sequence (get buyerId → load cart)
  // ---------------------------------------------------------
  Future<void> _initializeCart() async {
    await _loadBuyerId();
    if (buyerId != null) {
      await loadCart();
    }
    _animationController.forward();
  }

  // ---------------------------------------------------------
  // 🔵 NEW: Fetch buyerId from MongoDB using Firebase UID
  // ---------------------------------------------------------
  Future<void> _loadBuyerId() async {
    setState(() => _loadingBuyerId = true);
    _buyerIdError = null; // Reset error

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() => _buyerIdError = "Please login to view your cart");
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

      if (res.statusCode != 200) {
        setState(() => _buyerIdError = "Unable to fetch account details");
        return;
      }

      final data = jsonDecode(res.body);

      // Check if response has errors
      if (data["errors"] != null) {
        setState(() => _buyerIdError = "Unable to fetch account details");
        return;
      }

      // Check if data exists
      if (data["data"] == null || data["data"]["getBuyerfirebaseUidCart"] == null) {
        setState(() => _buyerIdError = "Buyer account not found");
        return;
      }

      final buyerData = data["data"]["getBuyerfirebaseUidCart"];

      if (buyerData != null && buyerData["buyerId"] != null) {
        buyerId = buyerData["buyerId"];
        await RoleManager.saveBuyerId(buyerId!);
      } else {
        setState(() => _buyerIdError = "Buyer account not found");
      }
    } catch (e) {
      // Generic error message
      setState(() => _buyerIdError = "Network error. Please try again.");
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
      // Removed console error message as requested
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
  // 🔵 BUY NOW (Single Item)
  // ---------------------------------------------------------
  void _buyNow(int index) {
    final item = cartItems[index];
    final product = item["product"];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressPage(
          total: product["price"] * item["quantity"],
          orderData: {
            "type": "single",
            "cartItems": [{
              "productId": item["productId"],
              "category": product["category"],
              "quantity": item["quantity"],
            }],
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // 🔵 SAVE FOR LATER (Placeholder)
  // ---------------------------------------------------------
  void _saveForLater(int index) {
    final item = cartItems[index];
    final product = item["product"];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${product["name"]} saved for later"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ---------------------------------------------------------
  // 🔵 PRICE CALCULATIONS
  // ---------------------------------------------------------
  double get subtotal =>
      cartItems.fold(0.0,
              (sum, item) => sum + (item["product"]["price"] * item["quantity"]));

  double get discount => subtotal * 0.10;

  double get deliveryFee => subtotal > 5000 ? 0.0 : 40.0;

  double get total => subtotal - discount + deliveryFee;

  // ---------------------------------------------------------
  // 🔵 UI BUILD
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loadingBuyerId) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(themeColor),
          ),
        ),
      );
    }

    if (_buyerIdError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(
            "My Cart",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: themeColor,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: themeColor),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, themeColor.withOpacity(0.1), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon or image for empty cart state
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 60,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Account Required",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _buyerIdError!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Please login or register as a buyer to continue shopping",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to BuyerRegisterPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BuyerRegisterPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text("Register as Buyer"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navigate to BuyerLoginPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BuyerLoginPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login, color: Color(0xFF1A0A5B)),
                    label: const Text(
                      "Login to Existing Account",
                      style: TextStyle(color: Color(0xFF1A0A5B)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1A0A5B)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Navigate back
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Back to Home",
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "My Cart",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: themeColor,
                fontSize: 20,
              ),
            ),
            if (cartItems.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${cartItems.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: themeColor),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, themeColor.withOpacity(0.1), Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
        ),
      )
          : cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
        children: [
          // Free delivery banner
          if (subtotal > 0 && subtotal < 2000)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor.withOpacity(0.1), accentColor.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping_outlined, color: accentColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black87, fontSize: 13),
                        children: [
                          const TextSpan(text: "Add "),
                          TextSpan(
                            text: "₹${(2000 - subtotal).toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          const TextSpan(text: " more for FREE delivery!"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return _buildCartItem(item, index);
              },
            ),
          ),

          _buildPriceDetails(),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Your cart is empty",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add items to get started",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text("Start Shopping"),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(dynamic item, int index) {
    final product = item["product"];
    final qty = item["quantity"];
    final productId = item["productId"];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product["image"] ?? "",
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 90,
                              height: 90,
                              color: Colors.grey.shade200,
                              child: Icon(Icons.image_not_supported, color: Colors.grey.shade400),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Product Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product["name"] ?? "Product",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.grey.shade600, size: 20),
                                onPressed: () => _removeItem(productId),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Price
                          Text(
                            "₹${product["price"]?.toStringAsFixed(2) ?? "0.00"}",
                            style: TextStyle(
                              fontSize: 18,
                              color: themeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Quantity Controls
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _quantityButton(
                                  icon: Icons.remove,
                                  onPressed: qty > 1 ? () => _updateQty(productId, qty - 1) : null,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    "$qty",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _quantityButton(
                                  icon: Icons.add,
                                  onPressed: () => _updateQty(productId, qty + 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _actionButton(
                      icon: Icons.favorite_border,
                      label: "Save",
                      color: Colors.pink,
                      onTap: () => _saveForLater(index),
                    ),
                    Container(width: 1, height: 20, color: Colors.grey.shade300),
                    _actionButton(
                      icon: Icons.shopping_bag_outlined,
                      label: "Buy Now",
                      color: Colors.green,
                      onTap: () => _buyNow(index),
                    ),
                    Container(width: 1, height: 20, color: Colors.grey.shade300),
                    _actionButton(
                      icon: Icons.delete_outline,
                      label: "Remove",
                      color: Colors.red,
                      onTap: () => _removeItem(productId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quantityButton({required IconData icon, required VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onPressed != null ? null : Colors.grey.shade200,
        ),
        child: Icon(
          icon,
          size: 18,
          color: onPressed != null ? themeColor : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetails() {
    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long_outlined, color: themeColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Price Details",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: themeColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _priceRow("Price (${cartItems.length} items)", "₹${subtotal.toStringAsFixed(2)}"),
                  const SizedBox(height: 8),
                  _priceRow(
                    "Discount (10%)",
                    "- ₹${discount.toStringAsFixed(2)}",
                    color: Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _priceRow(
                    "Delivery Fee",
                    deliveryFee == 0 ? "FREE" : "₹${deliveryFee.toStringAsFixed(2)}",
                    color: deliveryFee == 0 ? Colors.green : null,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Colors.grey.shade300, thickness: 1),
                  ),

                  _priceRow(
                    "Total Amount",
                    "₹${total.toStringAsFixed(2)}",
                    isBold: true,
                    fontSize: 18,
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: cartItems.isEmpty
                          ? null
                          : () {
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            "Proceed to Checkout",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          "Safe and Secure Payments",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
    );
  }

  Widget _priceRow(
      String title,
      String value, {
        bool isBold = false,
        Color? color,
        double fontSize = 15,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.grey.shade700,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? (isBold ? themeColor : Colors.black87),
          ),
        ),
      ],
    );
  }
}