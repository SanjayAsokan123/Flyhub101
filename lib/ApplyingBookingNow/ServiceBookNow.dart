import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../CommonClass/ApiClass.dart';
import '../CommonClass/utils.dart';
import '../config/env.dart';

class ServiceBookNow extends StatefulWidget {
  final Map<String, dynamic> service;
  const ServiceBookNow({super.key, required this.service});

  @override
  State<ServiceBookNow> createState() => _ServiceBookNowState();
}

class _ServiceBookNowState extends State<ServiceBookNow> {
  final _formKey = GlobalKey<FormState>();
  final ApiClass _apiClass = ApiClass();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController locationCtrl = TextEditingController();
  final TextEditingController noteCtrl = TextEditingController();

  DateTime? selectedDate;
  bool _isLoading = false;

  // ================= BUYER ID LOGIC (ADDED) =================
  late GraphQLClient _client;

  bool _isLoadingBuyerId = false;
  String? buyerId;
  String? buyerIdError;

  @override
  void initState() {
    super.initState();
    _initGraphQl();
    _loadBuyerId();
  }

  void _initGraphQl() {
    final HttpLink httpLink = HttpLink(
      EnvConfig.baseUrl,
      defaultHeaders: {
        "Content-Type": "application/json",
      },
    );

    _client = GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
    );
  }

  Future<void> _loadBuyerId() async {
    setState(() => _isLoadingBuyerId = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => buyerIdError = "Not logged in");
        return;
      }

      final String firebaseUid = user.uid;

      const String query = r'''
        query GetBuyerByFirebaseUid($firebaseUid: String!) {
          getBuyerfirebaseUidInServiceBooking(firebaseUid: $firebaseUid) {
            buyerId
            firebaseUid
            name
            email
          }
        }
      ''';

      final QueryResult result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {"firebaseUid": firebaseUid},
        ),
      );

      if (result.hasException) {
        setState(() => buyerIdError = result.exception.toString());
        return;
      }

      final data = result.data?["getBuyerfirebaseUidInServiceBooking"];

      if (data != null && data["buyerId"] != null) {
        setState(() {
          buyerId = data["buyerId"];
          buyerIdError = null;
        });
      } else {
        buyerIdError = "Buyer ID not found in DB";
      }
    } catch (e) {
      setState(() => buyerIdError = e.toString());
    } finally {
      setState(() => _isLoadingBuyerId = false);
    }
  }

  // ===================================================================

  final Color primaryColor = const Color(0xFF1A0A5B);
  final Color accentColor = const Color(0xFF00C6FF);

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(2030),
    );

    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDate == null) {
      Utils.bottomToast(context, "Please choose a service date");
      return;
    }

    // ==================== CHECK BUYER ID ======================
    if (buyerId == null) {
      Utils.bottomToast(context,
          "Unable to load buyer ID. Error: $buyerIdError\nPlease restart app.");
      return;
    }
    // ==========================================================

    setState(() => _isLoading = true);

    // =============== FINAL BACKEND BODY WITH buyerId ===============
    final body = {
      "input": {
        "name": nameCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "location": locationCtrl.text.trim(),
        "information": noteCtrl.text.trim(),
        "phone": "",
        "date": selectedDate.toString().split(" ")[0],
        "serviceId": widget.service["serviceId"],
        "sellerId": widget.service["sellerId"] ?? "",
        "buyerId": buyerId, // ******** BUYER ID ADDED ********
      }
    };

    log("📤 Final Body Sent: $body");

    final response = await _apiClass.bookDroneService(body);

    setState(() => _isLoading = false);

    if (response.success) {
      Utils.bottomToast(context, "Booking Successful!");
      Navigator.pop(context);
    } else {
      Utils.bottomToast(context, "Error: ${response.message}");
    }
  }

  // Text Field Builder - EXACTLY LIKE JOB APPLY NOW
  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: type,
              validator: validator,
              maxLines: maxLines,
              style: GoogleFonts.poppins(fontSize: 15),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tile Builder for Date Picker - EXACTLY LIKE JOB APPLY NOW
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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? title,
                style: GoogleFonts.poppins(
                  color: value == null ? Colors.grey[600] : Colors.black,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Service Avatar Builder
  Widget _buildServiceAvatar({double size = 80}) {
    final serviceName = widget.service['name'] ?? 'Service';
    final initials = serviceName.isNotEmpty
        ? serviceName.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
        : 'SV';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: size / 3,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final serviceName = (service['name'] ?? 'Drone Service').trim();
    final price = service['price']?.toString() ?? '0';

    if (_isLoadingBuyerId) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F7FB),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header - EXACTLY LIKE JOB APPLY NOW
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Let's book your drone service",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Book professional drone service at your preferred time and location.",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Service Card - EXACTLY LIKE JOB APPLY NOW
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildServiceAvatar(size: 80),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(serviceName,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              )),
                          Text(
                            "Professional Drone Service",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const SizedBox(width: 4),
                              const Spacer(),
                              Text("₹$price",
                                  style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Booking Form - EXACTLY LIKE JOB APPLY NOW
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      label: "Your Name",
                      icon: Icons.person,
                      controller: nameCtrl,
                      validator: (v) =>
                      v == null || v.isEmpty ? "Enter your name" : null,
                    ),
                    _buildTextField(
                      label: "Email Address",
                      icon: Icons.email,
                      controller: emailCtrl,
                      type: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Enter email";
                        if (!RegExp(r"^[^@]+@[^@]+\.[^@]+").hasMatch(v.trim())) {
                          return "Enter valid email";
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      label: "Location",
                      icon: Icons.location_on,
                      controller: locationCtrl,
                      validator: (v) =>
                      v == null || v.isEmpty ? "Enter location" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTile(
                      title: "Select Service Date",
                      value: selectedDate != null
                          ? selectedDate.toString().split(" ")[0]
                          : null,
                      icon: Icons.calendar_today,
                      onTap: pickDate,
                    ),
                    _buildTextField(
                      label: "Additional Notes (Optional)",
                      icon: Icons.note,
                      controller: noteCtrl,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Book Now Button - EXACTLY LIKE JOB APPLY NOW
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)
                      : Text(
                    "Book Now",
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}