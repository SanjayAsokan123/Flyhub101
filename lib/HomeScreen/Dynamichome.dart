import 'package:flutter/material.dart';
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
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _roleStream;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _initializeUserListener();
  }

  /// 🔹 Auth + Firestore listener setup
  void _initializeUserListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _user = user;
      });

      if (user != null) {
        _listenToRoleChanges(user.uid);
      } else {
        // Guest user
        setState(() {
          _role = null;
          _roleStream = null;
        });
      }
    });
  }

  /// 🔹 Listen for Firestore role updates
  void _listenToRoleChanges(String uid) {
    _roleStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots();

    _roleStream!.listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        final role = data?['role']?.toString().toLowerCase();

        setState(() {
          if (role == 'seller') {
            _role = 'seller';
          } else {
            _role = 'buyer';
          }
        });

        debugPrint("👤 Firestore Role Updated: $_role");
      } else {
        // default to buyer if no data
        setState(() => _role = 'buyer');
      }
    });
  }

  /// 🔹 Define screens dynamically
  List<Widget> get _screens {
    return [
      const HomeScreen(),
      const MarketPage(),
      const PilotPage(),
      const RentalsPage(),
      _buildProfileTab(),
    ];
  }

  /// 🔹 Determine which profile page to show
  Widget _buildProfileTab() {
    if (_user == null) {
      return const GuestProfilePage();
    }

    if (_role == 'seller') {
      return const SellerPage();
    }

    // default → buyer
    return const BuyerPage();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // show loading until role fetched
    if (_user != null && _role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.purple)),
      );
    }

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop && _selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(index: _selectedIndex, children: _screens),
        bottomNavigationBar: BottomNavigationBar(
          elevation: 20,
          backgroundColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
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
