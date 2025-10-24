import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PilotBookNowPage extends StatefulWidget {
  final Map<String, String> pilot;
  const PilotBookNowPage({super.key, required this.pilot});

  @override
  State<PilotBookNowPage> createState() => _PilotBookNowPageState();
}

class _PilotBookNowPageState extends State<PilotBookNowPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  final TextEditingController locationController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  final Color primaryColor = const Color(0xFF1A0A5B);
  final Color accentColor = const Color(0xFF00C6FF);

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

  void _submitBooking() {
    if (_formKey.currentState!.validate()) {
      if (selectedDate == null || startTime == null || endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select date and time range")),
        );
        return;
      }

      final bookingDate = DateFormat('dd MMM yyyy').format(selectedDate!);
      final pilotName = (widget.pilot['name'] ?? 'Pilot').trim();
      final price = widget.pilot['price'] ?? 'N/A';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: primaryColor,
          content: Text(
            "$pilotName booked for  $bookingDate "
                "from ${startTime!.format(context)} to ${endTime!.format(context)}\n"
                "Rate: ₹$price/hr",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );

      Navigator.pop(context);
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

    final imagePath = widget.pilot['image'];
    final name = (widget.pilot['name'] ?? 'Pilot').trim();
    final initials = name.isNotEmpty
        ? name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join()
        : 'P';

    if (imagePath != null && imagePath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          imagePath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CircleAvatar(
            radius: size / 2,
            backgroundColor: primaryColor,
            child: Text(initials,
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: size / 3)),
          ),
        ),
      );
    } else {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: primaryColor,
        child: Text(initials,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: size / 3)),
      );
    }
  }

  @override
  void dispose() {
    locationController.dispose();
    contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pilotName = (widget.pilot['name'] ?? 'Pilot').trim();
    final pilotRole = (widget.pilot['role'] ?? 'Professional').trim();
    final pilotSpecialty = (widget.pilot['specialty'] ?? 'General').trim();
    final pilotPrice = (widget.pilot['price'] ?? '1200').trim();
    final pilotRating = (widget.pilot['rating'] ?? '4.8').trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
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
                      "Let’s book your pilot ✈",
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

              // Pilot Card
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
                    _buildPilotAvatar(size: 80),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pilotName,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              )),
                          Text(pilotRole,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              )),
                          const SizedBox(height: 4),
                          Text("Specialty: $pilotSpecialty",
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: Colors.grey[700])),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star,
                                  color: Colors.amber.shade600, size: 20),
                              const SizedBox(width: 4),
                              Text("$pilotRating / 5.0",
                                  style: GoogleFonts.poppins(
                                      fontSize: 13, color: Colors.black87)),
                              const Spacer(),
                              Text("₹$pilotPrice/hr",
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
              // Booking Form
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
                      value:
                      startTime != null ? startTime!.format(context) : null,
                      icon: Icons.access_time,
                      onTap: _pickStartTime,
                    ),
                    const SizedBox(height: 16),
                    _buildTile(
                      title: "Select End Time",
                      value: endTime != null ? endTime!.format(context) : null,
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

              // Book Now Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  child: Text(
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

  DateFormat(String s) {}
}