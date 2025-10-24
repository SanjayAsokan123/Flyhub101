import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flyhub/Help_Support_Page.dart';
import 'package:flyhub/PrivacyPolicy.dart';
import 'package:flyhub/Terms_Conditions.dart';
import 'package:flyhub/feedback_form.dart';
import '../../BuyerDetails/DroneRentalConfirmation.dart';
import '../../BuyerDetails/MyCartPage.dart';
import 'SellerFormDialog.dart';
import 'BuyerPersonalDetail.dart';
import '../../Regulatory.dart';
class BuyerProfilePage extends StatefulWidget {
  const BuyerProfilePage({super.key});

  @override
  State<BuyerProfilePage> createState() => _BuyerProfilePageState();
}

class _BuyerProfilePageState extends State<BuyerProfilePage> {
  Map<String, String>? userProfile;
  bool notificationsEnabled = true;

  final Color primaryColor = const Color(0xFF1A0A5B); // 🎨 Custom Theme Color

  @override
  Widget build(BuildContext context) {
    final name = userProfile?['name'] ?? 'Raj Kumar';
    final location = userProfile?['location'] ?? 'Chennai, Tamil Nadu';
    final role = userProfile?['role'] ?? 'Drone Buyer';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer Profile'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          GestureDetector(
            onTap: () {
              // SellerFormDialog.show(context);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.switch_account, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Switch to Seller',
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
        child: Column(
          children: [
            const SizedBox(height: 25),

            // 👤 Profile Photo with Edit Icon
            Stack(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: primaryColor.withOpacity(0.15),
                  backgroundImage: userProfile?['profileImage'] != null &&
                      userProfile!['profileImage']!.isNotEmpty
                      ? FileImage(File(userProfile!['profileImage']!))
                      : null,
                  child: userProfile?['profileImage'] == null ||
                      userProfile!['profileImage']!.isEmpty
                      ? const Icon(Icons.person, size: 45, color: Colors.white)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () async {
                      // Navigate to Personal Information Page
                      final updatedData = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PersonalInformationPage(existingData: userProfile),
                        ),
                      );
                      if (updatedData != null && mounted) {
                        setState(() => userProfile = updatedData);
                      }
                    },
                    child: Container(
                      height: 25,
                      width: 25,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Name and badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 5),
                Icon(Icons.verified, color: primaryColor, size: 18),
              ],
            ),
            const SizedBox(height: 4),
            Text('$role · $location',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),

            const SizedBox(height: 25),

            // ================= Dashboard =================
            buildDashboardRow("My Orders", Icons.shopping_bag_outlined),
            buildDashboardRow("Wishlist", Icons.favorite_border),
            buildDashboardRow(
              "Cart",
              Icons.shopping_cart_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const  RegulatoryPage ()),
                );
              },
            ),
            buildDashboardRow(
              "Drone Rentals",
              Icons.flight_takeoff_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DroneRentalApprovalPage(),
                  ),
                );
              },
            ),
            buildDashboardRow("Purchase History", Icons.history),

            const SizedBox(height: 25),

            // ================= Account Settings =================
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Account Settings",
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const Divider(),

            buildSettingsRow(
              "Notifications",
              icon: Icons.notifications_active_outlined,
              trailing: Switch(
                value: notificationsEnabled,
                activeColor: primaryColor,
                onChanged: (val) => setState(() => notificationsEnabled = val),
              ),
            ),
            buildSettingsRow("Help & Support",
                icon: Icons.help_outline, onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpAndSupportPage()),
                  );
                }),
            buildSettingsRow("Terms and Conditions",
                icon: Icons.description_outlined, onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TermsAndConditionsPage()),
                  );
                }),
            buildSettingsRow("Privacy Policy", icon: Icons.privacy_tip_outlined, onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
              );
            }),
            buildSettingsRow("Send Feedback", icon: Icons.feedback_outlined, onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackFormPage()),
              );
            }),

            const SizedBox(height: 25),

            // Logout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Logout",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            const SizedBox(height: 10),
            const Text("Version 1.0.0",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildDashboardRow(String label, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(label),
      onTap: onTap,
    );
  }

  Widget buildSettingsRow(String label,
      {IconData? icon, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(label),
      trailing: trailing,
      onTap: onTap,
    );
  }
}