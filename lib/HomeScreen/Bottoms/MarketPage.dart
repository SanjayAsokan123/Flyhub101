import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../CommonClass/ApiClass.dart';
import '../../CommonClass/utils.dart';
import '../../DroneDetailPage.dart';
import '../../BuyerDetails/MyCartPage.dart';
import '../../WishlistPage.dart';
import '../../services/cart_wishlist_provider.dart';
import '../Dynamichome.dart';

// --- Professional Theme/Style Constants ---
const Color kPrimaryColor = Color(0xFF1A0A5B);
const Color kSecondaryColor = Color(0xFF6C63FF);
const Color kAccentColor = Color(0xFF00BFA6);
const Color kTextPrimary = Color(0xFF1F2937);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kSurfaceColor = Colors.white;
const Color kBorderColor = Color(0xFFF0F0F0);
const Color kShimmerColor = Color(0xFFF5F5F5);
const Color kLightBackground = Color(0xFFF8FAFC);
const Color kCardShadow = Color(0x0A000000);

class MarketPage extends StatefulWidget {
  final int initialTab;
  const MarketPage({super.key, this.initialTab = 0});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClass _api = ApiClass();

  // Data lists
  List<dynamic> drones = [];
  List<dynamic> parts = [];
  List<dynamic> accessories = [];

  // Filtered lists
  List<dynamic> filteredDrones = [];
  List<dynamic> filteredParts = [];
  List<dynamic> filteredAccessories = [];

  // UI state
  bool isLoading = true;
  String searchQuery = '';

  // Filters
  RangeValues currentPriceRange = const RangeValues(0, 100000);
  String selectedBrand = 'All';
  String sortBy = 'Recommended';
  List<String> availableBrands = ['All'];

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ----------------------
  // Data loading & helpers
  // ----------------------
  Future<void> _fetchAll() async {
    setState(() => isLoading = true);

    try {
      final results = await Future.wait([
        _api.getDrones(),
        _api.getParts(),
        _api.getAccessories(),
      ]);

      if (!mounted) return;

      final dronesRes = results[0];
      final partsRes = results[1];
      final accRes = results[2];

      drones = (dronesRes.status == "success" ? List.from(dronesRes.data) : [])
          .map((d) => _normalizeItem(d, category: 'drone'))
          .where((item) => item['status'] == "approved")
          .toList();

      parts = (partsRes.status == "success" ? List.from(partsRes.data) : [])
          .map((p) => _normalizeItem(p, category: 'part'))
          .where((item) => item['status'] == "approved")
          .toList();

      accessories = (accRes.status == "success" ? List.from(accRes.data) : [])
          .map((a) => _normalizeItem(a, category: 'accessory'))
          .where((item) => item['status'] == "approved")
          .toList();

      final brands = <String>{};
      for (var item in [...drones, ...parts, ...accessories]) {
        final b = (item['brand'] ?? '').toString();
        if (b.isNotEmpty) brands.add(b);
      }
      availableBrands = ['All', ...brands.toList()];

      _applyFiltersAndSort();
      setState(() => isLoading = false);
    } catch (e) {
      Utils.bottomToast(context, "Error fetching marketplace: $e");
      setState(() => isLoading = false);
    }
  }

  Map<String, dynamic> _normalizeItem(dynamic raw, {required String category}) {
    final Map m = (raw is Map) ? Map<String, dynamic>.from(raw) : {'raw': raw};
    dynamic id = m['droneId'] ?? m['partId'] ?? m['accessoryId'] ?? m['id'] ?? m['uin'] ?? m['name'];
    final name = m['name'] ?? '';
    final brand = m['brand'] ?? '';
    double price = 0.0;
    final rawPrice = m['price'] ?? m['cost'] ?? 0;
    if (rawPrice is int) price = rawPrice.toDouble();
    else if (rawPrice is double) price = rawPrice;
    else {
      try {
        price = double.parse(rawPrice?.toString() ?? '0');
      } catch (_) {
        price = 0.0;
      }
    }
    final image = m['image'] ?? m['imageUrl'] ?? '';
    final description = m['description'] ?? m['desc'] ?? '';

    return {
      'id': id?.toString() ?? name.toString(),
      'raw': m,
      'category': category,
      'name': name,
      'brand': brand,
      'price': price,
      'image': image,
      'description': description,
      'status': m['status'] ?? '',
    };
  }

  // ----------------------
  // Filtering / Searching
  // ----------------------
  void _searchProducts(String q) {
    setState(() {
      searchQuery = q.trim().toLowerCase();
    });
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    List<dynamic> apply(List<dynamic> list) {
      var res = list.where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final brand = (item['brand'] ?? '').toString().toLowerCase();
        if (searchQuery.isNotEmpty && !(name.contains(searchQuery) || brand.contains(searchQuery))) {
          return false;
        }
        return true;
      }).toList();

      if (selectedBrand != 'All') {
        res = res.where((i) => (i['brand'] ?? '') == selectedBrand).toList();
      }

      res = res.where((i) {
        final price = (i['price'] ?? 0.0).toDouble();
        return price >= currentPriceRange.start && price <= currentPriceRange.end;
      }).toList();

      switch (sortBy) {
        case 'Price: Low to High':
          res.sort((a, b) => (a['price'] ?? 0.0).toDouble().compareTo((b['price'] ?? 0.0).toDouble()));
          break;
        case 'Price: High to Low':
          res.sort((a, b) => (b['price'] ?? 0.0).toDouble().compareTo((a['price'] ?? 0.0).toDouble()));
          break;
        case 'Name: A to Z':
          res.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
          break;
        case 'Name: Z to A':
          res.sort((a, b) => (b['name'] ?? '').toString().compareTo((a['name'] ?? '').toString()));
          break;
        default:
          break;
      }

      return res;
    }

    setState(() {
      filteredDrones = apply(drones);
      filteredParts = apply(parts);
      filteredAccessories = apply(accessories);
    });
  }

  void _resetFilters() {
    setState(() {
      currentPriceRange = const RangeValues(0, 100000);
      selectedBrand = 'All';
      sortBy = 'Recommended';
    });
    _applyFiltersAndSort();
  }

  // ----------------------
  // Wishlist / Cart actions
  // ----------------------
  Future<void> _toggleWishlist(Map<String, dynamic> item) async {
    final provider = context.read<CartWishlistProvider>();
    final name = item['name'] ?? 'Item';
    final added = await provider.toggleWishlist(item);
    Utils.bottomToast(context, added ? "$name added to wishlist" : "$name removed from wishlist");
  }

  // ----------------------
  // Enhanced Filter modal
  // ----------------------
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Filter & Sort",
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: kTextPrimary,
                            )),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: kLightBackground,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, color: kTextSecondary, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("Refine your search results",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: kTextSecondary,
                        )),
                    const SizedBox(height: 32),

                    // Price Range
                    _buildSectionHeader("Price Range"),
                    const SizedBox(height: 16),
                    RangeSlider(
                      values: currentPriceRange,
                      min: 0,
                      max: 100000,
                      divisions: 20,
                      activeColor: kPrimaryColor,
                      inactiveColor: Colors.grey.shade200,
                      onChanged: (v) => setModal(() => currentPriceRange = v),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPriceChip("₹${currentPriceRange.start.round()}"),
                        _buildPriceChip("₹${currentPriceRange.end.round()}"),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Brand
                    _buildSectionHeader("Brand"),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: kLightBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorderColor),
                      ),
                      child: DropdownButton<String>(
                        value: selectedBrand,
                        isExpanded: true,
                        underline: Container(),
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: kTextSecondary),
                        items: availableBrands.map((String brand) {
                          return DropdownMenuItem<String>(
                            value: brand,
                            child: Text(brand,
                                style: GoogleFonts.inter(
                                  color: kTextPrimary,
                                  fontSize: 16,
                                )),
                          );
                        }).toList(),
                        onChanged: (String? newValue) => setModal(() => selectedBrand = newValue ?? 'All'),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Sort
                    _buildSectionHeader("Sort By"),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: kLightBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorderColor),
                      ),
                      child: DropdownButton<String>(
                        value: sortBy,
                        isExpanded: true,
                        underline: Container(),
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: kTextSecondary),
                        items: const [
                          'Recommended',
                          'Price: Low to High',
                          'Price: High to Low',
                          'Name: A to Z',
                          'Name: Z to A',
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value,
                                style: GoogleFonts.inter(
                                  color: kTextPrimary,
                                  fontSize: 16,
                                )),
                          );
                        }).toList(),
                        onChanged: (String? newValue) => setModal(() => sortBy = newValue ?? 'Recommended'),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _resetFilters();
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: kBorderColor, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: kLightBackground,
                            ),
                            child: Text("Reset All",
                                style: GoogleFonts.inter(
                                  color: kTextSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                )),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _applyFiltersAndSort();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              shadowColor: kPrimaryColor.withOpacity(0.3),
                            ),
                            child: Text("Apply Filters",
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                )),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Text(text,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: kTextPrimary,
        ));
  }

  Widget _buildPriceChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: kPrimaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  // ----------------------
  // Clean Grid Shimmer
  // ----------------------
  Widget _shimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, __) => Container(
        color: kSurfaceColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              color: kShimmerColor,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 12,
                    color: kShimmerColor,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: kShimmerColor,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 14,
                    color: kShimmerColor,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 70,
                        height: 18,
                        color: kShimmerColor,
                      ),
                      Container(
                        width: 60,
                        height: 20,
                        color: kShimmerColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(int count) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.red.shade600,
      borderRadius: BorderRadius.circular(8),
    ),
    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
    child: Text('$count',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center),
  );

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CartWishlistProvider>();
    final cartCount = provider.cartCount;
    final wishlistCount = provider.wishlistCount;

    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: kSurfaceColor,
        elevation: 1,
        surfaceTintColor: kSurfaceColor,
        title: Text("Marketplace",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kPrimaryColor,
            )),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kTextSecondary, size: 20),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const Dynamichome(selectedIndex: 0),
            ),
          ),
        ),
        actions: [
          // Wishlist icon with badge
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.favorite_outline, color: kTextSecondary, size: 22),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WishlistPage())
                ),
              ),
              if (wishlistCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: _badge(wishlistCount),
                ),
            ],
          ),

          // Cart icon with badge
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_bag_outlined, color: kTextSecondary, size: 22),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyCartPage())
                ),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: _badge(cartCount),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search + Filter button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    border: Border.all(color: kBorderColor),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(Icons.search, color: kTextSecondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          onChanged: _searchProducts,
                          style: GoogleFonts.inter(fontSize: 16, color: kTextPrimary),
                          decoration: InputDecoration(
                            hintText: "Search drones, parts, accessories...",
                            hintStyle: GoogleFonts.inter(color: kTextSecondary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 8),
                        color: kPrimaryColor,
                        child: IconButton(
                            onPressed: _showFilterModal,
                            icon: const Icon(Icons.tune, color: Colors.white, size: 20),
                            padding: EdgeInsets.zero
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Clean Tabs
              Container(
                height: 48,
                color: kSurfaceColor,
                child: TabBar(
                  controller: _tabController,
                  labelColor: kPrimaryColor,
                  unselectedLabelColor: kTextSecondary,
                  indicatorColor: kPrimaryColor,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Drones'),
                    Tab(text: 'Parts'),
                    Tab(text: 'Accessories'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGridView(filteredDrones),
          _buildGridView(filteredParts),
          _buildGridView(filteredAccessories),
        ],
      ),
    );
  }

  Widget _buildGridView(List<dynamic> items) {
    if (isLoading) return _shimmer();
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: kTextSecondary),
            const SizedBox(height: 16),
            Text("No products found",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: kTextPrimary,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 8),
            Text("Try adjusting your search or filters",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: kTextSecondary,
                )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text("Reset Filters",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
      );
    }

    final cross = MediaQuery.of(context).size.width > 900 ? 4 :
    (MediaQuery.of(context).size.width > 600 ? 3 : 2);

    return RefreshIndicator(
      onRefresh: _fetchAll,
      color: kPrimaryColor,
      backgroundColor: kSurfaceColor,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cross,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = Map<String, dynamic>.from(items[index]);
          final id = item['id']?.toString() ?? index.toString();
          final provider = context.watch<CartWishlistProvider>();
          final isFav = provider.wishlistIds.contains(id);

          return GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DroneDetailPage(drone: item, Drone: null))
            ),
            child: Container(
              color: kSurfaceColor,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image container - no border radius
                      Container(
                        height: 140,
                        width: double.infinity,
                        color: kLightBackground,
                        child: CachedNetworkImage(
                          imageUrl: (item['image'] ?? '').toString(),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (ctx, url) => Container(
                            color: kShimmerColor,
                            child: Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: kPrimaryColor.withOpacity(0.5)
                              ),
                            ),
                          ),
                          errorWidget: (ctx, url, err) => Container(
                            color: kShimmerColor,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo_camera_back, color: kTextSecondary, size: 32),
                                const SizedBox(height: 4),
                                Text('No Image', style: GoogleFonts.inter(color: kTextSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Product details
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['brand'] ?? '',
                              style: GoogleFonts.inter(
                                color: kSecondaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['name'] ?? '',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: kTextPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "₹${(item['price'] ?? 0).round()}",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                    color: kPrimaryColor,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  color: kAccentColor.withOpacity(0.1),
                                  child: Text(
                                    "In Stock",
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: kAccentColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () async {
                        await _toggleWishlist(item);
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        color: kSurfaceColor.withOpacity(0.9),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red.shade500 : kTextSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}