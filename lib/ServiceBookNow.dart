import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../CommonClass/ApiClass.dart';
import '../CommonClass/utils.dart';

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

  final Color primaryColor = const Color(0xFF1A0A5B);
  final Color secondaryColor = const Color(0xFF6C56F5);
  final Color backgroundColor = const Color(0xFFF8F9FF);

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

    setState(() => _isLoading = true);

    // =============== BACKEND BODY ======================
    final body = {
      "input": {
        "name": nameCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "location": locationCtrl.text.trim(),
        "information": noteCtrl.text.trim(),
        "phone": "",
        "date": selectedDate.toString().split(" ")[0],
        "serviceId": widget.service["_id"],
        "sellerId": widget.service["sellerId"] ?? "",
        "serviceBookingId": DateTime.now().millisecondsSinceEpoch.toString(),
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

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text("Book ${service['name']}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ================= SERVICE CARD ==================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.rocket_launch, color: Colors.white, size: 33),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service["name"] ?? "",
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "₹${service['price']}",
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ================= FORM ==================
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: _input("Your Name", Icons.person),
                    validator: (v) => v!.isEmpty ? "Enter your name" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: _input("Email ID", Icons.email),
                    validator: (v) =>
                    v!.contains("@") ? null : "Enter valid email",
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: locationCtrl,
                    decoration: _input("Your Location", Icons.location_on),
                    validator: (v) => v!.isEmpty ? "Enter your location" : null,
                  ),
                  const SizedBox(height: 16),

                  // Date Picker
                  InkWell(
                    onTap: pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border:
                          Border.all(color: Colors.grey.shade300)),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: primaryColor),
                          const SizedBox(width: 10),
                          Text(
                            selectedDate == null
                                ? "Choose Service Date"
                                : selectedDate.toString().split(" ")[0],
                            style: GoogleFonts.lexend(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: noteCtrl,
                    maxLines: 4,
                    decoration: _input("Additional Notes", Icons.notes),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : submitBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Confirm Booking"),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}