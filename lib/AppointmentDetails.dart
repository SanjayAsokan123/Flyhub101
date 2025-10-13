import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Appointmentdetails extends StatefulWidget {
  const Appointmentdetails({super.key});

  @override
  State<Appointmentdetails> createState() => _AppointmentdetailsState();
}

class _AppointmentdetailsState extends State<Appointmentdetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: SafeArea(
          child: Material(
            elevation: 3,
            shadowColor: Colors.black.withOpacity(0.4),
            child: Container(
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Appointment Details',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appointment Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Upcoming",
                      style: GoogleFonts.lexend(color: Colors.grey),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Appointment ID: #123456",
                      style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'https://i.pravatar.cc/100?img=2',
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Drone Details
            Text(
              "Drone Details",
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            _infoRow(
              Icons.airplanemode_active,
              "Drone ID: DRN-2034X",
              "DJI Mavic Air 2",
            ),
            SizedBox(height: 24),

            // Service Details
            Text(
              "Service Details",
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            _infoRow(
              Icons.build,
              "Propeller Repair, Battery Check",
              "SkyTech Drones, Coimbatore",
            ),
            SizedBox(height: 12),
            _infoRow(Icons.currency_rupee, "Estimated Cost ₹12500"),
            SizedBox(height: 12),
            _infoRow(Icons.verified_user, "Warranty: Valid till Aug 2025"),
            SizedBox(height: 24),

            // Appointment Time
            Text(
              "Appointment Time",
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            _infoRow(
              Icons.calendar_today,
              "July 15, 2025",
              "11:00 AM–12:00 PM",
            ),
            SizedBox(height: 12),
            _infoRow(
              Icons.location_on,
              "Pickup: Enabled",
              "123 Main Street, Coimbatore",
            ),
            SizedBox(height: 24),

            // Additional Notes
            Text(
              "Additional Notes",
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),

            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.15,
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Please check the battery calibration. Avoid replacing parts unless necessary.",
                style: GoogleFonts.lexend(color: Colors.black87),
              ),
            ),

            SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 18.0),
              decoration: BoxDecoration(
                color: Color(0xffF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text("Reschedule", style: GoogleFonts.lexend()),
              ),
            ),

            SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 18.0),
              decoration: BoxDecoration(
                color: Color(0xffF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text("Cancel Appointment", style: GoogleFonts.lexend()),
              ),
            ),

            SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 18.0),
              decoration: BoxDecoration(
                color: Color(0xffF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  "Contact Service Center",
                  style: GoogleFonts.lexend(),
                ),
              ),
            ),

            SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 18.0),
              decoration: BoxDecoration(
                color: Color(0xffF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  "View Location on Map",
                  style: GoogleFonts.lexend(),
                ),
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, [String? subtitle]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xffF1F3F3),
              borderRadius: BorderRadius.circular(8)
            ),
            child: Icon(icon, size: 24, color: Colors.black54)),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
