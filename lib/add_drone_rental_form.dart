import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class AddDroneRentalForm extends StatefulWidget {
  const AddDroneRentalForm({super.key});

  @override
  State<AddDroneRentalForm> createState() => _AddDroneRentalFormState();
}

class _AddDroneRentalFormState extends State<AddDroneRentalForm> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String brand = '';
  String uin = '';
  String description = '';
  double? price;
  String duration = 'Per Day';
  bool withPilot = false;
  bool insured = false;
  bool availableToday = true;
  File? imageFile;

  bool _isSubmitting = false;
  final picker = ImagePicker();

  final String graphqlUrl = "http://192.168.1.178:5001/graphql";
  final String uploadUrl = "http://192.168.1.178:5001/upload";
  final Color themeColor = const Color(0xFF1A0A5B);

  /// 🧩 Image Picker
  Future<void> _pickImage() async {
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => imageFile = File(pickedFile.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to pick image: $e")),
      );
    }
  }

  /// ☁️ Upload Image
  Future<String?> _uploadImage(File image) async {
    try {
      final uri = Uri.parse(uploadUrl);
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        image.path,
        filename: path.basename(image.path),
      ));

      final response = await request.send();
      if (response.statusCode == 200) {
        return await response.stream.bytesToString();
      } else {
        debugPrint("❌ Upload failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("⚠️ Upload error: $e");
      return null;
    }
  }

  /// 🚀 Submit Rental Drone Data
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);
    try {
      // Upload image first
      String? uploadedUrl;
      if (imageFile != null) {
        uploadedUrl = await _uploadImage(imageFile!);
      }

      final imageUrl = uploadedUrl ??
          "https://via.placeholder.com/300x200.png?text=${Uri.encodeComponent(name)}";

      final client = GraphQLClient(
        link: HttpLink(graphqlUrl),
        cache: GraphQLCache(store: InMemoryStore()),
      );

      final mutation = gql("""
        mutation CreateRentalDrone(\$input: RentalDroneInput!) {
          createRentalDrone(input: \$input) {
            id
            name
            brand
            uin
            price
            description
            image
            duration
            with_pilot
            insurance
            available_today
            status
          }
        }
      """);

      final result = await client.mutate(
        MutationOptions(
          document: mutation,
          variables: {
            'input': {
              'name': name,
              'brand': brand,
              'uin': uin,
              'price': price,
              'description': description,
              'image': imageUrl,
              'duration': duration,
              'with_pilot': withPilot,
              'insurance': insured,
              'available_today': availableToday,
              'status': "Available",
            },
          },
        ),
      );

      if (!mounted) return;

      if (result.hasException) {
        final msg = result.exception!.graphqlErrors.isNotEmpty
            ? result.exception!.graphqlErrors.first.message
            : "⚠️ Network/Server Error";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(msg)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: Colors.green,
              content: Text("✅ Rental drone added successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Add Drone for Rental", style: TextStyle(color: themeColor)),
        backgroundColor: Colors.white,
        foregroundColor: themeColor,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 📸 Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 170,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: themeColor.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: imageFile == null
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 45, color: themeColor),
                        const SizedBox(height: 8),
                        Text("Tap to upload image",
                            style: TextStyle(
                                color: themeColor.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(imageFile!, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              _buildTextField("Drone Name",
                  icon: Icons.airplanemode_active,
                  onSaved: (v) => name = v!.trim()),
              _buildTextField("Brand",
                  icon: Icons.business, onSaved: (v) => brand = v!.trim()),
              _buildTextField("UIN Number",
                  icon: Icons.qr_code_2_outlined, onSaved: (v) => uin = v!.trim()),
              _buildTextField("Price (₹/Day)",
                  icon: Icons.currency_rupee_rounded,
                  keyboardType: TextInputType.number,
                  onSaved: (v) => price = double.tryParse(v ?? "0")),
              _buildTextField("Description",
                  icon: Icons.description_outlined,
                  onSaved: (v) => description = v!.trim(),
                  maxLines: 3),

              const SizedBox(height: 15),

              // 🕒 Duration Dropdown
              DropdownButtonFormField<String>(
                value: duration,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.timer, color: themeColor),
                  labelText: "Rental Duration",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: ['Per Day', 'Per Week', 'Per Month']
                    .map((e) =>
                    DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => duration = val!),
              ),

              const SizedBox(height: 15),

              // 🚁 With Pilot Switch
              SwitchListTile(
                title: const Text("Includes Pilot"),
                secondary: Icon(Icons.flight_takeoff, color: themeColor),
                activeColor: themeColor,
                value: withPilot,
                onChanged: (val) => setState(() => withPilot = val),
              ),

              // 🛡️ Insurance Switch
              SwitchListTile(
                title: const Text("Insured Drone"),
                secondary: Icon(Icons.shield_moon, color: themeColor),
                activeColor: themeColor,
                value: insured,
                onChanged: (val) => setState(() => insured = val),
              ),

              // 📅 Availability Switch
              SwitchListTile(
                title: const Text("Available Today"),
                secondary: Icon(Icons.event_available, color: themeColor),
                activeColor: themeColor,
                value: availableToday,
                onChanged: (val) => setState(() => availableToday = val),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  )
                      : const Text("Submit",
                      style:
                      TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Your rental drone will appear in the FlyHub Rentals section after admin approval.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
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
            borderSide: BorderSide(color: themeColor.withValues(alpha: 0.5)),
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
