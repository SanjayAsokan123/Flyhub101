import 'package:flutter/material.dart';
import 'package:flyhub/AppointmentDetails.dart';
import 'package:google_fonts/google_fonts.dart';

class Bookingconformation extends StatefulWidget {
  const Bookingconformation({super.key});

  @override
  State<Bookingconformation> createState() => _BookingconformationState();
}

class _BookingconformationState extends State<Bookingconformation> {
  final bool pickup = true;
  final String date = "2025-06-19";
  final String time = "11:29 AM";
  final String cost = "₹12500";
  final String referenceId = "#123456";

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
                    'Booking Confirmation',
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
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () async {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Appointmentdetails()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xff7057FF),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            "View Appointment Details",
            style: GoogleFonts.lexend(fontSize: 16, color: Colors.white),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Confirmation Icon & Message
            Column(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.greenAccent[400],
                ),
                SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    text: 'Booking ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Confirmed!',
                        style: TextStyle(color: Colors.purple),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Thank you! Your drone service appointment is now confirmed.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            SizedBox(height: 30),

            // Drone Service Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Drone Service",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.teal),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "SkyTech Drones",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            "Coimbatore, Koothampoondi,\nTamil Nadu - 637202",
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),

            // Date & Time Row
            Row(
              children: [
                _infoBox("Date", date),
                SizedBox(width: 16),
                _infoBox("Time", time),
              ],
            ),
            SizedBox(height: 24),

            // Pickup Option
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pickup Option",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Do you need a home pickup?"),
                        Text(
                          pickup ? "Yes" : "No",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Switch(value: pickup, onChanged: null),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),

            // Cost & Ref ID
            Row(
              children: [
                _infoBox("Estimated Cost", cost),
                SizedBox(width: 16),
                _infoBox("Reference ID", referenceId),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22.0),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Color(0xff09ADAC),
                ),
                child: Text(
                  "Add to Calendar",
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            Text(
              "You will receive a notification 24 hours before your appointment.",
              style: GoogleFonts.lexend(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xff8B98B4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
