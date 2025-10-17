import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class AddDroneForm extends StatefulWidget {
  const AddDroneForm({super.key});

  @override
  State<AddDroneForm> createState() => _AddDroneFormState();
}

class _AddDroneFormState extends State<AddDroneForm> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String brand = '';
  String uin = '';
  String description = '';
  double? price;
  File? imageFile;

  bool _isSubmitting = false;
  final picker = ImagePicker();

  final String graphqlUrl = "http://192.168.1.178:5001/graphql";
  final String uploadUrl = "http://192.168.1.178:5001/upload";
  final Color themeColor = const Color(0xFF1A0A5B);

  /// 🧩 Pick an Image
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

  /// ☁️ Upload Image to Server
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

  /// 🚀 Submit Drone Details to GraphQL API
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);
    try {
      // Upload image if available
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
        mutation CreateDrone(\$input: DroneInput!) {
          createDrone(input: \$input) {
            id
            name
            brand
            uin
            price
            description
            image
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
            content: Text("✅ Drone added successfully!"),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Add Drone for Sale", style: TextStyle(color: themeColor)),
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
                        Text(
                          "Tap to upload image",
                          style: TextStyle(
                            color: themeColor.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
              _buildTextField("Price (₹)",
                  icon: Icons.currency_rupee_rounded,
                  keyboardType: TextInputType.number,
                  onSaved: (v) => price = double.tryParse(v ?? "0")),
              _buildTextField("Description",
                  icon: Icons.description_outlined,
                  onSaved: (v) => description = v!.trim(),
                  maxLines: 3),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    "Submit",
                    style:
                    TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Your drone will appear in the FlyHub marketplace after admin approval.",
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
            borderSide:
            BorderSide(color: themeColor.withValues(alpha: 0.5)),
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
