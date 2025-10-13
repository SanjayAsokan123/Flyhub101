import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../CommonClass/ApiClass.dart';
import '../../CommonClass/Utils.dart';
import 'DroneFullDetailsPage.dart';

class CropSprayingPage extends StatefulWidget {
  const CropSprayingPage({super.key});

  @override
  State<CropSprayingPage> createState() => _CropSprayingPageState();
}

class _CropSprayingPageState extends State<CropSprayingPage>
    with TickerProviderStateMixin {
  late TabController _mainTabController;
  final ApiClass _apiClass = ApiClass();
  List<dynamic> sprayDrones = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    fetchSprayDrones();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  /// ✅ Fetch spraying drones from GraphQL marketplace query
  Future<void> fetchSprayDrones() async {
    if (await Utils.checkInternetConnection()) {
      try {
        setState(() => isLoading = true);
        final data = await _apiClass.getMarketplaceItems("drones");
        setState(() {
          sprayDrones = data;
          isLoading = false;
        });
        print("✅ Crop Spraying Drones loaded: ${sprayDrones.length}");
      } catch (e) {
        print("⚠️ Error fetching drones: $e");
        setState(() => isLoading = false);
      }
    } else {
      Utils.bottomToast(context, "Check your Internet connection");
    }
  }

  Widget buildSprayCard(Map<String, dynamic> drone) {
    double screenWidth = MediaQuery.of(context).size.width;
    double imageHeight = screenWidth * 0.25;

    final imageUrl = drone["image"]?.toString() ?? "";
    final name = drone["name"]?.toString() ?? "Unnamed Drone";
    final price = drone["price"]?.toString() ?? "0";
    final category = drone["category"]?.toString() ?? "Drone";

    final fullImageUrl = imageUrl.startsWith("http")
        ? imageUrl
        : "http://192.168.0.180:5001/uploads/$imageUrl";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DroneFullDetailsPage(
                droneData: drone,
              )),
        );
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Drone Image ---
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: fullImageUrl,
                  placeholder: (context, url) => SizedBox(
                    height: imageHeight,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Image.asset(
                    'assets/images/MaskGroup34@2x.png',
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  height: imageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 8),

              // --- Name ---
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),

              // --- Category ---
              Text(
                category.toUpperCase(),
                style: GoogleFonts.lexend(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),

              const Spacer(),

              // --- Price ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "₹$price/day",
                    style: GoogleFonts.lexend(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Icon(Icons.local_florist,
                      size: 16, color: Colors.green),
                ],
              ),

              const SizedBox(height: 8),

              // --- Book Now Button ---
              SizedBox(
                width: double.infinity,
                height: 30,
                child: ElevatedButton(
                  onPressed: () {
                    Utils.bottomToast(context, "$name booking coming soon!");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff7057FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Book Now",
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Crop Spraying', style: GoogleFonts.lexend()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : sprayDrones.isEmpty
          ? const Center(child: Text("No drones available"))
          : Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: GridView.builder(
          itemCount: sprayDrones.length,
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            return buildSprayCard(sprayDrones[index]);
          },
        ),
      ),
    );
  }
}
