import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flyhub/Help_Support_Page.dart';
import 'package:flyhub/PrivacyPolicy.dart';
import 'package:flyhub/Terms_Conditions.dart';
import 'package:flyhub/feedback_form.dart';
import '../../HomeScreen/Dynamichome.dart';
import '../../HomeScreen/Bottoms/SellerPage.dart';
import '../../HomeScreen/Bottoms/GuestProfilePage.dart';
import '../../services/role_manager.dart';
import '../../WishlistPage.dart';
import '../../BuyerDetails/MyCartPage.dart';
import '../../Login/SellerLoginPage.dart';
import '../../BuyerDetails/DroneRentalConfirmation.dart';
import '../../BuyerDetails/MyCartPage.dart';
import '../../BuyerDetails/Pilot_Booking_Status.dart';
class BuyerProfilePage extends StatefulWidget {
  const BuyerProfilePage({super.key});

  @override
  State<BuyerProfilePage> createState() => _BuyerProfilePageState();
}

class _BuyerProfilePageState extends State<BuyerProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic>? _buyerData;
  bool _loading = true;

  static const Color themeColor = Color(0xFF1A0A5B);

  @override
  void initState() {
    super.initState();
    _initBuyerPage();
  }

  Future<void> _initBuyerPage() async {
    try {
      _user = _auth.currentUser;

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

      if (!doc.exists) {
        await RoleManager.setLocalRole("buyer");
        if (!mounted) return;
        setState(() => _buyerData = {
          'name': _user?.displayName ?? 'User',
          'email': _user?.email ?? '',
        });
        return;
      }

      final data = doc.data()!;
      final role = data['role']?.toString().toLowerCase() ?? "buyer";

      if (role != "buyer") {
        await RoleManager.setLocalRole("seller");
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SellerPage()),
        );
        return;
      }

      await RoleManager.setLocalRole("buyer");
      setState(() => _buyerData = data);
    } catch (e) {
      debugPrint("⚠ BuyerPage init error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Future<void> _switchToSeller() async {
  //   HapticFeedback.selectionClick();
  //   try {
  //     await RoleManager.updateRole("seller");
  //     if (!mounted) return;
  //
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (_) => const SellerPage()),
  //     );
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("✅ Switched to Seller Mode")),
  //     );
  //   } catch (e) {
  //     debugPrint("⚠ Switch to seller error: $e");
  //   }
  // }

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

  Widget _buildTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: themeColor),
      title: Text(title),

      onTap: onTap,
    );
  }

  Widget _buildHeader() {
    final name = _buyerData?['name'] ??
        _buyerData?['firstName'] ??
        _user?.displayName ??
        "Buyer";
    final email = _buyerData?['email'] ?? _user?.email ?? "";

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
        Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          email,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
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
        title: const Text("Buyer Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          InkWell(
            // onTap: _switchToSeller,
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
                  Icon(Icons.store_mall_directory_outlined,
                      color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    "Switch to Seller",
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

            _buildSection("My Activities"),
            _buildTile("My Cart", Icons.shopping_cart_outlined, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyCartPage()),
              );
            }),
            _buildTile("My Wishlist", Icons.favorite_border, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WishlistPage()),
              );
            }),
            _buildTile("My Orders", Icons.receipt_long, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SellerLoginPage()),
              );
            }),
            _buildTile("Pilot Booking Status", Icons.person, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PilotBookingStatusPage()),
              );
            }),
            _buildTile("Rental Drone", Icons.flight, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DroneRentalApprovalPage()),
              );
            }),

            _buildSection("Account Settings"),
            _buildTile("Register as Seller", Icons.storefront, () {

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SellerLoginPage()),
              );
            }),
            _buildTile("Logout", Icons.logout, _logout),

            const SizedBox(height: 20),
            _buildSection("Legal & Support"),
            _buildTile("Terms and Conditions", Icons.description_outlined, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TermsAndConditionsPage()),
              );
            }),
            _buildTile("Privacy Policy", Icons.privacy_tip_outlined, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              );
            }),
            _buildTile("Help and Support", Icons.help_outline, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpAndSupportPage()),
              );
            }),
            _buildTile("Send Feedback", Icons.feedback_outlined, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FeedbackFormPage()),
              );
            }),

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