import 'package:flutter/material.dart';

class RegistrationDetails extends StatefulWidget {
  const RegistrationDetails({super.key});

  @override
  State<RegistrationDetails> createState() => _RegistrationDetailsState();
}

class _RegistrationDetailsState extends State<RegistrationDetails> {
  final _formKey = GlobalKey<FormState>();

  // Form state variables
  String? name;
  String? address;
  String? phone;
  String? city;
  final services = {
    'Crop Spraying': false,
    'Mapping': false,
    'Land Survey': false,
    'Delivery': false,
    'Photography': false,
    'Videography': false,
    'Inspection': false,
    'Security': false,
  };

  final List<String> cities = ['City 1', 'City 2', 'City 3'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Container(
          width: 370,
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.arrow_back),
                      SizedBox(width: 8),
                      Text(
                        'Registration Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Name Field
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Name *',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => name = val,
                  ),
                  SizedBox(height: 16),

                  // Address Field
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Address *',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => address = val,
                  ),
                  SizedBox(height: 16),

                  // Phone Field
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Phone no *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: (val) => phone = val,
                  ),
                  SizedBox(height: 16),

                  // City Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select City *',
                      border: OutlineInputBorder(),
                    ),
                    items: cities
                        .map((c) => DropdownMenuItem(
                      child: Text(c),
                      value: c,
                    ))
                        .toList(),
                    onChanged: (val) => setState(() => city = val),
                  ),
                  SizedBox(height: 20),

                  Text(
                    'Select Your service',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  SizedBox(height: 8),

                  // Checkbox Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    childAspectRatio: 5,
                    children: services.keys.map((key) {
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(key, style: TextStyle(fontSize: 14)),
                        value: services[key],
                        onChanged: (val) {
                          setState(() => services[key] = val ?? false);
                        },
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8763FF),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Continue',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          // Handle form submission logic
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
