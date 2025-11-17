import 'dart:io';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddAccessoryForm extends StatefulWidget {
  final String sellerId;
  const AddAccessoryForm({super.key, required this.sellerId});

  @override
  _AddAccessoryFormState createState() => _AddAccessoryFormState();
}

class _AddAccessoryFormState extends State<AddAccessoryForm> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String brand = '';
  String description = '';
  double? price;
  int quantity = 1;
  File? imageFile;

  bool _isSubmitting = false;
  double _uploadProgress = 0.0;

  final picker = ImagePicker();
  final String graphqlUrl = "http://192.168.1.178:5001/graphql";
  final Color themeColor = const Color(0xFF1A0A5B);

  /// 📸 Pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() => imageFile = File(pickedFile.path));
    }
  }

  /// 🔐 Ensure Firebase authentication
  Future<void> _ensureFirebaseAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }

  /// ☁️ Upload image to Firebase Storage with progress tracking
  Future<String> _uploadImageToFirebase(File file) async {
    await _ensureFirebaseAuth();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? "unknown";
      final ref = FirebaseStorage.instance
          .ref()
          .child("accessories/${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg");

      final uploadTask = ref.putFile(file);
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress =
              snapshot.bytesTransferred / snapshot.totalBytes.toDouble();
        });
      });

      await uploadTask;
      final url = await ref.getDownloadURL();
      debugPrint("✅ Uploaded Accessory Image: $url");
      return url;
    } catch (e) {
      debugPrint("❌ Firebase Upload Error: $e");
      throw Exception("Image upload failed: $e");
    }
  }

  /// 🚀 Submit Accessory to GraphQL
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    try {
      await _ensureFirebaseAuth();

      String imageUrl =
          "https://via.placeholder.com/300x200.png?text=${Uri.encodeComponent(name)}";
      if (imageFile != null) {
        imageUrl = await _uploadImageToFirebase(imageFile!);
      }

      debugPrint("📤 Uploading Accessory:");
      debugPrint("SellerId: ${widget.sellerId}");
      debugPrint("Data: name=$name, brand=$brand, price=$price, qty=$quantity");

      final client = GraphQLClient(
        link: HttpLink(graphqlUrl),
        cache: GraphQLCache(store: InMemoryStore()),
      );

      final mutation = gql("""
        mutation CreateAccessory(\$input: AccessoryInput!) {
          createAccessory(input: \$input) {
            accessoryId
            name
            brand
            price
            description
            image
            quantity
            status
            sellerId
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
              'price': price,
              'description': description,
              'image': imageUrl,
              'quantity': quantity,
              'sellerId': widget.sellerId,
            },
          },
        ),
      );

      if (result.hasException) {
        debugPrint("❌ GraphQL Error: ${result.exception.toString()}");
        final errorMsg = result.exception!.graphqlErrors.isNotEmpty
            ? result.exception!.graphqlErrors.first.message
            : "Network error or invalid mutation";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $errorMsg"), backgroundColor: Colors.red),
        );
      } else {
        debugPrint("✅ Accessory Created Successfully!");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Accessory submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("⚠️ Unexpected Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Unexpected Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
        _uploadProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Add Accessory", style: TextStyle(color: themeColor)),
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
              /// 🖼 Image Picker + Upload Progress
              GestureDetector(
                onTap: _isSubmitting ? null : _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: themeColor.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: imageFile == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 45, color: themeColor),
                      const SizedBox(height: 8),
                      Text(
                        "Tap to upload image",
                        style: TextStyle(
                            color: themeColor.withOpacity(0.7),
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  )
                      : Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(imageFile!, fit: BoxFit.cover),
                      ),
                      if (_uploadProgress > 0 && _uploadProgress < 1)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.4),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: _uploadProgress,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              /// 📋 Input Fields
              _buildTextField("Accessory Name",
                  icon: Icons.build, onSaved: (v) => name = v!),
              _buildTextField("Brand",
                  icon: Icons.business, onSaved: (v) => brand = v!),
              _buildTextField("Price (₹)",
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                  onSaved: (v) => price = double.tryParse(v ?? "0")),
              _buildTextField("Quantity",
                  icon: Icons.add_shopping_cart,
                  keyboardType: TextInputType.number,
                  onSaved: (v) => quantity = int.tryParse(v ?? "1") ?? 1),
              _buildTextField("Description",
                  icon: Icons.description, onSaved: (v) => description = v!, maxLines: 3),

              const SizedBox(height: 25),

              /// 🔘 Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Submit Accessory",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                "Your accessory will appear in marketplace after admin approval.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🧩 Reusable TextField Builder
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
