import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../CommonClass/ApiClass.dart';
import '../../CommonClass/utils.dart';
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
  bool hasError = false;

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

  /// ✅ Fetch spraying drones safely from APIClass
  Future<void> fetchSprayDrones() async {
    if (!await Utils.checkInternetConnection()) {
      Utils.bottomToast(context, "Check your Internet connection");
      return;
    }

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final result = await _apiClass.getMarketplaceItems("drones");

      if (result.status == "success" && result.data != null) {
        setState(() {
          sprayDrones = result.data!;
          isLoading = false;
        });
        debugPrint("✅ Loaded ${sprayDrones.length} crop spraying drones");
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
        Utils.bottomToast(context, result.message ?? "Failed to load drones");
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching drones: $e");
      setState(() {
        isLoading = false;
        hasError = true;
      });
      Utils.bottomToast(context, "Something went wrong. Try again later.");
    }
  }

  /// 🛩️ Drone Card Builder
  Widget buildSprayCard(Map<String, dynamic> drone) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageHeight = screenWidth * 0.25;

    final imageUrl = (drone["image"] ?? "").toString();
    final name = (drone["name"] ?? "Unnamed Drone").toString();
    final price = (drone["price"] ?? "0").toString();
    final category = (drone["category"] ?? "Drone").toString();

    final fullImageUrl = imageUrl.startsWith("http")
        ? imageUrl
        : "https://flyhub-storage.s3.ap-south-1.amazonaws.com/uploads/$imageUrl";

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DroneFullDetailsPage(droneData: drone),
        ),
      ),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// --- Drone Image ---
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: fullImageUrl,
                  height: imageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: imageHeight,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Image.asset(
                    'assets/images/MaskGroup34@2x.png',
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              /// --- Name ---
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),

              /// --- Category ---
              Text(
                category.toUpperCase(),
                style: GoogleFonts.lexend(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),

              /// --- Price + Icon ---
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

              /// --- Book Button ---
              SizedBox(
                width: double.infinity,
                height: 30,
                child: ElevatedButton(
                  onPressed: () =>
                      Utils.bottomToast(context, "$name booking coming soon!"),
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

  /// ===========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Crop Spraying', style: GoogleFonts.lexend()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      /// ✅ Body
      body: RefreshIndicator(
        onRefresh: fetchSprayDrones,
        color: const Color(0xff7057FF),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError
            ? Center(
          child: TextButton.icon(
            icon: const Icon(Icons.refresh, color: Color(0xff7057FF)),
            label: Text(
              "Retry",
              style: GoogleFonts.lexend(
                  color: const Color(0xff7057FF),
                  fontWeight: FontWeight.w500),
            ),
            onPressed: fetchSprayDrones,
          ),
        )
            : sprayDrones.isEmpty
            ? Center(
          child: Text(
            "No crop spraying drones available",
            style: GoogleFonts.lexend(
                fontSize: 15, color: Colors.grey[600]),
          ),
        )
            : Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 8),
          child: GridView.builder(
            itemCount: sprayDrones.length,
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, i) =>
                buildSprayCard(sprayDrones[i]),
          ),
        ),
      ),
    );
  }
}
