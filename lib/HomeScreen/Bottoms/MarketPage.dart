import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../CommonClass/ApiClass.dart';
import '../../CommonClass/utils.dart';
import '../../DroneDetailPage.dart';
import '../../BuyerDetails/MyCartPage.dart';
import '../../BuyerDetails/WishlistPage.dart';
import '../../config/env.dart';
import '../../services/cart_wishlist_provider.dart';
import '../../services/role_manager.dart';
import '../Dynamichome.dart';
import '../../utils/responsive_utils.dart';

const Color kPrimaryColor = Color(0xFF1A0A5B);
const Color kSecondaryColor = Color(0xFF6C63FF);
const Color kTextPrimary = Color(0xFF1F2937);
const Color kTextSecondary = Color(0xFF1A0A5B);
const Color kSurfaceColor = Colors.white;
const Color kBorderColor = Color(0xFFF0F0F0);
const Color kShimmerColor = Color(0xFFF5F5F5);
const Color kLightBackground = Color(0xFFF8FAFC);

class MarketPage extends StatefulWidget {
  final int initialTab;
  const MarketPage({super.key, this.initialTab = 0});
  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClass _api = ApiClass();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> drones = [], parts = [], accessories = [];
  List<dynamic> filteredDrones = [], filteredParts = [], filteredAccessories = [];
  bool isLoading = true;
  String searchQuery = '', selectedBrand = 'All', sortBy = 'Recommended';
  RangeValues currentPriceRange = const RangeValues(0, 100000);
  List<String> availableBrands = ['All'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _fetchAll();
    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text);
      _applyFilters();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([_api.getDrones(), _api.getParts(), _api.getAccessories()]);
      if (!mounted) return;

      drones = _processItems(results[0], 'drone');
      parts = _processItems(results[1], 'part');
      accessories = _processItems(results[2], 'accessory');

      final brands = <String>{'All'};
      for (var item in [...drones, ...parts, ...accessories]) {
        final b = (item['brand'] ?? '').toString();
        if (b.isNotEmpty) brands.add(b);
      }
      availableBrands = brands.toList();

      _applyFilters();
      setState(() => isLoading = false);
    } catch (e) {
      if (mounted) Utils.bottomToast(context, "Error: $e");
      setState(() => isLoading = false);
    }
  }

  List<dynamic> _processItems(dynamic result, String category) {
    return (result.status == "success" ? List.from(result.data) : [])
        .map((d) => _normalizeItem(d, category))
        .where((item) => item['status'] == "approved")
        .toList();
  }

  Map<String, dynamic> _normalizeItem(dynamic raw, String category) {
    final Map m = (raw is Map) ? Map<String, dynamic>.from(raw) : {'raw': raw};
    dynamic id = m['droneId'] ?? m['partId'] ?? m['accessoryId'] ?? m['id'] ?? m['uin'] ?? m['name'];

    double price = 0.0;
    final rawPrice = m['price'] ?? m['cost'] ?? 0;
    if (rawPrice is int) price = rawPrice.toDouble();
    else if (rawPrice is double) price = rawPrice;
    else try { price = double.parse(rawPrice?.toString() ?? '0'); } catch (_) {}

    return {
      'id': id?.toString() ?? '${category}${DateTime.now().millisecondsSinceEpoch}',
      'raw': m,
      'category': category,
      'name': m['name'] ?? 'Unknown Product',
      'brand': m['brand'] ?? '',
      'price': price,
      'image': m['image'] ?? m['imageUrl'] ?? '',
      'description': m['description'] ?? m['desc'] ?? '',
      'status': m['status'] ?? '',
    };
  }

  void _applyFilters() {
    filteredDrones = _filterList(drones);
    filteredParts = _filterList(parts);
    filteredAccessories = _filterList(accessories);
    setState(() {});
  }

  List<dynamic> _filterList(List<dynamic> list) {
    var result = list.where((item) {
      if (searchQuery.isNotEmpty) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final brand = (item['brand'] ?? '').toString().toLowerCase();
        if (!(name.contains(searchQuery) || brand.contains(searchQuery))) return false;
      }
      if (selectedBrand != 'All' && (item['brand'] ?? '') != selectedBrand) return false;
      final price = (item['price'] ?? 0.0).toDouble();
      return price >= currentPriceRange.start && price <= currentPriceRange.end;
    }).toList();

    switch (sortBy) {
      case 'Price: Low to High': result.sort((a, b) => (a['price'] ?? 0.0).compareTo((b['price'] ?? 0.0))); break;
      case 'Price: High to Low': result.sort((a, b) => (b['price'] ?? 0.0).compareTo((a['price'] ?? 0.0))); break;
      case 'Name: A to Z': result.sort((a, b) => (a['name'] ?? '').compareTo((b['name'] ?? ''))); break;
      case 'Name: Z to A': result.sort((a, b) => (b['name'] ?? '').compareTo((a['name'] ?? ''))); break;
    }
    return result;
  }

  void _resetFilters() {
    setState(() {
      currentPriceRange = const RangeValues(0, 100000);
      selectedBrand = 'All';
      sortBy = 'Recommended';
      _searchController.clear();
    });
    _applyFilters();
  }

  Future<dynamic> _gql(String query, Map<String, dynamic> vars) async {
    final res = await http.post(
      Uri.parse(EnvConfig.baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"query": query, "variables": vars}),
    );

    final body = jsonDecode(res.body);
    if (body["errors"] != null) {
      print("GraphQL Error: ${body["errors"]}");
      return null;
    }
    return body["data"];
  }

  Future<void> _toggleWishlist(Map<String, dynamic> item) async {
    final buyerId = await RoleManager.getBuyerId();
    if (buyerId == null) return;

    final productId = item["productId"] ?? item["id"];

    // Check current wishlist state — backend
    const queryGet = r"""
    query GetWishlist($buyerId: String!) {
      getWishlist(buyerId: $buyerId) {
        productId
      }
    }
  """;

    final data = await _gql(queryGet, {"buyerId": buyerId});
    final wishlist = data?["getWishlist"] ?? [];

    final isFav = wishlist.any(
          (w) => w["productId"].toString() == productId.toString(),
    );

    // Toggle logic
    final query = isFav
        ? r"""
          mutation Remove($buyerId: String!, $productId: String!) {
            removeFromWishlist(buyerId: $buyerId, productId: $productId)
          }
        """
        : r"""
          mutation Add($buyerId: String!, $productId: String!) {
            addToWishlist(buyerId: $buyerId, productId: $productId) {
              id
            }
          }
        """;

    await _gql(query, {"buyerId": buyerId, "productId": productId});

    setState(() {}); // Rebuild UI

    Utils.bottomToast(
      context,
      isFav ? "Removed from wishlist" : "Added to wishlist ❤️",
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: ResponsiveUtils.getSafeContainerHeight(context, percentage: 0.8),
        decoration: const BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StatefulBuilder(builder: (context, setModal) {
          return Padding(
            padding: ResponsiveUtils.getMarketFilterModalPadding(context),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Filter & Sort", style: GoogleFonts.inter(fontSize: ResponsiveUtils.getTitleFontSize(context), fontWeight: FontWeight.w700, color: kTextPrimary)),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: EdgeInsets.all(ResponsiveUtils.getCardMargin(context) / 2),
                          decoration: BoxDecoration(color: kLightBackground, shape: BoxShape.circle),
                          child: Icon(Icons.close, color: kTextSecondary, size: ResponsiveUtils.getIconSize(context)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.getCardMargin(context) / 2),
                  Text("Refine your search results", style: GoogleFonts.inter(fontSize: ResponsiveUtils.getBodyFontSize(context), color: kTextSecondary)),
                  SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),

                  Text("Price Range", style: GoogleFonts.inter(fontSize: ResponsiveUtils.getTitleFontSize(context) - 2, fontWeight: FontWeight.w600, color: kTextPrimary)),
                  SizedBox(height: ResponsiveUtils.getCardMargin(context)),
                  RangeSlider(
                    values: currentPriceRange,
                    min: 0,
                    max: 100000,
                    divisions: 20,
                    activeColor: kPrimaryColor,
                    inactiveColor: Colors.grey.shade200,
                    onChanged: (v) => setModal(() => currentPriceRange = v),
                  ),
                  SizedBox(height: ResponsiveUtils.getCardMargin(context) / 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _priceChip("₹${currentPriceRange.start.round()}"),
                      _priceChip("₹${currentPriceRange.end.round()}"),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),

                  Text("Brand", style: GoogleFonts.inter(fontSize: ResponsiveUtils.getTitleFontSize(context) - 2, fontWeight: FontWeight.w600, color: kTextPrimary)),
                  SizedBox(height: ResponsiveUtils.getCardMargin(context)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getCardMargin(context), vertical: ResponsiveUtils.getCardMargin(context) / 2),
                    decoration: BoxDecoration(color: kLightBackground, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderColor)),
                    child: DropdownButton<String>(
                      value: selectedBrand,
                      isExpanded: true,
                      underline: Container(),
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: kTextSecondary, size: ResponsiveUtils.getIconSize(context)),
                      items: availableBrands.map((String brand) {
                        return DropdownMenuItem<String>(
                          value: brand,
                          child: Text(brand, style: GoogleFonts.inter(color: kTextPrimary, fontSize: ResponsiveUtils.getBodyFontSize(context))),
                        );
                      }).toList(),
                      onChanged: (String? newValue) => setModal(() => selectedBrand = newValue ?? 'All'),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),

                  Text("Sort By", style: GoogleFonts.inter(fontSize: ResponsiveUtils.getTitleFontSize(context) - 2, fontWeight: FontWeight.w600, color: kTextPrimary)),
                  SizedBox(height: ResponsiveUtils.getCardMargin(context)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getCardMargin(context), vertical: ResponsiveUtils.getCardMargin(context) / 2),
                    decoration: BoxDecoration(color: kLightBackground, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderColor)),
                    child: DropdownButton<String>(
                      value: sortBy,
                      isExpanded: true,
                      underline: Container(),
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: kTextSecondary, size: ResponsiveUtils.getIconSize(context)),
                      items: const ['Recommended', 'Price: Low to High', 'Price: High to Low', 'Name: A to Z', 'Name: Z to A'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: GoogleFonts.inter(color: kTextPrimary, fontSize: ResponsiveUtils.getBodyFontSize(context))),
                        );
                      }).toList(),
                      onChanged: (String? newValue) => setModal(() => sortBy = newValue ?? 'Recommended'),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getSectionSpacing(context) + 8),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () { _resetFilters(); Navigator.pop(context); },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: kBorderColor, width: 1.5),
                            padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.getButtonHeight(context) - 32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: kLightBackground,
                          ),
                          child: Text("Reset All", style: GoogleFonts.inter(color: kTextSecondary, fontWeight: FontWeight.w600, fontSize: ResponsiveUtils.getBodyFontSize(context))),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.getCardMargin(context)),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () { _applyFilters(); Navigator.pop(context); },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.getButtonHeight(context) - 32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            shadowColor: kPrimaryColor.withOpacity(0.3),
                          ),
                          child: Text("Apply Filters", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: ResponsiveUtils.getBodyFontSize(context))),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.getVerticalPadding(context)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _priceChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getCardMargin(context), vertical: ResponsiveUtils.getCardMargin(context) / 2),
      decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: kPrimaryColor.withOpacity(0.2))),
      child: Text(text, style: GoogleFonts.inter(color: kPrimaryColor, fontWeight: FontWeight.w600, fontSize: ResponsiveUtils.getSmallFontSize(context))),
    );
  }

  Widget _shimmer() {
    final crossCount = ResponsiveUtils.getMarketGridCrossAxisCount(context);
    final gridPadding = ResponsiveUtils.getMarketGridPadding(context);
    final gridSpacing = ResponsiveUtils.getMarketGridSpacing(context);
    final safeItemCount = crossCount * 4;

    return Padding(
      padding: EdgeInsets.all(gridPadding),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossCount, childAspectRatio: 0.75, crossAxisSpacing: gridSpacing, mainAxisSpacing: gridSpacing),
        itemCount: safeItemCount,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: double.infinity, height: MediaQuery.of(context).size.width / crossCount * 0.7, decoration: BoxDecoration(color: kShimmerColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)))),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(ResponsiveUtils.getCardMargin(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 40, height: 12, color: kShimmerColor),
                      SizedBox(height: 8),
                      Container(width: double.infinity, height: 14, color: kShimmerColor),
                      SizedBox(height: 6),
                      Container(width: 70, height: 14, color: kShimmerColor),
                      Spacer(),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(width: 50, height: 16, color: kShimmerColor), Container(width: 30, height: 20, color: kShimmerColor)]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(int count) => Container(
    padding: EdgeInsets.all(ResponsiveUtils.getCardMargin(context) / 3),
    decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(8)),
    constraints: BoxConstraints(minWidth: ResponsiveUtils.getMarketBadgeSize(context), minHeight: ResponsiveUtils.getMarketBadgeSize(context)),
    child: Text(count > 99 ? '99+' : '$count', style: GoogleFonts.inter(color: Colors.white, fontSize: ResponsiveUtils.getSmallFontSize(context) - 1, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
  );

  Widget _buildSearchBar() {
    return Container(
      height: ResponsiveUtils.getSearchBarHeight(context),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(ResponsiveUtils.getDynamicPadding(context, 0.025)),
        border: Border.all(color: kBorderColor, width: ResponsiveUtils.getBorderWidth(context) * 6),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Padding(padding: EdgeInsets.only(left: ResponsiveUtils.getDynamicPadding(context, 0.03)), child: Icon(Icons.search_rounded, color: kTextSecondary, size: ResponsiveUtils.getIconSize(context) * 0.8)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getDynamicPadding(context, 0.02)),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(fontSize: ResponsiveUtils.getBodyFontSize(context), color: kTextPrimary, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: "Search drones, parts, accessories...",
                  hintStyle: GoogleFonts.inter(color: kTextSecondary, fontSize: ResponsiveUtils.getBodyFontSize(context), fontWeight: FontWeight.w400),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ),
          Container(
            width: ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.05),
            height: ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.05),
            margin: EdgeInsets.only(right: ResponsiveUtils.getDynamicPadding(context, 0.012)),
            decoration: BoxDecoration(color: kPrimaryColor, borderRadius: BorderRadius.circular(ResponsiveUtils.getDynamicPadding(context, 0.018)), boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]),
            child: IconButton(icon: Icon(Icons.tune_rounded, color: Colors.white, size: ResponsiveUtils.getIconSize(context) * 0.7), onPressed: _showFilterModal, padding: EdgeInsets.zero),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CartWishlistProvider>();
    final cartCount = provider.cartCount;

    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: kSurfaceColor,
        elevation: 1,
        surfaceTintColor: kSurfaceColor,
        toolbarHeight: ResponsiveUtils.getAppBarHeight(context),
        title: Text("Marketplace", style: GoogleFonts.inter(fontSize: ResponsiveUtils.getTitleFontSize(context), fontWeight: FontWeight.w700, color: kPrimaryColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kTextSecondary, size: ResponsiveUtils.getIconSize(context)),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0))),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_outline, color: kTextSecondary, size: ResponsiveUtils.getIconSize(context)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) =>  WishlistPage())).then((_) { if (mounted) setState(() {}); });
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_bag_outlined, color: kTextSecondary, size: ResponsiveUtils.getIconSize(context)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCartPage())).then((_) { if (mounted) setState(() {}); }),
              ),
              if (cartCount > 0) Positioned(right: 6, top: 6, child: _badge(cartCount)),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(ResponsiveUtils.getMarketTabBarHeight(context)),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getHorizontalPadding(context), vertical: ResponsiveUtils.getVerticalPadding(context)),
                child: _buildSearchBar(),
              ),
              Container(
                height: ResponsiveUtils.getButtonHeight(context) - 4,
                color: kSurfaceColor,
                child: TabBar(
                  controller: _tabController,
                  labelColor: kPrimaryColor,
                  unselectedLabelColor: kTextSecondary,
                  indicatorColor: kPrimaryColor,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: ResponsiveUtils.getBodyFontSize(context)),
                  unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: ResponsiveUtils.getBodyFontSize(context)),
                  tabs: const [Tab(text: 'Drones'), Tab(text: 'Parts'), Tab(text: 'Accessories')],
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
    if (items.isEmpty) return Center(child: Text("No products found", style: GoogleFonts.inter(fontSize: ResponsiveUtils.getTitleFontSize(context) - 2, color: kTextPrimary, fontWeight: FontWeight.w600)));

    final crossCount = ResponsiveUtils.getMarketGridCrossAxisCount(context);
    final gridPadding = ResponsiveUtils.getMarketGridPadding(context);
    final gridSpacing = ResponsiveUtils.getMarketGridSpacing(context);

    return RefreshIndicator(
      onRefresh: _fetchAll,
      color: kPrimaryColor,
      backgroundColor: kSurfaceColor,
      child: Padding(
        padding: EdgeInsets.all(gridPadding),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossCount, childAspectRatio: 0.75, crossAxisSpacing: gridSpacing, mainAxisSpacing: gridSpacing),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildProductItem(items[index]),
        ),
      ),
    );
  }

  Widget _buildProductItem(dynamic item) {
    final provider = context.watch<CartWishlistProvider>();
    final isFav = provider.wishlistIds.contains(item['id']?.toString());
    final crossCount = ResponsiveUtils.getMarketGridCrossAxisCount(context);
    final gridPadding = ResponsiveUtils.getMarketGridPadding(context);
    final gridSpacing = ResponsiveUtils.getMarketGridSpacing(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - (2 * gridPadding) - ((crossCount - 1) * gridSpacing);
    final itemWidth = availableWidth / crossCount;
    final imageHeight = itemWidth * 0.7;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DroneDetailPage(drone: item))),
      child: Container(
        decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: imageHeight,
                  decoration: BoxDecoration(color: kLightBackground, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: (item['image'] ?? '').toString(),
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Container(color: kShimmerColor, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryColor.withOpacity(0.5)))),
                      errorWidget: (ctx, url, err) => Container(color: kShimmerColor, child: Icon(Icons.photo_camera_back, color: kTextSecondary, size: ResponsiveUtils.getIconSize(context) + 10)),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(ResponsiveUtils.getCardMargin(context)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['brand'] ?? '', style: GoogleFonts.inter(color: kSecondaryColor, fontSize: ResponsiveUtils.getSmallFontSize(context), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(height: ResponsiveUtils.getCardMargin(context) / 4),
                        Expanded(child: Text(item['name'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: ResponsiveUtils.getBodyFontSize(context), color: kTextPrimary), maxLines: 2, overflow: TextOverflow.ellipsis)),
                        SizedBox(height: ResponsiveUtils.getCardMargin(context) / 2),
                        Text("₹${(item['price'] ?? 0).round()}", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: ResponsiveUtils.getBodyFontSize(context) + 2, color: kPrimaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: ResponsiveUtils.getCardMargin(context),
              right: ResponsiveUtils.getCardMargin(context),
              child: GestureDetector(
                onTap: () async => await _toggleWishlist(item),
                child: Container(
                  width: ResponsiveUtils.getButtonHeight(context) - 24,
                  height: ResponsiveUtils.getButtonHeight(context) - 24,
                  decoration: BoxDecoration(color: kSurfaceColor.withOpacity(0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]),
                  child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red.shade500 : kTextSecondary, size: ResponsiveUtils.getIconSize(context) - 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}