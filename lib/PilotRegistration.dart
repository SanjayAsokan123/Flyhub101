import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Pilotregistration extends StatefulWidget {
  const Pilotregistration({super.key});

  @override
  State<Pilotregistration> createState() => _PilotregistrationState();
}

class _PilotregistrationState extends State<Pilotregistration> {
  String dgcaApproval = '';

  Map<String, bool> droneCategories = {
    'Rotor Craft': false,
    'Fixed Wing': false,
    'Hybrid': false,
  };

  Map<String, bool> selectedCategories = {
    'Micro (250g - 2kgs)': false,
    'Small (2kgs - 25kgs)': false,
    'Medium (25kgs - 150kgs)': false,
    'Large (> 150kgs)': false,
  };

  Map<String, bool> roleCategories = {
    'Drone / UAV Pilot': false,
    'Drone Instructor': false,
    'GIS / UAV Date Analysis': false,
    'UAV Hardware Engineer': false,
  };

  Map<String, bool> subCategories = {
    'Agri Drone': false,
    'Mapping Drone': false,
    'FPV Drone': false,
  };

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
                    'Pilot Registration',
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
          onPressed: () async {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xff7057FF),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            "Continue",
            style: GoogleFonts.lexend(fontSize: 16, color: Colors.white),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
        // Extra bottom padding for button
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Do you have DGCA Approval *",
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 5),

            Row(
              children: [
                Radio(
                  value: '1',
                  groupValue: dgcaApproval,
                  onChanged: (val) {
                    setState(() {
                      dgcaApproval = val as String;

                    });
                  },
                ),

                Text(
                  "Yes",
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: dgcaApproval == "1" ? FontWeight.bold : null,
                    color: Colors.black,
                  ),
                ),

                Radio(
                  value: '0',
                  groupValue: dgcaApproval,
                  onChanged: (val) {
                    setState(() {
                      dgcaApproval = val as String;

                    });
                  },
                ),

                Text(
                  "No",
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: dgcaApproval == "0" ? FontWeight.bold : null,
                    color: Colors.black,
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),

            Text(
              "Add Drone Category *",
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),

            ...droneCategories.keys.map((category) {
              return CheckboxListTile(
                value: droneCategories[category],
                onChanged: (value) {
                  setState(() {
                    droneCategories[category] = value!;
                  });
                },
                title: Text(category),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true, // Reduces overall height
                visualDensity: VisualDensity(horizontal: -4, vertical: -4), // Tighter spacing
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0), // Less padding
              );
            }),

            SizedBox(height: 10),

            Text(
              "Add Drone Category *",
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            ...selectedCategories.entries.map((entry) {
              final label = entry.key;
              final isSelected = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        selectedCategories[label] = value!;
                      });
                    },
                    title: Text(label),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (isSelected) _buildFormFields(label),
                ],
              );
            }),

            SizedBox(height: 10),

            Text(
              "Add Your role *",
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),

            ...roleCategories.keys.map((category) {
              return CheckboxListTile(
                value: roleCategories[category],
                onChanged: (value) {
                  setState(() {
                    roleCategories[category] = value!;
                  });
                },
                title: Text(category),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true, // Reduces overall height
                visualDensity: VisualDensity(horizontal: -4, vertical: -4), // Tighter spacing
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0), // Less padding
              );
            }),


            SizedBox(height: 10),

            Text(
              "Add Select Drone Sub-category *",
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),

            ...subCategories.keys.map((category) {
              return CheckboxListTile(
                value: subCategories[category],
                onChanged: (value) {
                  setState(() {
                    subCategories[category] = value!;
                  });
                },
                title: Text(category),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true, // Reduces overall height
                visualDensity: VisualDensity(horizontal: -4, vertical: -4), // Tighter spacing
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0), // Less padding
              );
            }),

          ],
        ),
      ),
    );
  }

  // Reusable form section
  Widget _buildFormFields(String label) {
    return Container(
      margin: EdgeInsets.only(left: 8, right: 8, bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTextField("RPC Number *"),
          _buildTextField("RPC Certificate Name *"),
          _buildTextField("Training Institute Name *"),
          Row(
            children: [
              Expanded(child: _buildTextField("Start Date *")),
              SizedBox(width: 10),
              Expanded(child: _buildTextField("Start Date *")),
            ],
          ),
          SizedBox(height: 12),
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      size: 30, color: Colors.grey),
                  SizedBox(height: 8),
                  Text("Upload PDF *",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          isDense: true,
        ),
      ),
    );
  }

}