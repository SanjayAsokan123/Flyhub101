import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flyhub/config/env.dart';

class RentalBookNowPage extends StatefulWidget {
  final Map<String, dynamic> rental; // the rental object from RentalsPage (must include rentalId)
  final Map<String, dynamic>? drone; // optional

  const RentalBookNowPage({
    Key? key,
    required this.rental,
    this.drone,
  }) : super(key: key);

  @override
  State<RentalBookNowPage> createState() => _RentalBookNowPageState();
}

class _RentalBookNowPageState extends State<RentalBookNowPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? bookingDate;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  final Color primaryColor = const Color(0xFF1A0A5B);
  final Color secondaryColor = const Color(0xFF4C1D95);
  // final Color accentColor = const Color(0xFF00C6FF);
  final Color backgroundColor = Colors.white;
  final Color surfaceColor = Colors.white;
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);
  final Color borderColor = const Color(0xFFE5E7EB);

  // GraphQL client config
  final String graphqlUrl = EnvConfig.baseUrl;
  late GraphQLClient _client;

  bool _submitting = false;

  // ✅ NEW: Loading state for buyerId
  bool _isLoadingBuyerId = false;

  // ✅ NEW: Error tracking for buyerId
  String? _buyerIdError;

  // Seller info fetched from listing (best-effort)
  String? listingSellerEmail;
  String? listingSellerPhone;

  // ✅ UPDATED: Buyer id fetched from MongoDB (not Firebase UID)
  String? buyerId;

  @override
  void initState() {
    super.initState();

    // Create HttpLink with default header (content-type)
    final HttpLink httpLink = HttpLink(
      graphqlUrl,
      defaultHeaders: {
        'Content-Type': 'application/json',
      },
    );

    _client = GraphQLClient(link: httpLink, cache: GraphQLCache());

    // ✅ FIXED: Call dedicated initialization function that awaits loading
    _initializeBooking();
  }

  // ✅ NEW: Dedicated initialization function that properly awaits
  Future<void> _initializeBooking() async {
    await _loadBuyerId();
    await fetchListingSeller();
  }

  // ✅ REWRITTEN: Fetch buyerId from MongoDB using Firebase UID
  Future<void> _loadBuyerId() async {
    if (mounted) setState(() => _isLoadingBuyerId = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint("⚠ Firebase user not logged in");
        if (mounted) {
          setState(() => _buyerIdError = "Not logged in");
        }
        return;
      }

      final String firebaseUid = user.uid;
      debugPrint("🔍 Firebase UID: $firebaseUid");

      // ✅ STEP 1: Query MongoDB to get buyerId using firebaseUid
      // This query finds the buyer document and returns the buyerId (e.g., "FLYHUBB0114")
      const String query = r'''
      query GetBuyerByFirebaseUid($firebaseUid: String!) {
        getBuyerfirebaseUidInDroneRental(firebaseUid: $firebaseUid) {
          buyerId
          firebaseUid
          name
          email
        }
      }
    ''';

      final QueryOptions options = QueryOptions(
        document: gql(query),
        variables: {"firebaseUid": firebaseUid},
      );

      // debugPrint("📤 Sending GraphQL query to get buyerId...");
      final QueryResult result = await _client.query(options);

      if (!mounted) return;

      if (result.hasException) {
        debugPrint("❌ GraphQL Error: ${result.exception.toString()}");
        setState(() => _buyerIdError = result.exception.toString());
        return;
      }

      // debugPrint("📥 GraphQL Response: ${result.data}");
      final data = result.data?["getBuyerfirebaseUidInDroneRental"];

      if (data != null && data["buyerId"] != null) {
        setState(() {
          buyerId = data["buyerId"];  // ✅ GET buyerId from MongoDB (e.g., "FLYHUBB0114")
          _buyerIdError = null;
        });
        debugPrint("✅ Loaded buyerId from MongoDB: $buyerId");
      } else {
        debugPrint("⚠ Buyer not found in MongoDB for this Firebase UID");
        setState(() => _buyerIdError = "Buyer profile not found in database");
      }
    } catch (e) {
      debugPrint("❌ Error loading buyerId: $e");
      if (mounted) {
        setState(() => _buyerIdError = "Error: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoadingBuyerId = false);
    }
  }


  // Query name here is a best-effort guess; backend may need a different field name.
  // This query attempts to get the rental listing by rentalId and receives seller info.
  // If your backend exposes a different query, replace the query string below with that.
  static const String getListingQuery = r'''
    query GetRentalListing($rentalId: String!) {
      getRentalListingById(rentalId: $rentalId) {
        rentalId
        name
        sellerId
        sellerEmail
        sellerPhone
        image
        price
      }
    }
  ''';

  Future<void> fetchListingSeller() async {
    final rentalId = extractRentalId(widget.rental);
    if (rentalId == null) return;

    try {
      final res = await _client.query(QueryOptions(
        document: gql(getListingQuery),
        variables: {"rentalId": rentalId},
        fetchPolicy: FetchPolicy.networkOnly,
      ));

      if (res.hasException) {
        // Not fatal — log it so you can debug backend/field names
        debugPrint("fetchListingSeller error: ${res.exception}");
        return;
      }

      final listing = res.data?['getRentalListingById'];
      if (listing != null) {
        setState(() {
          listingSellerEmail = listing['sellerEmail']?.toString();
          listingSellerPhone = listing['sellerPhone']?.toString();
        });
      }
    } catch (e) {
      debugPrint("fetchListingSeller exception: $e");
    }
  }

  // Fixed mutation: declare $buyerId variable and pass buyerId: $buyerId
  // ✅ Now passes the MongoDB buyerId (e.g., "FLYHUBB0114") to the mutation
  static const String createBookingMutation = r'''
  mutation CreateDroneRental(
    $name: String!,
    $phone: String!,
    $location: String!,
    $rentalDate: String!,
    $rentalId: String!,
    $buyerId: String!
  ) {
    createDroneRental(
      name: $name,
      phone: $phone,
      location: $location,
      rentalDate: $rentalDate,
      rentalId: $rentalId,
      buyerId: $buyerId
    ) {
      success
      message
    }
  }
''';


  Future<void> _pickBookingDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: bookingDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => bookingDate = picked);
  }

  // tries to extract rentalId from rental object (multiple possible keys)
  String? extractRentalId(Map<String, dynamic> obj) {
    return obj['rentalId'] ??
        obj['rental_id'] ??
        obj['rentalID'] ??
        obj['_id'] ??
        obj['id'];
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (bookingDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please select a date")));
      return;
    }

    final rentalId = extractRentalId(widget.rental);
    if (rentalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ rentalId missing from selected rental")),
      );
      return;
    }

    // ✅ FIXED: Better null check with meaningful error message
    if (buyerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          _buyerIdError != null
              ? "⚠ Buyer setup failed: $_buyerIdError. Please restart the app."
              : "❌ Buyer ID not loaded. Please wait...",
        ),
        duration: const Duration(seconds: 4),
      ));
      return;
    }

    // ✅ FIXED: Prevent duplicate submissions
    if (_submitting) {
      debugPrint("⚠ Already submitting, ignoring duplicate click");
      return;
    }

    setState(() => _submitting = true);

    try {
      // Wrap network call in timeout to avoid indefinite waiting
      final mutateFuture = _client.mutate(MutationOptions(
        document: gql(createBookingMutation),
        variables: {
          "name": nameController.text.trim(),
          "phone": contactController.text.trim(),
          "location": locationController.text.trim(),
          "rentalDate": bookingDate!.toIso8601String(),
          "rentalId": rentalId,
          "buyerId": buyerId,  // ✅ Now sends MongoDB buyerId (e.g., "FLYHUBB0114")
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ));

      // Wait at most 12 seconds
      final result = await mutateFuture.timeout(const Duration(seconds: 12));

      if (result.hasException) {
        final exc = result.exception!;
        String msg = "Booking failed";

        if (exc.graphqlErrors.isNotEmpty) {
          msg = exc.graphqlErrors.map((e) => e.message).join(", ");
        } else if (exc.linkException != null) {
          // linkException often indicates network issues / CORS / connection refused
          msg = exc.linkException.toString();
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("❌ $msg"), backgroundColor: Colors.redAccent));
        return;
      }

      final data = result.data?['createDroneRental'];
      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Something went wrong"))
        );
        return;
      }

      final bool success = data['success'];
      final String message = data['message'];

      if (!success) {
        // ❌ DUPLICATE OR ERROR
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("⚠ $message"), backgroundColor: Colors.orange)
        );
        return;
      }

// ✔ SUCCESS
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ $message"), backgroundColor: Colors.green)
      );

// Close page
      Navigator.pop(context);
      final formatted = DateFormat('dd MMM yyyy').format(bookingDate!);
      // Show bottom sheet confirmation (nice modern UI)
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isDismissible: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Booking Confirmed ✅",
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(); // close sheet
                      Navigator.of(context)
                          .pop(data); // return to previous screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Done",
                        style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                )
              ],
            ),
          );
        },
      );
    } on TimeoutException catch (_) {
      // Clear submitting indicator first
      if (mounted) setState(() => _submitting = false);

      // Helpful message pointing to common causes of timeouts
      final snack = SnackBar(
        backgroundColor: Colors.orange.shade700,
        content: Text(
          "Request timed out. Common causes:\n"
              "• Server not running or not reachable at $graphqlUrl\n"
              "• Device and server not on same network (phone vs PC Wi-Fi)\n"
              "• Firewall/antivirus blocking port 5001\n\n"
              "Check the backend and your IP, then try again.",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        duration: const Duration(seconds: 6),
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(snack);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Unexpected error: $e"),
          backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: type,
              validator: validator,
              style: GoogleFonts.poppins(fontSize: 15),
              decoration:
              InputDecoration(labelText: label, border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required String title,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
            color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Text(value ?? title,
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: value == null ? Colors.grey[600] : Colors.black))),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey)
          ],
        ),
      ),
    );
  }

  // Build drone image widget with tap -> full screen preview
  Widget _buildDroneImage({double size = 100}) {
    final imagePath = widget.drone?['image'] ?? widget.rental['image'];
    if (imagePath != null && imagePath.toString().isNotEmpty) {
      return GestureDetector(
        onTap: () => _openImagePreview(imagePath.toString()),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imagePath.toString(),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.flight, size: size, color: primaryColor),
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => _openImagePreview(null),
        child: Icon(Icons.flight, size: size, color: primaryColor),
      );
    }
  }

  void _openImagePreview(String? imageUrl) {
    showDialog(
      context: context,
      builder: (_) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.black.withOpacity(0.9),
            child: Center(
              child: imageUrl != null
                  ? InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const CircularProgressIndicator();
                  },
                  errorBuilder: (_, __, ___) => Icon(Icons.flight,
                      size: 80, color: Colors.white54),
                ),
              )
                  : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flight, size: 80, color: Colors.white54),
                  const SizedBox(height: 12),
                  Text("No image available",
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    contactController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rental = widget.rental;

    // Extract all the details shown in RentalsPage
    final droneName = rental['name'] ?? widget.drone?['name'] ?? 'Professional Drone';
    final droneBrand = rental['brand'] ?? widget.drone?['brand'] ?? 'Premium Brand';
    final droneLocation = rental['location'] ?? widget.drone?['location'] ?? 'Multiple Locations';
    final droneModel = rental['model'] ?? widget.drone?['model'] ?? '';
    final pricePerHour = rental['pricePerHour'] ?? widget.drone?['pricePerHour'] ?? '0';
    final pricePerDay = rental['pricePerDay'] ?? widget.drone?['pricePerDay'] ?? '0';
    final isPremium = rental['premium'] ?? false;


    // ✅ FIXED: Show loading state while data is being prepared
    if (_isLoadingBuyerId) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: primaryColor),
                const SizedBox(height: 16),
                Text("Preparing your booking...",
                    style: GoogleFonts.poppins(fontSize: 14)),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ FIXED: Show error state if buyerId loading failed
    if (_buyerIdError != null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text("Failed to load booking",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 16)),
                const SizedBox(height: 8),
                Text(_buyerIdError ?? "Unknown error",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadBuyerId,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text("Retry",
                      style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Blue gradient header
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(height: 12),
                    Text("Rent your drone",
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text("Book a high-quality drone for your project needs.",
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Drone details card - updated to match RentalsPage
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4)),
                  ],
                  border: Border.all(color: borderColor.withOpacity(0.5), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top part: image and details
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image with premium badge
                        Stack(
                          children: [
                            _buildDroneImage(size: 100),
                            if (isPremium)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [secondaryColor, primaryColor],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "PREMIUM",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(droneName,
                                  style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      color: textPrimary,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              Text(droneBrand,
                                  style: GoogleFonts.poppins(color: textSecondary)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 14, color: textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(droneLocation,
                                        style: GoogleFonts.poppins(color: textSecondary)),
                                  ),
                                ],
                              ),
                              if (droneModel.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text("Model: $droneModel",
                                    style: GoogleFonts.poppins(color: textSecondary)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Divider
                    Divider(color: borderColor.withOpacity(0.6)),

                    const SizedBox(height: 12),

                    // Prices section
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("₹$pricePerHour",
                                      style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          color: primaryColor,
                                          fontWeight: FontWeight.w900)),
                                  Text("/hr",
                                      style: GoogleFonts.poppins(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text("₹$pricePerDay",
                                      style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          color: primaryColor,
                                          fontWeight: FontWeight.w900)),
                                  Text("/day",
                                      style: GoogleFonts.poppins(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Booking section header card (white)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor.withOpacity(0.5), width: 1)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Booking details",
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                      const SizedBox(height: 6),
                      Text("Enter your details to reserve this drone.",
                          style: GoogleFonts.poppins(color: textSecondary)),
                    ]),
              ),

              const SizedBox(height: 18),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                        label: "Full Name",
                        icon: Icons.person,
                        controller: nameController,
                        validator: (v) =>
                        v == null || v.isEmpty ? "Enter name" : null),
                    _buildTextField(
                        label: "Contact Number",
                        icon: Icons.phone,
                        controller: contactController,
                        type: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Enter contact";
                          if (!RegExp(r'^\d{10}$').hasMatch(v))
                            return "Enter 10-digit number";
                          return null;
                        }),
                    _buildTextField(
                        label: "Pickup Location",
                        icon: Icons.location_on,
                        controller: locationController,
                        validator: (v) =>
                        v == null || v.isEmpty ? "Enter location" : null),
                    const SizedBox(height: 12),
                    _buildTile(
                        title: "Select Date",
                        value: bookingDate != null
                            ? DateFormat('dd MMM yyyy').format(bookingDate!)
                            : null,
                        icon: Icons.calendar_today,
                        onTap: _pickBookingDate),
                    const SizedBox(height: 24),
                    // ✅ FIXED: Disable button if submitting, loading, or error
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_submitting || _isLoadingBuyerId || _buyerIdError != null)
                            ? null
                            : _submitBooking,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            disabledBackgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: _submitting
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text("Booking...",
                                style: GoogleFonts.poppins(
                                    fontSize: 15, color: Colors.white)),
                          ],
                        )
                            : Text("Confirm Booking",
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Extra content below form — helpful notes
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}