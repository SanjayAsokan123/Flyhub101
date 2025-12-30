import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/env.dart';
import '../../services/role_manager.dart';

// IMPORT YOUR PRODUCT DETAIL PAGE
import 'DroneDetailPage.dart';
import '../Login/BuyerRegisterPage.dart'; // Update this with your actual import
import '../Login/BuyerLoginPage.dart'; // Import BuyerLoginPage

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<dynamic> wishlist = [];
  bool isLoading = true;

  String? buyerId;
  bool _loadingBuyerId = false;
  String? _buyerIdError;

  // Premium Color Scheme
  final Color primaryColor = const Color(0xFF1A0A5B);
  final Color secondaryColor = const Color(0xFF6C63FF);
  final Color accentColor = const Color(0xFFFF6584);
  final Color surfaceColor = Colors.white;
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);
  final Color borderColor = const Color(0xFFF0F0F0);
  final Color successColor = const Color(0xFF10B981);
  final Color errorColor = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _initializeWishlist();
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
          _initializeWishlist();
        }
      }
    });
  }

  // ---------------------------------------------------------
  // 🔵 Initialize: Load buyerId → Load wishlist
  // ---------------------------------------------------------
  Future<void> _initializeWishlist() async {
    await _loadBuyerId();
    if (buyerId != null) {
      await loadWishlist();
    }
  }

  // ---------------------------------------------------------
  // 🔵 Fetch buyerId from MongoDB using Firebase UID
  // ---------------------------------------------------------
  Future<void> _loadBuyerId() async {
    setState(() {
      _loadingBuyerId = true;
      _buyerIdError = null; // Reset error
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() => _buyerIdError = "Please login to view your wishlist");
        return;
      }

      final firebaseUid = user.uid;

      const String query = r'''
        query GetBuyerfirebaseUidWish($firebaseUid: String!) {
          getBuyerfirebaseUidWish(firebaseUid: $firebaseUid) {
            buyerId
            firebaseUid
            name
            email
          }
        }
      ''';

      final res = await http.post(
        Uri.parse(EnvConfig.baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "query": query,
          "variables": {"firebaseUid": firebaseUid},
        }),
      );

      final body = jsonDecode(res.body);

      if (body["errors"] != null) {
        setState(() => _buyerIdError = "Unable to fetch account details");
        return;
      }

      final data = body["data"]["getBuyerfirebaseUidWish"];

      if (data != null && data["buyerId"] != null) {
        buyerId = data["buyerId"];
        await RoleManager.saveBuyerId(buyerId!);
      } else {
        setState(() => _buyerIdError = "Account not found");
      }
    } catch (e) {
      setState(() => _buyerIdError = "Network error. Please try again.");
    } finally {
      setState(() => _loadingBuyerId = false);
    }
  }

  // ---------------------------------------------------------
  // 🔵 GraphQL Helper
  // ---------------------------------------------------------
  Future<dynamic> _graphQL(String query, Map<String, dynamic> variables) async {
    try {
      final res = await http.post(
        Uri.parse(EnvConfig.baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"query": query, "variables": variables}),
      );

      final data = jsonDecode(res.body);
      return data["errors"] != null ? null : data["data"];
    } catch (e) {
      return null;
    }
  }

  // ---------------------------------------------------------
  // 🔵 Fetch Wishlist Items
  // ---------------------------------------------------------
  Future<void> loadWishlist() async {
    if (buyerId == null) return;

    const query = r"""
      query GetWishlist($buyerId: String!) {
        getWishlist(buyerId: $buyerId) {
          id
          productId
          addedAt
          product {
            productId
            name
            price
            image
            brand
            category
          }
        }
      }
    """;

    final data = await _graphQL(query, {"buyerId": buyerId});

    setState(() {
      wishlist = data?["getWishlist"] ?? [];
      isLoading = false;
    });
  }

  // ---------------------------------------------------------
  // 🔵 Remove Item from Wishlist
  // ---------------------------------------------------------
  Future<void> _remove(String productId) async {
    const query = r"""
      mutation Remove($buyerId: String!, $productId: String!) {
        removeFromWishlist(buyerId: $buyerId, productId: $productId)
      }
    """;

    await _graphQL(query, {"buyerId": buyerId, "productId": productId});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Removed from wishlist",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );

    loadWishlist();
  }

  // ---------------------------------------------------------
  // 🔵 Move Item to Cart
  // ---------------------------------------------------------
  Future<void> _moveToCart(dynamic product) async {
    // Implement your cart addition logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "'${product['name']}' moved to cart",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ---------------------------------------------------------
  // 🔵 Format Price
  // ---------------------------------------------------------
  String _formatPrice(dynamic price) {
    try {
      final formatter = NumberFormat.currency(
        symbol: '₹',
        decimalDigits: 0,
        locale: 'en_IN',
      );
      return formatter.format(double.parse(price.toString()));
    } catch (e) {
      return '₹${price}';
    }
  }

  // ---------------------------------------------------------
  // 🔵 Clear All Wishlist Items
  // ---------------------------------------------------------
  Future<void> _clearWishlist() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Clear Wishlist?",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          "This will remove all items from your wishlist. This action cannot be undone.",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(
                color: textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: errorColor,
            ),
            child: Text(
              "Clear All",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    for (final item in wishlist) {
      final productId = item["product"]?["productId"] ?? item["productId"];
      await _remove(productId);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Wishlist cleared",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ---------------------------------------------------------
  // 🔵 Navigate to Product Detail Page
  // ---------------------------------------------------------
  void _navigateToProductDetail(dynamic product) async {
    // Navigate to your DroneDetailPage
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DroneDetailPage(
            drone: product,
            initialIsFavorite: true, // Since it's in wishlist
            // Adjust these parameters according to your DroneDetailPage constructor
            Drone: product, // Pass the product data
          ),
        ),
      );

      // Refresh wishlist when returning from detail page
      // in case user removed it from favorites there
      loadWishlist();
    } catch (e) {
      // Handle navigation error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open product details'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  // ---------------------------------------------------------
  // 🔵 Calculate Responsive Values - DYNAMIC SIZING
  // ---------------------------------------------------------
  double _getResponsiveSize(BuildContext context, double mobileSize, double tabletSize, double desktopSize) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final shortestSide = width < height ? width : height;

    if (shortestSide < 600) return mobileSize; // Mobile
    if (shortestSide < 1200) return tabletSize; // Tablet
    return desktopSize; // Desktop/Large Tablet
  }

  int _getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final shortestSide = width < MediaQuery.of(context).size.height ? width : MediaQuery.of(context).size.height;

    if (shortestSide < 400) return 2; // Small mobile (portrait)
    if (shortestSide < 600) return 2; // Mobile (landscape) / small tablet (portrait)
    if (shortestSide < 900) return 2; // Tablet
    if (shortestSide < 1200) return 4; // Large tablet
    return 6; // Desktop
  }

  double _getGridChildAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final shortestSide = width < height ? width : height;

    // Larger aspect ratio for taller cards (better image space)
    if (shortestSide < 400) return 0.60; // Small phones
    if (shortestSide < 600) return 0.66; // Phones
    if (shortestSide < 900) return 0.75; // Small tablets
    return 0.78; // Tablets and larger
  }

  double _getGridSpacing(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide * 0.02; // 2% of shortest side
  }

  double _getGridPadding(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    if (shortestSide < 600) return shortestSide * 0.03; // Mobile: 3%
    return shortestSide * 0.04; // Tablet: 4%
  }

  double _getCardImageHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = _getGridCrossAxisCount(context);
    final availableWidth = width - (_getGridPadding(context) * 1) - (_getGridSpacing(context) * (crossAxisCount - 1));
    final cardWidth = availableWidth / crossAxisCount;

    // Image takes 60-70% of card height based on screen size
    final imageHeightRatio = _getResponsiveSize(context, 0.85, 0.70, 0.15);
    return cardWidth * imageHeightRatio;
  }

  // ---------------------------------------------------------
  // 🔵 Dynamic Button Sizing Methods
  // ---------------------------------------------------------
  double _getAddToCartButtonHeight(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;

    if (shortestSide < 400) return 28.0; // Very small phones
    if (shortestSide < 600) return 32.0; // Phones
    if (shortestSide < 900) return 36.0; // Small tablets
    if (shortestSide < 1200) return 40.0; // Tablets
    return 44.0; // Large tablets/Desktop
  }

  double _getAddToCartButtonFontSize(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;

    if (shortestSide < 400) return 12.0; // Very small phones
    if (shortestSide < 600) return 13.0; // Phones
    if (shortestSide < 900) return 14.0; // Small tablets
    if (shortestSide < 1200) return 15.0; // Tablets
    return 16.0; // Large tablets/Desktop
  }

  double _getAddToCartButtonIconSize(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;

    if (shortestSide < 400) return 14.0; // Very small phones
    if (shortestSide < 600) return 16.0; // Phones
    if (shortestSide < 900) return 18.0; // Small tablets
    if (shortestSide < 1200) return 20.0; // Tablets
    return 22.0; // Large tablets/Desktop
  }

  double _getAddToCartButtonBorderRadius(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;

    if (shortestSide < 600) return 6.0; // Mobile
    return 8.0; // Tablet & larger
  }

  EdgeInsets _getAddToCartButtonPadding(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;

    if (shortestSide < 400) return EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    if (shortestSide < 600) return EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    if (shortestSide < 900) return EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    return EdgeInsets.symmetric(horizontal: 14, vertical: 10);
  }

  // ---------------------------------------------------------
  // 🔵 UI States
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "My Wishlist",
          style: GoogleFonts.inter(
            fontSize: _getResponsiveSize(context, 18, 20, 22),
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        backgroundColor: surfaceColor,
        elevation: 1,
        surfaceTintColor: surfaceColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textSecondary,
            size: _getResponsiveSize(context, 20, 22, 24),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!isLoading && wishlist.isNotEmpty)
            IconButton(
              onPressed: _clearWishlist,
              icon: Icon(
                Icons.delete_sweep_rounded,
                color: textSecondary,
                size: _getResponsiveSize(context, 22, 24, 26),
              ),
              tooltip: "Clear Wishlist",
            ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  // -----------------------------------------
  // BODY CONTENT
  // -----------------------------------------
  Widget _buildBody(BuildContext context) {
    if (_loadingBuyerId) {
      return _buildLoadingState(context);
    }

    if (_buyerIdError != null) {
      return _buildErrorState(context);
    }

    if (isLoading) {
      return _buildLoadingState(context);
    }

    if (wishlist.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: loadWishlist,
      color: secondaryColor,
      backgroundColor: surfaceColor,
      child: _buildWishlistGrid(context),
    );
  }

  // -----------------------------------------
  // LOADING STATE
  // -----------------------------------------
  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
          ),
          SizedBox(height: _getResponsiveSize(context, 16, 20, 24)),
          Text(
            "Loading your wishlist...",
            style: GoogleFonts.inter(
              fontSize: _getResponsiveSize(context, 14, 16, 18),
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------
  // ERROR STATE
  // -----------------------------------------
  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(_getResponsiveSize(context, 24, 32, 40)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon or image for empty cart state
            Container(
              padding: EdgeInsets.all(_getResponsiveSize(context, 20, 24, 28)),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                size: _getResponsiveSize(context, 50, 60, 70),
                color: primaryColor,
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 24, 32, 40)),
            Text(
              "Account Required",
              style: GoogleFonts.inter(
                fontSize: _getResponsiveSize(context, 20, 24, 28),
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 12, 16, 20)),
            Text(
              _buyerIdError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: _getResponsiveSize(context, 14, 16, 18),
                color: textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 8, 10, 12)),
            Text(
              "Please login or register as a buyer to continue shopping",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: _getResponsiveSize(context, 14, 16, 18),
                color: textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 32, 40, 48)),

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
                icon: Icon(
                  Icons.person_add,
                  size: _getResponsiveSize(context, 18, 20, 22),
                ),
                label: Text(
                  "Register as Buyer",
                  style: GoogleFonts.inter(
                    fontSize: _getResponsiveSize(context, 14, 16, 18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: _getResponsiveSize(context, 24, 28, 32),
                    vertical: _getResponsiveSize(context, 14, 16, 18),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 12, 16, 20)),

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
                icon: Icon(
                  Icons.login,
                  size: _getResponsiveSize(context, 18, 20, 22),
                  color: primaryColor,
                ),
                label: Text(
                  "Login to Existing Account",
                  style: GoogleFonts.inter(
                    fontSize: _getResponsiveSize(context, 14, 16, 18),
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryColor),
                  padding: EdgeInsets.symmetric(
                    horizontal: _getResponsiveSize(context, 24, 28, 32),
                    vertical: _getResponsiveSize(context, 14, 16, 18),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 16, 20, 24)),
            TextButton(
              onPressed: () {
                // Navigate back
                Navigator.pop(context);
              },
              child: Text(
                "Back to Home",
                style: GoogleFonts.inter(
                  fontSize: _getResponsiveSize(context, 14, 16, 18),
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------
  // EMPTY STATE
  // -----------------------------------------
  Widget _buildEmptyState(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final iconSize = shortestSide * _getResponsiveSize(context, 0.3, 0.25, 0.2);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(_getResponsiveSize(context, 20, 32, 40)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(iconSize * 0.3),
              decoration: BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: iconSize,
                color: textSecondary,
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 24, 32, 40)),
            Text(
              "Your Wishlist is Empty",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: _getResponsiveSize(context, 22, 26, 30),
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 12, 16, 20)),
            Text(
              "Save items you love for later\nExplore products and add them to your wishlist",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: _getResponsiveSize(context, 14, 16, 18),
                color: textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 24, 32, 40)),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                padding: EdgeInsets.symmetric(
                  horizontal: _getResponsiveSize(context, 32, 40, 48),
                  vertical: _getResponsiveSize(context, 16, 18, 20),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Continue Shopping",
                style: GoogleFonts.inter(
                  fontSize: _getResponsiveSize(context, 16, 18, 20),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------
  // WISHLIST GRID VIEW
  // -----------------------------------------
  Widget _buildWishlistGrid(BuildContext context) {
    final crossAxisCount = _getGridCrossAxisCount(context);
    final spacing = _getGridSpacing(context);
    final padding = _getGridPadding(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: padding,
            vertical: _getResponsiveSize(context, 16, 20, 24),
          ),
          child: Row(
            children: [
              Text(
                "Saved Items",
                style: GoogleFonts.inter(
                  fontSize: _getResponsiveSize(context, 18, 20, 22),
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              SizedBox(width: spacing * 0.5),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _getResponsiveSize(context, 12, 14, 16),
                  vertical: _getResponsiveSize(context, 6, 8, 10),
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${wishlist.length}",
                  style: GoogleFonts.inter(
                    fontSize: _getResponsiveSize(context, 12, 14, 16),
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
              const Spacer(),
              if (MediaQuery.of(context).size.width > 400)
                Text(
                  "Tap card to view details",
                  style: GoogleFonts.inter(
                    fontSize: _getResponsiveSize(context, 12, 14, 16),
                    color: textSecondary,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: _getGridChildAspectRatio(context),
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
              ),
              itemCount: wishlist.length,
              itemBuilder: (context, index) {
                final item = wishlist[index];
                final product = item["product"];
                if (product == null) {
                  return _buildUnavailableItem(item, context);
                }
                return _buildWishlistCard(product, item["addedAt"], index, context);
              },
            ),
          ),
        ),
      ],
    );
  }

  // -----------------------------------------
  // WISHLIST CARD - WITH TEXT TRUNCATION
  // -----------------------------------------
  Widget _buildWishlistCard(dynamic product, String addedAt, int index, BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = _getGridCrossAxisCount(context);
    final spacing = _getGridSpacing(context);
    final padding = _getGridPadding(context);
    final availableWidth = width - (padding * 2) - (spacing * (crossAxisCount - 1));
    final isSmallScreen = width < 500;

    return GestureDetector(
      onTap: () => _navigateToProductDetail(product),
      child: Container(
        margin: EdgeInsets.all(width * 0.01),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Section - TALLER IMAGE
            GestureDetector(
              onTap: () => _navigateToProductDetail(product),
              child: Stack(
                children: [
                  // Product Image - Increased Height
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Container(
                      height: _getCardImageHeight(context),
                      width: double.infinity,
                      color: backgroundColor,
                      child: _buildProductImage(product, context),
                    ),
                  ),

                  // Remove Button
                  Positioned(
                    top: _getResponsiveSize(context, 8, 10, 12),
                    right: _getResponsiveSize(context, 8, 10, 12),
                    child: GestureDetector(
                      onTap: () => _remove(product["productId"]),
                      child: Container(
                        width: _getResponsiveSize(context, 28, 32, 36),
                        height: _getResponsiveSize(context, 28, 32, 36),
                        decoration: BoxDecoration(
                          color: surfaceColor.withOpacity(0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: _getResponsiveSize(context, 16, 18, 20),
                          color: errorColor,
                        ),
                      ),
                    ),
                  ),

                  // Saved Badge
                  Positioned(
                    top: _getResponsiveSize(context, 8, 10, 12),
                    left: _getResponsiveSize(context, 8, 10, 12),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _getResponsiveSize(context, 8, 10, 12),
                        vertical: _getResponsiveSize(context, 4, 6, 8),
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            color: surfaceColor,
                            size: _getResponsiveSize(context, 14, 16, 18),
                          ),
                          if (!isSmallScreen) SizedBox(width: _getResponsiveSize(context, 4, 6, 8)),
                          if (!isSmallScreen)
                            Text(
                              "Saved",
                              style: GoogleFonts.inter(
                                color: surfaceColor,
                                fontSize: _getResponsiveSize(context, 10, 12, 14),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product Details Section
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(_getResponsiveSize(context, 12, 14, 16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand and Name Section - WITH TEXT TRUNCATION
                    GestureDetector(
                      onTap: () => _navigateToProductDetail(product),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand Name
                          if (product["brand"] != null && product["brand"].toString().isNotEmpty)
                            Text(
                              product["brand"].toString().toUpperCase(),
                              style: GoogleFonts.inter(
                                color: secondaryColor,
                                fontSize: _getResponsiveSize(context, 10, 12, 14),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                          SizedBox(height: _getResponsiveSize(context, 4, 6, 8)),

                          // Product Name - ALWAYS SINGLE LINE WITH ELLIPSIS
                          SizedBox(
                            height: _getResponsiveSize(context, 20, 24, 28),
                            child: Text(
                              product["name"]?.toString() ?? "Unnamed Product",
                              style: GoogleFonts.inter(
                                fontSize: _getResponsiveSize(context, 14, 16, 18),
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price Section
                    GestureDetector(
                      onTap: () => _navigateToProductDetail(product),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price - Single line
                          Text(
                            _formatPrice(product["price"]),
                            style: GoogleFonts.inter(
                              fontSize: _getResponsiveSize(context, 16, 18, 20),
                              fontWeight: FontWeight.w800,
                              color: primaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          if (addedAt.isNotEmpty)
                            SizedBox(height: _getResponsiveSize(context, 4, 6, 8)),

                          if (addedAt.isNotEmpty)
                            SizedBox(
                              height: _getResponsiveSize(context, 16, 18, 20),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: _getResponsiveSize(context, 12, 14, 16),
                                    color: textSecondary,
                                  ),
                                  SizedBox(width: _getResponsiveSize(context, 4, 6, 8)),
                                  Expanded(
                                    child: Text(
                                      "Added ${_formatDate(addedAt)}",
                                      style: GoogleFonts.inter(
                                        fontSize: _getResponsiveSize(context, 10, 12, 14),
                                        color: textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Add to Cart Button - FULLY DYNAMIC SIZING
                    // SizedBox(
                    //   width: double.infinity,
                    //   height: _getAddToCartButtonHeight(context),
                    //   child: FilledButton(
                    //     onPressed: () => _moveToCart(product),
                    //     style: FilledButton.styleFrom(
                    //       backgroundColor: primaryColor,
                    //       padding: _getAddToCartButtonPadding(context),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(
                    //           _getAddToCartButtonBorderRadius(context),
                    //         ),
                    //       ),
                    //       elevation: 0,
                    //     ),
                    //     child: Row(
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       children: [
                    //         Icon(
                    //           Icons.shopping_cart_outlined,
                    //           size: _getAddToCartButtonIconSize(context),
                    //           color: surfaceColor,
                    //         ),
                    //         SizedBox(width: _getResponsiveSize(context, 4, 6, 8)),
                    //         Expanded(
                    //           child: Text(
                    //             "Add to Cart",
                    //             style: GoogleFonts.inter(
                    //               fontSize: _getAddToCartButtonFontSize(context),
                    //               fontWeight: FontWeight.w500,
                    //             ),
                    //             maxLines: 1,
                    //             overflow: TextOverflow.ellipsis,
                    //             textAlign: TextAlign.center,
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------
  // UNAVAILABLE ITEM CARD
  // -----------------------------------------
  Widget _buildUnavailableItem(dynamic item, BuildContext context) {
    return Container(
      margin: EdgeInsets.all(_getResponsiveSize(context, 8, 10, 12)),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(_getResponsiveSize(context, 16, 18, 20)),
        child: Row(
          children: [
            Container(
              width: _getResponsiveSize(context, 60, 70, 80),
              height: _getResponsiveSize(context, 60, 70, 80),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.block_rounded,
                size: _getResponsiveSize(context, 28, 32, 36),
                color: textSecondary,
              ),
            ),
            SizedBox(width: _getResponsiveSize(context, 12, 14, 16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Product unavailable",
                    style: GoogleFonts.inter(
                      fontSize: _getResponsiveSize(context, 14, 16, 18),
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: _getResponsiveSize(context, 4, 6, 8)),
                  Text(
                    "This item is no longer available",
                    style: GoogleFonts.inter(
                      fontSize: _getResponsiveSize(context, 12, 14, 16),
                      color: textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _remove(item["productId"]),
              icon: Icon(
                Icons.delete_outline_rounded,
                size: _getResponsiveSize(context, 20, 22, 24),
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------
  // PRODUCT IMAGE BUILDER - WITH DYNAMIC SIZING
  // -----------------------------------------
  Widget _buildProductImage(dynamic product, BuildContext context) {
    final imageUrl = product["image"]?.toString();
    final imageHeight = _getCardImageHeight(context);

    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: imageHeight,
        color: backgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera_back_rounded,
              color: textSecondary,
              size: _getResponsiveSize(context, 32, 40, 48),
            ),
            SizedBox(height: _getResponsiveSize(context, 4, 6, 8)),
            Text(
              'No Image',
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: _getResponsiveSize(context, 12, 14, 16),
              ),
            ),
          ],
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: imageHeight,
      placeholder: (context, url) => Container(
        height: imageHeight,
        color: backgroundColor,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: primaryColor,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: imageHeight,
        color: backgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_rounded,
              color: textSecondary,
              size: _getResponsiveSize(context, 32, 40, 48),
            ),
            SizedBox(height: _getResponsiveSize(context, 4, 6, 8)),
            Text(
              'Image Error',
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: _getResponsiveSize(context, 12, 14, 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------
  // 🔵 Format Date
  // -----------------------------------------
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM').format(date);
    } catch (e) {
      return dateString;
    }
  }
}