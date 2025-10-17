import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flyhub/PilotRegistration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Dynamichome.dart';
import '../../BuyerDetails/MyCartPage.dart';

class PilotPage extends StatefulWidget {
  const PilotPage({super.key});
  @override
  State<PilotPage> createState() => _PilotPageState();
}

class _PilotPageState extends State<PilotPage> with TickerProviderStateMixin {
  late TabController _mainTabController;
  static const Color themeColor = Color(0xFF1A0A5B);

  int cartCount = 0;
  String selectedFilter = '';
  List<Map<String, String>> cartItems = [];

  final List<Map<String, String>> pilots = [
    {
      "name": "Arjun Singh",
      "role": "Certified DGCA Pilot\nSpecializes in Wedding Photography",
      "specialty": "Photography",
      "image": "assets/images/pilot1.png"
    },
    {
      "name": "Maya Krishnan",
      "role": "Agricultural Survey Expert\nAvailable for Crop Monitoring",
      "specialty": "Agriculture",
      "image": "assets/images/pilot2.png"
    },
    {
      "name": "Ravi Kumar",
      "role": "Drone Survey Specialist\nAvailable for Mapping",
      "specialty": "Survey",
      "image": "assets/images/pilot3.png"
    },
    {
      "name": "Ananya Sen",
      "role": "Freelance Drone Photographer\nAvailable Today",
      "specialty": "Available Today",
      "image": "assets/images/pilot4.png"
    },
  ];

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

  Future<void> _addToCart(Map<String, String> pilot) async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    cartItems.add(pilot);
    await prefs.setString('pilotCart', jsonEncode(cartItems));
    if (!mounted) return;
    setState(() => cartCount = cartItems.length);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: themeColor,
        content: Text("${pilot['name']} added to bookings",
            style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPilots = selectedFilter.isEmpty
        ? pilots
        : pilots.where((p) => p["specialty"] == selectedFilter).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Certified Pilots",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                const SnackBar(content: Text("Wishlist clicked")),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined,
                    color: themeColor),
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
                    constraints:
                    const BoxConstraints(minWidth: 16, minHeight: 16),
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
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildFilterChips(),
          const SizedBox(height: 6),
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              children: [
                _buildPilotList(filteredPilots),
                _buildPilotList(filteredPilots),
                _buildPilotList(filteredPilots),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "pilot_register_fab", // ✅ unique tag avoids Hero conflict
        backgroundColor: themeColor,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Pilotregistration(),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  // ✅ Filter Chips
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
            onTap: () => setState(() {
              selectedFilter = selected ? '' : filters[index];
            }),
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

  // ✅ Pilot List
  Widget _buildPilotList(List<Map<String, String>> filteredPilots) {
    if (filteredPilots.isEmpty) {
      return const Center(
        child: Text("No pilots available",
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: filteredPilots.length,
      itemBuilder: (context, index) {
        final pilot = filteredPilots[index];
        return _buildPilotCard(pilot);
      },
    );
  }

  // ✅ Pilot Card
  Widget _buildPilotCard(Map<String, String> pilot) {
    const double rating = 4.5;
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
          CircleAvatar(
              radius: 28, backgroundImage: AssetImage(pilot["image"]!)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pilot["name"]!,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  pilot["role"]!,
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
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child:
            const Text("Book Now", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ Filter Sheet
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
                    setState(() {
                      selectedFilter = val ? filter : '';
                    });
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  setState(() => selectedFilter = '');
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
