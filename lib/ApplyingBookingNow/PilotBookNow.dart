import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../CommonClass/ApiClass.dart';
import '../services/role_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final ApiClass _api = ApiClass();

class PilotBookNowPage extends StatefulWidget {
  final Map<String, dynamic> pilot;
  const PilotBookNowPage({super.key, required this.pilot});

  @override
  State<PilotBookNowPage> createState() => _PilotBookNowPageState();
}

class _PilotBookNowPageState extends State<PilotBookNowPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool isLoading = false;

  final TextEditingController locationController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  final Color primaryColor = const Color(0xFF1A0A5B);
  final Color accentColor = const Color(0xFF00C6FF);

  // ----------------------- PICKERS ------------------------
  Future<void> _pickDate() async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _pickStartTime() async {
    final TimeOfDay? picked =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final TimeOfDay? picked =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => endTime = picked);
  }
  Future<Map<String, dynamic>> getBuyerDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    final snap = await FirebaseFirestore.instance
        .collection("buyers")
        .where("firebaseUid", isEqualTo: user.uid)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw Exception("Buyer not found in database");
    }

    final data = snap.docs.first.data();
    return {
      "buyerId": data["buyerId"],
      "buyerName": data["name"],
      "buyerEmail": data["email"],
    };
  }

  // ----------------------- SUBMIT BOOKING ------------------------
  Future<void> _submitBooking() async {
    if (_formKey.currentState!.validate()) {
      if (selectedDate == null || startTime == null || endTime == null) {
        _showSnack("Please select date and time", isError: true);
        return;
      }

      // 1️⃣ Get buyer info from Firestore
      final buyerData = await getBuyerDetails();
      final buyerId = buyerData["buyerId"];
      final buyerName = buyerData["buyerName"];
      final buyerEmail = buyerData["buyerEmail"];

      final rentalDate = DateFormat('yyyy-MM-dd').format(selectedDate!);

      final rentalStart = DateFormat('yyyy-MM-dd HH:mm').format(
        DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day,
            startTime!.hour, startTime!.minute),
      );

      final rentalEnd = DateFormat('yyyy-MM-dd HH:mm').format(
        DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day,
            endTime!.hour, endTime!.minute),
      );

      final pilotId = widget.pilot['pilotId']?.toString() ?? "";

      setState(() => isLoading = true);
      _showSnack("Booking your pilot...", isLoading: true);

      // 2️⃣ API Call
      final result = await _api.bookPilot(
        pilotId: pilotId,
        buyerId: buyerId,
        buyerName: buyerName,
        buyerEmail: buyerEmail,
        contact: contactController.text.trim(),
        location: locationController.text.trim(),
        date: rentalDate,
        startTime: rentalStart,
        endTime: rentalEnd,
      );

      setState(() => isLoading = false);

      if (result['status'] == "success") {
        _showSnack("Pilot booked successfully!");
        Navigator.pop(context);
      } else {
        _showSnack("Booking failed: ${result['message']}", isError: true);
      }
    }
  }


  // ----------------------- SNACKBAR ------------------------
  void _showSnack(String message,
      {bool isError = false, bool isLoading = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration:
        isLoading ? const Duration(seconds: 1) : const Duration(seconds: 3),
        backgroundColor: isError
            ? Colors.redAccent
            : isLoading
            ? Colors.blueAccent
            : primaryColor,
        content: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child:
                CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            if (isLoading) const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------- UI COMPONENTS ------------------------
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
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
      ),
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
              decoration: InputDecoration(
                labelText: label,
                labelStyle:
                GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
                border: InputBorder.none,
              ),
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
                    fontSize: 15),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPilotAvatar({double size = 80}) {
    final imagePath = widget.pilot['certifications'] != null &&
        widget.pilot['certifications'].isNotEmpty
        ? widget.pilot['certifications'][0]['url']
        : null;

    final name = (widget.pilot['pilotName'] ?? 'Pilot').trim();
    final initials = name.isNotEmpty
        ? name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join()
        : 'P';

    // Constrain the avatar so it cannot push layout outwards
    final double avatarSize = size;

    if (imagePath != null && imagePath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: avatarSize,
          height: avatarSize,
          child: Image.network(
            imagePath,
            fit: BoxFit.cover,
            // show a small progress indicator while loading
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: SizedBox(
                  width: avatarSize * 0.4,
                  height: avatarSize * 0.4,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            // Replace with circle avatar / initials if image fails
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: avatarSize,
                height: avatarSize,
                color: Colors.grey[200],
                child: CircleAvatar(
                  radius: avatarSize / 2,
                  backgroundColor: primaryColor,
                  child: Text(initials,
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: avatarSize / 3)),
                ),
              );
            },
          ),
        ),
      );
    }

    // fallback when no imagePath
    return CircleAvatar(
      radius: avatarSize / 2,
      backgroundColor: primaryColor,
      child: Text(initials,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: avatarSize / 3)),
    );
  }


  // ----------------------- BUILD UI ------------------------
  @override
  Widget build(BuildContext context) {
    final pilotName = (widget.pilot['pilotName'] ?? 'Pilot').trim();
    final pilotCompany = (widget.pilot['pilotCompany'] ?? 'FlyHub').trim();
    final pilotSpec = (widget.pilot['specification'] ?? 'General').trim();
    final pilotPrice = widget.pilot['price']?['perHour']?.toString() ?? '1200';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ---------------- HEADER ----------------
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
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
                      "Let’s book your pilot",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Book a professional pilot at your preferred time and location.",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ---------------- PILOT CARD ----------------
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildPilotAvatar(size: 80),
                    const SizedBox(width: 16),
                    // Constrain the right side with Expanded
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pilotName,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pilotCompany,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Skills: $pilotSpec",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Right-aligned price without forcing extra width
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "₹$pilotPrice/hr",
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ---------------- BOOKING FORM ----------------
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTile(
                      title: "Select Date",
                      value: selectedDate != null
                          ? DateFormat('dd MMM yyyy').format(selectedDate!)
                          : null,
                      icon: Icons.calendar_today,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 16),

                    _buildTile(
                      title: "Select Start Time",
                      value: startTime != null
                          ? startTime!.format(context)
                          : null,
                      icon: Icons.access_time,
                      onTap: _pickStartTime,
                    ),
                    const SizedBox(height: 16),

                    _buildTile(
                      title: "Select End Time",
                      value: endTime != null
                          ? endTime!.format(context)
                          : null,
                      icon: Icons.access_time_outlined,
                      onTap: _pickEndTime,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      label: "Enter Location",
                      icon: Icons.location_on,
                      controller: locationController,
                      validator: (v) =>
                      v == null || v.isEmpty ? "Enter location" : null,
                    ),

                    _buildTextField(
                      label: "Contact Number",
                      icon: Icons.phone,
                      controller: contactController,
                      type: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Enter contact";
                        if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                          return "Enter valid 10-digit number";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ---------------- BOOK NOW BUTTON ----------------
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  child: isLoading
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
