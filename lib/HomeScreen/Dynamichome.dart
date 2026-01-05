// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// Screens
import '../Login/FlyHubSelectionPage.dart';
import '../services/network_wrapper.dart';
import '../services/role_manager.dart';
import 'Bottoms/BuyerProfilePage.dart';
import 'Bottoms/MarketPage.dart';
import 'Bottoms/PilotPage.dart';
import 'Bottoms/Popup.dart';
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
  bool _isNavigating = false;

  // NEW: Control popup visibility here
  bool _showWelcomePopup = false;
  static bool _popupShownThisSession = false;
  bool _checkingAnnouncements = false;
  bool _hasAnnouncements = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roleSubscription;
  DateTime? _lastBackPressed;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHome();
    });
  }

  @override
  void dispose() {
    _roleSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // NEW: Check if there are active announcements
  Future<bool> _checkForActiveAnnouncements() async {
    if (_checkingAnnouncements) return false;

    _checkingAnnouncements = true;
    print('Checking for active announcements...');

    try {
      final client = GraphQLProvider.of(context).value;
      if (client == null) {
        print('GraphQL client not available');
        _checkingAnnouncements = false;
        return false;
      }

      const query = '''
        query GetAllAnnouncements {
          getAllAnnouncements {
            id
            imagePath
            imageUrl
            isActive
          }
        }
      ''';

      final result = await client.query(
        QueryOptions(
          document: gql(query),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        print('Error fetching announcements: ${result.exception}');
        _checkingAnnouncements = false;
        return false;
      }

      if (result.data != null && result.data!['getAllAnnouncements'] != null) {
        final List<dynamic> allData = result.data!['getAllAnnouncements'] as List<dynamic>;

        final activeAnnouncements = allData.where((item) {
          final data = item as Map<String, dynamic>;
          final imageUrl = data['imageUrl']?.toString() ?? data['imagePath']?.toString() ?? '';
          final isActive = data['isActive'] == true;

          return imageUrl.isNotEmpty && isActive;
        }).toList();

        print('Found ${activeAnnouncements.length} active announcements');

        _checkingAnnouncements = false;
        return activeAnnouncements.isNotEmpty;
      }

      _checkingAnnouncements = false;
      return false;
    } catch (e) {
      print('Exception checking announcements: $e');
      _checkingAnnouncements = false;
      return false;
    }
  }

  // NEW: Check and show popup only if there are announcements
  Future<void> _checkAndShowPopup() async {
    // Don't show if already shown or not on home screen
    if (_popupShownThisSession || _selectedIndex != 0) return;

    print('Checking if should show popup...');

    // Check for active announcements
    final hasAnnouncements = await _checkForActiveAnnouncements();

    if (hasAnnouncements && !_popupShownThisSession) {
      print('Found announcements, will show popup');

      // Small delay to ensure everything loads
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_popupShownThisSession) {
          print('Showing welcome popup');
          setState(() {
            _showWelcomePopup = true;
            _popupShownThisSession = true;
            _hasAnnouncements = true;
          });
        }
      });
    } else {
      print('No announcements found, not showing popup');
      // Mark as shown even if no announcements, so we don't check again
      _popupShownThisSession = true;
    }
  }

  // NEW: Hide popup method
  void _hideWelcomePopup() {
    if (mounted) {
      setState(() {
        _showWelcomePopup = false;
        _popupShownThisSession = true;
      });
    }
  }

  Future<void> _initializeHome() async {
    if (_isNavigating) return;
    _isNavigating = true;

    _user = FirebaseAuth.instance.currentUser;

    // Load cached role
    _role = await RoleManager.getLocalRole();
    debugPrint("Initial cached role = $_role");

    // ALLOW GUEST WITHOUT FORCING LOGIN
    if (_role == "guest") {
      setState(() => _loading = false);
      _isNavigating = false;
      // Check for announcements after loading
      _checkAndShowPopup();
      return;
    }

    // If no Firebase user AND role is not guest, go to selection page
    if (_user == null && _role != "guest") {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FlyHubSelectionPage()),
      );
      return;
    }

    // If Firebase user exists, listen to role changes
    if (_user != null) {
      _listenToRoleChanges(_user!.uid);

      // Listen to auth state changes
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (!mounted) return;

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
    }

    setState(() => _loading = false);
    _isNavigating = false;

    // Check for announcements after everything is loaded
    _checkAndShowPopup();
  }

  void _listenToRoleChanges(String uid) {
    final stream =
    FirebaseFirestore.instance.collection("users").doc(uid).snapshots();

    _roleSubscription?.cancel();

    _roleSubscription = stream.listen((snapshot) async {
      if (!mounted) return;

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

  List<Widget> get _screens => [
    const HomeScreen(),
    const MarketPage(),
    const PilotPage(),
    const RentalsPage(),
    _buildProfileTab(),
  ];

  Widget _buildProfileTab() {
    if (_user == null || _role == "guest") {
      return const FlyHubSelectionPage();
    } else if (_role == "seller") {
      return const SellerPage();
    }
    return const BuyerProfilePage();
  }

  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();
    _selectedIndex = index;
    setState(() {});
    _pageController.jumpToPage(index);

    // NEW: Check if we're navigating to home screen and have announcements
    if (index == 0 && !_popupShownThisSession && _hasAnnouncements) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_popupShownThisSession && _hasAnnouncements) {
          setState(() {
            _showWelcomePopup = true;
            _popupShownThisSession = true;
          });
        }
      });
    }
  }

  void _onPageChanged(int index) {
    _selectedIndex = index;
    setState(() {});

    // NEW: Check if we're navigating to home screen and have announcements
    if (index == 0 && !_popupShownThisSession && _hasAnnouncements) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_popupShownThisSession && _hasAnnouncements) {
          setState(() {
            _showWelcomePopup = true;
            _popupShownThisSession = true;
          });
        }
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    return NetworkWrapper(
      child: Stack(
        children: [
          WillPopScope(
            onWillPop: _onWillPop,
            child: Scaffold(
              body: PageView(
                controller: _pageController,
                children: _screens,
                onPageChanged: _onPageChanged,
              ),
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
          ),

          // Welcome Popup Overlay - Controlled by Dynamichome
          // Only show if we have announcements and haven't shown before
          if (_showWelcomePopup && _hasAnnouncements)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: WelcomePopup(
                  onClose: () {
                    print('Welcome popup closed by user');
                    _hideWelcomePopup();
                  },
                  onGetStarted: () {
                    print('Welcome popup get started tapped');
                    _hideWelcomePopup();
                  },
                  showCloseButton: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}