import 'CommonClass/utils.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'BuyerDetails/MyCartPage.dart';
import 'AddressPage.dart';
import '../services/cart_wishlist_provider.dart';

class DroneDetailPage extends StatefulWidget {
  final Map<String, dynamic> drone;
  final bool initialIsFavorite;

  const DroneDetailPage({
    super.key,
    required this.drone,
    this.initialIsFavorite = false, required Drone,
  });

  @override
  State<DroneDetailPage> createState() => _DroneDetailPageState();
}

class _DroneDetailPageState extends State<DroneDetailPage> {
  int quantity = 1;
  int cartCount = 0;
  bool _localIsFavorite = false;
  bool _wishlistChanged = false;

  final Color themeColor = const Color(0xFF1A0A5B);

  @override
  void initState() {
    super.initState();
    _loadCartCount();
    _localIsFavorite = widget.initialIsFavorite;
  }

  Future<void> _loadCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('cart') ?? '[]';
    final cartItems = jsonDecode(saved);
    setState(() => cartCount = cartItems.length);
  }

  Future<void> _toggleWishlist() async {
    final provider = context.read<CartWishlistProvider>();
    final name = widget.drone['name'] ?? 'Item';

    final added = await provider.toggleWishlist(widget.drone);

    setState(() {
      _localIsFavorite = added;
      _wishlistChanged = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: themeColor,
        content: Row(
          children: [
            Icon(
              added ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Text(
              added
                  ? "$name added to wishlist"
                  : "$name removed from wishlist",
              style: GoogleFonts.lexend(color: Colors.white),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }



  bool _isInWishlist(BuildContext context) {
    final provider = context.watch<CartWishlistProvider>();
    final id = widget.drone['id']?.toString() ?? '';
    return provider.wishlistIds.contains(id);
  }


  Future<void> _addToCart() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('cart') ?? '[]';
    List<dynamic> cartItems = jsonDecode(saved);

    final currentDrone = {
      'id': widget.drone['id'],
      'name': widget.drone['name'],
      'price': widget.drone['price'],
      'brand': widget.drone['brand'],
      'image': widget.drone['image'],
      'quantity': quantity,
    };

    final exists =
    cartItems.any((item) => item['id'] == currentDrone['id']);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This item is already in your cart 🛒"),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    cartItems.add(currentDrone);
    await prefs.setString('cart', jsonEncode(cartItems));
    setState(() => cartCount = cartItems.length);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: themeColor,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              "Added to cart successfully!",
              style: GoogleFonts.lexend(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    await _loadCartCount();
  }

  void _showFullScreenImage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imageUrl: widget.drone['image'],
          productName: widget.drone['name'],
        ),
      ),
    );
  }

  void _popWithResult() {
    Navigator.pop(context, {
      'wishlistChanged': _wishlistChanged,
      'isFavorite': _localIsFavorite,
    });
  }

  @override
  Widget build(BuildContext context) {
    final drone = widget.drone;
    final isFavorite = _isInWishlist(context) || _localIsFavorite;

    final double price = (drone['price'] ?? 0).toDouble();
    final double totalAmount = price * quantity;

    return WillPopScope(
      onWillPop: () async {
        _popWithResult();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xfff7f7f7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _popWithResult,
          ),
          title: Text(
            drone['name'] ?? 'Drone Details',
            style: GoogleFonts.lexend(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.redAccent : themeColor,
              ),
              onPressed: _toggleWishlist,
            ),
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.shopping_cart_outlined,
                      color: themeColor),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MyCartPage()),
                    );
                    _loadCartCount();
                  },
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                          minWidth: 16, minHeight: 16),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.share, color: themeColor),
              onPressed: () {
                final text =
                    "🚀 Check out this drone!\n${drone['name']} - ₹${drone['price']}\n${drone['description'] ?? "Amazing performance and great quality!"}";
                Share.share(text);
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: themeColor,
          backgroundColor: Colors.white,
          displacement: 70,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _showFullScreenImage,
                  child: Container(
                    height: 280,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: drone['image'] != null
                            ? NetworkImage(drone['image'])
                            : const AssetImage(
                            'assets/images/MaskGroup34@2x.png')
                        as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.zoom_in,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Tap to view',
                              style: GoogleFonts.lexend(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(20),
                  margin:
                  const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        drone['name'] ?? "Drone",
                        style: GoogleFonts.lexend(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        drone['brand'] ?? "Drone Brand",
                        style: GoogleFonts.lexend(
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            "₹${drone['price'] ?? 0}",
                            style: GoogleFonts.lexend(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "₹${(drone['price'] ?? 0) + 2000}",
                            style: GoogleFonts.lexend(
                              fontSize: 16,
                              color: Colors.grey,
                              decoration:
                              TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding:
                            const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius:
                              BorderRadius.circular(6),
                            ),
                            child: Text(
                              "10% OFF",
                              style: GoogleFonts.lexend(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            "Quantity:",
                            style: GoogleFonts.lexend(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons
                                      .remove_circle_outline),
                                  onPressed: () {
                                    if (quantity > 1) {
                                      setState(
                                              () => quantity--);
                                    }
                                  },
                                ),
                                Text(
                                  '$quantity',
                                  style: GoogleFonts.lexend(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.add_circle_outline),
                                  onPressed: () {
                                    setState(
                                            () => quantity++);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _sectionTitle("Description"),
                _sectionText(
                  drone['description'] ??
                      "Experience high-speed performance, stability and HD imaging with this advanced drone.",
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                  ),
                  onPressed: _addToCart,
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                  ),
                  label: Text(
                    "Add to Cart",
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddressPage(
                          drone: widget.drone,
                          total: totalAmount,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.flash_on,
                    color: Colors.white,
                  ),
                  label: Text(
                    "Buy Now",
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Text(
      text,
      style: GoogleFonts.lexend(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),
  );

  Widget _sectionText(String text) => Padding(
    padding:
    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    child: Text(
      text,
      style: GoogleFonts.lexend(
        color: Colors.black87,
        height: 1.6,
        fontSize: 14,
      ),
    ),
  );
}

// Full Screen Image Viewer
class FullScreenImageViewer extends StatefulWidget {
  final String? imageUrl;
  final String? productName;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.productName,
  });

  @override
  State<FullScreenImageViewer> createState() =>
      _FullScreenImageViewerState();
}

class _FullScreenImageViewerState
    extends State<FullScreenImageViewer> {
  final TransformationController _transformationController =
  TransformationController();
  late InteractiveViewer _interactiveViewer;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _interactiveViewer = InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 5.0,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: widget.imageUrl != null
                ? NetworkImage(widget.imageUrl!)
                : const AssetImage(
                'assets/images/MaskGroup34@2x.png')
            as ImageProvider,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );

    _transformationController.addListener(() {
      setState(() {
        _scale =
            _transformationController.value.getMaxScaleOnAxis();
      });
    });
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final paddingTop = MediaQuery.of(context).padding.top;
    final paddingBottom =
        MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onDoubleTap: _resetZoom,
              child: _interactiveViewer,
            ),
          ),
          Positioned(
            top: paddingTop + 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          Positioned(
            top: paddingTop + 16,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: Text(
                  widget.productName ?? 'Product Image',
                  style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: paddingBottom + 20,
            right: 20,
            child: GestureDetector(
              onTap: _resetZoom,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                      Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: paddingBottom + 20,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _scale != 1.0 ? 1.0 : 0.0,
              duration:
              const Duration(milliseconds: 300),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(_scale * 100).round()}%',
                    style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: paddingBottom + 80,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedOpacity(
                opacity: _scale == 1.0 ? 1.0 : 0.0,
                duration:
                const Duration(milliseconds: 300),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.swipe,
                          color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Swipe to view more images',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight:
                          FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: paddingBottom + 20,
            left: 20,
            child: AnimatedOpacity(
              opacity: _scale == 1.0 ? 1.0 : 0.0,
              duration:
              const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.zoom_in,
                        color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Pinch to zoom',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}