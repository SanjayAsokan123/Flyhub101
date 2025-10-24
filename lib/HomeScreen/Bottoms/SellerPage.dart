import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../HomeScreen/Dynamichome.dart';
import '../../HomeScreen/Bottoms/BuyerProfilePage.dart';
import '../../HomeScreen/Bottoms/GuestProfilePage.dart';
import '../../services/role_manager.dart';
import '../../add_drone_form.dart';
import 'admin_login.dart';

class SellerPage extends StatefulWidget {
  const SellerPage({super.key});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic>? _sellerData;
  bool _loading = true;

  static const Color themeColor = Color(0xFF1A0A5B);

  @override
  void initState() {
    super.initState();
    _initSellerPage();
  }

  Future<void> _initSellerPage() async {
    try {
      _user = _auth.currentUser;

      // 🧩 Not logged in → Guest
      if (_user == null) {
        await RoleManager.setLocalRole("guest");
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GuestProfilePage()),
        );
        return;
      }

      final doc = await _firestore.collection('users').doc(_user!.uid).get();

      // 🧩 No Firestore document → treat as Buyer
      if (!doc.exists) {
        await RoleManager.setLocalRole("buyer");
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BuyerProfilePage()),
        );
        return;
      }

      final data = doc.data()!;
      final role = data['role']?.toString().toLowerCase() ?? "buyer";

      // 🧩 Wrong role → Redirect
      if (role != "seller") {
        await RoleManager.setLocalRole("buyer");
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BuyerProfilePage()),
        );
        return;
      }

      await RoleManager.setLocalRole("seller");
      setState(() => _sellerData = data);
    } catch (e) {
      debugPrint("❌ SellerPage init error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 🔄 Switch to Buyer Mode (safe and clean)
  Future<void> _switchToBuyer() async {
    HapticFeedback.selectionClick();
    try {
      await RoleManager.updateRole("buyer");
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BuyerProfilePage()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Switched to Buyer Mode")),
      );
    } catch (e) {
      debugPrint("⚠️ Error switching to buyer: $e");
    }
  }

  /// 🚪 Logout safely
  Future<void> _logout() async {
    HapticFeedback.lightImpact();
    await _auth.signOut();
    await RoleManager.clearRole();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
          (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("👋 Logged out successfully")),
    );
  }

  /// 🧱 Reusable tile
  Widget _buildTile(String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: themeColor),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  /// 🧩 Seller Info Header
  Widget _buildHeader() {
    final name = _sellerData?['name'] ??
        _sellerData?['firstName'] ??
        _user?.displayName ??
        "Seller";
    final email = _sellerData?['email'] ?? _user?.email ?? "No email";

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: themeColor,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : "?",
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
        const SizedBox(height: 10),
        Text(name,
            style:
            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: themeColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Seller Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
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
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    "Switch to Buyer",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          children: [
            _buildHeader(),

            _buildSection("My Store"),
            _buildTile("Add Drone for Sale", Icons.airplanemode_active, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddDroneForm()),
              );
            }),
            _buildTile("Add Spare Parts", Icons.build_outlined, () {}),
            _buildTile("Add Rental Drone", Icons.precision_manufacturing, () {}),
            _buildTile("Add Drone Services", Icons.design_services_outlined, () {}),
            _buildTile("Add Jobs / Gigs", Icons.work_outline, () {}),

            const SizedBox(height: 20),
            _buildSection("Account Settings"),
            _buildTile("Admin Login", Icons.admin_panel_settings_outlined, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminLoginPage()),
              );
            }),
            _buildTile("Logout", Icons.logout, _logout),

            const SizedBox(height: 30),
            const Text("Version 1.0.0",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
