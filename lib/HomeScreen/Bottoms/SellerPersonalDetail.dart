import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SellerPersonalDetailPage extends StatefulWidget {
  const SellerPersonalDetailPage({super.key});

  @override
  State<SellerPersonalDetailPage> createState() => _SellerPersonalDetailPageState();
}

class _SellerPersonalDetailPageState extends State<SellerPersonalDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final Color primaryColor = const Color(0xFF1A0A5B);

  late TextEditingController _nameController;
  late TextEditingController _companyController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  File? _profileImage;
  bool _loading = true;

  User? _user;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _initializeSellerData();
  }

  /// ✅ Load seller data from Firestore
  Future<void> _initializeSellerData() async {
    try {
      _user = FirebaseAuth.instance.currentUser;
      if (_user == null) {
        Navigator.pop(context);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      final data = doc.data() ?? {};

      _nameController = TextEditingController(text: data['name'] ?? '');
      _companyController = TextEditingController(text: data['company'] ?? '');
      _emailController = TextEditingController(text: data['email'] ?? _user!.email ?? '');
      _phoneController = TextEditingController(text: data['phone'] ?? '');
      _locationController = TextEditingController(text: data['location'] ?? '');
      _imageUrl = data['profileImage'] ?? '';

      setState(() => _loading = false);
    } catch (e) {
      print("⚠️ Error loading seller profile: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  /// ✅ Upload image to Firebase Storage and get the URL
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('seller_profiles')
          .child('${_user!.uid}.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print("❌ Error uploading image: $e");
      return null;
    }
  }

  /// ✅ Save or update seller data to Firestore
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      String? uploadedUrl = _imageUrl;
      if (_profileImage != null) {
        uploadedUrl = await _uploadImage(_profileImage!);
      }

      final updatedData = {
        'name': _nameController.text.trim(),
        'company': _companyController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'role': 'seller',
        'profileImage': uploadedUrl ?? '',
        'sellerProfileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .set(updatedData, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Seller profile updated successfully")),
      );

      Navigator.pop(context, updatedData);
    } catch (e) {
      print("❌ Error saving seller profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to save: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1A0A5B))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Seller Information', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 🖼 Profile Picture
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (_imageUrl != null && _imageUrl!.isNotEmpty
                        ? NetworkImage(_imageUrl!) as ImageProvider
                        : null),
                    child: (_profileImage == null && (_imageUrl == null || _imageUrl!.isEmpty))
                        ? const Icon(Icons.person, size: 50, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person, color: primaryColor),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 15),

              // Company
              TextFormField(
                controller: _companyController,
                decoration: InputDecoration(
                  labelText: "Company Name",
                  prefixIcon: Icon(Icons.business, color: primaryColor),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter your company name' : null,
              ),
              const SizedBox(height: 15),

              // Email
              TextFormField(
                controller: _emailController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Email (read-only)",
                  prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: Icon(Icons.phone, color: primaryColor),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                v == null || v.isEmpty ? 'Enter phone number' : (v.length != 10 ? 'Enter valid 10-digit number' : null),
              ),
              const SizedBox(height: 15),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: "Location",
                  prefixIcon: Icon(Icons.location_on_outlined, color: primaryColor),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter your location' : null,
              ),
              const SizedBox(height: 25),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text("Save Changes",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
}
