import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Login/LoginPage.dart';
import '../../services/role_manager.dart';
import '../../HomeScreen/Dynamichome.dart';

class GuestProfilePage extends StatefulWidget {
  const GuestProfilePage({super.key});

  @override
  State<GuestProfilePage> createState() => _GuestProfilePageState();
}

class _GuestProfilePageState extends State<GuestProfilePage> {
  static const Color themeColor = Color(0xFF1A0A5B);
  String _guestMessage = "You’re currently exploring as a guest.";

  @override
  void initState() {
    super.initState();
    _initGuestMode();
  }

  Future<void> _initGuestMode() async {
    final role = await RoleManager.getLocalRole();
    if (role != "guest") {
      await RoleManager.setLocalRole("guest");
    }
    setState(() {
      _guestMessage =
      "You’re currently exploring as a guest.\nLog in to unlock all FlyHub features!";
    });
  }

  /// 🧠 Switch to Buyer
  Future<void> _switchToBuyer() async {
    HapticFeedback.selectionClick();
    await RoleManager.setLocalRole("buyer");
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  /// 🧠 Switch to Seller
  Future<void> _switchToSeller() async {
    HapticFeedback.selectionClick();
    await RoleManager.setLocalRole("seller");
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  /// 🚪 Continue as Guest (no login)
  Future<void> _continueAsGuest() async {
    await RoleManager.setLocalRole("guest");
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
    );
  }

  /// 🔹 Reusable button
  Widget _buildActionButton(
      {required String text,
        required IconData icon,
        required VoidCallback onTap,
        required Color color}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          text,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Guest Mode"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline,
                  size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              Text(
                "Guest Mode",
                style: TextStyle(
                  color: themeColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _guestMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 40),

              // 🔹 Buyer Login Button
              _buildActionButton(
                text: "Login as Buyer",
                icon: Icons.shopping_bag_outlined,
                onTap: _switchToBuyer,
                color: themeColor,
              ),
              const SizedBox(height: 16),

              // 🔹 Seller Login Button
              _buildActionButton(
                text: "Login as Seller",
                icon: Icons.store_mall_directory_outlined,
                onTap: _switchToSeller,
                color: Colors.deepPurpleAccent,
              ),
              const SizedBox(height: 20),

              // 🔹 Continue as Guest
              TextButton(
                onPressed: _continueAsGuest,
                child: const Text(
                  "Continue as Guest",
                  style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                      fontSize: 14),
                ),
              ),
              const SizedBox(height: 50),

              const Text(
                "FlyHub Technologies Pvt. Ltd.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Text(
                "Version 1.0.0",
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
