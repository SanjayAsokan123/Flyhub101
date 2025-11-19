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
import '../../RentalBookNow.dart';

class RentalsPage extends StatefulWidget {
  const RentalsPage({Key? key}) : super(key: key);

  @override
  State<RentalsPage> createState() => _RentalsPageState();
}

class _RentalsPageState extends State<RentalsPage> with TickerProviderStateMixin {
  final ApiClass _api = ApiClass();
  List<dynamic> rentalList = [];
  List<dynamic> filteredList = [];
  bool isLoading = true;
  String searchQuery = '';
  int cartCount = 0;

  // Filters
  bool withPilot = false;
  bool insured = false;
  bool availableToday = false;
  String sortBy = 'Recommended';

  final Set<String> favoriteItems = {};
  final Map<String, dynamic> favoriteData = {};

  // Colors
  final Color lightPurple = const Color(0xFFE8EAF6);
  final Color lightBlue = const Color(0xFFE3F2FD);
  final Color accentColor = const Color(0xFF1A0A5B);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);
  final Color surfaceColor = Colors.white;
  final Color borderColor = const Color(0xFFE5E7EB);
  final Color successColor = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadCartCount();
    fetchRentals();
  }

  Future<void> fetchRentals() async {
    HapticFeedback.selectionClick();
    setState(() => isLoading = true);
    try {
      final result = await _api.getRentals();
      if (result.status == "success" && result.data is List) {
        rentalList = result.data;
        _applyFiltersAndSort();
      } else {
        Utils.bottomToast(context, "No rentals found");
      }
    } catch (e) {
      Utils.bottomToast(context, "Error loading rentals: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> _loadCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final saved = prefs.getString('cart') ?? '[]';
      final cartItems = jsonDecode(saved) as List;
      setState(() => cartCount = cartItems.length);
    } catch (_) {
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
      setState(() {});
    } catch (_) {}
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wishlist', jsonEncode(favoriteData.values.toList()));
  }

  void _searchRentals(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
    _applyFiltersAndSort();
  }

  void _toggleFavorite(Map<String, dynamic> rental) async {
    final id = rental['rentalId']?.toString() ?? rental['name'];
    final isFav = favoriteItems.contains(id);
    HapticFeedback.selectionClick();
    setState(() {
      if (isFav) {
        favoriteItems.remove(id);
        favoriteData.remove(id);
      } else {
        favoriteItems.add(id);
        favoriteData[id] = rental;
      }
    });
    await _saveFavorites();
  }

  void _applyFiltersAndSort() {
    List<dynamic> result = List.from(rentalList);

    // Filters
    if (withPilot) result = result.where((r) => r['with_pilot'] == true).toList();
    if (insured) result = result.where((r) => r['insurance'] == true).toList();
    if (availableToday) {
      result = result.where((r) => r['available_today'] == true).toList();
    }

    // Search
    if (searchQuery.isNotEmpty) {
      result = result.where((r) {
        final name = (r['name'] ?? '').toString().toLowerCase();
        final location = (r['location'] ?? '').toString().toLowerCase();
        final brand = (r['brand'] ?? '').toString().toLowerCase();
        return name.contains(searchQuery) ||
            location.contains(searchQuery) ||
            brand.contains(searchQuery);
      }).toList();
    }

    // Sorting
    switch (sortBy) {
      case 'Price: Low to High':
        result.sort((a, b) =>
            (a['pricePerDay'] ?? 0).compareTo(b['pricePerDay'] ?? 0));
        break;
      case 'Price: High to Low':
        result.sort((a, b) =>
            (b['pricePerDay'] ?? 0).compareTo(a['pricePerDay'] ?? 0));
        break;
      case 'Name: A to Z':
        result.sort((a, b) =>
            (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
        break;
      case 'Name: Z to A':
        result.sort((a, b) =>
            (b['name'] ?? '').toString().compareTo((a['name'] ?? '').toString()));
        break;
      default:
        break;
    }

    setState(() => filteredList = result);
  }

  void _resetFilters() {
    setState(() {
      withPilot = false;
      insured = false;
      availableToday = false;
      sortBy = 'Recommended';
    });
    _applyFiltersAndSort();
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StatefulBuilder(
          builder: (context, setModal) => Padding(
            padding: const EdgeInsets.all(24),
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
                              color: textPrimary)),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: textSecondary))
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text("Filters",
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: withPilot,
                    activeColor: accentColor,
                    onChanged: (v) => setModal(() => withPilot = v ?? false),
                    title: const Text("With Pilot"),
                  ),
                  CheckboxListTile(
                    value: insured,
                    activeColor: accentColor,
                    onChanged: (v) => setModal(() => insured = v ?? false),
                    title: const Text("Insured"),
                  ),
                  CheckboxListTile(
                    value: availableToday,
                    activeColor: accentColor,
                    onChanged: (v) => setModal(() => availableToday = v ?? false),
                    title: const Text("Available Today"),
                  ),
                  const Divider(height: 30),
                  Text("Sort By",
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: sortBy,
                    isExpanded: true,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                    items: const [
                      'Recommended',
                      'Price: Low to High',
                      'Price: High to Low',
                      'Name: A to Z',
                      'Name: Z to A'
                    ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setModal(() => sortBy = v ?? 'Recommended'),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _resetFilters();
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text("Reset",
                            style: GoogleFonts.inter(color: textSecondary)),
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
                            padding:
                            const EdgeInsets.symmetric(vertical: 16)),
                        child: Text("Apply Filters",
                            style: GoogleFonts.inter(color: Colors.white)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void handleBooking(dynamic rental) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RentalBookNowPage(rental: rental, drone: {}),
      ),
    );
  }

  Widget _buildRentalCard(Map<String, dynamic> r) {
    final id = r['rentalId']?.toString() ?? r['name'];
    final isFav = favoriteItems.contains(id);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: accentColor.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => handleBooking(r),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
                child: CachedNetworkImage(
                  imageUrl: r['image'] ??
                      'https://cdn-icons-png.flaticon.com/512/201/201623.png',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(height: 180, color: Colors.grey[200]),
                  errorWidget: (_, __, ___) =>
                      Container(height: 180, color: Colors.grey[200]),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => _toggleFavorite(r),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: surfaceColor.withOpacity(0.9),
                        shape: BoxShape.circle),
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : accentColor,
                      size: 20,
                    ),
                  ),
                ),
              )
            ]),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['name'] ?? 'Unnamed Drone',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: accentColor)),
                    const SizedBox(height: 6),
                    Text(r['location'] ?? 'Unknown Location',
                        style: GoogleFonts.inter(
                            color: textSecondary, fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Text("₹${r['pricePerHour'] ?? 0}/hr",
                          style: GoogleFonts.inter(
                              color: successColor,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Text("₹${r['pricePerDay'] ?? 0}/day",
                          style: GoogleFonts.inter(
                              color: accentColor,
                              fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => handleBooking(r),
                      icon: const Icon(Icons.flight_takeoff, color: Colors.white),
                      label: const Text("Book Now"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ]),
            )
          ]),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (filteredList.isEmpty) {
      return Center(
        child: Text("No Rentals Found",
            style:
            GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w600)),
      );
    }
    return RefreshIndicator(
      onRefresh: fetchRentals,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: filteredList.length,
        itemBuilder: (context, i) => _buildRentalCard(filteredList[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPurple,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [lightPurple, lightBlue],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter)),
          child: Column(children: [
            // Header
            Container(
              color: surfaceColor,
              child: Column(children: [
                // AppBar
                Container(
                  height: kToolbarHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: accentColor),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Dynamichome(selectedIndex: 0),
                        ),
                      ),
                    ),
                    Expanded(
                        child: Text("Drone Rentals",
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                                color: accentColor))),
                    Stack(children: [
                      IconButton(
                          icon: Icon(Icons.shopping_cart_outlined,
                              color: accentColor),
                          onPressed: () async {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const MyCartPage()));
                            _loadCartCount();
                          }),
                      if (cartCount > 0)
                        Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(10)),
                                constraints:
                                const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text('$cartCount',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center))),
                    ])
                  ]),
                ),
                // Search + Filter
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor)),
                    child: Row(children: [
                      const SizedBox(width: 16),
                      Icon(Icons.search, color: textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          onChanged: _searchRentals,
                          style: GoogleFonts.inter(
                              fontSize: 16, color: textPrimary),
                          decoration: InputDecoration(
                              hintText: "Search by name or location...",
                              hintStyle:
                              GoogleFonts.inter(color: textSecondary),
                              border: InputBorder.none),
                        ),
                      ),
                      Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(8)),
                          child: IconButton(
                              icon: const Icon(Icons.tune,
                                  color: Colors.white, size: 20),
                              onPressed: _showFilterModal))
                    ]),
                  ),
                ),
              ]),
            ),
            // Body
            Expanded(
                child: isLoading
                    ? Center(
                    child: CircularProgressIndicator(color: accentColor))
                    : _buildList())
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentColor,
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => MyDroneListPage())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}