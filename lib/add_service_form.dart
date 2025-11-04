import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddServiceForm extends StatefulWidget {
  final String sellerId; // ✅ sellerId from SellerPage
  const AddServiceForm({required this.sellerId, super.key});

  @override
  State<AddServiceForm> createState() => _AddServiceFormState();
}

class _AddServiceFormState extends State<AddServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final Color themeColor = const Color(0xFF1A0A5B);
  final picker = ImagePicker();

  File? imageFile;
  bool _isSubmitting = false;

  String name = '';
  String specificDrone = '';
  int experience = 0;
  String location = '';
  String description = '';
  double? price;

  final String graphqlUrl = "http://192.168.0.180:5001/graphql";

  /// 🖼 Pick Image
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() => imageFile = File(pickedFile.path));
    }
  }

  /// 🔐 Ensure Firebase Auth
  Future<void> _ensureFirebaseAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }

  /// ☁️ Upload Image to Firebase
  Future<String> _uploadImageToFirebase(File file) async {
    await _ensureFirebaseAuth();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? "unknown";
      final ref = FirebaseStorage.instance
          .ref()
          .child("services/${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg");

      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();

      debugPrint("✅ Uploaded image: $url");
      return url;
    } catch (e) {
      debugPrint("❌ Firebase upload failed: $e");
      throw Exception("Image upload failed: $e");
    }
  }

  /// 🚀 Submit GraphQL Mutation
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    try {
      String imageUrl =
          "https://via.placeholder.com/300x200.png?text=${Uri.encodeComponent(name)}";

      if (imageFile != null) {
        imageUrl = await _uploadImageToFirebase(imageFile!);
      }

      final client = GraphQLClient(
        link: HttpLink(graphqlUrl),
        cache: GraphQLCache(store: InMemoryStore()),
      );

      final mutation = gql("""
        mutation CreateService(\$input: ServiceInput!) {
          createService(input: \$input) {
            serviceId
            name
            specificDrone
            experience
            location
            description
            price
            image
            status
            sellerId
          }
        }
      """);

      final variables = {
        'input': {
          'name': name,
          'specificDrone': specificDrone,
          'experience': experience,
          'location': location,
          'description': description,
          'price': price,
          'image': imageUrl,
          'sellerId': widget.sellerId,
        },
      };

      final result = await client.mutate(
        MutationOptions(document: mutation, variables: variables),
      );

      if (result.hasException) {
        final errorMsg = result.exception!.graphqlErrors.isNotEmpty
            ? result.exception!.graphqlErrors.first.message
            : result.exception!.linkException.toString();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $errorMsg"), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Service added successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Unexpected error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Drone Service", style: TextStyle(color: themeColor)),
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
              /// 🖼 Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: themeColor.withOpacity(0.4), width: 1.3),
                  ),
                  child: imageFile == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: themeColor, size: 50),
                      const SizedBox(height: 8),
                      Text("Tap to upload image",
                          style: TextStyle(
                              color: themeColor.withOpacity(0.7),
                              fontWeight: FontWeight.w500)),
                    ],
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(imageFile!, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              /// ✍️ Input Fields
              _buildTextField("Service Name",
                  icon: Icons.design_services, onSaved: (v) => name = v!),
              _buildTextField("Specific Drone (Model)",
                  icon: Icons.flight, onSaved: (v) => specificDrone = v!),
              _buildTextField("Experience (in years)",
                  icon: Icons.work,
                  keyboardType: TextInputType.number,
                  onSaved: (v) => experience = int.tryParse(v ?? "0") ?? 0),
              _buildTextField("Location",
                  icon: Icons.location_on, onSaved: (v) => location = v!),
              _buildTextField("Description",
                  icon: Icons.notes, onSaved: (v) => description = v!, maxLines: 3),
              _buildTextField("Price (₹)",
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                  onSaved: (v) => price = double.tryParse(v ?? "0")),

              const SizedBox(height: 25),

              /// 🟢 Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Submit Service",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "Your drone service will appear after admin approval.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🧩 Custom TextField Builder
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
            borderSide: BorderSide(color: themeColor),
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: themeColor.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? "Please enter $label" : null,
        onSaved: onSaved,
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }
}
