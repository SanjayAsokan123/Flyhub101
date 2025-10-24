// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// // Screens
// import 'Bottoms/homescreen.dart';
// import 'Bottoms/MarketPage.dart';
// import 'Bottoms/PilotPage.dart';
// import 'Bottoms/RentalsPage.dart';
// import 'Bottoms/BuyerProfilePage.dart';
// import 'Bottoms/SellerPage.dart';
// import 'Bottoms/GuestProfilePage.dart';
//
// import '../services/role_manager.dart';
//
// class Dynamichome extends StatefulWidget {
//   final int selectedIndex;
//   const Dynamichome({super.key, required this.selectedIndex});
//
//   @override
//   State<Dynamichome> createState() => _DynamichomeState();
// }
//
// class _DynamichomeState extends State<Dynamichome> with WidgetsBindingObserver {
//   int _selectedIndex = 0;
//   User? _user;
//   String? _role;
//   bool _loading = true;
//   bool _shouldRefresh = false;
//
//   StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roleSubscription;
//   DateTime? _lastBackPressed;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _selectedIndex = widget.selectedIndex;
//     _initializeHome();
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _roleSubscription?.cancel();
//     super.dispose();
//   }
//
//   /// 🔄 When app resumes, refresh pages if new drone was added
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed && _shouldRefresh) {
//       debugPrint("🔁 App resumed — refreshing marketplace/rentals...");
//       _refreshCurrentPage();
//       _shouldRefresh = false;
//     }
//   }
//
//   /// 🧠 Initialize user role (local → Firestore)
//   Future<void> _initializeHome() async {
//     _user = FirebaseAuth.instance.currentUser;
//
//     if (_user == null) {
//       _role = "guest";
//       await RoleManager.setLocalRole("guest");
//       setState(() => _loading = false);
//       return;
//     }
//
//     // Load cached role first
//     _role = await RoleManager.getLocalRole();
//     setState(() {});
//
//     // Start listening for updates
//     FirebaseAuth.instance.authStateChanges().listen((user) {
//       setState(() => _user = user);
//       if (user != null) {
//         _listenToRoleChanges(user.uid);
//       } else {
//         _roleSubscription?.cancel();
//         setState(() => _role = "guest");
//       }
//     });
//
//     setState(() => _loading = false);
//   }
//
//   /// 🔐 Listen to role changes in Firestore (auto updates)
//   void _listenToRoleChanges(String uid) {
//     final roleStream =
//     FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
//
//     _roleSubscription?.cancel();
//     _roleSubscription = roleStream.listen((snapshot) async {
//       if (!snapshot.exists) {
//         setState(() => _role = "buyer");
//         await RoleManager.setLocalRole("buyer");
//         return;
//       }
//
//       final data = snapshot.data();
//       final role = data?['role']?.toString().toLowerCase() ?? "buyer";
//
//       if (_role != role) {
//         setState(() => _role = role);
//         await RoleManager.setLocalRole(role);
//       }
//
//       debugPrint("👤 [Dynamichome] Role updated → $role");
//     }, onError: (e) {
//       debugPrint("❌ Role stream error: $e");
//     });
//   }
//
//   /// 🔹 Refresh specific screen (used when Adddrone completes)
//   void _refreshCurrentPage() {
//     setState(() {
//       // Simply rebuilds the IndexedStack — pages can use FutureBuilders/Streams
//     });
//   }
//
//   /// 🔹 Screens for navigation
//   List<Widget> get _screens => [
//     const HomeScreen(),
//     const MarketPage(), // Drone Marketplace
//     const PilotPage(),
//     const RentalsPage(), // Drone Rentals
//     _buildProfileTab(),
//   ];
//
//   /// 🔹 Pick correct profile tab based on user role
//   Widget _buildProfileTab() {
//     if (_user == null || _role == "guest") return const GuestProfilePage();
//     if (_role == "seller") return const SellerPage();
//     return const BuyerProfilePage();
//   }
//
//   /// 🔹 Handle Bottom Navigation Taps
//   void _onItemTapped(int index) {
//     HapticFeedback.selectionClick();
//     setState(() => _selectedIndex = index);
//   }
//
//   /// 🔙 Handle Back Button (Double Tap to Exit)
//   Future<bool> _onWillPop() async {
//     HapticFeedback.lightImpact();
//
//     if (_selectedIndex != 0) {
//       setState(() => _selectedIndex = 0);
//       return false;
//     }
//
//     final now = DateTime.now();
//     if (_lastBackPressed == null ||
//         now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
//       _lastBackPressed = now;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Press back again to exit"),
//           duration: Duration(seconds: 2),
//         ),
//       );
//       return false;
//     }
//
//     return true;
//   }
//
//   /// ✅ Mark home to refresh when coming back from Adddrone
//   @override
//   void didPopNext() {
//     debugPrint("🔄 Returned to Dynamichome — refresh triggered");
//     _shouldRefresh = true;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
//       );
//     }
//
//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body: IndexedStack(index: _selectedIndex, children: _screens),
//         bottomNavigationBar: BottomNavigationBar(
//           elevation: 16,
//           backgroundColor: Colors.white,
//           currentIndex: _selectedIndex,
//           onTap: _onItemTapped,
//           type: BottomNavigationBarType.fixed,
//           selectedItemColor: Colors.deepPurple,
//           unselectedItemColor: Colors.grey,
//           selectedLabelStyle: const TextStyle(
//               fontWeight: FontWeight.w600, fontSize: 12),
//           unselectedLabelStyle: const TextStyle(
//               fontWeight: FontWeight.w400, fontSize: 11),
//           items: const [
//             BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//             BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Market'),
//             BottomNavigationBarItem(icon: Icon(Icons.person_pin), label: 'Pilot'),
//             BottomNavigationBarItem(icon: Icon(Icons.car_rental), label: 'Rentals'),
//             BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
//           ],
//         ),
//       ),
//     );
//   }
// }
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

import '../services/role_manager.dart';

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
  bool _loading = true;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roleSubscription;

  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _initializeHome();
  }

  @override
  void dispose() {
    _roleSubscription?.cancel();
    super.dispose();
  }

  /// 🔹 Initialize with local cache first (instant UI), then sync Firestore in background
  Future<void> _initializeHome() async {
    _user = FirebaseAuth.instance.currentUser;

    if (_user == null) {
      _role = "guest";
      await RoleManager.setLocalRole("guest");
      setState(() => _loading = false);
      return;
    }

    // Load cached role immediately
    _role = await RoleManager.getLocalRole();
    setState(() {});

    // Start listening to Firebase Auth and Firestore for updates
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

  /// 🔹 Firestore listener (syncs updates in real time)
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

      debugPrint("👤 [Dynamichome] Firestore Role Updated → $role");
    }, onError: (e) {
      debugPrint("❌ Role stream error: $e");
    });
  }

  /// 🔹 Screens based on bottom navigation
  List<Widget> get _screens => [
    const HomeScreen(),
    const MarketPage(),
    const PilotPage(),
    const RentalsPage(),
    _buildProfileTab(),
  ];

  /// 🔹 Decide which profile page to show
  Widget _buildProfileTab() {
    if (_user == null || _role == "guest") return const GuestProfilePage();
    if (_role == "seller") return const SellerPage();
    return const BuyerProfilePage();
  }

  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  /// 🔹 Handle back button (double tap to exit)
  Future<bool> _onWillPop() async {
    HapticFeedback.lightImpact();

    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
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
          selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400, fontSize: 11),
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
