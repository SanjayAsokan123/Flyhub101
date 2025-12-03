import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../CommonClass/utils.dart';
import '../../CommonClass/ApiClass.dart';
import '../../ServiceBookNow.dart' hide ApiClass;

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final ApiClass _apiClass = ApiClass();

  bool isLoading = true;
  List<dynamic> serviceList = [];
  List<dynamic> filteredList = [];
  String searchQuery = '';

  List<String> locations = [];
  List<String> experiences = [];
  List<String> priceRanges = ["0-5000", "5000-10000", "10000-20000", "20000+"];

  String selectedLocation = "";
  String selectedPriceRange = "";

  final Color primaryColor = const Color(0xFF1A0A5B);

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  Future<void> fetchServices() async {
    setState(() => isLoading = true);
    final res = await _apiClass.getServices();

    if (!mounted) return;

    if (res.status == "success") {
      final List<dynamic> allServices = res.data ?? [];
      final approved = allServices.where((s) => s["status"] == "approved").toList();

      locations = approved.map((s) => (s["location"] ?? "").toString())
          .where((e) => e.isNotEmpty).toSet().toList();

      experiences = approved.map((s) => (s["experience"] ?? "").toString())
          .where((e) => e.isNotEmpty).toSet().toList();

      setState(() {
        serviceList = approved;
        filteredList = List.from(serviceList);
        isLoading = false;
      });
    } else {
      Utils.bottomToast(context, "Error: ${res.message}");
      setState(() => isLoading = false);
    }
  }

  void _searchServices(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      applyFilters();
    });
  }

  void applyFilters() {
    filteredList = serviceList.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      final loc = (s['location'] ?? '').toString().toLowerCase();
      final price = int.tryParse(s['price'].toString()) ?? 0;

      if (!(name.contains(searchQuery) || loc.contains(searchQuery))) return false;
      if (selectedLocation.isNotEmpty && s['location'] != selectedLocation) return false;

      if (selectedPriceRange.isNotEmpty) {
        final parts = selectedPriceRange.split("-");
        final min = int.parse(parts[0]);
        final max = parts[1] == "+" ? 999999 : int.parse(parts[1]);
        if (!(price >= min && price <= max)) return false;
      }

      return true;
    }).toList();

    setState(() {});
  }

  /// FILTER SHEET
  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),

                const SizedBox(height: 20),
                Text("Filters",
                    style: GoogleFonts.lexend(
                        fontSize: 18, fontWeight: FontWeight.bold)),

                const SizedBox(height: 20),

                DropdownButtonFormField(
                  decoration: const InputDecoration(labelText: "Location"),
                  value: selectedLocation.isEmpty ? null : selectedLocation,
                  items: locations
                      .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                      .toList(),
                  onChanged: (value) => selectedLocation = value.toString(),
                ),
                const SizedBox(height: 15),

                DropdownButtonFormField(
                  decoration: const InputDecoration(labelText: "Price Range"),
                  value:
                  selectedPriceRange.isEmpty ? null : selectedPriceRange,
                  items: priceRanges
                      .map((range) =>
                      DropdownMenuItem(value: range, child: Text(range)))
                      .toList(),
                  onChanged: (value) => selectedPriceRange = value.toString(),
                ),

                const SizedBox(height: 25),

                ElevatedButton(
                  onPressed: () {
                    applyFilters();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  child: const Text("Apply Filters",
                      style: TextStyle(color: Colors.white)),
                ),

                TextButton(
                  onPressed: () {
                    selectedLocation = "";
                    selectedPriceRange = "";
                    applyFilters();
                    Navigator.pop(context);
                  },
                  child: const Text("Clear Filters",
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget buildServiceCard(Map<String, dynamic> s) {
    final imageUrl = (s['image'] ?? '').toString();
    final img = imageUrl.startsWith('http')
        ? imageUrl
        : 'https://flyhub-storage.s3.ap-south-1.amazonaws.com/uploads/$imageUrl';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: img,
              height: 110,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['name'] ?? '',
                    style: GoogleFonts.lexend(
                        fontSize: 13, fontWeight: FontWeight.bold)),

                const SizedBox(height: 3),

                Text(s['specificDrone'] ?? '',
                    style: GoogleFonts.lexend(fontSize: 11, color: Colors.grey)),

                const SizedBox(height: 5),

                Text("₹${s['price'] ?? 'Contact'}",
                    style: GoogleFonts.lexend(
                        color: primaryColor, fontSize: 12)),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ServiceBookNowPage(service: s)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text("Book Now",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✨ NEW SEARCH BAR UI (as per your sample image)
  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),

            Icon(Icons.search, color: Colors.grey[600], size: 22),

            const SizedBox(width: 10),

            Expanded(
              child: TextField(
                onChanged: _searchServices,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Search drones, brands, ...",
                  hintStyle: GoogleFonts.lexend(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // FILTER BUTTON (rounded like your image)
            Container(
              margin: const EdgeInsets.only(right: 8),
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.tune, color: Colors.white, size: 20),
                onPressed: _openFilterSheet,
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text("Drone Services"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.6,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchServices,
        child: Column(
          children: [

            /// NEW SEARCH BAR
            buildSearchBar(),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10),
                itemCount: filteredList.length,
                itemBuilder: (context, i) =>
                    buildServiceCard(filteredList[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}