import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Core pages
import '../../HomeScreen/Dynamichome.dart';
import '../../HomeScreen/Bottoms/BuyerProfilePage.dart';
import '../../HomeScreen/Bottoms/GuestProfilePage.dart';
import '../../services/role_manager.dart';

// Product Status Pages
import '../../Sold_Product_Page.dart';
import '../../Rejected_Products_Page.dart';
import '../../Pending_Products_Page.dart';
import '../../Approval_Products_Page.dart';
import '../../Return_Product_Page.dart';

// Add Product Pages
import '../../AddDrone.dart';
import '../../add_spare_parts.dart';
import '../../add_accessories_form.dart';
import '../../add_service_form.dart';
import '../../add_hire_pilots_form.dart';
import '../../add_drone_rental_form.dart';
import '../../add_job_form.dart';

// Rental pages
import '../../Seller_Drone_Rental_Page.dart';
import '../../Seller_Pilot_Rental_Page.dart';

// Settings Pages
import 'package:flyhub/Help_Support_Page.dart';
import 'package:flyhub/PrivacyPolicy.dart';
import 'package:flyhub/Terms_Conditions.dart';
import '../../feedback_form.dart';

// Bottom Pages
import './MarketPage.dart';
import './PilotPage.dart';
import './RentalsPage.dart';
import './homescreen.dart';

class SellerPage extends StatefulWidget {
  const SellerPage({super.key});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _user;
  Map<String, dynamic>? _sellerData;
  String? _sellerId;

  bool _loading = true;

  static const Color themeColor = Color(0xFF1A0A5B);
  final String graphqlUrl = "http://192.168.1.178:5001/graphql";

  @override
  void initState() {
    super.initState();
    _initSellerPage();
  }

  Future<void> _initSellerPage() async {
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

      await RoleManager.setLocalRole("seller");
      await _fetchOrCreateSeller(
        _user!.email ?? "",
        _user!.displayName ?? "Seller",
      );
    } catch (e) {
      debugPrint("❌ SellerPage init error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchOrCreateSeller(String email, String name) async {
    try {
      final client = GraphQLClient(
        link: HttpLink(graphqlUrl),
        cache: GraphQLCache(),
      );

      const String query = r'''
      query SellerByEmail($email: String!) {
        sellerByEmail(email: $email) {
          customId
          companyName
          email
          address
        }
      }
      ''';

      final result = await client.query(
        QueryOptions(document: gql(query), variables: {'email': email}),
      );

      final seller = result.data?['sellerByEmail'];

      if (seller != null) {
        setState(() {
          _sellerData = seller;
          _sellerId = seller['customId'];
        });
        return;
      }

      const String mutation = r'''
      mutation CreateSeller($input: SellerInput!) {
        createSeller(input: $input) {
          customId
          companyName
          email
        }
      }
      ''';

      final createResult = await client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {
            'input': {
              'name': name,
              'companyName': 'My Drone Store',
              'PANnumber': 'AUTO1234F',
              'gstNumber': '',
              'address': 'Unknown Address',
              'authorized': name,
              'email': email,
              'phoneNumber': 'N/A',
              'shippingAddresses': ['Unknown Address'],
              'pickupAddresses': ['Unknown Address'],
              'companyPan': 'AUTO1234F',
              'bankAccountNumber': '0000000000',
              'bankIFCnumber': 'AUTOIFSC1234',
              'bankName': 'Unknown',
            },
          },
        ),
      );

      final newSeller = createResult.data?['createSeller'];
      if (newSeller != null) {
        setState(() {
          _sellerData = newSeller;
          _sellerId = newSeller['customId'];
        });
      }
    } catch (e) {
      debugPrint("❌ Fetch/Create Seller Error: $e");
    }
  }

  Future<void> _switchToBuyer() async {
    await RoleManager.updateRole("buyer");
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BuyerProfilePage()),
    );
  }

  Future<void> _logout() async {
    await _auth.signOut();
    await RoleManager.clearRole();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
          (route) => false,
    );
  }

  void _showMissingSellerSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("⚠ Seller ID not found")),
    );
  }

  Widget _buildHeader() {
    final name = _sellerData?['companyName'] ?? "Seller";
    final email = _sellerData?['email'] ?? "No email";

    return Column(
      children: [
        CircleAvatar(
          radius: 45,
          backgroundColor: themeColor,
          child: Text(
            name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
        const SizedBox(height: 12),
        Text(name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(email, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildTile(String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: themeColor),
      title: Text(label),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

  // PROFILE PAGE
  Widget buildProfilePage() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: themeColor),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Seller Dashboard"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          InkWell(
            onTap: _switchToBuyer,
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.swap_horiz, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text("Buyer Mode",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
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

            _buildSection("My Store"),

            _buildTile("Add Drone for Sale", Icons.airplanemode_active, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddDronePage(sellerId: _sellerId!)),
              );
            }),

            _buildTile("Add Spare Parts", Icons.build, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AddSparePartForm(sellerId: _sellerId!)),
              );
            }),

            _buildTile("Add Accessories", Icons.memory, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AddAccessoryForm(sellerId: _sellerId!)),
              );
            }),

            _buildTile("Add Rental Drone", Icons.precision_manufacturing, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AddDroneRentalForm(sellerId: _sellerId!)),
              );
            }),

            _buildTile("Add Drone Services", Icons.design_services, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddServiceForm(sellerId: _sellerId!)),
              );
            }),

            _buildTile("Add Jobs / Gigs", Icons.work_outline, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddJobForm(sellerId: _sellerId!)),
              );
            }),

            _buildTile("Add Hire Pilot", Icons.flight_takeoff, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AddHirePilotForm(sellerId: _sellerId!)),
              );
            }),

            const SizedBox(height: 20),

            // Product Status
            _buildSection("Product Status"),

            _buildTile("Sold Products", Icons.check_circle_outline, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SoldProductsPage()),
              );
            }),

            _buildTile("Rejected Products", Icons.cancel_outlined, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        RejectedProductsPage(
                            sellerCustomId: _sellerId!)),
              );
            }),

            _buildTile("Pending Products", Icons.pending_actions_outlined, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        PendingProductsPage(
                            sellerCustomId: _sellerId!)),
              );
            }),

            _buildTile("Approval Products", Icons.verified_outlined, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        ApprovalProductsPage(
                            sellerCustomId: _sellerId!)),
              );
            }),

            _buildTile("Return Products", Icons.keyboard_return_outlined, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReturnedProductsPage()),
              );
            }),

            _buildTile("Rental Drones", Icons.air_outlined, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SellerDroneRentalPage()),
              );
            }),

            _buildTile("Pilot Rental", Icons.person_pin_circle_rounded, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        PilotRentalPage(sellerId: _sellerId!)),
              );
            }),

            const SizedBox(height: 20),

            _buildSection("Account Settings"),

            _buildTile("Logout", Icons.logout, _logout),

            _buildSection("Legal & Support"),

            _buildTile("Terms & Conditions", Icons.description_outlined, () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TermsAndConditionsPage()));
            }),

            _buildTile("Privacy Policy", Icons.privacy_tip_outlined, () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyPage()));
            }),

            _buildTile("Help & Support", Icons.help_outline, () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HelpAndSupportPage()));
            }),

            _buildTile("Send Feedback", Icons.feedback_outlined, () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FeedbackFormPage()));
            }),

            const SizedBox(height: 10),
            const Text("Version 1.0.0",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildProfilePage(); // NO BOTTOM NAVIGATION
  }
}