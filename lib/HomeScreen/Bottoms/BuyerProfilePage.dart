import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flyhub/T&C/Help_Support_Page.dart';
import 'package:flyhub/T&C/PrivacyPolicy.dart';
import 'package:flyhub/T&C/Terms_Conditions.dart';
import 'package:flyhub/T&C/feedback_form.dart';
import '../../BuyerBookingStatuses/Buyer_Shipping_Policy.dart';
import '../../HomeScreen/Dynamichome.dart';
import '../../HomeScreen/Bottoms/SellerPage.dart';
import '../../HomeScreen/Bottoms/GuestProfilePage.dart';
import '../../BuyerBookingStatuses/Buyer_Return_Refund_Policy.dart';
import '../../SellerBookingStatuses/Seller_Shipping_Policy.dart';
import '../../services/role_manager.dart';
import '../../BuyerDetails/WishlistPage.dart';
import '../../BuyerDetails/MyCartPage.dart';
import '../../Login/SellerLoginPage.dart';
import '../../BuyerDetails/DroneRentalConfirmation.dart';
import '../../BuyerDetails/MyCartPage.dart';
import '../../BuyerDetails/Pilot_Booking_Status.dart';
import '../../BuyerBookingStatuses/BuyerServiceBookingStatus.dart';
import '../../BuyerBookingStatuses/BuyerJobApplyStatus.dart';

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

  static const Color primaryColor = Color(0xFF1A0A5B);
  static const Color backgroundColor = Color(0xFFF8F9FA);

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

      final doc = await _firestore.collection('buyers').doc(_user!.uid).get();

      if (!doc.exists) {
        await RoleManager.setLocalRole("buyer");
        if (!mounted) return;
        setState(() =>
        _buyerData = {
          'name': _user?.displayName ?? 'User',
          'email': _user?.email ?? '',
        });
        return;
      }

      final data = doc.data();
      if (data != null) {
        setState(() =>
        _buyerData = {
          'name': data['name'] ?? '',
          'email': data['email'] ?? '',
        });
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
      }
    }
      catch (e) {
      debugPrint("⚠ BuyerPage init error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _switchToSeller() async {
    HapticFeedback.selectionClick();
    try {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SellerPage()),
      );
    } catch (e) {
      debugPrint("⚠ Switch to seller error: $e");
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _auth.signOut();
              await RoleManager.clearRole();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const Dynamichome(selectedIndex: 0),
                ),
                    (route) => false,
              );
            },
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _buyerData?['name'] ??
        _buyerData?['firstName'] ??
        _user?.displayName ??
        "Buyer";
    final email = _buyerData?['email'] ?? _user?.email ?? "";


    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : "B",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    bool showDivider = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        ...children,
        if (showDivider) const Divider(height: 0, thickness: 1, color: Color(0xFFF0F0F0)),
      ],
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    bool showTrailing = true,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (iconColor ?? primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor ?? primaryColor,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: showTrailing
          ? Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _switchToSeller,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: primaryColor, width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.store, size: 14, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      "Seller",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // Profile Header
                _buildProfileHeader(),

                // Quick Actions
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionButton(
                        icon: Icons.shopping_cart_outlined,
                        label: "Cart",
                        color: primaryColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyCartPage()),
                        ),
                      ),
                      _buildActionButton(
                        icon: Icons.favorite_border,
                        label: "Wishlist",
                        color: Colors.pink,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WishlistPage()),
                        ),
                      ),
                      _buildActionButton(
                        icon: Icons.receipt_long,
                        label: "Orders",
                        color: Colors.green,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SellerLoginPage()),
                        ),
                      ),

                    ],
                  ),
                ),

                // Activities Section
                _buildSection(
                  title: "My Activities",
                  children: [
                    _buildListItem(
                      icon: Icons.flight,
                      title: "Drone Rentals",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DroneRentalApprovalPage()),
                      ),
                    ),
                    _buildListItem(
                      icon: Icons.work_outline,
                      title: "Job Applications",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BuyerJobApplyStatusPage(buyerId: '',)),
                      ),
                    ),
                    _buildListItem(
                      icon: Icons.handyman_outlined,
                      title: "Service Bookings",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BuyerServiceBookingStatusPage()),
                      ),
                    ),
                  ],
                ),

                // Account Section
                _buildSection(
                  title: "Account",
                  children: [
                    _buildListItem(
                      icon: Icons.storefront_outlined,
                      title: "Become a Seller",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SellerLoginPage()),
                      ),
                    ),
                  ],
                ),

                // Support Section
                _buildSection(
                  title: "Support",
                  children: [
                    _buildListItem(
                      icon: Icons.help_outline,
                      title: "Help & Support",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpAndSupportPage()),
                      ),
                    ),
                    _buildListItem(
                      icon: Icons.feedback_outlined,
                      title: "Send Feedback",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FeedbackFormPage()),
                      ),
                    ),
                  ],
                ),

                // Legal Section
                _buildSection(
                  title: "Legal",
                  children: [
                    _buildListItem(
                      icon: Icons.description_outlined,
                      title: "Terms & Conditions",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsAndConditionsPage()),
                      ),
                    ),
                    _buildListItem(
                      icon: Icons.privacy_tip_outlined,
                      title: "Privacy Policy",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                      ),
                    ),
                    _buildListItem(
                      icon: Icons.local_shipping_outlined,
                      title: "Shipping Policy",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BuyerShippingPolicyPage()),
                      ),
                    ),
                    _buildListItem(
                      icon: Icons.assignment_return_outlined,
                      title: "Return Policy",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RRPolicy()),
                      ),
                    ),
                  ],
                  showDivider: false,
                ),

                // Logout Button
                Container(
                  margin: const EdgeInsets.all(20),
                  child: _buildListItem(
                    icon: Icons.logout,
                    title: "Logout",
                    iconColor: Colors.red,
                    onTap: _logout,
                    showTrailing: false,
                  ),
                ),

                // Footer
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        "v1.0.0",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),

                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}