import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flyhub/Login/FlyHubSelectionPage.dart';
// Settings Pages
import 'package:flyhub/T&C/Help_Support_Page.dart';
import 'package:flyhub/T&C/PrivacyPolicy.dart';
import 'package:flyhub/T&C/Terms_Conditions.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// Add Product Pages
import '../../SellerAddingForm/AddDrone.dart';
import '../../SellerBookingStatuses/Approval_Products_Page.dart';
import '../../HomeScreen/Bottoms/BuyerProfilePage.dart';
import '../../Login/SellerLoginPage.dart';
import '../../Login/splashscreen.dart';
import '../../SellerBookingStatuses/Pending_Products_Page.dart';
import '../../SellerBookingStatuses/Rejected_Products_Page.dart';
import '../../Return_Product_Page.dart';
// Rental pages
import '../../SellerBookingStatuses/Seller_Drone_Rental_Page.dart';
import '../../SellerBookingStatuses/Seller_Pilot_Rental_Page.dart';
// Product Status Pages
import '../../SellerBookingStatuses/Seller_Return_Refund_Policy.dart';
import '../../SellerBookingStatuses/Seller_Shipping_Policy.dart';
import '../../BuyerBookingStatuses/ServiceBookingStatus.dart';
import '../../Sold_Product_Page.dart';
import '../../SellerAddingForm/add_accessories_form.dart';
import '../../SellerAddingForm/add_drone_rental_form.dart';
import '../../SellerAddingForm/add_hire_pilots_form.dart';
import '../../SellerAddingForm/add_job_form.dart';
import '../../SellerAddingForm/add_service_form.dart';
import '../../SellerAddingForm/add_spare_parts.dart';
import '../../config/env.dart';
import '../../T&C/feedback_form.dart';
import '../../SellerBookingStatuses/jobApplyStatus.dart';
import '../../services/logout_service.dart';
import '../../services/role_manager.dart';

// Add this import for EditSellerProfile
import '../../Login/SellerEditProfile.dart';

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

  // Modern color palette based on themeColor (#1A0A5B)
  static const Color themeColor = Color(0xFF1A0A5B); // Deep Indigo
  static const Color primaryColor = Color(0xFF1E0E5C); // Dark blue-purple
  static const Color primaryLight = Color(0xFF2A1A6E);
  static const Color secondaryColor = Color(0xFF10B981); // Emerald green
  static const Color accentColor = Color(0xFFF59E0B); // Amber
  static const Color backgroundColor = Color(0xFFF8FAFC); // Light background
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937); // Dark gray
  static const Color textSecondary = Color(0xFF6B7280); // Medium gray
  static const Color textLight = Color(0xFF9CA3AF); // Light gray
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color successColor = Color(0xFF10B981);

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

  // Add this method to navigate to Edit Profile
  void _navigateToEditProfile() async {
    if (_sellerId == null || _sellerData == null) {
      _showMissingSellerSnack();
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditSellerProfile(
          sellerData: _sellerData!,
          sellerId: _sellerId!,
        ),
      ),
    );

    // Refresh data if profile was updated
    if (result == true && mounted) {
      setState(() => _loading = true);
      await _fetchOrCreateSeller(
        _user!.email ?? "",
        _user!.displayName ?? "",
      );
      setState(() => _loading = false);
    }
  }

  Future<void> _switchToBuyer() async {
    try {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            width: 140,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                ),
                const SizedBox(height: 16),
                Text(
                  "Switching to Buyer...",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final client = GraphQLClient(
        link: HttpLink(graphqlUrl),
        cache: GraphQLCache(),
      );

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

      if (mounted) Navigator.pop(context);

      final buyer = result.data?['buyerByEmail'];

      if (buyer != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BuyerProfilePage()),
        );
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FlyHubSelectionPage()),
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Please verify as a buyer to continue"),
                backgroundColor: warningColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            );
          }
        });
      }
    } catch (e) {
      debugPrint("❌ Switch to Buyer Error: $e");

      if (mounted) Navigator.pop(context);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SellerLoginPage()),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  "Error switching to buyer mode. Please login again."),
              backgroundColor: errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          );
        }
      });
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: errorColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout,
                    color: errorColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Logout",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Are you sure you want to logout?",
                  style: TextStyle(
                    fontSize: 15,
                    color: textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textSecondary,
                          side: BorderSide(color: borderColor, width: 1),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          LogoutService.logoutSeller(context, _sellerId!);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: errorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text("Logout"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeColor.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/profile.jpg',
                  fit: BoxFit.cover,
                  width: 80,
                  height: 80,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint("❌ Loading screen image error: $error");
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [themeColor, primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.store_mall_directory_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Loading Dashboard",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: borderColor,
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                borderRadius: BorderRadius.circular(10),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated _buildAvatar method with edit icon
  Widget _buildAvatar(String? companyName, {double size = 60, bool showEditIcon = true}) {
    final String initials = companyName != null && companyName.isNotEmpty
        ? companyName[0].toUpperCase()
        : "S";

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: themeColor.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/profile.jpg',
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [themeColor, primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (showEditIcon)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _navigateToEditProfile,
              child: Container(
                width: size * 0.35,
                height: size * 0.35,
                decoration: BoxDecoration(
                  color: themeColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: size * 0.2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    final name = _sellerData?['companyName'] ?? "Seller";
    final email = _sellerData?['email'] ?? "No email";
    final status = _sellerData?['status'] ?? "";
    final customId = _sellerData?['customId'] ?? "";

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(name, showEditIcon: true), // Updated with edit icon
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!_isApproved)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: warningColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock,
                        color: warningColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Pending",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: warningColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Seller Status",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _isApproved ? Icons.verified : Icons.pending,
                      color: _isApproved ? successColor : warningColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isApproved ? "Verified Seller" : "Pending Verification",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _isApproved ? successColor : warningColor,
                      ),
                    ),
                    const Spacer(),
                    if (_isApproved && customId.isNotEmpty)
                      Text(
                        "ID: $customId",
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: themeColor,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    bool disabled = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (iconColor ?? themeColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: disabled ? textLight : (iconColor ?? themeColor),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: disabled ? textLight : textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: disabled ? textLight : textSecondary,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.99,
      ),
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildCategoryItem(
          icon: item['icon'],
          label: item['label'],
          onTap: item['onTap'],
          color: item['color'],
          disabled: item['disabled'] ?? false,
        );
      },
    );
  }

  Widget _buildCategoryItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: disabled ? textLight : color,
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: disabled ? textLight : textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMissingSellerSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("⚠ Seller ID not found"),
        backgroundColor: warningColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showNotApprovedDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: warningColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock,
                    color: warningColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Account Not Verified",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "After verifying your details, we will send your ID and email. "
                      "My Store and Product Status sections will be enabled once approved.",
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("OK"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildProfilePage() {
    if (_loading) {
      return _buildLoadingScreen();
    }

    final storeItems = [
      {
        'icon': Icons.airplanemode_active,
        'label': 'Add Drone',
        'color': Colors.blue,
        'disabled': !_isApproved,
        'onTap': () {
          if (_sellerId == null) {
            _showMissingSellerSnack();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddDronePage(sellerId: _sellerId!),
            ),
          );
        },
      },
      {
        'icon': Icons.build,
        'label': 'Spare Parts',
        'color': Colors.green,
        'disabled': !_isApproved,
        'onTap': () {
          if (_sellerId == null) {
            _showMissingSellerSnack();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddSparePartForm(sellerId: _sellerId!),
            ),
          );
        },
      },
      {
        'icon': Icons.memory,
        'label': 'Accessories',
        'color': Colors.orange,
        'disabled': !_isApproved,
        'onTap': () {
          if (_sellerId == null) {
            _showMissingSellerSnack();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddAccessoryForm(sellerId: _sellerId!),
            ),
          );
        },
      },
      {
        'icon': Icons.precision_manufacturing,
        'label': 'Rental Drone',
        'color': Colors.purple,
        'disabled': !_isApproved,
        'onTap': () {
          if (_sellerId == null) {
            _showMissingSellerSnack();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddDroneRentalForm(sellerId: _sellerId!),
            ),
          );
        },
      },
      {
        'icon': Icons.design_services,
        'label': 'Services',
        'color': Colors.teal,
        'disabled': !_isApproved,
        'onTap': () {
          if (_sellerId == null) {
            _showMissingSellerSnack();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddServiceForm(sellerId: _sellerId!),
            ),
          );
        },
      },
      {
        'icon': Icons.work_outline,
        'label': 'Jobs/Gigs',
        'color': Colors.red,
        'disabled': !_isApproved,
        'onTap': () {
          if (_sellerId == null) {
            _showMissingSellerSnack();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddJobForm(sellerId: _sellerId!),
            ),
          );
        },
      },
      {
        'icon': Icons.flight_takeoff,
        'label': 'Hire Pilot',
        'color': Colors.indigo,
        'disabled': !_isApproved,
        'onTap': () {
          if (_sellerId == null) {
            _showMissingSellerSnack();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddHirePilotForm(sellerId: _sellerId!),
            ),
          );
        },
      },
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Seller Dashboard",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _switchToBuyer,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.swap_horiz,
                color: themeColor,
                size: 20,
              ),
            ),
            tooltip: "Switch to Buyer",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),

            // Warning banner if not approved
            if (!_isApproved)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: warningColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: warningColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Your account is pending verification. My Store and Product Status will be enabled after approval.",
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // My Store Section
            const SizedBox(height: 16),
            _buildSectionHeader("My Store", Icons.storefront),
            const SizedBox(height: 4),
            _buildCategoryGrid(storeItems),

            // Product Status Section
            const SizedBox(height: 16),
            _buildSectionHeader("Product Status", Icons.analytics_outlined),
            const SizedBox(height: 4),
            ..._buildProductStatusItems(),

            // Rental & Services Section
            const SizedBox(height: 16),
            _buildSectionHeader("Rental & Services", Icons.work_outline),
            const SizedBox(height: 4),
            ..._buildRentalServicesItems(),

            // Legal & Support Section
            const SizedBox(height: 16),
            _buildSectionHeader("Legal & Support", Icons.gavel),
            const SizedBox(height: 4),
            ..._buildLegalSupportItems(),

            // Account Settings Section
            const SizedBox(height: 16),
            _buildSectionHeader("Account Settings", Icons.settings),
            const SizedBox(height: 4),
            _buildLogoutItem(),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      "Version 1.0.0",
                      style: TextStyle(
                        fontSize: 12,
                        color: textLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProductStatusItems() {
    return [
      _buildMenuItem(
        title: "Sold Products",
        icon: Icons.check_circle_outline,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SoldProductsPage()),
        ),
        disabled: !_isApproved,
        iconColor: themeColor,
      ),
      _buildMenuItem(
        title: "Rejected Products",
        icon: Icons.cancel_outlined,
        onTap: () {
          if (_sellerId == null) {
            _showMissingSellerSnack();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RejectedProductsPage(sellerCustomId: _sellerId!),
            ),
          );
        },
        disabled: !_isApproved,
        iconColor: themeColor,
      ),
      _buildMenuItem(
        title: "Pending Products",
        icon: Icons.pending_actions_outlined,
        onTap: () {
          if (_sellerId == null) {
            _showMissingSellerSnack();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PendingProductsPage(sellerCustomId: _sellerId!),
            ),
          );
        },
        disabled: !_isApproved,
        iconColor: themeColor,
      ),
      _buildMenuItem(
        title: "Approved Products",
        icon: Icons.verified_outlined,
        onTap: () {
          if (_sellerId == null) {
            _showMissingSellerSnack();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ApprovalProductsPage(sellerCustomId: _sellerId!),
            ),
          );
        },
        disabled: !_isApproved,
        iconColor: themeColor,
      ),
      _buildMenuItem(
        title: "Return Products",
        icon: Icons.keyboard_return_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReturnedProductsPage()),
        ),
        disabled: !_isApproved,
        iconColor: themeColor,
      ),
    ];
  }

  List<Widget> _buildRentalServicesItems() {
    return [
      _buildMenuItem(
        title: "Rental Drones",
        icon: Icons.air_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SellerDroneRentalPage()),
        ),
        disabled: !_isApproved,
        iconColor: themeColor,
      ),
      _buildMenuItem(
        title: "Pilot Rental",
        icon: Icons.person_pin_circle_rounded,
        onTap: () {
          if (_sellerId == null) {
            _showMissingSellerSnack();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SellerPilotBookingStatusPage(sellerId: _sellerId!),
            ),
          );
        },
        disabled: !_isApproved,
        iconColor: themeColor,
      ),
      _buildMenuItem(
        title: "Job Apply Status",
        icon: Icons.work_history,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => JobApplyStatusPage(sellerId: _sellerId!)),
        ),
        disabled: !_isApproved,
        iconColor: themeColor,
      ),
      _buildMenuItem(
        title: "Service Booking Status",
        icon: Icons.work_history,
        onTap: () {
          if (_sellerId == null) {
            _showMissingSellerSnack();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceBookingStatusPage(sellerId: _sellerId!),
            ),
          );
        },
        disabled: !_isApproved,
        iconColor: themeColor,
      ),
    ];
  }

  List<Widget> _buildLegalSupportItems() {
    return [
      _buildMenuItem(
        title: "Terms & Conditions",
        icon: Icons.description_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TermsAndConditionsPage()),
        ),
        iconColor: themeColor,
      ),
      _buildMenuItem(
        title: "Privacy Policy",
        icon: Icons.privacy_tip_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
        ),
        iconColor: themeColor,
      ),
      _buildMenuItem(
        title: "Shipping Policy",
        icon: Icons.local_shipping,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SellerShippingPolicyPage()),
        ),
        iconColor: themeColor,
      ),
      _buildMenuItem(
        title: "Return & Refund Policy",
        icon: Icons.assignment_return,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SRRPolicy()),
        ),
        iconColor: themeColor,
      ),
      _buildMenuItem(
        title: "Help & Support",
        icon: Icons.help_outline,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HelpAndSupportPage()),
        ),
        iconColor: themeColor,
      ),
      _buildMenuItem(
        title: "Send Feedback",
        icon: Icons.feedback_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FeedbackFormPage()),
        ),
        iconColor: themeColor,
      ),
    ];
  }

  Widget _buildLogoutItem() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _logout,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: errorColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: errorColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.logout,
                    color: errorColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Logout",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: errorColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: errorColor,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildProfilePage();
  }
}