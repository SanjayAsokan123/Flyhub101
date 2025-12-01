// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Screens
import '../Login/FlyHubSelectionPage.dart';
import '../services/role_manager.dart';
import 'Bottoms/BuyerProfilePage.dart';
import 'Bottoms/MarketPage.dart';
import 'Bottoms/PilotPage.dart';
import 'Bottoms/RentalsPage.dart';
import 'Bottoms/SellerPage.dart';
import 'Bottoms/homescreen.dart';

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
  String? _role = "guest";
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

  // -----------------------------------------------------------
  // INITIALIZATION HANDLER
  // -----------------------------------------------------------
  Future<void> _initializeHome() async {
    _user = FirebaseAuth.instance.currentUser;

    // Load cached role
    _role = await RoleManager.getLocalRole();
    debugPrint("Initial cached role = $_role");

    // ALLOW GUEST WITHOUT FORCING LOGIN
    if (_role == "guest") {
      setState(() => _loading = false);
      return;
    }

    if (_user == null) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FlyHubSelectionPage()),
        );
      });
      return;
    }

    _listenToRoleChanges(_user!.uid);

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      _user = user;
      setState(() {});

      if (user == null) {
        _roleSubscription?.cancel();
        _role = "guest";
        await RoleManager.setLocalRole("guest");
        return;
      }

      _listenToRoleChanges(user.uid);
    });

    setState(() => _loading = false);
  }

  // -----------------------------------------------------------
  // FIRESTORE ROLE WATCHER
  // -----------------------------------------------------------
  void _listenToRoleChanges(String uid) {
    final stream =
    FirebaseFirestore.instance.collection("users").doc(uid).snapshots();

    _roleSubscription?.cancel();

    _roleSubscription = stream.listen((snapshot) async {
      if (!snapshot.exists) {
        _role = "buyer";
        setState(() {});
        await RoleManager.setLocalRole("buyer");
        return;
      }

      final data = snapshot.data();
      final newRole = data?["role"]?.toString().toLowerCase() ?? "buyer";

      if (_role != newRole) {
        _role = newRole;
        setState(() {});
        await RoleManager.setLocalRole(newRole);
      }
    });
  }

  // -----------------------------------------------------------
  // SCREENS LIST
  // -----------------------------------------------------------
  List<Widget> get _screens => [
    const HomeScreen(),
    const MarketPage(),
    const PilotPage(),
    const RentalsPage(),
    _buildProfileTab(),
  ];

  // FIXED PROFILE TAB
  Widget _buildProfileTab() {
    if (_user == null || _role == "guest") {
      return const FlyHubSelectionPage();
    } else if (_role == "seller") {
      return const SellerPage();
    }
    return const BuyerProfilePage();
  }

  // -----------------------------------------------------------
  // NAVIGATION HANDLERS
  // -----------------------------------------------------------
  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();
    _selectedIndex = index;
    setState(() {});
    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
    _selectedIndex = index;
    setState(() {});
  }

  // -----------------------------------------------------------
  // BACK BUTTON EXIT
  // -----------------------------------------------------------
  Future<bool> _onWillPop() async {
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

  // -----------------------------------------------------------
  // BUILD UI
  // -----------------------------------------------------------
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

        // -----------------------------------------------------------
        // SVG BOTTOM NAVIGATION BAR
        // -----------------------------------------------------------
        bottomNavigationBar: BottomNavigationBar(
          elevation: 16,
          backgroundColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF1E0D51),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w400, fontSize: 11),
          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset("assets/categories/home.svg",
                  height: 24, color: Colors.grey),
              activeIcon: SvgPicture.asset("assets/categories/home.svg",
                  height: 26, color: const Color(0xFF1E0D51)),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset("assets/categories/seller.svg",
                  height: 24, color: Colors.grey),
              activeIcon: SvgPicture.asset("assets/categories/seller.svg",
                  height: 26, color: const Color(0xFF1E0D51)),
              label: "Market",
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset("assets/categories/pilots.svg",
                  height: 24, color: Colors.grey),
              activeIcon: SvgPicture.asset("assets/categories/pilots.svg",
                  height: 26, color: const Color(0xFF1E0D51)),
              label: "Pilot",
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset("assets/categories/rentals.svg",
                  height: 24, color: Colors.grey),
              activeIcon: SvgPicture.asset("assets/categories/rentals.svg",
                  height: 26, color: const Color(0xFF1E0D51)),
              label: "Rentals",
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset("assets/categories/user.svg",
                  height: 24, color: Colors.grey),
              activeIcon: SvgPicture.asset("assets/categories/user.svg",
                  height: 26, color: const Color(0xFF1E0D51)),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}