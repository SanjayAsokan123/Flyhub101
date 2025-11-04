import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Screens
import 'Bottoms/homescreen.dart';
import 'Bottoms/MarketPage.dart';
import 'Bottoms/PilotPage.dart';
import 'Bottoms/RentalsPage.dart';
import 'Bottoms/BuyerProfilePage.dart';
import 'Bottoms/SellerPage.dart';
import 'Bottoms/GuestProfilePage.dart';
import 'Bottoms/JobPage.dart';
import 'Bottoms/ServicesPage.dart';

import '../services/role_manager.dart';

class Dynamichome extends StatefulWidget {
  final int selectedIndex;
  const Dynamichome({super.key, required this.selectedIndex});

  @override
  State<Dynamichome> createState() => _DynamichomeState();
}

class _DynamichomeState extends State<Dynamichome>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  User? _user;
  String? _role;
  bool _loading = true;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roleSubscription;
  DateTime? _lastBackPressed;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _pageController = PageController(initialPage: _selectedIndex);
    _initializeHome();
  }

  @override
  void dispose() {
    _roleSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// 🔹 Initialize Firebase Auth + Firestore Role Listener
  Future<void> _initializeHome() async {
    _user = FirebaseAuth.instance.currentUser;

    if (_user == null) {
      _role = "guest";
      await RoleManager.setLocalRole("guest");
      setState(() => _loading = false);
      return;
    }

    // Load cached role quickly
    _role = await RoleManager.getLocalRole();
    setState(() {});

    // Start real-time listener for role updates
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() => _user = user);
      if (user != null) {
        _listenToRoleChanges(user.uid);
      } else {
        _roleSubscription?.cancel();
        setState(() => _role = "guest");
      }
    });

    setState(() => _loading = false);
  }

  /// 🔹 Listen for real-time role changes
  void _listenToRoleChanges(String uid) {
    final roleStream =
    FirebaseFirestore.instance.collection('users').doc(uid).snapshots();

    _roleSubscription?.cancel();
    _roleSubscription = roleStream.listen((snapshot) async {
      if (!snapshot.exists) {
        setState(() => _role = "buyer");
        await RoleManager.setLocalRole("buyer");
        return;
      }

      final data = snapshot.data();
      final role = data?['role']?.toString().toLowerCase() ?? "buyer";

      if (_role != role) {
        setState(() => _role = role);
        await RoleManager.setLocalRole(role);
      }

      debugPrint("👤 [Dynamichome] Role Updated → $role");
    }, onError: (e) {
      debugPrint("❌ Role stream error: $e");
    });
  }

  /// 🔹 Screens for each tab
  List<Widget> get _screens => [
    const HomeScreen(),
    const MarketPage(),
    const PilotPage(),
    const JobsPage(),
    const ServicesPage(),
    const RentalsPage(),
    _buildProfileTab(),
  ];

  /// 🔹 Return correct profile based on user role
  Widget _buildProfileTab() {
    if (_user == null || _role == "guest") return const GuestProfilePage();
    if (_role == "seller") return const SellerPage();
    return const BuyerProfilePage();
  }

  /// 🔹 Handle tab tap
  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }

  /// 🔹 Handle swipe (syncs with bottom nav)
  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  /// 🔹 Double-tap back to exit
  Future<bool> _onWillPop() async {
    HapticFeedback.lightImpact();

    if (_selectedIndex != 0) {
      _onItemTapped(0);
      return false;
    }

    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Press back again to exit"),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          elevation: 16,
          backgroundColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w400, fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Market'),
            BottomNavigationBarItem(icon: Icon(Icons.person_pin), label: 'Pilot'),
            BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Jobs'),
            BottomNavigationBarItem(icon: Icon(Icons.build_circle), label: 'Services'),
            BottomNavigationBarItem(icon: Icon(Icons.car_rental), label: 'Rentals'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
