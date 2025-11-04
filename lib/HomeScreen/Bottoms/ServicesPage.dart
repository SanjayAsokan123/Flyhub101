import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../CommonClass/utils.dart';
import '../../CommonClass/ApiClass.dart';

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
  final Color primaryColor = const Color(0xFF1A0A5B);

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  /// ✅ Fetch Services via ApiClass
  Future<void> fetchServices() async {
    // if (!await Utils.checkInternetConnection()) {
    //   Utils.bottomToast(context, "Please check your internet connection");
    //   return;
    // }

    setState(() => isLoading = true);
    final res = await _apiClass.getServices();
    if (!mounted) return;

    if (res.status == "success") {
      setState(() {
        serviceList = res.data ?? [];
        filteredList = List.from(serviceList);
        isLoading = false;
      });
    } else {
      Utils.bottomToast(context, "Error fetching services: ${res.message}");
      setState(() => isLoading = false);
    }
  }

  /// 🔍 Search Function
  void _searchServices(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredList = serviceList.where((s) {
        final name = (s['name'] ?? '').toString().toLowerCase();
        final loc = (s['location'] ?? '').toString().toLowerCase();
        return name.contains(searchQuery) || loc.contains(searchQuery);
      }).toList();
    });
  }

  /// 🧾 Service Details Bottom Sheet
  void _showServiceDetails(Map<String, dynamic> s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        height: 5,
                        width: 60,
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10)))),
                Text(s['name'] ?? "Unnamed Service",
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 5),
                Text(s['specificDrone'] ?? "",
                    style:
                    GoogleFonts.lexend(color: Colors.grey[700], fontSize: 14)),
                const Divider(height: 20, thickness: 1.2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoChip(Icons.location_on_outlined, s['location'] ?? "N/A"),
                    _infoChip(Icons.star, "${s['experience']} yrs exp"),
                    _infoChip(Icons.currency_rupee, "${s['price']}"),
                  ],
                ),
                const SizedBox(height: 16),
                Text("Description:",
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Text(s['description'] ?? "No details available.",
                    style: GoogleFonts.lexend(fontSize: 13, height: 1.4)),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart_checkout,
                        color: Colors.white, size: 18),
                    onPressed: () {
                      Utils.bottomToast(
                          context, "Booked ${s['name']} successfully!");
                      Navigator.pop(context);
                    },
                    label: const Text("Book Now",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 18),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.lexend(fontSize: 12)),
      ],
    );
  }

  /// 🎨 Compact Service Card
  Widget buildServiceCard(Map<String, dynamic> s) {
    final imageUrl = (s['image'] ?? '').toString();
    final img = imageUrl.startsWith('http')
        ? imageUrl
        : 'https://flyhub-storage.s3.ap-south-1.amazonaws.com/uploads/$imageUrl';

    return InkWell(
      onTap: () => _showServiceDetails(s),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: img,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image,
                    size: 50, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['name'] ?? 'Unnamed Service',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lexend(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(s['specificDrone'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                      GoogleFonts.lexend(color: Colors.grey[700], fontSize: 11)),
                  const SizedBox(height: 5),
                  Text("₹${s['price'] ?? 'Contact'}",
                      style: GoogleFonts.lexend(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🏗️ Main Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Drone Services"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.8,
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: fetchServices,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: _searchServices,
                decoration: InputDecoration(
                  hintText: "Search service or location...",
                  prefixIcon: Icon(Icons.search, color: primaryColor),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredList.isEmpty
                  ? const Center(
                child: Text("No drone services available 😶"),
              )
                  : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
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
