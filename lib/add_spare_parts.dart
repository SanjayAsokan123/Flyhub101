import 'dart:io';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/env.dart';

class AddSparePartForm extends StatefulWidget {
  final String sellerId;
  const AddSparePartForm({required this.sellerId, super.key});

  @override
  _AddSparePartFormState createState() => _AddSparePartFormState();
}

class _AddSparePartFormState extends State<AddSparePartForm> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String brand = '';
  String description = '';
  double? price;
  int? quantity;
  File? imageFile;
  bool _isSubmitting = false;

  final picker = ImagePicker();
  final String graphqlUrl = EnvConfig.baseUrl;

  // 📸 Pick image
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => imageFile = File(pickedFile.path));
      debugPrint("📸 Picked spare part image: ${pickedFile.path}");
    }
  }

  /// ✅ Ensure Firebase user exists
  Future<void> _ensureFirebaseAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      debugPrint("👤 No Firebase user, signing in anonymously...");
      await auth.signInAnonymously();
    } else {
      debugPrint("✅ Firebase user: ${auth.currentUser!.uid}");
    }
  }

  /// ✅ Check Firestore role before upload
  Future<bool> _isSeller() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final role = doc.data()?['role']?.toString().toLowerCase();

      debugPrint("🔍 Firestore role: $role");
      return role == "seller";
    } catch (e) {
      debugPrint("⚠️ Role check failed: $e");
      return false;
    }
  }

  /// ✅ Upload image to Firebase
  Future<String> _uploadImageToFirebase(File file) async {
    await _ensureFirebaseAuth();
    if (!await _isSeller()) {
      throw Exception("Unauthorized: Only sellers can upload spare parts.");
    }

    try {
      final fileName =
          "spare_parts/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";
      final ref = FirebaseStorage.instance.ref().child(fileName);

      debugPrint("🚀 Uploading image: $fileName");

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint("✅ Uploaded: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      debugPrint("❌ Upload failed: $e");
      rethrow;
    }
  }

  // 🚀 Submit the form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);

    try {
      await _ensureFirebaseAuth();

      if (!await _isSeller()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("❌ Only verified sellers can add spare parts."),
          backgroundColor: Colors.red,
        ));
        setState(() => _isSubmitting = false);
        return;
      }

      String imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadImageToFirebase(imageFile!);
      } else {
        imageUrl =
        "https://via.placeholder.com/300x200.png?text=${Uri.encodeComponent(name)}";
      }

      final HttpLink link = HttpLink(graphqlUrl);
      final client = GraphQLClient(
        link: link,
        cache: GraphQLCache(store: InMemoryStore()),
      );

      // 🔹 GraphQL Mutation
      final mutation = gql("""
        mutation CreatePart(\$input: PartInput!) {
          createPart(input: \$input) {
            partId
            name
            brand
            price
            quantity
            description
            status
            image
            sellerId
          }
        }
      """);

      // 🔹 Variables
      final variables = {
        'input': {
          'name': name,
          'brand': brand,
          'price': price,
          'description': description,
          'image': imageUrl,
          'quantity': quantity ?? 1,
          'sellerId': widget.sellerId,
          'status': "pending",
        },
      };

      final result = await client.mutate(
        MutationOptions(document: mutation, variables: variables),
      );

      if (result.hasException) {
        final err = result.exception!.graphqlErrors.isNotEmpty
            ? result.exception!.graphqlErrors.first.message
            : result.exception!.linkException.toString();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $err")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Spare part added successfully!"),
          backgroundColor: Color(0xFF7F1DBA),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("⚠️ Error submitting part: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // 🧱 Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Spare Part"),
        backgroundColor: const Color(0xFF7F1DBA),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 🖼 Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: imageFile == null
                      ? const Center(
                    child: Icon(Icons.image,
                        size: 60, color: Color(0xFF7F1DBA)),
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(imageFile!, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildTextField("Name", onSaved: (v) => name = v!),
              _buildTextField("Brand", onSaved: (v) => brand = v!),
              _buildTextField(
                "Price (₹)",
                keyboardType: TextInputType.number,
                onSaved: (v) => price = double.tryParse(v!),
              ),
              _buildTextField(
                "Quantity",
                keyboardType: TextInputType.number,
                onSaved: (v) => quantity = int.tryParse(v!),
              ),
              _buildTextField(
                "Description",
                onSaved: (v) => description = v!,
                maxLines: 3,
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7F1DBA),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Submit Part",
                    style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🧩 Reusable field builder
  Widget _buildTextField(
      String label, {
        required FormFieldSetter<String> onSaved,
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Please enter $label' : null,
        onSaved: onSaved,
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }
}
