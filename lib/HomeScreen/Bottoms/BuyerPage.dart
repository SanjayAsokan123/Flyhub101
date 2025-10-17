import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🔹 Local imports
import 'SellerFormDialog.dart';
import '../Dynamichome.dart';
import '../../Login/SellerSignupScreen.dart';
import '../../firebase_options.dart';
import '../../wishlistPage.dart';
import '../../MyCartPage.dart';
import '../../Help_Support_Page.dart';
import '../../PrivacyPolicy.dart';
import '../../Terms_Conditions.dart';
import '../../feedback_form.dart';
import '../../BuyerDetails/DroneRentalConfirmation.dart';
import '../../Regulatory.dart';
// import 'SellerPage.dart';
import 'GuestProfilePage.dart';

class BuyerPage extends StatefulWidget {
  const BuyerPage({super.key});

  @override
  State<BuyerPage> createState() => _BuyerPageState();
}

class _BuyerPageState extends State<BuyerPage> {
  User? _user;
  String? _userName;
  String? _profileImage;
  bool notificationsEnabled = true;
  bool _loading = true;

  final Color primaryColor = const Color(0xFF1A0A5B);

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
      await _checkAccess();
      await _loadBuyerData();
    } catch (e) {
      debugPrint("⚠️ Firebase Init Error: $e");
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// 🛡 Restrict to buyers only
  Future<void> _checkAccess() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GuestProfilePage()),
      );
      return;
    }

    final db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'flyhub');
    final doc = await db.collection('users').doc(user.uid).get();

    if (!doc.exists || doc.data()?['role'] != 'buyer') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Access denied — switching to Seller view.")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SellerFormDialog()),
      );
    }
  }

  /// 🔹 Load buyer info
  Future<void> _loadBuyerData() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user == null) return;

    final db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'flyhub');
    final doc = await db.collection('users').doc(_user!.uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _userName = (data['name'] ?? data['firstName'] ?? _user!.email?.split('@').first)?.toString();
        _profileImage = data['profileImage'];
      });
    }
  }

  /// 🖼 Update Profile Photo
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => _profileImage = picked.path);
      final db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'flyhub');
      await db.collection('users').doc(_user!.uid).set({
        'profileImage': picked.path,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// 🚪 Logout
  Future<void> _logoutUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out and continue as guest?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Dynamichome(selectedIndex: 0)),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error logging out: $e")));
    }
  }

  /// 🔄 Switch to Seller
  Future<void> _switchToSeller() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const SellerSignupScreen()));
      return;
    }

    try {
      final db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'flyhub');
      await db.collection('users').doc(user.uid).set({
        'role': 'seller',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("✅ Switched to Seller Mode")));

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SellerFormDialog()));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Error switching role: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer Profile'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          GestureDetector(
            onTap: _switchToSeller,
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.switch_account, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text('Switch to Seller',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 25),

            // Profile Picture
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.deepPurple.withOpacity(0.1),
                  backgroundImage: _profileImage != null && _profileImage!.isNotEmpty
                      ? FileImage(File(_profileImage!))
                      : null,
                  child: _profileImage == null
                      ? const Icon(Icons.person, size: 50, color: Colors.deepPurple)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 28,
                      width: 28,
                      decoration: const BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Text(_userName ?? "Buyer User",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Drone Buyer · Chennai, Tamil Nadu",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),

            // Dashboard
            _buildDashboardRow("My Orders", Icons.shopping_bag_outlined),
            _buildDashboardRow("Wishlist", Icons.favorite_border, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistPage()));
            }),
            _buildDashboardRow("Cart", Icons.shopping_cart_outlined, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCartPage()));
            }),
            _buildDashboardRow("Drone Rentals", Icons.flight_takeoff_outlined, onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DroneRentalApprovalPage()));
            }),
            _buildDashboardRow("Regulatory Info", Icons.assignment_outlined, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RegulatoryPage()));
            }),
            const SizedBox(height: 20),

            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Account Settings",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            _buildSettingsRow("Notifications",
                icon: Icons.notifications_active_outlined,
                trailing: Switch(
                  value: notificationsEnabled,
                  activeColor: Colors.deepPurple,
                  onChanged: (val) => setState(() => notificationsEnabled = val),
                )),
            _buildSettingsRow("Help & Support", icon: Icons.help_outline, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpAndSupportPage()));
            }),
            _buildSettingsRow("Terms & Conditions",
                icon: Icons.description_outlined,
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const TermsAndConditionsPage()))),
            _buildSettingsRow("Privacy Policy",
                icon: Icons.privacy_tip_outlined,
                onTap: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()))),
            _buildSettingsRow("Send Feedback",
                icon: Icons.feedback_outlined,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackFormPage()))),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: _logoutUser,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("Logout",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text("Version 1.0.0", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardRow(String label, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(label),
      onTap: onTap,
    );
  }

  Widget _buildSettingsRow(String label,
      {IconData? icon, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(label),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
