import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddDronePage extends StatefulWidget {
  final String sellerId;
  const AddDronePage({super.key, required this.sellerId});

  @override
  State<AddDronePage> createState() => _AddDronePageState();
}

class _AddDronePageState extends State<AddDronePage> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  String name = '';
  String brand = '';
  String uin = '';
  String description = '';
  double? price;
  File? imageFile;
  bool _isSubmitting = false;

  final String graphqlUrl = "http://192.168.0.180:5001/graphql";

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => imageFile = File(pickedFile.path));
      debugPrint("📸 Selected image: ${pickedFile.path}");
    }
  }

  /// ✅ Ensure Firebase Authentication
  Future<void> _ensureFirebaseAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      debugPrint("👤 No Firebase user, signing in anonymously...");
      await auth.signInAnonymously();
    } else {
      debugPrint("✅ Firebase user: ${auth.currentUser!.uid}");
    }
  }

  /// ✅ Check Firestore Role
  Future<bool> _isSeller() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final role = doc.data()?['role']?.toString().toLowerCase();

      debugPrint("🔍 Firestore role check: $role");
      return role == "seller";
    } catch (e) {
      debugPrint("⚠️ Role check error: $e");
      return false;
    }
  }

  /// ✅ Upload Image to Firebase Storage
  Future<String> _uploadImageToFirebase(File file) async {
    await _ensureFirebaseAuth();

    // Check if seller is allowed before upload
    if (!await _isSeller()) {
      throw Exception("Unauthorized: Only verified sellers can upload drones.");
    }

    try {
      final fileName =
          "drones/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";
      final ref = FirebaseStorage.instance.ref().child(fileName);

      debugPrint("🚀 Uploading drone image: $fileName");

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint("✅ Firebase upload complete: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      debugPrint("❌ Upload failed: $e");
      rethrow;
    }
  }

  /// ✅ Submit Drone Form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);

    try {
      await _ensureFirebaseAuth();

      if (!await _isSeller()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("❌ Only verified sellers can upload drones."),
          backgroundColor: Colors.red,
        ));
        setState(() => _isSubmitting = false);
        return;
      }

      String imageUrl = "";
      if (imageFile != null) {
        imageUrl = await _uploadImageToFirebase(imageFile!);
      } else {
        imageUrl =
        "https://via.placeholder.com/400x300.png?text=${Uri.encodeComponent(name)}";
      }

      final HttpLink httpLink = HttpLink(graphqlUrl);
      final GraphQLClient client = GraphQLClient(
        link: httpLink,
        cache: GraphQLCache(store: InMemoryStore()),
      );

      final mutation = gql("""
        mutation CreateDrone(\$input: DroneInput!) {
          createDrone(input: \$input) {
            droneId
            name
            brand
            price
            status
            image
          }
        }
      """);

      final variables = {
        "input": {
          "name": name,
          "brand": brand,
          "uin": uin,
          "price": price,
          "description": description,
          "image": imageUrl,
          "status": "pending",
          "sellerId": widget.sellerId,
        }
      };

      final result = await client.mutate(
        MutationOptions(document: mutation, variables: variables),
      );

      if (result.hasException) {
        final err = result.exception!.graphqlErrors.isNotEmpty
            ? result.exception!.graphqlErrors.first.message
            : result.exception!.linkException.toString();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("❌ Error: $err")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Drone submitted successfully!"),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("⚠️ Submit error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Drone"),
        backgroundColor: const Color(0xFF7F1DBA),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
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
              _buildTextField("Drone Name", (v) => name = v!),
              _buildTextField("Brand", (v) => brand = v!),
              _buildTextField("UIN (optional)", (v) => uin = v!),
              _buildTextField("Price (₹)", (v) => price = double.tryParse(v!) ?? 0,
                  keyboardType: TextInputType.number),
              _buildTextField("Description", (v) => description = v!, maxLines: 3),
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
                    "Submit Drone",
                    style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontSize: 16,
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

  Widget _buildTextField(
      String label,
      FormFieldSetter<String> onSaved, {
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
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (v) =>
        (v == null || v.isEmpty) && !label.contains("optional")
            ? "Please enter $label"
            : null,
        onSaved: onSaved,
      ),
    );
  }
}
