import 'dart:async';
import 'dart:convert';
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

  // Data lists (raw)
  List<dynamic> drones = [];
  List<dynamic> parts = [];
  List<dynamic> accessories = [];

  // Filtered lists (for display)
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

  // Colors (matching your new UI)
  final Color lightPurple = const Color(0xFFE8EAF6);
  final Color lightBlue = const Color(0xFFE3F2FD);
  final Color accentColor = const Color(0xFF1A0A5B);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);
  final Color surfaceColor = Colors.white;
  final Color borderColor = const Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _fetchAll();
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

      // Normalize and store
      final dronesRes = results[0];
      final partsRes = results[1];
      final accRes = results[2];

      drones = (dronesRes.status == "success" ? List.from(dronesRes.data) : [])
          .map((d) => _normalizeItem(d, category: 'drone'))
          .toList();

      parts = (partsRes.status == "success" ? List.from(partsRes.data) : [])
          .map((p) => _normalizeItem(p, category: 'part'))
          .toList();

      accessories = (accRes.status == "success" ? List.from(accRes.data) : [])
          .map((a) => _normalizeItem(a, category: 'accessory'))
          .toList();

      // collect brands
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

  /// Ensures each item has a stable id, name, brand, price, image, description.
  Map<String, dynamic> _normalizeItem(dynamic raw, {required String category}) {
    final Map m = (raw is Map) ? Map<String, dynamic>.from(raw) : {'raw': raw};
    dynamic id = m['droneId'] ?? m['partId'] ?? m['accessoryId'] ?? m['id'] ?? m['uin'] ?? m['name'];
    final name = m['name'] ?? '';
    final brand = m['brand'] ?? '';
    final price = m['price'] ?? m['cost'] ?? 0;
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

      // brand filter
      if (selectedBrand != 'All') {
        res = res.where((i) => (i['brand'] ?? '') == selectedBrand).toList();
      }

      // price filter
      res = res.where((i) {
        final rawPrice = i['price'];
        double price;
        if (rawPrice is int) price = rawPrice.toDouble();
        else if (rawPrice is double) price = rawPrice;
        else {
          try {
            price = double.parse(rawPrice?.toString() ?? '0');
          } catch (_) {
            price = 0.0;
          }
        }
        return price >= currentPriceRange.start && price <= currentPriceRange.end;
      }).toList();

      // sort
      switch (sortBy) {
        case 'Price: Low to High':
          res.sort((a, b) {
            final pa = (a['price'] ?? 0).toDouble();
            final pb = (b['price'] ?? 0).toDouble();
            return pa.compareTo(pb);
          });
          break;
        case 'Price: High to Low':
          res.sort((a, b) {
            final pa = (a['price'] ?? 0).toDouble();
            final pb = (b['price'] ?? 0).toDouble();
            return pb.compareTo(pa);
          });
          break;
        case 'Name: A to Z':
          res.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
          break;
        case 'Name: Z to A':
          res.sort((a, b) => (b['name'] ?? '').toString().compareTo((a['name'] ?? '').toString()));
          break;
        default:
        // Recommended -> keep order as fetched
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
  // Wishlist / Cart actions (via provider)
  // ----------------------
  Future<void> _toggleWishlist(Map<String, dynamic> item) async {
    // provider expects item with 'id' key - normalization ensures that.
    final provider = context.read<CartWishlistProvider>();
    final name = item['name'] ?? 'Item';
    final added = await provider.toggleWishlist(item);
    Utils.bottomToast(context, added ? "$name added to wishlist" : "$name removed from wishlist");
  }

  Future<void> _addToCart(Map<String, dynamic> item) async {
    final provider = context.read<CartWishlistProvider>();
    final name = item['name'] ?? 'Item';
    final added = await provider.addToCart(item);
    Utils.bottomToast(context, added ? "$name added to cart" : "$name already in cart");
  }

  // ----------------------
  // Filter modal
  // ----------------------
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Filters & Sort",
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            )),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Price Range
                    Text("Price Range",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        )),
                    const SizedBox(height: 12),
                    RangeSlider(
                      values: currentPriceRange,
                      min: 0,
                      max: 100000,
                      divisions: 20,
                      activeColor: accentColor,
                      inactiveColor: Colors.grey.shade200,
                      onChanged: (v) => setModal(() => currentPriceRange = v),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "₹${currentPriceRange.start.round()}",
                            style: GoogleFonts.inter(color: accentColor),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "₹${currentPriceRange.end.round()}",
                            style: GoogleFonts.inter(color: accentColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Brand
                    Text("Brand",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        )),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButton<String>(
                        value: selectedBrand,
                        isExpanded: true,
                        underline: Container(),
                        icon: Icon(Icons.keyboard_arrow_down, color: textSecondary),
                        items: availableBrands.map((String brand) {
                          return DropdownMenuItem<String>(
                            value: brand,
                            child: Text(brand),
                          );
                        }).toList(),
                        onChanged: (String? newValue) => setModal(() => selectedBrand = newValue ?? 'All'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sort
                    Text("Sort By",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        )),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButton<String>(
                        value: sortBy,
                        isExpanded: true,
                        underline: Container(),
                        icon: Icon(Icons.keyboard_arrow_down, color: textSecondary),
                        items: const [
                          'Recommended',
                          'Price: Low to High',
                          'Price: High to Low',
                          'Name: A to Z',
                          'Name: Z to A',
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) => setModal(() => sortBy = newValue ?? 'Recommended'),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _resetFilters();
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text("Reset", style: GoogleFonts.inter(color: textSecondary, fontWeight: FontWeight.w600)),
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
                              backgroundColor: accentColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Text("Apply Filters", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ----------------------
  // UI building
  // ----------------------
  Widget _shimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(children: [
          Expanded(child: Container(color: lightPurple.withOpacity(0.5))),
          Container(height: 80, padding: const EdgeInsets.all(12), color: Colors.white),
        ]),
      ),
    );
  }

  Widget _badge(int count) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
    child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
  );

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CartWishlistProvider>();
    final wishlistIds = provider.wishlistIds;
    final cartIds = provider.cartIds;
    final cartCount = provider.cartCount;
    final wishlistCount = provider.wishlistCount;

    return Scaffold(
      backgroundColor: lightPurple,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [lightPurple, lightBlue]),
          ),
          child: Column(
            children: [
              // Header: top row, search, tabs
              Container(
                color: surfaceColor,
                child: Column(
                  children: [
                    Container(
                      height: kToolbarHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          IconButton(icon: Icon(Icons.arrow_back, color: textSecondary), onPressed: () => Navigator.pop(context)),
                          const SizedBox(width: 8),
                          Expanded(child: Text("Marketplace", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: accentColor))),

                          // Wishlist icon with badge
                          Stack(
                            children: [
                              IconButton(
                                icon: Icon(Icons.favorite_outline, color: textSecondary),
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistPage())),
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
                                icon: Icon(Icons.shopping_bag_outlined, color: textSecondary),
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCartPage())),
                              ),
                              if (cartCount > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: _badge(cartCount),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Search + Filter button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            Icon(Icons.search, color: textSecondary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                onChanged: _searchProducts,
                                style: GoogleFonts.inter(fontSize: 16, color: textPrimary),
                                decoration: InputDecoration(
                                  hintText: "Search drones, parts, accessories...",
                                  hintStyle: GoogleFonts.inter(color: textSecondary),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(8)),
                              child: IconButton(onPressed: _showFilterModal, icon: const Icon(Icons.tune, color: Colors.white, size: 20), padding: EdgeInsets.zero),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tabs
                    Container(
                      height: 48,
                      color: surfaceColor,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: accentColor,
                        unselectedLabelColor: textSecondary,
                        indicatorColor: accentColor,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                        tabs: const [Tab(text: 'Drones'), Tab(text: 'Parts'), Tab(text: 'Accessories')],
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGridView(filteredDrones),
                    _buildGridView(filteredParts),
                    _buildGridView(filteredAccessories),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(List<dynamic> items) {
    if (isLoading) return _shimmer();
    if (items.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [lightPurple, lightBlue]),
          ),
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: surfaceColor.withOpacity(0.8), shape: BoxShape.circle), child: Icon(Icons.search_off, size: 40, color: textSecondary)),
              const SizedBox(height: 20),
              Text("No products found", style: GoogleFonts.inter(fontSize: 18, color: textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text("Try adjusting your search or filters", style: GoogleFonts.inter(fontSize: 14, color: textSecondary)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _resetFilters, style: ElevatedButton.styleFrom(backgroundColor: accentColor), child: Text("Reset Filters", style: GoogleFonts.inter(color: Colors.white))),
            ]),
          ),
        ),
      );
    }

    final cross = MediaQuery.of(context).size.width > 900 ? 4 : (MediaQuery.of(context).size.width > 600 ? 3 : 2);

    return RefreshIndicator(
      onRefresh: _fetchAll,
      color: accentColor,
      backgroundColor: surfaceColor,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cross,
          childAspectRatio: 0.72,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = Map<String, dynamic>.from(items[index]);
          final id = item['id']?.toString() ?? index.toString();
          final provider = context.watch<CartWishlistProvider>();
          final isFav = provider.wishlistIds.contains(id);
          final inCart = provider.cartIds.contains(id);

          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DroneDetailPage(drone: item, Drone: null))),
            child: Container(
              decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 3))]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // image
                    Container(
                      height: 121,
                      width: double.infinity,
                      color: lightPurple.withOpacity(0.3),
                      child: CachedNetworkImage(
                        imageUrl: (item['image'] ?? '').toString(),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (ctx, url) => Container(color: lightPurple.withOpacity(0.5), child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                        errorWidget: (ctx, url, err) => Container(color: lightPurple.withOpacity(0.5), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.photo, color: textSecondary, size: 40), const SizedBox(height: 4), Text('No Image', style: GoogleFonts.inter(color: textSecondary, fontSize: 12))])),
                      ),
                    ),

                    // details
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item['brand'] ?? '', style: GoogleFonts.inter(color: accentColor, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(item['name'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text("₹${item['price'] ?? 0}", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: accentColor)),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)), child: Text("In Stock", style: GoogleFonts.inter(fontSize: 10, color: Colors.green.shade700))),
                        ]),
                      ]),
                    ),
                  ]),

                  // fav button
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
                        decoration: BoxDecoration(color: surfaceColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))]),
                        child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : textSecondary, size: 18),
                      ),
                    ),
                  ),

                  // add to cart button (bottom-right)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () async => _addToCart(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(color: inCart ? Colors.green : accentColor, borderRadius: BorderRadius.circular(8)),
                        child: Text(inCart ? "In Cart" : "Add to Cart", style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}