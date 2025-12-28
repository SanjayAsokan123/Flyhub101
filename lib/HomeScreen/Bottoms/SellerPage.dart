import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
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
import '../../Orders/Return_Product_Page.dart';
import '../../Orders/Seller_Order_Page.dart';
// Rental pages
import '../../SellerBookingStatuses/Seller_Drone_Rental_Page.dart';
import '../../SellerBookingStatuses/Seller_Pilot_Rental_Page.dart';
// Product Status Pages
import '../../SellerBookingStatuses/Seller_Return_Policy.dart';
import '../../SellerBookingStatuses/Seller_Shipping_Policy.dart';
import '../../SellerBookingStatuses/ServiceBookingStatus.dart';
import '../../Orders/Sold_Product_Page.dart';
import '../../SellerAddingForm/add_accessories_form.dart';
import '../../SellerAddingForm/add_drone_rental_form.dart';
import '../../SellerAddingForm/add_hire_pilots_form.dart';
import '../../SellerAddingForm/add_job_form.dart';
import '../../SellerAddingForm/add_service_form.dart';
import '../../SellerAddingForm/add_spare_parts.dart';
import '../../T&C/Seller_settings.dart';
import '../../config/env.dart';
import '../../T&C/feedback_form.dart';
import '../../SellerBookingStatuses/jobApplyStatus.dart';
import '../../services/logout_service.dart';
import '../../services/role_manager.dart';

class SellerPage extends StatefulWidget {
  const SellerPage({super.key});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

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

  // Social Media URLs - Same as buyer page
  final Map<String, String> socialMediaUrls = {
    'instagram': 'https://www.instagram.com/flyhub_info',
    'linkedin': 'https://www.linkedin.com/company/flyhubinfo',
    'facebook': 'https://www.facebook.com/share/1A8fBiqxmt/',
    'whatsapp': 'https://wa.me/6379800193', // Replace with your number
  };

  final String graphqlUrl = EnvConfig.baseUrl;

  // Function to launch URLs
  Future<void> _launchSocialMedia(String platform) async {
    final url = socialMediaUrls[platform];

    if (url == null) {
      _showMessage("Link not available for $platform");
      return;
    }

    try {
      final uri = Uri.parse(url);

      if (platform == 'whatsapp' && url.contains('wa.me')) {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          final webUri = Uri.parse('https://web.whatsapp.com/');
          if (await canLaunchUrl(webUri)) {
            await launchUrl(webUri);
          } else {
            _showMessage("Could not launch WhatsApp");
          }
        }
      } else {
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          _showMessage("Could not launch $platform");
        }
      }
    } catch (e) {
      debugPrint("Error launching $platform: $e");
      _showMessage("Error opening $platform");
    }
  }

  // Social Icon Widget - Same as buyer page
  Widget _buildSocialIcon(String iconPath, {required VoidCallback onTap, String? tooltip}) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? '',
        child: Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: themeColor.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Image.asset(
            iconPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 20,
              );
            },
          ),
        ),
      ),
    );
  }

  // SVG Helper Methods
  Widget _buildSvgIcon(String assetPath, {Color? color, double size = 22}) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
      placeholderBuilder: (context) => Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.2),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
        ),
      ),
    );
  }

  // Method to get SVG asset path for My Store section
  String _getStoreSvgAssetPath(String label) {
    switch (label.toLowerCase()) {
      case 'add drone':
        return 'assets/categories/drone1.svg';
      case 'spare parts':
        return 'assets/categories/parts.svg';
      case 'accessories':
        return 'assets/categories/accessories.svg';
      case 'rental drone':
        return 'assets/categories/rentals.svg';
      case 'services':
        return 'assets/categories/services.svg';
      case 'jobs':
        return 'assets/categories/employee.svg';
      case 'hire pilot':
        return 'assets/categories/pilots.svg';
      default:
        return 'assets/icons/default.svg';
    }
  }

  // Method to get SVG asset path for Rental & Services section
  String _getRentalServiceSvgAssetPath(String title) {
    switch (title.toLowerCase()) {
      case 'rental drones':
        return 'assets/categories/drone1.svg';
      case 'pilot rental':
        return 'assets/categories/pilots.svg';
      case 'job apply status':
        return 'assets/categories/employee.svg';
      case 'service booking status':
        return 'assets/categories/services.svg';
      default:
        return 'assets/categories/default.svg';
    }
  }

  // SVG category item builder
  Widget _buildSvgCategoryItem({
    required String svgAsset,
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool disabled = false,
    double iconSize = 42,
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
              width: iconSize,
              height: iconSize,
              padding: EdgeInsets.all(iconSize * 0.15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _buildSvgIcon(
                svgAsset,
                color: disabled ? textLight : color,
                size: iconSize * 0.6,
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

  @override
  void initState() {
    super.initState();
    _initSellerPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: themeColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
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

  Widget _buildAvatar(String? companyName, {double size = 60}) {
    final String initials = companyName != null && companyName.isNotEmpty
        ? companyName[0].toUpperCase()
        : "S";

    return Container(
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
              _buildAvatar(name),
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

  // Updated _buildMenuItem to support SVG icons
  Widget _buildMenuItem({
    required String title,
    String? svgAsset,
    IconData? icon,
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
                  child: Center(
                    child: svgAsset != null
                        ? _buildSvgIcon(
                      svgAsset,
                      color: disabled ? textLight : (iconColor ?? themeColor),
                      size: 20,
                    )
                        : Icon(
                      icon,
                      color: disabled ? textLight : (iconColor ?? themeColor),
                      size: 18,
                    ),
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
        return _buildSvgCategoryItem(
          svgAsset: item['svgAsset'],
          label: item['label'],
          onTap: item['onTap'],
          color: item['color'],
          disabled: item['disabled'] ?? false,
        );
      },
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
        'svgAsset': _getStoreSvgAssetPath('Add Drone'),
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
        'svgAsset': _getStoreSvgAssetPath('Spare Parts'),
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
        'svgAsset': _getStoreSvgAssetPath('Accessories'),
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
        'svgAsset': _getStoreSvgAssetPath('Rental Drone'),
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
        'svgAsset': _getStoreSvgAssetPath('Services'),
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
        'svgAsset': _getStoreSvgAssetPath('Jobs'),
        'label': 'Jobs',
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
        'svgAsset': _getStoreSvgAssetPath('Hire Pilot'),
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
      {
        'svgAsset': _getStoreSvgAssetPath('Hire pilot'),
        'label': 'Orders',
        'color': Colors.brown,
        'disabled': !_isApproved,
        'onTap': () {
          if (_sellerId == null) {
            _showMissingSellerSnack();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SellerOrdersPage(sellerCustomId: _sellerId!),
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

      ),
      body: SingleChildScrollView(
        child: Column(
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

            // Rental & Services Section (Now with SVG icons)
            const SizedBox(height: 16),
            _buildSectionHeader("Rental & Services", Icons.handshake),
            const SizedBox(height: 4),
            ..._buildRentalServicesItems(),

            // Legal & Support Section
            const SizedBox(height: 16),
            _buildSectionHeader("Support", Icons.support_agent),
            const SizedBox(height: 4),
            ..._buildLegalSupportItems(),

            // Account Section
            const SizedBox(height: 16),
            _buildSectionHeader("Account", Icons.person_outline),
            const SizedBox(height: 4),

            // Settings Menu Item
            _buildMenuItem(
              title: "Settings",
              icon: Icons.settings,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SellerSettingsPage(
                      user: _user,
                      sellerData: _sellerData,
                      sellerId: _sellerId,
                    ),
                  ),
                );
              },
              iconColor: themeColor,
            ),

            // Logout Menu Item
            _buildLogoutItem(),

            // Follow Us Footer with Version info inside the same container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "Follow us on",
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Instagram
                      _buildSocialIcon(
                        'assets/categories/instagram.png',
                        onTap: () => _launchSocialMedia('instagram'),
                        tooltip: 'Follow us on Instagram',
                      ),
                      const SizedBox(width: 20),

                      // Facebook
                      _buildSocialIcon(
                        'assets/categories/facebook.png',
                        onTap: () => _launchSocialMedia('facebook'),
                        tooltip: 'Like us on Facebook',
                      ),
                      const SizedBox(width: 20),

                      // LinkedIn
                      _buildSocialIcon(
                        'assets/categories/linkedin.png',
                        onTap: () => _launchSocialMedia('linkedin'),
                        tooltip: 'Connect on LinkedIn',
                      ),
                      const SizedBox(width: 20),

                      // WhatsApp
                      _buildSocialIcon(
                        'assets/categories/whatsapp.png',
                        onTap: () => _launchSocialMedia('whatsapp'),
                        tooltip: 'Message us on WhatsApp',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Contact info
                  GestureDetector(
                    onTap: () async {
                      final Uri url = Uri.parse("https://www.flyhub.info");
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.withOpacity(1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.open_in_new, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            "Explore Our Website",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Version and Copyright - Inside the same container
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Text(
                          "v1.0.0",
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
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
        onTap: () {
          if (_sellerId == null) {
            _showMissingSellerSnack();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SoldProductsPage(sellerCustomId: _sellerId!),
            ),
          );
        },
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
          MaterialPageRoute(builder: (_) => ReturnedProductsPage(sellerCustomId: _sellerId!)),
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
        svgAsset: _getRentalServiceSvgAssetPath('Rental Drones'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SellerDroneRentalPage()),
        ),
        disabled: !_isApproved,
        iconColor: Color(0xFF3B82F6), // Blue
      ),
      _buildMenuItem(
        title: "Pilot Rental",
        svgAsset: _getRentalServiceSvgAssetPath('Pilot Rental'),
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
        iconColor: Color(0xFF8B5CF6), // Purple
      ),
      _buildMenuItem(
        title: "Job Apply Status",
        svgAsset: _getRentalServiceSvgAssetPath('Job Apply Status'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => JobApplyStatusPage(sellerId: _sellerId!)),
        ),
        disabled: !_isApproved,
        iconColor: Color(0xFF10B981), // Green
      ),
      _buildMenuItem(
        title: "Service Booking Status",
        svgAsset: _getRentalServiceSvgAssetPath('Service Booking Status'),
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
        iconColor: Color(0xFFF59E0B), // Amber
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