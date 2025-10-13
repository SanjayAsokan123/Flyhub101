import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Local imports
import './SellerPage.dart';
import './admin_login.dart';
import './GuestProfilePage.dart';
import '../MyCartPage.dart';
import '../wishlistPage.dart';
import '../Dynamichome.dart';
import '../../Login/SellerSignupScreen.dart'; // ✅ New OTP-based seller signup

class BuyerPage extends StatefulWidget {
  const BuyerPage({super.key});

  @override
  State<BuyerPage> createState() => _BuyerPageState();
}

class _BuyerPageState extends State<BuyerPage> {
  XFile? selectedPhoto;
  User? _user;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _checkAccess();
    _loadBuyerData();
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

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists || doc.data()?['role'] != 'buyer') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Access denied — switching to Seller view.")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SellerPage()),
      );
    }
  }

  /// 🔹 Load buyer info
  Future<void> _loadBuyerData() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();

    if (doc.exists) {
      setState(() => _userName = doc['name'] ?? "Buyer");
    }
  }

  /// 🔹 Logout
  Future<void> _logoutUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content:
        const Text('Are you sure you want to log out and continue as guest?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout')),
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

  /// 🔹 Switch to Seller (via OTP registration)
  Future<void> _switchToSeller() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Not logged in → redirect to OTP signup
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SellerSignupScreen()),
      );
    } else {
      try {
        // Already logged in buyer → update Firestore role
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'role': 'seller',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Switched to Seller Mode")),
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SellerPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("❌ Error switching role: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          // 🔄 Switch to Seller
          GestureDetector(
            onTap: _switchToSeller,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.deepPurpleAccent],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.4),
                    offset: const Offset(0, 4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.switch_account, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Switch to Seller',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
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
                _userName != null ? _userName![0].toUpperCase() : 'B',
                style: const TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _userName ?? 'Buyer User',
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Drone Buyer · Chennai, Tamil Nadu',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            buildSettings(context),
          ],
        ),
      ),
    );
  }

  Widget buildSettings(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const ListTile(
              title: Text(
                "Account Settings",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.purple),
              title: const Text("Personal Info"),
              trailing: const Icon(Icons.chevron_right),
            ),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.purple),
              title: const Text("Payment Methods"),
              trailing: const Icon(Icons.chevron_right),
            ),
            const Divider(height: 1),
            ElevatedButton(
              onPressed: _logoutUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Logout"),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
