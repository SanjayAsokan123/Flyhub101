import 'package:flutter/material.dart';
import 'package:flyhub/BookingConformation.dart';
import 'package:google_fonts/google_fonts.dart';

class Bookservice extends StatefulWidget {
  const Bookservice({super.key});

  @override
  State<Bookservice> createState() => _BookserviceState();
}

class _BookserviceState extends State<Bookservice> {
  String? selectedDrone;
  String? selectedServiceCenter;
  DateTime? selectedDate;
  int selectedServiceIndex = 1; // Default to "Propeller Repair"

  final List<String> serviceTypes = [
    "Battery Replacement",
    "Propeller Repair",
    "Camera Calibration",
    "Software Update",
    "Full Diagnostic",
    "Custom Issue",
  ];

  final List<IconData> serviceIcons = [
    Icons.battery_charging_full,
    Icons.build,
    Icons.center_focus_strong,
    Icons.system_update,
    Icons.medical_services,
    Icons.bug_report,
  ];

  bool needsPickup = false;
  bool enableNotification = false;
  DateTime? reminderDate;
  final TextEditingController notesController = TextEditingController();

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
                    'Book a Service',
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
              MaterialPageRoute(builder: (context) => Bookingconformation()),
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
            "Book Service",
            style: GoogleFonts.lexend(fontSize: 16, color: Colors.white),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Drone Selection", style: GoogleFonts.lexend()),
            SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: selectedDrone,
              hint: Text("Select your drone", style: GoogleFonts.lexend()),
              items: ["Drone A", "Drone B", "Drone C"]
                  .map(
                    (drone) => DropdownMenuItem(
                      value: drone,
                      child: Text(drone, style: GoogleFonts.lexend()),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => selectedDrone = value),
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
            SizedBox(height: 20),
            Text("Service Type", style: GoogleFonts.lexend()),
            SizedBox(height: 10),

            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.5,
              children: List.generate(serviceTypes.length, (index) {
                bool isSelected = selectedServiceIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => selectedServiceIndex = index),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal[300] : Colors.white,
                      border: Border.all(
                        color: isSelected ? Colors.teal : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          serviceIcons[index],
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            serviceTypes[index],
                            style: GoogleFonts.lexend(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),

            SizedBox(height: 20),
            Text("Preferred Service Center", style: GoogleFonts.lexend()),
            SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: selectedServiceCenter,
              hint: Text(
                "Select a service center",
                style: GoogleFonts.lexend(),
              ),
              items: ["Center A", "Center B", "Center C"]
                  .map(
                    (center) => DropdownMenuItem(
                      value: center,
                      child: Text(center, style: GoogleFonts.lexend()),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => selectedServiceCenter = value),
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
            SizedBox(height: 20),
            Text("Appointment Date & Time", style: GoogleFonts.lexend()),
            SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined),
                    SizedBox(width: 10),
                    Text(
                      selectedDate == null
                          ? "Choose date"
                          : "${selectedDate!.toLocal()}".split(' ')[0],
                      style: GoogleFonts.lexend(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            Text(
              "Pickup Option",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Do you need a home pickup?"),
                    Text(
                      needsPickup ? "Yes" : "No",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: needsPickup,
                  onChanged: (value) {
                    setState(() {
                      needsPickup = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 20),

            // Additional Notes
            Text(
              "Additional Notes (Optional)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            TextFormField(
              controller: notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Enter any specific issues or requests",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Reminder
            Text("Reminder", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    reminderDate = picked;
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined),
                    SizedBox(width: 10),
                    Text(
                      reminderDate == null
                          ? "Choose date"
                          : "${reminderDate!.toLocal()}".split(' ')[0],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Enable Notification
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Enable Notification",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: enableNotification,
                  onChanged: (value) {
                    setState(() {
                      enableNotification = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
