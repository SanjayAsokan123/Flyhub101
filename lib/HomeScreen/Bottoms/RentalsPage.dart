import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../CommonClass/ApiClass.dart';
import '../../CommonClass/utils.dart';
import '../../BuyerDetails/MyCartPage.dart';
import '../../MyDroneListScreen.dart';
import '../Dynamichome.dart';

class RentalsPage extends StatefulWidget {
  const RentalsPage({Key? key}) : super(key: key);

  @override
  State<RentalsPage> createState() => _RentalsPageState();
}

class _RentalsPageState extends State<RentalsPage>
    with TickerProviderStateMixin {
  late final TabController _mainTabController;
  final ApiClass _apiClass = ApiClass();

  List<dynamic> rentalList = [];
  List<dynamic> filteredList = [];
  final Set<String> favoriteItems = {};
  final Map<String, dynamic> favoriteData = {};

  int cartCount = 0;
  bool isLoading = true;
  String searchQuery = '';
  String selectedFilter = 'All';
  final Color primaryColor = const Color(0xFF1A0A5B);

  final List<String> subFilters = [
    'All',
    'Today',
    'Professional',
    'With Pilot',
    'Insured',
  ];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    _loadFavorites();
    _loadCartCount();
    fetchRentals();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  /// Fetch Rentals safely
  Future<void> fetchRentals() async {
    HapticFeedback.selectionClick();
    if (!await Utils.checkInternetConnection()) {
      if (!mounted) return;
      Utils.bottomToast(context, "Please check your internet connection");
      return;
    }

    try {
      if (mounted) setState(() => isLoading = true);
      final response = await _apiClass.getMarketplaceItems("drones");

      if (!mounted) return;
      setState(() {
        rentalList = response ?? [];
        filteredList = List.from(rentalList);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      Utils.bottomToast(context, "Error loading rentals: $e");
      setState(() => isLoading = false);
    }
  }

  /// Load Cart & Favorites
  Future<void> _loadCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final saved = prefs.getString('cart') ?? '[]';
      final cartItems = jsonDecode(saved) as List;
      if (!mounted) return;
      setState(() => cartCount = cartItems.length);
    } catch (_) {
      if (!mounted) return;
      setState(() => cartCount = 0);
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('wishlist');
    if (saved == null) return;

    try {
      final decoded = jsonDecode(saved) as List;
      favoriteItems.clear();
      favoriteData.clear();
      for (var item in decoded) {
        final id = item['id'].toString();
        favoriteItems.add(id);
        favoriteData[id] = item;
      }
      if (!mounted) return;
      setState(() {});
    } catch (_) {}
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wishlist', jsonEncode(favoriteData.values.toList()));
  }

  /// Apply Filters
  void applyFilter(String filter) {
    HapticFeedback.selectionClick();
    if (!mounted) return;

    setState(() {
      selectedFilter = filter;
      filteredList = rentalList.where((d) {
        switch (filter) {
          case 'All':
            return true;
          case 'Insured':
            return (d['insurance'] ?? false) == true;
          case 'With Pilot':
            return (d['with_pilot'] ?? false) == true ||
                (d['pilot']?.toString().toLowerCase() == 'yes');
          case 'Professional':
            return (d['type']?.toString().toLowerCase() ?? '') == 'professional';
          case 'Today':
            return (d['available_today']?.toString().toLowerCase() == 'true');
          default:
            return true;
        }
      }).toList();
    });
  }

  /// Search Rentals
  void _searchRentals(String query) {
    if (!mounted) return;

    setState(() {
      searchQuery = query.toLowerCase();
      filteredList = rentalList.where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final brand = (item['brand'] ?? '').toString().toLowerCase();
        return name.contains(searchQuery) || brand.contains(searchQuery);
      }).toList();
    });
  }

  /// Build Rental Card
  Widget buildRentalCard(Map<String, dynamic> drone) {
    final id = drone['id'].toString();
    final isFav = favoriteItems.contains(id);
    final imageUrl = (drone['image'] ?? '').toString();
    final fullImageUrl = imageUrl.startsWith('http')
        ? imageUrl
        : 'https://flyhub-storage.s3.ap-south-1.amazonaws.com/uploads/$imageUrl';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: fullImageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 140,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: GestureDetector(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  if (isFav) {
                    favoriteItems.remove(id);
                    favoriteData.remove(id);
                  } else {
                    favoriteItems.add(id);
                    favoriteData[id] = drone;
                  }
                  await _saveFavorites();
                  if (mounted) setState(() {});
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.9),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.redAccent : primaryColor, size: 22),
                ),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(drone['name'] ?? 'Unnamed Drone', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
                Text((drone['category'] ?? '').toString().toUpperCase(), style: GoogleFonts.lexend(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 6),
                Text("₹${drone['price'] ?? 0}/day", style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: primaryColor)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: () => Utils.bottomToast(context, "${drone['name']} booking feature coming soon!"),
                    child: Text("Book Now", style: GoogleFonts.lexend(color: Colors.white, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build Sub Filters
  Widget buildSubFilterTabs() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: subFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = subFilters[index];
          final selected = filter == selectedFilter;
          return GestureDetector(
            onTap: () => applyFilter(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? primaryColor : const Color(0xffF7F7F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(filter, style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : Colors.black)),
            ),
          );
        },
      ),
    );
  }

  /// MAIN UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Drone Rentals', style: GoogleFonts.lexend()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
                  (Route<dynamic> route) => false,
            );
          },
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border, color: Color(0xFF1A0A5B)), onPressed: () {}),
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart_outlined, color: primaryColor),
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCartPage()));
                  _loadCartCount();
                },
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(controller: _mainTabController, labelColor: primaryColor, unselectedLabelColor: Colors.grey, indicatorColor: primaryColor, tabs: const [
          Tab(text: 'Available'),
          Tab(text: 'My Bookings'),
          Tab(text: 'Insurance'),
        ]),
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: fetchRentals,
        child: TabBarView(
          controller: _mainTabController,
          children: [
            Column(
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: _searchRentals,
                    decoration: InputDecoration(
                      hintText: "Search drones...",
                      prefixIcon: Icon(Icons.search, color: primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                buildSubFilterTabs(),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredList.isEmpty
                      ? const Center(child: Text("No rentals available 😶"))
                      : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredList.length,
                    itemBuilder: (context, i) => buildRentalCard(filteredList[i]),
                  ),
                ),
              ],
            ),
            Center(child: Text("My Bookings will appear here", style: GoogleFonts.lexend(fontSize: 16, color: Colors.grey.shade600))),
            Center(child: Text("Insurance details coming soon", style: GoogleFonts.lexend(fontSize: 16, color: Colors.grey.shade600))),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "rental_add_fab",
        backgroundColor: primaryColor,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => MyDroneListPage()));
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
