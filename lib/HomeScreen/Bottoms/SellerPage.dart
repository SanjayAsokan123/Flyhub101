import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import './BuyerPage.dart';
import './admin_login.dart';
import '../../AddDroneForm.dart';
import '../Dynamichome.dart';
import './GuestProfilePage.dart';

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

  @override
  void initState() {
    super.initState();
    _checkAccess(); // 🛡 Protect access by role
    _loadSellerData();
  }

  /// 🛡 Restrict access to only sellers
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

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (!doc.exists || doc.data()?['role'] != 'seller') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Access denied — switching to Buyer view.")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BuyerPage()),
      );
    }
  }

  /// ✅ Load seller data
  Future<void> _loadSellerData() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _sellerEmail = data['email'] ?? _user!.email;
        _sellerName = data['name'] ?? "Seller";
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  /// 🔄 Switch to Buyer (Automatic Role Update)
  Future<void> _switchToBuyer() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // 🚫 Guest user → go to GuestProfilePage
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GuestProfilePage()),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'role': 'buyer',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Switched to Buyer Mode")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BuyerPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error switching to Buyer: $e")),
      );
    }
  }

  /// 🚪 Logout
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Dynamichome(selectedIndex: 0)),
            (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("👋 Logged out successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Logout error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.purple)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit, color: Colors.purple),
          ),
          InkWell(
            onTap: _switchToBuyer,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.deepPurpleAccent],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.4),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
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
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.black,
              child: Text(
                _sellerName != null ? _sellerName![0].toUpperCase() : 'S',
                style: const TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _sellerName ?? 'Seller',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              _sellerEmail ?? '',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            buildDashboardSection(context),
            const SizedBox(height: 20),
            buildSettingsSection(context),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// 🧾 Seller Dashboard Section
  Widget buildDashboardSection(BuildContext context) {
    return _buildSectionContainer(
      title: "Seller Dashboard",
      children: [
        buildAddRow("Add Drone (Sell)", context, openAddDroneForm: true),
        buildAddRow("Add Drone (Rental)", context),
        buildAddRow("Add Jobs", context),
        buildAddRow("Add Service", context),
        buildAddRow("Add Spare Parts", context),
      ],
    );
  }

  /// ⚙ Account Settings
  Widget buildSettingsSection(BuildContext context) {
    return _buildSectionContainer(
      title: "Account Settings",
      children: [
        buildSettingsRow("Personal Information"),
        buildSettingsRow("Notifications", badge: "3"),
        buildSettingsRow("Help & Support"),
        buildSettingsRow("Admin Login", onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminLoginPage()),
          );
        }),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _logout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text("Logout"),
        ),
      ],
    );
  }

  /// 📦 Helper UI Containers
  Widget _buildSectionContainer({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            ListTile(
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  /// ➕ Add Drone / Jobs / Service Row
  Widget buildAddRow(String title, BuildContext context, {bool openAddDroneForm = false}) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        if (openAddDroneForm) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddDroneForm()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title page coming soon...')),
          );
        }
      },
    );
  }

  /// ⚙ Settings Row
  Widget buildSettingsRow(String label, {String? badge, VoidCallback? onTap}) {
    return ListTile(
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: const TextStyle(color: Colors.white, fontSize: 10),
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
