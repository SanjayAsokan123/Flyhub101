import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// ✅ Local Imports
import './BuyerPage.dart';
import './admin_login.dart';
import '../../AddDroneForm.dart';
import '../Dynamichome.dart';
import './GuestProfilePage.dart';
import '../../firebase_options.dart';

class SellerPage extends StatefulWidget {
  const SellerPage({super.key});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  User? _user;
  String? _sellerName;
  String? _sellerEmail;
  bool _loading = true;

  final Color themeColor = const Color(0xFF1A0A5B);

  @override
  void initState() {
    super.initState();
    _initializeSellerPage();
  }

  /// ✅ Initialize Firebase, verify role, and load data
  Future<void> _initializeSellerPage() async {
    try {
      await _ensureFirebaseInitialized();
      await _checkAccess();
      await _loadSellerData();
    } catch (e) {
      debugPrint("❌ Initialization error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Error initializing seller page: $e"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 🔧 Ensure Firebase is initialized before using Firestore
  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      debugPrint("✅ Firebase initialized inside SellerPage");
    }
  }

  /// 🛡 Verify Seller Access Role
  Future<void> _checkAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GuestProfilePage()),
      );
      return;
    }

    try {
      final db = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'flyhub',
      );

      final doc = await db.collection('users').doc(user.uid).get();
      final data = doc.data();

      if (data == null || (data['role'] ?? 'buyer') != 'seller') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text("🔒 Access denied — switching to Buyer view."),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BuyerPage()),
        );
      }
    } catch (e) {
      debugPrint("❌ Firestore Access Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error verifying seller access: $e")),
        );
      }
    }
  }

  /// 🔹 Load Seller Profile Data
  Future<void> _loadSellerData() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user == null) return;

    try {
      final db = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'flyhub',
      );

      final doc = await db.collection('users').doc(_user!.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        setState(() {
          _sellerEmail = data['email'] ?? _user!.email;
          _sellerName = data['name'] ?? data['firstName'] ?? "Seller";
        });
      }
    } catch (e) {
      debugPrint("⚠️ Error loading seller data: $e");
    }
  }

  /// 🔄 Switch to Buyer Mode
  Future<void> _switchToBuyer() async {
    HapticFeedback.selectionClick();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GuestProfilePage()),
      );
      return;
    }

    try {
      final db = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'flyhub',
      );

      await db.collection('users').doc(user.uid).set({
        'role': 'buyer',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("✅ Switched to Buyer Mode"),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BuyerPage()),
      );
    } catch (e) {
      debugPrint("❌ Error switching to Buyer: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to switch to Buyer: $e")),
      );
    }
  }

  /// 🚪 Logout Function
  Future<void> _logout() async {
    HapticFeedback.lightImpact();
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
            (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("👋 Logged out successfully."),
        ),
      );
    } catch (e) {
      debugPrint("❌ Logout Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Logout error: $e")));
    }
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Seller Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
            },
            icon: Icon(Icons.edit, color: themeColor),
          ),
          InkWell(
            onTap: _switchToBuyer,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [themeColor, themeColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withOpacity(0.25),
                    offset: const Offset(2, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.switch_account, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Switch to Buyer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            // 🧑‍💼 Profile Header
            CircleAvatar(
              radius: 45,
              backgroundColor: themeColor,
              child: Text(
                _sellerName != null && _sellerName!.isNotEmpty
                    ? _sellerName![0].toUpperCase()
                    : 'S',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _sellerName ?? 'Seller',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              _sellerEmail ?? '',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 25),

            _buildSectionTitle("Seller Dashboard"),
            const Divider(),
            buildAddRow("Add Drone (Sell)", context, openAddDroneForm: true),
            buildAddRow("Add Drone (Rental)", context),
            buildAddRow("Add Jobs", context),
            buildAddRow("Add Services", context),
            buildAddRow("Add Spare Parts", context),

            const SizedBox(height: 25),
            _buildSectionTitle("Account Settings"),
            const Divider(),
            buildSettingsRow("Personal Information"),
            buildSettingsRow("Notifications", badge: "3"),
            buildSettingsRow("Help & Support"),
            buildSettingsRow("Admin Login", onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) =>  AdminLoginPage()),
              );
            }),

            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                label: const Text(
                  "Logout",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text("Version 1.0.0",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget buildAddRow(String title, BuildContext context,
      {bool openAddDroneForm = false}) {
    return ListTile(
      leading: Icon(Icons.add_circle_outline, color: themeColor),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        HapticFeedback.selectionClick();
        if (openAddDroneForm) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDroneForm()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title page coming soon...')),
          );
        }
      },
    );
  }

  Widget buildSettingsRow(String label, {String? badge, VoidCallback? onTap}) {
    return ListTile(
      leading: const Icon(Icons.settings_outlined, color: Color(0xFF1A0A5B)),
      title: Text(label),
      trailing: badge != null
          ? Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.chevron_right),
          Positioned(
            top: 4,
            right: 16,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style:
                const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      )
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
