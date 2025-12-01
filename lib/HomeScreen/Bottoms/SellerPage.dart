import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Settings Pages
import 'package:flyhub/Help_Support_Page.dart';
import 'package:flyhub/PrivacyPolicy.dart';
import 'package:flyhub/Terms_Conditions.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// Add Product Pages
import '../../AddDrone.dart';
import '../../Approval_Products_Page.dart';
import '../../HomeScreen/Bottoms/BuyerProfilePage.dart';
// import '../../HomeScreen/Bottoms/GuestProfilePage.dart';
import '../../Login/SellerLoginPage.dart';
import '../../Login/splashscreen.dart';
import '../../Pending_Products_Page.dart';
import '../../Rejected_Products_Page.dart';
import '../../Return_Product_Page.dart';
// Rental pages
import '../../Buyer_Return_Refund_Policy.dart';
import '../../Seller_Drone_Rental_Page.dart';
import '../../Seller_Pilot_Rental_Page.dart';
// Product Status Pages
import '../../Seller_Return_Refund_Policy.dart';
import '../../Seller_Shipping_Policy.dart';
import '../../Sold_Product_Page.dart';
import '../../add_accessories_form.dart';
import '../../add_drone_rental_form.dart';
import '../../add_hire_pilots_form.dart';
import '../../add_job_form.dart';
import '../../add_service_form.dart';
import '../../add_spare_parts.dart';
import '../../config/env.dart';
import '../../feedback_form.dart';
import '../../services/role_manager.dart';
import '../../jobApplyStatus.dart';
import '../../ServiceBookingStatus.dart';

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
  final String graphqlUrl = EnvConfig.baseUrl;

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
          MaterialPageRoute(builder: (_) => const Splashscreen()),
        );
        return;
      }

      await RoleManager.setLocalRole("seller");
      await _fetchOrCreateSeller(
        _user!.email ?? "",
        _user!.displayName ?? "",
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
          status
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
              'companyName': 'Nil',
              'PANnumber': 'Nil',
              'gstNumber': 'Unknown GST',
              'address': 'Unknown Address',
              'authorized': name,
              'email': email,
              'phoneNumber': 'N/A',
              'shippingAddresses': ['Unknown Address'],
              'pickupAddresses': ['Unknown Address'],
              'companyPan': 'Unknown Pan',
              'bankAccountNumber': 'Unknown Bank Account',
              'bankIFCnumber': 'Unknown BankIFC',
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

  bool get _isApproved {
    final status = _sellerData?['status'] ?? "";
    return status.toLowerCase() == "approved";
  }

  Future<void> _switchToBuyer() async {
    try {
      // Update role to buyer
      // await RoleManager.updateRole("buyer");
      if (!mounted) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: themeColor),
        ),
      );

      // Create GraphQL client
      final client = GraphQLClient(
        link: HttpLink(graphqlUrl),
        cache: GraphQLCache(),
      );

      // Check if buyer exists with this email
      const String query = r'''
      query BuyerByEmail($email: String!) {
        buyerByEmail(email: $email) {
          customId
          name
          email
        }
      }
      ''';

      final result = await client.query(
        QueryOptions(
          document: gql(query),
          variables: {'email': _user?.email ?? ""},
        ),
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      final buyer = result.data?['buyerByEmail'];

      if (buyer != null) {
        // Buyer exists, go directly to Buyer Profile Page
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BuyerProfilePage()),
        );
      } else {
        // Buyer doesn't exist, need to verify/login as buyer first
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SellerLoginPage()),
        );

        // Show message after navigation
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Please verify as a buyer to continue"),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        });
      }
    } catch (e) {
      debugPrint("❌ Switch to Buyer Error: $e");

      // Close loading dialog if open
      if (mounted) Navigator.pop(context);

      // On error, send to login page for safety
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SellerLoginPage()),
      );

      // Show error message
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
              Text("Error switching to buyer mode. Please login again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    await RoleManager.clearRole();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SellerLoginPage()),
          (route) => false,
    );
  }

  void _showMissingSellerSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("⚠ Seller ID not found")),
    );
  }

  void _showNotApprovedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: themeColor),
            const SizedBox(width: 10),
            const Text("Account Not Verified"),
          ],
        ),
        content: const Text(
          "After verifying your details, we will send your ID and email. "
              "My Store and Product Status sections will be enabled once approved.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: themeColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final name = _sellerData?['companyName'] ?? "Seller";
    final email = _sellerData?['email'] ?? "No email";
    final status = _sellerData?['status'] ?? "";
    final customId = _sellerData?['customId'] ?? "";

    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: themeColor,
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            if (!_isApproved)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.lock, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(email, style: const TextStyle(fontSize: 13, color: Colors.grey)),

        // Show customId only when status is "approved"
        if (_isApproved) ...[
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: themeColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: themeColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  "ID: $customId",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: themeColor,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pending, color: Colors.orange, size: 16),
                const SizedBox(width: 6),
                Text(
                  status.isEmpty
                      ? "Pending Verification"
                      : status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildTile(String label, IconData icon, VoidCallback onTap,
      {bool locked = false}) {
    return Opacity(
      opacity: locked ? 0.5 : 1.0,
      child: ListTile(
        leading: Icon(icon, color: locked ? Colors.grey : themeColor),
        title: Row(
          children: [
            Text(label,
                style: TextStyle(color: locked ? Colors.grey : Colors.black)),
            if (locked) ...[
              const SizedBox(width: 8),
              const Icon(Icons.lock, size: 14, color: Colors.grey),
            ],
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 14, color: locked ? Colors.grey : null),
        onTap: locked ? _showNotApprovedDialog : onTap,
      ),
    );
  }

  Widget _buildSection(String title, {bool locked = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: locked ? Colors.grey : Colors.black,
            ),
          ),
          if (locked) ...[
            const SizedBox(width: 8),
            const Icon(Icons.lock, size: 18, color: Colors.grey),
          ],
        ],
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

            // Show warning banner if not approved
            if (!_isApproved) ...[
              Container(
                margin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Your account is pending verification. My Store and Product Status will be enabled after approval.",
                        style: TextStyle(
                            fontSize: 12, color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            _buildSection("My Store", locked: !_isApproved),

            _buildTile("Add Drone for Sale", Icons.airplanemode_active, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddDronePage(sellerId: _sellerId!)),
              );
            }, locked: !_isApproved),

            _buildTile("Add Spare Parts", Icons.build, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AddSparePartForm(sellerId: _sellerId!)),
              );
            }, locked: !_isApproved),

            _buildTile("Add Accessories", Icons.memory, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AddAccessoryForm(sellerId: _sellerId!)),
              );
            }, locked: !_isApproved),

            _buildTile("Add Rental Drone", Icons.precision_manufacturing, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AddDroneRentalForm(sellerId: _sellerId!)),
              );
            }, locked: !_isApproved),

            _buildTile("Add Drone Services", Icons.design_services, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddServiceForm(sellerId: _sellerId!)),
              );
            }, locked: !_isApproved),

            _buildTile("Add Jobs / Gigs", Icons.work_outline, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddJobForm(sellerId: _sellerId!)),
              );
            }, locked: !_isApproved),

            _buildTile("Add Hire Pilot", Icons.flight_takeoff, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AddHirePilotForm(sellerId: _sellerId!)),
              );
            }, locked: !_isApproved),

            const SizedBox(height: 20),

            // Product Status
            _buildSection("Product Status", locked: !_isApproved),

            _buildTile("Sold Products", Icons.check_circle_outline, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SoldProductsPage()),
              );
            }, locked: !_isApproved),

            _buildTile("Rejected Products", Icons.cancel_outlined, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        RejectedProductsPage(sellerCustomId: _sellerId!)),
              );
            }, locked: !_isApproved),

            _buildTile("Pending Products", Icons.pending_actions_outlined, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        PendingProductsPage(sellerCustomId: _sellerId!)),
              );
            }, locked: !_isApproved),

            _buildTile("Approval Products", Icons.verified_outlined, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        ApprovalProductsPage(sellerCustomId: _sellerId!)),
              );
            }, locked: !_isApproved),

            _buildTile("Return Products", Icons.keyboard_return_outlined, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReturnedProductsPage()),
              );
            }, locked: !_isApproved),

            _buildTile("Rental Drones", Icons.air_outlined, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SellerDroneRentalPage()),
              );
            }, locked: !_isApproved),

            _buildTile("Pilot Rental", Icons.person_pin_circle_rounded, () {
              _sellerId == null
                  ? _showMissingSellerSnack()
                  : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        PilotRentalPage(sellerId: _sellerId!)),
              );
            }, locked: !_isApproved),

            _buildTile("Job Apply Status", Icons.work_history, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const JobApplyStatusPage()),
              );
            }, locked: !_isApproved),

            _buildTile("Service Booking Status", Icons.work_history, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ServiceBookingStatusPage()),
              );
            }, locked: !_isApproved),

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
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()));
            }),

            _buildTile("Shipping Policy", Icons.description_outlined, () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SellerShippingPolicyPage ()));
            }),
            _buildTile("Return & Refund Policy", Icons.description_outlined, () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SRRPolicy ()));
            }),


            _buildTile("Help & Support", Icons.help_outline, () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HelpAndSupportPage()));
            }),

            _buildTile("Send Feedback", Icons.feedback_outlined, () {
              Navigator.push(context,
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