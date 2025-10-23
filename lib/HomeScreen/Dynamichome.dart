import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Bottom Navigation Screens
import 'Bottoms/homescreen.dart';
import 'Bottoms/MarketPage.dart';
import 'Bottoms/PilotPage.dart';
import 'Bottoms/RentalsPage.dart';
import 'Bottoms/BuyerPage.dart';
import 'Bottoms/SellerPage.dart';
import 'Bottoms/GuestProfilePage.dart';

class Dynamichome extends StatefulWidget {
  final int selectedIndex;

  const Dynamichome({super.key, required this.selectedIndex});

  @override
  State<Dynamichome> createState() => _DynamichomeState();
}

class _DynamichomeState extends State<Dynamichome> {
  int _selectedIndex = 0;
  User? _user;
  String? _role;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roleSubscription;

  DateTime? _lastBackPressed; // Track last back press time

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _initializeUserListener();
  }

  @override
  void dispose() {
    _roleSubscription?.cancel();
    super.dispose();
  }

  void _initializeUserListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() => _user = user);

      if (user != null) {
        _listenToRoleChanges(user.uid);
      } else {
        _roleSubscription?.cancel();
        setState(() => _role = null);
      }
    });
  }

  void _listenToRoleChanges(String uid) {
    final roleStream = FirebaseFirestore.instance.collection('users').doc(uid).snapshots();

    _roleSubscription?.cancel();
    _roleSubscription = roleStream.listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        final role = data?['role']?.toString().toLowerCase();

        setState(() {
          _role = (role == 'seller') ? 'seller' : 'buyer';
        });

        debugPrint("👤 Firestore Role Updated: $_role");
      } else {
        setState(() => _role = 'buyer');
      }
    }, onError: (e) {
      debugPrint("❌ Role stream error: $e");
    });
  }

  List<Widget> get _screens {
    return [
      const HomeScreen(),
      const MarketPage(),
      const PilotPage(),
      const RentalsPage(),
      _buildProfileTab(),
    ];
  }

  Widget _buildProfileTab() {
    if (_user == null) return const GuestProfilePage();
    if (_role == 'seller') return const SellerPage();
    return const BuyerPage();
  }

  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  /// 🔹 Handle back press with double-back-to-exit and haptic feedback
  Future<bool> _onWillPop() async {
    HapticFeedback.lightImpact(); // subtle vibration on each back press

    // Navigate to Home tab if not already there
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
      return false;
    }

    // Double-back-to-exit logic
    final now = DateTime.now();
    if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Press back again to exit"),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    return true; // exit app
  }

  @override
  Widget build(BuildContext context) {
    if (_user != null && _role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(index: _selectedIndex, children: _screens),
        bottomNavigationBar: BottomNavigationBar(
          elevation: 16,
          backgroundColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Market'),
            BottomNavigationBarItem(icon: Icon(Icons.person_pin), label: 'Pilot'),
            BottomNavigationBarItem(icon: Icon(Icons.car_rental), label: 'Rentals'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
