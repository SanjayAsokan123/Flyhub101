import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../CommonClass/ApiClass.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final ApiClass api = ApiClass();

class PilotBookNowPage extends StatefulWidget {
  final Map<String, dynamic> pilot;
  const PilotBookNowPage({super.key, required this.pilot});

  @override
  State<PilotBookNowPage> createState() => PilotBookNowPageState();
}

class PilotBookNowPageState extends State<PilotBookNowPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final formKey = GlobalKey<FormState>();
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool isLoading = false;
  bool isLoadingBuyer = true;
  bool showFullSkills = false;

  final TextEditingController locationController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController buyerIdController = TextEditingController();
  final TextEditingController buyerNameController = TextEditingController();
  final TextEditingController buyerEmailController = TextEditingController();

  final Color primaryColor = const Color(0xFF1A0A5B);
  // final Color accentColor = const Color(0xFF00C6FF);
  final Color warningColor = const Color(0xFFFF6B6B);
  final Color successColor = const Color(0xFF51CF66);

  @override
  void initState() {
    super.initState();
    loadBuyerInfo();
  }

  @override
  void dispose() {
    locationController.dispose();
    contactController.dispose();
    buyerIdController.dispose();
    buyerNameController.dispose();
    buyerEmailController.dispose();
    super.dispose();
  }

  Future<void> loadBuyerInfo() async {
    try {
      setState(() => isLoadingBuyer = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        showSnack('User not logged in.', isError: true);
        setState(() => isLoadingBuyer = false);
        return;
      }
      final snap = await FirebaseFirestore.instance
          .collection('buyers')
          .where('firebaseUid', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        showSnack('Buyer profile not found.', isError: true);
        setState(() => isLoadingBuyer = false);
        return;
      }
      final data = snap.docs.first.data();
      setState(() {
        buyerIdController.text = data['buyerId'] ?? '';
        buyerNameController.text = data['name'] ?? '';
        buyerEmailController.text = data['email'] ?? '';
        isLoadingBuyer = false;
      });
    } catch (e) {
      showSnack('Error loading buyer info.', isError: true);
      setState(() => isLoadingBuyer = false);
    }
  }

  double calculateBookingDuration() {
    if (startTime == null || endTime == null) return 0;
    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = endTime!.hour * 60 + endTime!.minute;
    int diffMinutes = endMinutes - startMinutes;
    if (diffMinutes <= 0) diffMinutes += 24 * 60;
    return diffMinutes / 60;
  }

  String? validateTimeSelection() {
    if (startTime == null || endTime == null) return null;
    final duration = calculateBookingDuration();
    if (duration <= 0) return 'End time must be after start time';
    if (duration < 1) return 'Minimum booking duration is 1 hour';
    return null;
  }

  Future<void> pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryColor,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: primaryColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> pickStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryColor,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: primaryColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() {
      startTime = picked;
      endTime = null;
    });
  }

  Future<void> pickEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryColor,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: primaryColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => endTime = picked);
  }

  Future<void> submitBooking() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedDate == null || startTime == null || endTime == null) {
      showSnack('Please select date and time.', isError: true);
      return;
    }
    try {
      setState(() => isLoading = true);
      final rentalDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      final rentalStart = '${startTime!.hour.toString().padLeft(2, '0')}${startTime!.minute.toString().padLeft(2, '0')}';
      final rentalEnd = '${endTime!.hour.toString().padLeft(2, '0')}${endTime!.minute.toString().padLeft(2, '0')}';
      final result = await api.bookPilot(
        pilotId: widget.pilot['pilotId']?.toString() ?? '',
        buyerId: buyerIdController.text.trim(),
        buyerName: buyerNameController.text.trim(),
        buyerEmail: buyerEmailController.text.trim(),
        contact: contactController.text.trim(),
        location: locationController.text.trim(),
        date: rentalDate,
        startTime: rentalStart,
        endTime: rentalEnd,
      );
      setState(() => isLoading = false);
      if (result != null && !result['success']) {
        showSnack(result['message'] ?? 'Booking failed.', isError: true);
        return;
      }
      if (result != null && result['success']) {
        showSnack('Pilot booked successfully!');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, true);
      } else {
        showSnack(result?['message'] ?? 'Booking failed.', isError: true);
      }
    } catch (e) {
      setState(() => isLoading = false);
      showSnack('Error occurred: ${e.toString()}', isError: true);
    }
  }

  void showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? warningColor : primaryColor,
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
    );
  }

  Widget buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: type,
              validator: validator,
              readOnly: readOnly,
              maxLines: maxLines,
              minLines: 1,
              style: GoogleFonts.poppins(fontSize: 15),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTile({
    required String title,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
    bool isError = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isError ? warningColor.withOpacity(0.1) : Colors.grey[100],
          border: Border.all(
            color: isError ? warningColor : Colors.transparent,
            width: isError ? 2 : 0,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: isError ? warningColor : primaryColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? title,
                style: GoogleFonts.poppins(
                  color: value == null ? Colors.grey[600] : (isError ? warningColor : Colors.black),
                  fontSize: 15,
                  fontWeight: value != null ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget buildDurationDisplay() {
    final duration = calculateBookingDuration();
    final durationStr = duration > 0 ? '${duration.toStringAsFixed(2)} hours' : 'Select time';
    final isValid = duration >= 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: duration == 0
            ? Colors.grey[100]
            : (isValid ? successColor.withOpacity(0.1) : warningColor.withOpacity(0.1)),
        border: Border.all(
          color: duration == 0 ? Colors.transparent : (isValid ? successColor : warningColor),
          width: duration == 0 ? 0 : 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            duration == 0
                ? Icons.schedule
                : (isValid ? Icons.check_circle : Icons.info),
            color: duration == 0 ? Colors.grey[600] : (isValid ? successColor : warningColor),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Duration',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  durationStr,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: duration == 0 ? Colors.grey[600] : (isValid ? successColor : warningColor),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (duration == 0 || duration < 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: warningColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Min 1hr',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildPilotAvatar({double size = 80}) {
    final imagePath = widget.pilot['certifications'] != null && widget.pilot['certifications'].isNotEmpty
        ? widget.pilot['certifications'][0]['url']
        : null;
    final name = widget.pilot['pilotName'] ?? 'Pilot';
    final initials = name.isNotEmpty ? name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join('') : 'P';
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
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: SizedBox(
                  width: avatarSize * 0.4,
                  height: avatarSize * 0.4,
                  child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.poppins(color: primaryColor, fontSize: avatarSize / 2.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: avatarSize / 2.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pilotName = widget.pilot['pilotName'] ?? 'Pilot';
    final pilotCompany = widget.pilot['pilotCompany'] ?? 'FlyHub';
    final pilotSpec = widget.pilot['specification'] ?? 'General';
    final pilotLocation = widget.pilot['location'] ?? 'Multiple Locations';
    final pilotPrice = widget.pilot['price']?['perHour']?.toString() ?? '1200';
    final pilotPriceDay = widget.pilot['price']?['perDay']?.toString() ?? '9600';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor, primaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Let\'s book your pilot',
                      style: GoogleFonts.poppins(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Book a professional pilot for at least 1 hour at your preferred time.',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withOpacity(0.9), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // PILOT CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    buildPilotAvatar(size: 80),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pilotName,
                            style: GoogleFonts.poppins(fontSize: 18, color: primaryColor, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pilotCompany,
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Skills: $pilotSpec',
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                                maxLines: showFullSkills ? null : 3,
                                overflow: showFullSkills ? null : TextOverflow.ellipsis,
                                softWrap: true,
                              ),
                              if (pilotSpec.length > 100)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      showFullSkills = !showFullSkills;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      showFullSkills ? 'Read Less' : 'Read More',
                                      style: GoogleFonts.poppins(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 6),
                          Text(
                            'Location: $pilotLocation',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$pilotPrice/hr | $pilotPriceDay/day',
                              style: GoogleFonts.poppins(fontSize: 15, color: primaryColor, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // INFO BOX
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  border: Border.all(color: primaryColor, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Minimum booking duration 1 hour. Can book more.',
                        style: GoogleFonts.poppins(fontSize: 13, color: primaryColor, fontWeight: FontWeight.w500, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // BOOKING FORM
              Form(
                key: formKey,
                child: Column(
                  children: [
                    // Date Picker
                    buildTile(
                      title: 'Select Date',
                      value: selectedDate != null ? DateFormat('dd MMM yyyy').format(selectedDate!) : null,
                      icon: Icons.calendar_today,
                      onTap: pickDate,
                    ),
                    const SizedBox(height: 16),
                    // Start Time Picker
                    buildTile(
                      title: 'Select Start Time',
                      value: startTime != null ? startTime!.format(context) : null,
                      icon: Icons.access_time,
                      onTap: pickStartTime,
                    ),
                    const SizedBox(height: 16),
                    // End Time Picker
                    buildTile(
                      title: 'Select End Time',
                      value: endTime != null ? endTime!.format(context) : null,
                      icon: Icons.access_time_outlined,
                      onTap: pickEndTime,
                      isError: validateTimeSelection() != null && startTime != null && endTime != null,
                    ),
                    const SizedBox(height: 16),
                    // Duration Display
                    buildDurationDisplay(),
                    const SizedBox(height: 16),
                    // Location Field
                    buildTextField(
                      label: 'Enter Location',
                      icon: Icons.location_on,
                      controller: locationController,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Location is required';
                        if (v.length < 3) return 'Location must be at least 3 characters';
                        return null;
                      },
                    ),
                    // Contact Number Field
                    buildTextField(
                      label: 'Contact Number',
                      icon: Icons.phone,
                      controller: contactController,
                      type: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Contact number is required';
                        final digitsOnly = v.replaceAll(RegExp(r'\D'), '');
                        if (digitsOnly.length != 10) return 'Mobile number must be 10 digits';
                        final firstDigit = digitsOnly.substring(0, 1);
                        if (!RegExp(r'[6-9]').hasMatch(firstDigit)) return 'Enter a valid Indian mobile number';
                        return null;
                      },
                    ),
                    // Buyer Info (Read-only)
                    if (!isLoadingBuyer)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: successColor.withOpacity(0.1),
                          border: Border.all(color: successColor, width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: successColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Booking as ${buyerNameController.text}',
                                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    buyerEmailController.text,
                                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                    // BOOK NOW BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading || isLoadingBuyer ? null : submitBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          disabledBackgroundColor: Colors.grey[400],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : Text(
                          'Book Now',
                          style: GoogleFonts.poppins(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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