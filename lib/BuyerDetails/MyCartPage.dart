import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../AddressPage.dart';
import '../Login/BuyerLoginPage.dart'; // Import your BuyerLoginPage

class MyCartPage extends StatefulWidget {
  const MyCartPage({super.key});

  @override
  State<MyCartPage> createState() => _MyCartPageState();
}

class _MyCartPageState extends State<MyCartPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  late AnimationController _animationController;
  String userRole = 'guest'; // 'guest', 'seller', or 'buyer'

  final Color themeColor = const Color(0xFF1A0A5B);
  final Color accentColor = const Color(0xFF6C5CE7);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadUserRole();
    _loadCart();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Load user role from SharedPreferences
  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('userRole') ?? 'guest';
    });
  }

  Future<void> _loadCart() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('cart') ?? '[]';
    final decoded = List<Map<String, dynamic>>.from(jsonDecode(saved));
    setState(() {
      cartItems = decoded;
      isLoading = false;
    });
    _animationController.forward();
  }

  Future<void> _updateCart() async {
    if (userRole != 'buyer') {
      _showRoleRestrictionMessage();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cart', jsonEncode(cartItems));
  }

  Future<void> _removeItem(int index) async {
    if (userRole != 'buyer') {
      _showRoleRestrictionMessage();
      return;
    }

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
  }

  double get subtotal =>
      cartItems.fold(0.0, (sum, item) => sum + (item["price"] * item["quantity"]));

  double get deliveryFee => cartItems.isEmpty ? 0.0 : (subtotal > 500 ? 0.0 : 40.0);
  double get discount => subtotal * 0.10;
  double get total => subtotal - discount + deliveryFee;

  void _increaseQuantity(int index) {
    if (userRole != 'buyer') {
      _showRoleRestrictionMessage();
      return;
    }

    setState(() => cartItems[index]["quantity"]++);
    _updateCart();
  }

  void _decreaseQuantity(int index) {
    if (userRole != 'buyer') {
      _showRoleRestrictionMessage();
      return;
    }

    if (cartItems[index]["quantity"] > 1) {
      setState(() => cartItems[index]["quantity"]--);
      _updateCart();
    }
  }

  void _saveForLater(int index) {
    if (userRole != 'buyer') {
      _showRoleRestrictionMessage();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Item saved for later"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _buyNow(int index) {
    if (userRole != 'buyer') {
      _showRoleRestrictionMessage();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressPage(
          total: cartItems[index]["price"] * cartItems[index]["quantity"],
          drone: {},
        ),
      ),
    );
  }

  void _checkout() {
    if (userRole != 'buyer') {
      _showRoleRestrictionMessage();
      return;
    }

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Your cart is empty!"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressPage(total: total, drone: {},),
      ),
    );
  }

  void _showRoleRestrictionMessage() {
    String message = '';
    if (userRole == 'guest') {
      message = 'Please login as a buyer to use the cart';
    } else if (userRole == 'seller') {
      message = 'Sellers cannot use the cart. Please login as a buyer';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: userRole == 'guest'
            ? SnackBarAction(
          label: 'LOGIN',
          textColor: Colors.white,
          onPressed: () => _navigateToBuyerLogin(),
        )
            : null,
      ),
    );
  }

  // Method to navigate to BuyerLoginPage
  void _navigateToBuyerLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BuyerLoginPage(),
      ),
    );
  }

  // Method to handle account switching for sellers
  void _switchToBuyerAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BuyerLoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            if (cartItems.isNotEmpty && userRole == 'buyer') ...[
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
          : userRole != 'buyer'
          ? _buildRoleRestrictionView()
          : cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
        children: [
          // Free delivery banner
          if (subtotal > 0 && subtotal < 500)
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
                            text: "₹${(500 - subtotal).toStringAsFixed(2)}",
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

  Widget _buildRoleRestrictionView() {
    String title = '';
    String subtitle = '';
    String buttonText = '';
    IconData icon = Icons.person_outline;

    if (userRole == 'guest') {
      title = 'Login Required';
      subtitle = 'Please login as a buyer to access your cart';
      buttonText = 'Login as Buyer';
      icon = Icons.login;
    } else if (userRole == 'seller') {
      title = 'Role Restriction';
      subtitle = 'Sellers cannot use the shopping cart. Please switch to buyer account';
      buttonText = 'Switch to Buyer';
      icon = Icons.switch_account;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 80,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (userRole == 'guest')
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _navigateToBuyerLogin, // Updated to use navigation method
                    icon: const Icon(Icons.login),
                    label: Text(buttonText),
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
                  const SizedBox(height: 16),

                ],
              )
            else if (userRole == 'seller')
              ElevatedButton.icon(
                onPressed: _switchToBuyerAccount, // Updated to use navigation method
                icon: const Icon(Icons.switch_account),
                label: Text(buttonText),
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

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
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
                          item["image"],
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
                                  item["name"],
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
                                onPressed: () => _removeItem(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Price
                          Text(
                            "₹${item["price"].toStringAsFixed(2)}",
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
                                  onPressed: () => _decreaseQuantity(index),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    "${item["quantity"]}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _quantityButton(
                                  icon: Icons.add,
                                  onPressed: () => _increaseQuantity(index),
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
                      onTap: () => _removeItem(index),
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

  Widget _quantityButton({required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: themeColor),
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
                    onPressed: _checkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
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
      ),
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