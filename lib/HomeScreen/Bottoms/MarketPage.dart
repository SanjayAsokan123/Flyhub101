import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../../CommonClass/ApiClass.dart';
import '../../CommonClass/utils.dart';
import '../../DroneDetailPage.dart';
import '../../BuyerDetails/MyCartPage.dart';
import '../../WishlistPage.dart';
import '../../services/role_manager.dart';
import '../../services/cart_wishlist_provider.dart';

class MarketPage extends StatefulWidget {
  final int initialTab;
  const MarketPage({super.key, this.initialTab = 0});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClass _apiClass = ApiClass();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String userRole = "guest";
  bool isLoading = true;
  String searchQuery = '';

  List<dynamic> drones = [];
  List<dynamic> parts = [];
  List<dynamic> accessories = [];

  List<dynamic> filteredDrones = [];
  List<dynamic> filteredParts = [];
  List<dynamic> filteredAccessories = [];

  final Color primaryColor = const Color(0xFF1A0A5B);

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _detectUserRole();
    fetchMarketplaceData();
  }

  Future<void> _detectUserRole() async {
    final prefsRole = await RoleManager.getLocalRole();
    final user = _auth.currentUser;

    if (user == null && prefsRole == null) {
      setState(() => userRole = "guest");
      return;
    }

    if (prefsRole != null) {
      setState(() => userRole = prefsRole);
      return;
    }

    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      setState(() => userRole = doc.data()?['role'] ?? "buyer");
    }
  }

  // ✅ Fetch drones, parts, accessories in parallel
  Future<void> fetchMarketplaceData() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        _apiClass.getDrones(),
        _apiClass.getParts(),
        _apiClass.getAccessories(),
      ]);

      if (!mounted) return;

      setState(() {
        drones = results[0].data ?? [];
        parts = results[1].data ?? [];
        accessories = results[2].data ?? [];

        filteredDrones = List.from(drones);
        filteredParts = List.from(parts);
        filteredAccessories = List.from(accessories);
        isLoading = false;
      });
    } catch (e) {
      Utils.bottomToast(context, "Error fetching data: $e");
      setState(() => isLoading = false);
    }
  }

  void _searchProducts(String query) {
    setState(() {
      searchQuery = query.trim().toLowerCase();
      filteredDrones = _filterList(drones);
      filteredParts = _filterList(parts);
      filteredAccessories = _filterList(accessories);
    });
  }

  List<dynamic> _filterList(List<dynamic> list) {
    if (searchQuery.isEmpty) return List.from(list);
    return list.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final brand = (item['brand'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery) || brand.contains(searchQuery);
    }).toList();
  }

  /// 💖 Add/remove wishlist
  Future<void> _toggleWishlist(Map<String, dynamic> item) async {
    final provider = context.read<CartWishlistProvider>();
    final id = item['droneId'] ??
        item['partId'] ??
        item['accessoryId'] ??
        item['id'] ??
        item['name'];
    final name = item['name'] ?? 'Unnamed';

    final isAdded = await provider.toggleWishlist(item);
    Utils.bottomToast(context,
        isAdded ? "$name added to wishlist" : "$name removed from wishlist");
  }

  /// 🛒 Add to cart
  Future<void> _addToCart(Map<String, dynamic> item) async {
    final provider = context.read<CartWishlistProvider>();
    final id = item['droneId'] ??
        item['partId'] ??
        item['accessoryId'] ??
        item['id'] ??
        item['name'];
    final name = item['name'] ?? 'Unnamed';

    final added = await provider.addToCart(item);
    Utils.bottomToast(
        context, added ? "$name added to cart" : "$name already in cart");
  }

  Widget shimmerLoader() {
    return GridView.builder(
      itemCount: 6,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
  }) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon, color: primaryColor),
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              height: 15,
              width: 15,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "$count",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CartWishlistProvider>();
    final wishlistCount = provider.wishlistCount;
    final cartCount = provider.cartCount;
    final wishlistIds = provider.wishlistIds;
    final cartIds = provider.cartIds;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Marketplace',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          _buildBadge(
            icon: Icons.favorite_border,
            count: wishlistCount,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WishlistPage()),
            ),
          ),
          _buildBadge(
            icon: Icons.shopping_cart_outlined,
            count: cartCount,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyCartPage()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: _searchProducts,
                decoration: InputDecoration(
                  hintText: "Search by name or brand...",
                  prefixIcon: Icon(Icons.search, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColor,
              tabs: const [
                Tab(text: 'Drones'),
                Tab(text: 'Parts'),
                Tab(text: 'Accessories'),
              ],
            ),
          ]),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildTabView(drones, filteredDrones, wishlistIds, cartIds, "Drones"),
          buildTabView(parts, filteredParts, wishlistIds, cartIds, "Parts"),
          buildTabView(accessories, filteredAccessories, wishlistIds, cartIds, "Accessories"),
        ],
      ),
    );
  }

  Widget buildTabView(List<dynamic> items, List<dynamic> filteredItems,
      Set<String> wishlistIds, Set<String> cartIds, String label) {
    if (isLoading) return shimmerLoader();
    final data = searchQuery.isEmpty ? items : filteredItems;
    if (data.isEmpty) {
      return Center(
        child: Text("No $label found 😶",
            style: const TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchMarketplaceData,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.78,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: data.length,
        itemBuilder: (context, index) => buildMarketCard(
          Map<String, dynamic>.from(data[index]),
          wishlistIds,
          cartIds,
        ),
      ),
    );
  }

  Widget buildMarketCard(Map<String, dynamic> item, Set<String> wishlistIds,
      Set<String> cartIds) {
    final imageUrl = (item['image'] ?? '').toString();
    final fullImageUrl = imageUrl.isEmpty
        ? "https://via.placeholder.com/300x200.png?text=No+Image"
        : imageUrl;

    final id = item['droneId'] ?? item['partId'] ?? item['accessoryId'] ?? '';
    final isFav = wishlistIds.contains(id);
    final inCart = cartIds.contains(id);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(6),
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DroneDetailPage(drone: item, Drone: null),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: fullImageUrl,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(height: 130, color: Colors.grey[200]),
                  errorWidget: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 50),
                ),
              ),
              Positioned(
                top: 5,
                right: 5,
                child: IconButton(
                  onPressed: () async => _toggleWishlist(item),
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.redAccent : Colors.white,
                  ),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'] ?? 'Unnamed',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lexend(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 3),
                  Text("₹${item['price'] ?? 0}",
                      style: GoogleFonts.lexend(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () async => _addToCart(item),
              child: Container(
                margin:
                const EdgeInsets.only(bottom: 8, right: 8, left: 8, top: 2),
                padding:
                const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                decoration: BoxDecoration(
                    color: inCart ? Colors.green : primaryColor,
                    borderRadius: BorderRadius.circular(8)),
                child: Center(
                  child: Text(
                    inCart ? "In Cart" : "Add to Cart",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
