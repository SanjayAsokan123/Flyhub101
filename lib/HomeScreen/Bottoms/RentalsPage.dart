import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../CommonClass/ApiClass.dart';
import '../../CommonClass/Utils.dart';
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
  late TabController _mainTabController;
  final ApiClass _apiClass = ApiClass();

  List<dynamic> rentalList = [];
  List<dynamic> filteredList = [];

  final Set<String> favoriteItems = {};
  final Map<String, dynamic> favoriteData = {};

  int cartCount = 0;
  bool isLoading = true;
  String searchQuery = '';

  final List<String> subFilters = [
    'All',
    'Today',
    'Professional',
    'With Pilot',
    'Insured'
  ];
  String selectedFilter = 'All';
  final Color primaryColor = const Color(0xFF1A0A5B);

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

  // ✅ Fetch Drone Rentals using ApiClass
  Future<void> fetchRentals() async {
    if (await Utils.checkInternetConnection()) {
      try {
        setState(() => isLoading = true);
        final response = await _apiClass.getMarketplaceItems("drones");
        if (response != null) {
          setState(() {
            rentalList = response;
            filteredList = rentalList;
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } catch (e) {
        Utils.bottomToast(context, "Error loading rentals: $e");
        setState(() => isLoading = false);
      }
    } else {
      Utils.bottomToast(context, "Check your internet connection");
    }
  }

  // ✅ Cart + Favorites
  Future<void> _loadCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('cart') ?? '[]';
    final cartItems = jsonDecode(saved);
    setState(() => cartCount = cartItems.length);
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('wishlist');
    if (saved != null) {
      final decoded = jsonDecode(saved) as List;
      for (var item in decoded) {
        favoriteItems.add(item['id'].toString());
        favoriteData[item['id'].toString()] = item;
      }
      setState(() {});
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wishlist', jsonEncode(favoriteData.values.toList()));
  }

  // ✅ Filters
  void applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      if (filter == 'All') {
        filteredList = rentalList;
      } else if (filter == 'Insured') {
        filteredList =
            rentalList.where((d) => (d['insurance'] ?? false) == true).toList();
      } else if (filter == 'With Pilot') {
        filteredList = rentalList
            .where((d) =>
        (d['with_pilot'] ?? false) == true ||
            (d['pilot']?.toString().toLowerCase() == 'yes'))
            .toList();
      } else if (filter == 'Professional') {
        filteredList = rentalList
            .where((d) =>
        (d['type']?.toString().toLowerCase() ?? '') == 'professional')
            .toList();
      } else if (filter == 'Today') {
        filteredList = rentalList
            .where((d) =>
        (d['available_today']?.toString().toLowerCase() == 'true'))
            .toList();
      }
    });
  }

  void _searchRentals(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredList = rentalList
          .where((item) =>
      (item['name'] ?? '')
          .toString()
          .toLowerCase()
          .contains(searchQuery) ||
          (item['brand'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchQuery))
          .toList();
    });
  }

  // ✅ Rental Card (adaptive layout)
  Widget buildRentalCard(Map<String, dynamic> drone) {
    final id = drone['id'].toString();
    final isFav = favoriteItems.contains(id);
    final imageUrl = (drone['image'] ?? '').toString();
    final fullImageUrl = imageUrl.startsWith('http')
        ? imageUrl
        : 'http://192.168.1.178:5001/uploads/$imageUrl';

    final name = drone['name'] ?? 'Unnamed Drone';
    final category = drone['category'] ?? '';
    final price = drone['price'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        double imageHeight = constraints.maxHeight * 0.55;

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          margin: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              Stack(children: [
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: fullImageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: imageHeight,
                    placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                    const Icon(Icons.error, size: 50),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: GestureDetector(
                    onTap: () async {
                      if (isFav) {
                        favoriteItems.remove(id);
                        favoriteData.remove(id);
                      } else {
                        favoriteItems.add(id);
                        favoriteData[id] = drone;
                      }
                      await _saveFavorites();
                      setState(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.9),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4)
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.redAccent : primaryColor,
                        size: 22,
                      ),
                    ),
                  ),
                )
              ]),

              // Details section (Expanded fixes overflow)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lexend(
                                  fontWeight: FontWeight.bold)),
                          Text(category.toUpperCase(),
                              style: GoogleFonts.lexend(
                                  color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                      Text("₹$price/day",
                          style: GoogleFonts.lexend(
                              fontWeight: FontWeight.bold, color: primaryColor)),
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () {
                            Utils.bottomToast(
                                context, "$name booking coming soon!");
                          },
                          child: Text("Book Now",
                              style: GoogleFonts.lexend(
                                  color: Colors.white, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ Filter Tabs
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
              child: Text(
                filter,
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : Colors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ MAIN UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Drone Rentals', style: GoogleFonts.lexend()),
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => const Dynamichome(selectedIndex: 0)),
                  (Route<dynamic> route) => false,
            );
          },
          child: const Icon(Icons.arrow_back),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Color(0xFF1A0A5B)),
            onPressed: () {},
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart_outlined, color: primaryColor),
                onPressed: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MyCartPage()));
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
                    constraints:
                    const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$cartCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                  ),
                )
            ],
          ),
        ],
        bottom: TabBar(
          controller: _mainTabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'My Bookings'),
            Tab(text: 'Insurance'),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: fetchRentals,
        child: TabBarView(
          controller: _mainTabController,
          children: [
            // ✅ Tab 1 - Available
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
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
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
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredList.length,
                    itemBuilder: (context, i) =>
                        buildRentalCard(filteredList[i]),
                  ),
                ),
              ],
            ),
            // ✅ Tab 2
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "My Bookings will appear here",
                  style: GoogleFonts.lexend(
                      fontSize: 16, color: Colors.grey.shade600),
                ),
              ),
            ),
            // ✅ Tab 3
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "Insurance details coming soon",
                  style: GoogleFonts.lexend(
                      fontSize: 16, color: Colors.grey.shade600),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>  MyDroneListPage()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
