import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../CommonClass/ApiClass.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final ApiClass api = ApiClass();

class PilotBookNowPage extends StatefulWidget {
  final Map<String, dynamic> pilot;
  final bool isBuyerPilot;
  final String pilotId;

  const PilotBookNowPage({
    super.key,
    required this.pilot,
    this.isBuyerPilot = false,
    required this.pilotId,
  });

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
  final Color warningColor = const Color(0xFFFF6B6B);
  final Color successColor = const Color(0xFF51CF66);
  final Color buyerColor = const Color(0xFF4C1D95); // Purple for buyer pilots
  final Color sellerColor = const Color(0xFF1A0A5B); // Original blue for seller pilots

  @override
  void initState() {
    super.initState();
    loadBuyerInfo();

    // Pre-fill location if available
    final pilotLocation = widget.pilot['location'] ?? '';
    if (pilotLocation.isNotEmpty) {
      locationController.text = pilotLocation;
    }

    // Pre-fill contact if available from pilot info
    final pilotPhone = widget.pilot['contactPhone'] ?? widget.pilot['newphoneNumber'] ?? '';
    if (pilotPhone.isNotEmpty) {
      contactController.text = pilotPhone;
    }
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
            primary: widget.isBuyerPilot ? buyerColor : sellerColor,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: widget.isBuyerPilot ? buyerColor : sellerColor,
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
            primary: widget.isBuyerPilot ? buyerColor : sellerColor,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: widget.isBuyerPilot ? buyerColor : sellerColor,
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
            primary: widget.isBuyerPilot ? buyerColor : sellerColor,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: widget.isBuyerPilot ? buyerColor : sellerColor,
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

    final timeError = validateTimeSelection();
    if (timeError != null) {
      showSnack(timeError, isError: true);
      return;
    }

    try {
      setState(() => isLoading = true);

      // Format dates and times
      final rentalDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      final rentalStart = '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}';
      final rentalEnd = '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';

      // Use the correct pilot ID from the widget
      final pilotId = widget.pilotId;

      // Check if we have all required fields
      if (pilotId.isEmpty) {
        showSnack('Invalid pilot information.', isError: true);
        setState(() => isLoading = false);
        return;
      }

      if (buyerIdController.text.isEmpty || buyerNameController.text.isEmpty) {
        showSnack('Please complete your buyer profile.', isError: true);
        setState(() => isLoading = false);
        return;
      }

      debugPrint('Booking Pilot:');
      debugPrint('  Pilot ID: $pilotId');
      debugPrint('  Is Buyer Pilot: ${widget.isBuyerPilot}');
      debugPrint('  Buyer ID: ${buyerIdController.text}');
      debugPrint('  Buyer Name: ${buyerNameController.text}');
      debugPrint('  Date: $rentalDate');
      debugPrint('  Time: $rentalStart to $rentalEnd');
      debugPrint('  Location: ${locationController.text}');
      debugPrint('  Contact: ${contactController.text}');

      // In PilotBookNowPage.dart, submitBooking method:

      final result = await api.bookPilot(
        pilotId: pilotId,
        buyerId: buyerIdController.text.trim(),
        buyerName: buyerNameController.text.trim(),
        buyerEmail: buyerEmailController.text.trim(),
        contact: contactController.text.trim(),
        location: locationController.text.trim(),
        date: rentalDate,
        startTime: rentalStart,
        endTime: rentalEnd,
        isBuyerPilot: widget.isBuyerPilot, // Add this
      );

      setState(() => isLoading = false);

      if (result == null) {
        showSnack('Booking failed: No response from server', isError: true);
        return;
      }

      if (result['success'] == true) {
        showSnack('Pilot booked successfully!');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, true);
      } else {
        showSnack(result['message'] ?? 'Booking failed.', isError: true);
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
        backgroundColor: isError ? warningColor : (widget.isBuyerPilot ? buyerColor : sellerColor),
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
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(icon, color: widget.isBuyerPilot ? buyerColor : sellerColor, size: 20),
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
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isError ? warningColor.withOpacity(0.1) : Colors.grey[100],
          border: Border.all(
            color: isError ? warningColor : Colors.grey[300]!,
            width: isError ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isError ? warningColor : (widget.isBuyerPilot ? buyerColor : sellerColor),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? title,
                style: GoogleFonts.poppins(
                  color: value == null ? Colors.grey[600] : (isError ? warningColor : Colors.black87),
                  fontSize: 15,
                  fontWeight: value != null ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget buildDurationDisplay() {
    final duration = calculateBookingDuration();
    final durationStr = duration > 0 ? '${duration.toStringAsFixed(2)} hours' : 'Select time';
    final isValid = duration >= 1;
    final timeError = validateTimeSelection();
    final hasError = timeError != null && startTime != null && endTime != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: duration == 0
            ? Colors.grey[100]
            : (hasError ? warningColor.withOpacity(0.1) : successColor.withOpacity(0.1)),
        border: Border.all(
          color: duration == 0 ? Colors.grey[300]! : (hasError ? warningColor : successColor),
          width: duration == 0 ? 1 : 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            duration == 0
                ? Icons.schedule
                : (hasError ? Icons.error_outline : Icons.check_circle),
            color: duration == 0 ? Colors.grey[600] : (hasError ? warningColor : successColor),
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
                    color: duration == 0 ? Colors.grey[600] : (hasError ? warningColor : successColor),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      timeError!,
                      style: GoogleFonts.poppins(fontSize: 11, color: warningColor),
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
    String? imageUrl;

    // Handle images based on pilot type
    if (widget.isBuyerPilot) {
      // For buyer pilots, use profilePhoto
      if (widget.pilot['profilePhoto'] != null &&
          widget.pilot['profilePhoto'] is Map &&
          widget.pilot['profilePhoto']['url'] != null) {
        imageUrl = widget.pilot['profilePhoto']['url'];
      }
    } else {
      // For seller pilots, use certifications
      if (widget.pilot['certifications'] != null &&
          widget.pilot['certifications'] is List &&
          widget.pilot['certifications'].isNotEmpty) {
        final firstCert = widget.pilot['certifications'][0];
        if (firstCert is Map && firstCert['url'] != null) {
          imageUrl = firstCert['url'];
        }
      }
    }

    final name = widget.pilot['pilotName'] ?? 'Pilot';
    final initials = name.isNotEmpty ? name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join('').toUpperCase() : 'P';
    final double avatarSize = size;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: avatarSize,
          height: avatarSize,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: SizedBox(
                  width: avatarSize * 0.4,
                  height: avatarSize * 0.4,
                  child: CircularProgressIndicator(strokeWidth: 2, color: widget.isBuyerPilot ? buyerColor : sellerColor),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: (widget.isBuyerPilot ? buyerColor : sellerColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.poppins(
                    color: widget.isBuyerPilot ? buyerColor : sellerColor,
                    fontSize: avatarSize / 2.5,
                    fontWeight: FontWeight.w600,
                  ),
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
        color: widget.isBuyerPilot ? buyerColor : sellerColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: avatarSize / 2.5,
            fontWeight: FontWeight.w600,
          ),
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

    // Get contact info for display
    final contactPerson = widget.pilot['contactPerson'] ?? '';
    final contactEmail = widget.pilot['contactEmail'] ?? widget.pilot['newemail'] ?? '';
    final contactPhone = widget.pilot['contactPhone'] ?? widget.pilot['newphoneNumber'] ?? '';

    // Determine current color based on pilot type
    final currentPrimaryColor = widget.isBuyerPilot ? buyerColor : sellerColor;

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
                  gradient: LinearGradient(
                    colors: [currentPrimaryColor, currentPrimaryColor.withOpacity(0.9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: currentPrimaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        if (widget.isBuyerPilot)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Text(
                              'Buyer Pilot',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Text(
                              'Seller Pilot',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Book Your Pilot',
                      style: GoogleFonts.poppins(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Schedule a professional pilot for your needs',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withOpacity(0.9), height: 1.4),
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  pilotName,
                                  style: GoogleFonts.poppins(fontSize: 18, color: currentPrimaryColor, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Pilot ID badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: currentPrimaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'ID: ${widget.pilotId}',
                                  style: GoogleFonts.poppins(fontSize: 10, color: currentPrimaryColor, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pilotCompany,
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Contact info if available
                          if (contactPerson.isNotEmpty || contactEmail.isNotEmpty || contactPhone.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (contactPerson.isNotEmpty)
                                    Text(
                                      'Contact: $contactPerson',
                                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (contactPhone.isNotEmpty)
                                    Text(
                                      'Phone: $contactPhone',
                                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
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
                                      color: currentPrimaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      showFullSkills ? 'Read Less' : 'Read More',
                                      style: GoogleFonts.poppins(
                                        color: currentPrimaryColor,
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
                              '₹$pilotPrice/hr | ₹$pilotPriceDay/day',
                              style: GoogleFonts.poppins(fontSize: 15, color: currentPrimaryColor, fontWeight: FontWeight.w600),
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
                  color: currentPrimaryColor.withOpacity(0.1),
                  border: Border.all(color: currentPrimaryColor, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: currentPrimaryColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Minimum booking duration 1 hour. Can book more.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: currentPrimaryColor,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
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

                    // Start Time Picker
                    buildTile(
                      title: 'Select Start Time',
                      value: startTime != null ? startTime!.format(context) : null,
                      icon: Icons.access_time,
                      onTap: pickStartTime,
                    ),

                    // End Time Picker
                    buildTile(
                      title: 'Select End Time',
                      value: endTime != null ? endTime!.format(context) : null,
                      icon: Icons.access_time_outlined,
                      onTap: pickEndTime,
                      isError: validateTimeSelection() != null && startTime != null && endTime != null,
                    ),

                    // Duration Display
                    buildDurationDisplay(),

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
                        margin: const EdgeInsets.only(bottom: 16),
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: currentPrimaryColor),
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
                          backgroundColor: currentPrimaryColor,
                          disabledBackgroundColor: Colors.grey[400],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                          shadowColor: currentPrimaryColor.withOpacity(0.3),
                        ),
                        child: isLoading
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Book Now',
                              style: GoogleFonts.poppins(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
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