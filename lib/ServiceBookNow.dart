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
  final ApiClass _apiClass = ApiClass();
  final _formKey = GlobalKey<FormState>();

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
    DateTime now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDate == null) {
      Utils.bottomToast(context, "Please choose a date");
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> body = {
      "serviceId": widget.service["_id"],
      "name": nameCtrl.text.trim(),
      "email": emailCtrl.text.trim(),
      "location": locationCtrl.text.trim(),
      "notes": noteCtrl.text.trim(),
      "serviceName": widget.service["name"],
      "price": widget.service["price"].toString(),
      "date": selectedDate.toString().split(" ")[0],
    };

    final res = await _apiClass.bookDroneService(body);

    setState(() => _isLoading = false);

    if (res.status == "success") {
      Utils.bottomToast(context, "Booking Successful!");
      Navigator.pop(context);
    } else {
      Utils.bottomToast(context, "Error: ${res.message}");
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.lexend(
        color: Colors.grey[600],
        fontSize: 14,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: primaryColor, size: 20),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Book ${service['name']}",
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SERVICE DETAILS CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withOpacity(0.9),
                    secondaryColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.rocket_launch,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          service["name"] ?? "",
                          style: GoogleFonts.lexend(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        "Price: ",
                        style: GoogleFonts.lexend(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "₹${service['price']}",
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // FORM SECTION HEADER
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                "Booking Details",
                style: GoogleFonts.lexend(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),

            // FORM
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // NAME FIELD
                  TextFormField(
                    controller: nameCtrl,
                    style: GoogleFonts.lexend(fontSize: 14),
                    decoration: _buildInputDecoration(
                        "Your Name", Icons.person_outline),
                    validator: (v) => v!.isEmpty ? "Enter your name" : null,
                  ),
                  const SizedBox(height: 16),

                  // EMAIL FIELD
                  TextFormField(
                    controller: emailCtrl,
                    style: GoogleFonts.lexend(fontSize: 14),
                    decoration: _buildInputDecoration("Email ID", Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.contains("@") && v.contains(".")
                        ? null
                        : "Enter valid email",
                  ),
                  const SizedBox(height: 16),

                  // LOCATION FIELD
                  TextFormField(
                    controller: locationCtrl,
                    style: GoogleFonts.lexend(fontSize: 14),
                    decoration: _buildInputDecoration(
                        "Your Location", Icons.location_on_outlined),
                    validator: (v) => v!.isEmpty ? "Enter your location" : null,
                  ),
                  const SizedBox(height: 16),

                  // DATE PICKER
                  InkWell(
                    onTap: pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.calendar_today,
                                color: primaryColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedDate == null
                                  ? "Choose Service Date"
                                  : selectedDate.toString().split(" ")[0],
                              style: GoogleFonts.lexend(
                                fontSize: 14,
                                color: selectedDate == null
                                    ? Colors.grey[600]
                                    : Colors.black,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down,
                              color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // NOTES FIELD
                  TextFormField(
                    controller: noteCtrl,
                    style: GoogleFonts.lexend(fontSize: 14),
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: "Additional Notes (Optional)",
                      labelStyle: GoogleFonts.lexend(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.note_alt_outlined,
                            color: primaryColor, size: 20),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // BOOK BUTTON
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: primaryColor.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Confirm Booking",
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // SECURITY NOTE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.green[600], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Your booking details are secure and encrypted",
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}