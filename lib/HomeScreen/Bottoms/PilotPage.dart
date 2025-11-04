import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../CommonClass/ApiClass.dart';
import '../../BuyerDetails/MyCartPage.dart';
import '../Dynamichome.dart';
import 'package:google_fonts/google_fonts.dart';

class PilotPage extends StatefulWidget {
  const PilotPage({super.key});

  @override
  State<PilotPage> createState() => _PilotPageState();
}

class _PilotPageState extends State<PilotPage> with TickerProviderStateMixin {
  late TabController _mainTabController;
  final ApiClass _apiClass = ApiClass();

  static const Color themeColor = Color(0xFF1A0A5B);

  int cartCount = 0;
  bool isLoading = true;
  bool isError = false;
  String selectedFilter = '';

  List<dynamic> pilotList = [];
  List<dynamic> filteredList = [];
  List<Map<String, String>> cartItems = [];

  final List<String> filters = [
    'Photography',
    'Survey',
    'Agriculture',
    'Available Today'
  ];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    _loadCartCount();
    fetchPilots();
  }

  /// ✅ Fetch Pilots from GraphQL
  Future<void> fetchPilots() async {
    setState(() {
      isLoading = true;
      isError = false;
    });

    try {
      final result = await _apiClass.getHirePilots();

      if (result.status == "success") {
        setState(() {
          pilotList = result.data ?? [];
          filteredList = List.from(pilotList);
          isLoading = false;
        });
      } else {
        setState(() {
          isError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _loadCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('pilotCart') ?? '[]';
    try {
      cartItems = List<Map<String, String>>.from(
        jsonDecode(saved).map((e) => Map<String, String>.from(e)),
      );
      if (mounted) setState(() => cartCount = cartItems.length);
    } catch (_) {
      if (mounted) setState(() => cartCount = 0);
    }
  }

  Future<void> _addToCart(Map<String, dynamic> pilot) async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    cartItems.add({
      "pilotName": pilot['pilotName'] ?? "Unknown",
      "location": pilot['location'] ?? "N/A",
      "pilotCompany": pilot['pilotCompany'] ?? "",
    });
    await prefs.setString('pilotCart', jsonEncode(cartItems));
    if (!mounted) return;
    setState(() => cartCount = cartItems.length);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: themeColor,
        content: Text("${pilot['pilotName']} added to bookings",
            style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  void _applyFilter(String filter) {
    setState(() {
      selectedFilter = selectedFilter == filter ? '' : filter;
      if (selectedFilter.isEmpty) {
        filteredList = List.from(pilotList);
      } else {
        filteredList = pilotList.where((p) {
          final spec = (p['specification'] ?? '').toString().toLowerCase();
          return spec.contains(selectedFilter.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Certified Pilots", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const Dynamichome(selectedIndex: 0),
              ),
                  (Route<dynamic> route) => false,
            );
          },
          child: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: themeColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Wishlist feature coming soon")),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: themeColor),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyCartPage()),
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
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
            icon: const Icon(Icons.filter_list_rounded, color: themeColor),
            onPressed: _showFilterSheet,
          ),
        ],
        bottom: TabBar(
          controller: _mainTabController,
          labelColor: themeColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: themeColor,
          tabs: const [
            Tab(text: 'Near Me'),
            Tab(text: 'Top Rated'),
            Tab(text: 'Specialists'),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: themeColor,
        onRefresh: fetchPilots,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : isError
            ? const Center(child: Text("Failed to load pilots 😞"))
            : Column(
          children: [
            const SizedBox(height: 10),
            _buildFilterChips(),
            const SizedBox(height: 6),
            Expanded(
              child: TabBarView(
                controller: _mainTabController,
                children: [
                  _buildPilotList(filteredList),
                  _buildPilotList(filteredList),
                  _buildPilotList(filteredList),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "pilot_register_fab",
        backgroundColor: themeColor,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.pushNamed(context, '/Pilotregistration');
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final selected = selectedFilter == filters[index];
          return GestureDetector(
            onTap: () => _applyFilter(filters[index]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? themeColor : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                filters[index],
                style: TextStyle(
                  fontSize: 13,
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

  Widget _buildPilotList(List<dynamic> pilots) {
    if (pilots.isEmpty) {
      return const Center(
        child: Text("No pilots available", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: pilots.length,
      itemBuilder: (context, index) {
        final pilot = pilots[index];
        return _buildPilotCard(pilot);
      },
    );
  }

  Widget _buildPilotCard(Map<String, dynamic> pilot) {
    const double rating = 4.5;
    final imageUrl = pilot['resume']?['url'] ??
        "https://via.placeholder.com/150?text=Pilot";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 28, backgroundImage: NetworkImage(imageUrl)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pilot["pilotName"] ?? "Unnamed Pilot",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  pilot["specification"] ?? "No specialization",
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          Icons.star,
                          size: 16,
                          color: index < rating.round()
                              ? Colors.orange
                              : Colors.grey[300],
                        );
                      }),
                    ),
                    const SizedBox(width: 4),
                    Text(rating.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    const Text("(86)", style: TextStyle(color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _addToCart(pilot),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Book Now", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -3),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 15),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.filter_alt_rounded, color: themeColor),
                  SizedBox(width: 8),
                  Text(
                    "Filter Pilots",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: themeColor),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: filters
                    .map((filter) => ChoiceChip(
                  label: Text(filter),
                  selected: selectedFilter == filter,
                  selectedColor: themeColor,
                  backgroundColor: Colors.grey.shade200,
                  labelStyle: TextStyle(
                    color: selectedFilter == filter
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (val) {
                    _applyFilter(filter);
                    Navigator.pop(context);
                  },
                ))
                    .toList(),
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                icon: const Icon(Icons.clear_all_rounded, color: Colors.white),
                label: const Text("Clear Filters",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  setState(() => selectedFilter = '');
                  filteredList = List.from(pilotList);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
