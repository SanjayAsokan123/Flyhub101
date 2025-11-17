import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddDroneRentalForm extends StatefulWidget {
  final String sellerId;
  const AddDroneRentalForm({super.key,required this.sellerId});

  @override
  State<AddDroneRentalForm> createState() => _AddDroneRentalFormState();
}

class _AddDroneRentalFormState extends State<AddDroneRentalForm> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String brand = '';
  String location = '';
  String description = '';
  double? pricePerHour;
  double? pricePerDay;
  int quantity = 1;
  File? imageFile;
  bool _isSubmitting = false;

  final picker = ImagePicker();
  final Color themeColor = const Color(0xFF1A0A5B);
  final String graphqlUrl = "http://192.168.1.178:5001/graphql";

  /// 📸 Pick image
  Future<void> _pickImage() async {
    try {
      final pickedFile =
      await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (pickedFile != null) {
        setState(() => imageFile = File(pickedFile.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Failed to pick image: $e")));
    }
  }

  /// 🔐 Ensure Firebase authentication
  Future<void> _ensureFirebaseAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) await auth.signInAnonymously();
  }

  /// ☁️ Upload to Firebase Storage
  Future<String> _uploadImageToFirebase(File file) async {
    await _ensureFirebaseAuth();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? "anonymous";
      final ref = FirebaseStorage.instance
          .ref()
          .child("rental_drones/${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg");
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      debugPrint("✅ Uploaded Rental Drone Image: $url");
      return url;
    } catch (e) {
      throw Exception("Image upload failed: $e");
    }
  }

  /// 🚀 Submit form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    try {
      await _ensureFirebaseAuth();

      String imageUrl = imageFile != null
          ? await _uploadImageToFirebase(imageFile!)
          : "https://via.placeholder.com/300x200.png?text=${Uri.encodeComponent(name)}";

      final client = GraphQLClient(
        link: HttpLink(graphqlUrl),
        cache: GraphQLCache(store: InMemoryStore()),
      );

      final mutation = gql("""
        mutation CreateRental(\$input: RentalInput!) {
          createRental(input: \$input) {
            rentalId
            name
            brand
            location
            pricePerHour
            pricePerDay
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
              'location': location,
              'pricePerHour': pricePerHour,
              'pricePerDay': pricePerDay,
              'description': description,
              'image': imageUrl,
              'quantity': quantity,
              'sellerId': widget.sellerId,
            },
          },
        ),
      );

      if (result.hasException) {
        final msg = result.exception!.graphqlErrors.isNotEmpty
            ? result.exception!.graphqlErrors.first.message
            : "Network or server error";
        debugPrint("⚠️ GraphQL Error: $msg");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("❌ $msg"), backgroundColor: Colors.red));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Rental Drone Added Successfully!"),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// UI
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
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: themeColor.withOpacity(0.4), width: 1.3),
                  ),
                  child: imageFile == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: themeColor, size: 45),
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

              _buildTextField("Drone Name",
                  icon: Icons.airplanemode_active, onSaved: (v) => name = v!),
              _buildTextField("Brand", icon: Icons.business, onSaved: (v) => brand = v!),
              _buildTextField("Location", icon: Icons.location_on, onSaved: (v) => location = v!),
              _buildTextField("Price per Hour (₹)",
                  icon: Icons.schedule,
                  keyboardType: TextInputType.number,
                  onSaved: (v) => pricePerHour = double.tryParse(v ?? "0")),
              _buildTextField("Price per Day (₹)",
                  icon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                  onSaved: (v) => pricePerDay = double.tryParse(v ?? "0")),
              _buildTextField("Description",
                  icon: Icons.description, onSaved: (v) => description = v!, maxLines: 3),

              const SizedBox(height: 20),
              _buildTextField("Quantity",
                  icon: Icons.add_shopping_cart,
                  keyboardType: TextInputType.number,
                  onSaved: (v) => quantity = int.tryParse(v ?? "1") ?? 1),

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
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  )
                      : const Text("Submit Rental Drone",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Your rental drone will appear after admin approval.",
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
            borderSide: BorderSide(color: themeColor),
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: themeColor.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8),
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
