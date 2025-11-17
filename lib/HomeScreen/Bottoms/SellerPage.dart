import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flyhub/Help_Support_Page.dart';
import 'package:flyhub/PrivacyPolicy.dart';
import 'package:flyhub/Terms_Conditions.dart';
import 'package:flyhub/feedback_form.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../HomeScreen/Dynamichome.dart';
import '../../HomeScreen/Bottoms/BuyerProfilePage.dart';
import '../../HomeScreen/Bottoms/GuestProfilePage.dart';
import '../../services/role_manager.dart';

// Seller-related pages
import '../../AddDrone.dart';
import '../../add_spare_parts.dart';
import '../../add_drone_rental_form.dart';
import '../../add_service_form.dart';
import '../../add_job_form.dart';
import '../../add_accessories_form.dart';
import '../../add_hire_pilots_form.dart';
import 'admin_login.dart';

//DashBoard page
class SellerPage extends StatefulWidget {
  const SellerPage({super.key});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  Map<String, dynamic>? _sellerData;
  bool _loading = true;
  String? _sellerId;

  static const Color themeColor = Color(0xFF1A0A5B);
  // final String graphqlUrl = "http://192.168.1.45:5001/graphql";
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠ Error loading seller data: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 🧩 Fetch or Auto-Create Seller
  Future<void> _fetchOrCreateSeller(String email, String name) async {
    try {
      final HttpLink link = HttpLink(graphqlUrl);
      final client = GraphQLClient(link: link, cache: GraphQLCache());

      const String query = r'''
        query SellerByEmail($email: String!) {
          sellerByEmail(email: $email) {
            customId
            companyName
            address
            email
            gstNumber
          }
        }
      ''';

      final result = await client.query(
        QueryOptions(document: gql(query), variables: {'email': email}),
      );

      if (result.hasException) {
        debugPrint("⚠ GraphQL Fetch Error: ${result.exception}");
        return;
      }

      final seller = result.data?['sellerByEmail'];

      if (seller != null) {
        setState(() {
          _sellerData = seller;
          _sellerId = seller['customId'];
        });
        debugPrint("✅ Seller found in MongoDB: $_sellerId");
        return;
      }

      // Auto-create new seller
      debugPrint("⚙ Creating seller for $email");

      const String mutation = r'''
        mutation CreateSeller($input: SellerInput!) {
          createSeller(input: $input) {
            customId
            companyName
            email
            status
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
              'bankIFCnumber': 'AUTOIFSC1234',
              'bankAccountNumber': '0000000000',
              'authorized': name,
              'email': email,
              'phoneNumber': 'N/A',
              'shippingAddresses': ['Unknown Address'],
              'pickupAddresses': ['Unknown Address'],
              'companyPan': 'AUTO1234F',
              'bankName': 'Unknown',
            },
          },
        ),
      );

      if (createResult.hasException) {
        debugPrint("❌ CreateSeller Error: ${createResult.exception}");
        return;
      }

      final newSeller = createResult.data?['createSeller'];
      if (newSeller != null) {
        setState(() {
          _sellerData = newSeller;
          _sellerId = newSeller['customId'];
        });
        debugPrint("✅ Seller auto-created in MongoDB: $_sellerId");
      }
    } catch (e) {
      debugPrint("⚠ Fetch/Create Seller Error: $e");
    }
  }

  Future<void> _switchToBuyer() async {
    HapticFeedback.selectionClick();
    try {
      await RoleManager.updateRole("buyer");
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BuyerProfilePage()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Switched to Buyer Mode")),
      );
    } catch (e) {
      debugPrint("⚠ Error switching to buyer: $e");
    }
  }

  Future<void> _logout() async {
    HapticFeedback.lightImpact();
    await _auth.signOut();
    await RoleManager.clearRole();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
          (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("👋 Logged out successfully")),
    );
  }

  void _showMissingSellerSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
        Text("⚠ Seller ID not found. Please re-login or register again."),
      ),
    );
  }

  Widget _buildTile(String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: themeColor),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildHeader() {
    final name = _sellerData?['companyName'] ?? _user?.displayName ?? "Seller";
    final email = _sellerData?['email'] ?? _user?.email ?? "No email";

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: themeColor,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : "?",
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: themeColor)),
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
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [themeColor, themeColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    "Switch to Buyer",
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
            _buildTile("Add Spare Parts", Icons.build_outlined, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AddSparePartForm(sellerId: _sellerId!)),
              );
            }),
            _buildTile("Add Accessories", Icons.memory_rounded, () {
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
            _buildTile("Add Drone Services", Icons.design_services_outlined, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AddServiceForm(sellerId: _sellerId!)),
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
            _buildTile("Add Hire Pilot", Icons.flight_takeoff_rounded, () {
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
            _buildSection("Account Settings"),

            _buildTile("Logout", Icons.logout, _logout),

            const SizedBox(height: 20),
            _buildSection("Legal & Support"),

            _buildTile("Terms & Conditions", Icons.description_outlined, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsAndConditionsPage()),
              );
            }),

            _buildTile("Privacy Policy", Icons.privacy_tip_outlined, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Privacypolicy()),
              );
            }),

            _buildTile("Help & Support", Icons.help_outline, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpAndSupportPage()),
              );
            }),

            _buildTile("Send Feedback", Icons.feedback_outlined, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FeedbackFormPage()),
              );
            }),
            const Text("Version 1.0.0",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}