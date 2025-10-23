import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SellerPersonalDetailPage extends StatefulWidget {
  const SellerPersonalDetailPage({super.key});

  @override
  State<SellerPersonalDetailPage> createState() =>
      _SellerPersonalDetailPageState();
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
  User? _user;
  String? _imageUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initializeSellerData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// ✅ Load seller data from Firestore
  Future<void> _initializeSellerData() async {
    try {
      _user = FirebaseAuth.instance.currentUser;
      if (_user == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      final data = doc.data() ?? {};

      _nameController = TextEditingController(text: data['name'] ?? '');
      _companyController = TextEditingController(text: data['company'] ?? '');
      _emailController =
          TextEditingController(text: data['email'] ?? _user!.email ?? '');
      _phoneController = TextEditingController(text: data['phone'] ?? '');
      _locationController = TextEditingController(text: data['location'] ?? '');
      _imageUrl = data['profileImage'] ?? '';

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      debugPrint("⚠️ Error loading seller profile: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 🖼 Pick image from gallery
  Future<void> _pickImage() async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  /// ☁ Upload image to Firebase Storage
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('seller_profiles')
          .child('${_user!.uid}.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("❌ Error uploading image: $e");
      return null;
    }
  }

  /// 💾 Save or update seller data to Firestore
  Future<void> _saveProfile() async {
    HapticFeedback.lightImpact();

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
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("✅ Seller profile updated successfully"),
        ),
      );

      Navigator.pop(context, updatedData);
    } catch (e) {
      debugPrint("❌ Error saving seller profile: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to save profile: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 🔹 Get profile image safely
  ImageProvider? _getProfileImage() {
    if (_profileImage != null) return FileImage(_profileImage!);
    if (_imageUrl != null && _imageUrl!.isNotEmpty) return NetworkImage(_imageUrl!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1A0A5B)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Seller Information',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
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
                    backgroundImage: _getProfileImage(),
                    child: _getProfileImage() == null
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
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildTextField(
                controller: _nameController,
                label: "Full Name",
                icon: Icons.person,
                validator: (v) =>
                v == null || v.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _companyController,
                label: "Company Name",
                icon: Icons.business,
                validator: (v) =>
                v == null || v.isEmpty ? 'Enter your company name' : null,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _emailController,
                label: "Email (read-only)",
                icon: Icons.email_outlined,
                readOnly: true,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _phoneController,
                label: "Phone Number",
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter phone number';
                  if (v.length != 10) return 'Enter valid 10-digit number';
                  return null;
                },
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _locationController,
                label: "Location",
                icon: Icons.location_on_outlined,
                validator: (v) =>
                v == null || v.isEmpty ? 'Enter your location' : null,
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    "Save Changes",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
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

  /// 📋 Reusable text field builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }
}
