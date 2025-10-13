import 'dart:io';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';

class AddDroneRentalForm extends StatefulWidget {
  @override
  _AddDroneRentalFormState createState() => _AddDroneRentalFormState();
}

class _AddDroneRentalFormState extends State<AddDroneRentalForm> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String brand = '';
  String uin = '';
  String location = '';
  String description = '';
  double? priceperHour;
  double? priceperDay;
  File? imageFile;

  bool _isSubmitting = false;
  final picker = ImagePicker();

  final TextEditingController perHourController = TextEditingController();
  final TextEditingController perDayController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  final String graphqlUrl = "http://192.168.1.45:4000/graphql";
  final Color themeColor = const Color(0xFF1A0A5B);

  @override
  void initState() {
    super.initState();
    perHourController.addListener(_updatePerDay);
  }

  @override
  void dispose() {
    perHourController.dispose();
    perDayController.dispose();
    locationController.dispose();
    super.dispose();
  }

  void _updatePerDay() {
    if (perHourController.text.isEmpty) {
      perDayController.text = '';
      return;
    }
    final hourValue = double.tryParse(perHourController.text);
    if (hourValue != null) {
      final dayValue = hourValue * 24;
      perDayController.text = dayValue.toStringAsFixed(2);
    } else {
      perDayController.text = '';
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    final HttpLink link = HttpLink(graphqlUrl);
    final client = GraphQLClient(
      link: link,
      cache: GraphQLCache(store: InMemoryStore()),
    );

    final String imageUrl =
        "https://via.placeholder.com/300x200.png?text=${Uri.encodeComponent(name)}";

    final mutation = gql("""
      mutation AddRental(\$input: RentalInput!) {
        addRental(input: \$input) {
          id
          name
          brand
          location
          pricePerHour
          pricePerDay
          description
          additionalInfo
          aboutItem
        }
      }
    """);

    final options = MutationOptions(
      document: mutation,
      variables: {
        'input': {
          'name': name,
          'brand': brand,
          'location': location,
          'pricePerHour': priceperHour,
          'pricePerDay': priceperDay,
          'description': description,
          'additionalInfo': '',
          'aboutItem': '',
        },
      },
    );

    try {
      final result = await client.mutate(options);

      if (result.hasException) {
        final errorMsg = result.exception!.graphqlErrors.isNotEmpty
            ? result.exception!.graphqlErrors.first.message
            : "Network error or invalid mutation name";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $errorMsg"), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Rental Drone submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unexpected Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        Text("Add Drone for Rental", style: TextStyle(color: themeColor)),
        backgroundColor: Colors.white,
        foregroundColor: themeColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: imageFile == null
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 50, color: themeColor),
                        SizedBox(height: 8),
                        Text("Tap to upload image"),
                      ],
                    ),
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(imageFile!, fit: BoxFit.cover),
                  ),
                ),
              ),
              SizedBox(height: 16),

              _buildTextField(
                "Drone Name",
                icon: Icons.airplanemode_active,
                onSaved: (v) => name = v!,
              ),
              _buildTextField(
                "Brand",
                icon: Icons.business,
                onSaved: (v) => brand = v!,
              ),
              _buildTextField(
                "UIN Number",
                icon: Icons.qr_code,
                onSaved: (v) => uin = v!,
              ),
              _buildTextField(
                "Location",
                icon: Icons.location_on,
                controller: locationController,
                onSaved: (v) => location = v!,
              ),
              _buildTextField(
                "Price Per Hour (₹)",
                icon: Icons.access_time,
                controller: perHourController,
                keyboardType: TextInputType.number,
                onSaved: (v) => priceperHour = double.tryParse(v!),
              ),
              _buildTextField(
                "Price Per Day (₹)",
                icon: Icons.calendar_today,
                controller: perDayController,
                readOnly: true,
                onSaved: (v) => priceperDay = double.tryParse(v!),
              ),
              _buildTextField(
                "Description",
                icon: Icons.description,
                onSaved: (v) => description = v!,
                maxLines: 3,
              ),
              SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Submit",
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, {
        required IconData icon,
        FormFieldSetter<String>? onSaved,
        TextEditingController? controller,
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
        bool readOnly = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: themeColor),
          labelText: label,
          labelStyle: TextStyle(color: themeColor),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: themeColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: themeColor.withOpacity(0.5)),
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Please enter $label' : null,
        onSaved: onSaved,
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }
}