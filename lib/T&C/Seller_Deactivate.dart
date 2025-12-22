import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../CommonClass/ApiClass.dart'; // Your ApiClass

// Deactivate Account Page
class DeactivateAccountPage extends StatefulWidget {
  final String? sellerId;
  final Map<String, dynamic>? sellerData;

  const DeactivateAccountPage({
    super.key,
    required this.sellerId,
    required this.sellerData,
  });

  @override
  State<DeactivateAccountPage> createState() => _DeactivateAccountPageState();
}

class _DeactivateAccountPageState extends State<DeactivateAccountPage> {
  bool _isDeactivating = false;
  bool _isLoading = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiClass _api = ApiClass();
  Map<String, dynamic>? _fetchedSellerData;

  @override
  void initState() {
    super.initState();
    _fetchSellerData();
  }

  Future<void> _fetchSellerData() async {
    try {
      final result = await _api.getSellerDataForDeactivation();
      if (result.status == "success" && result.data != null) {
        setState(() {
          _fetchedSellerData = result.data;
        });
      } else {
        debugPrint("⚠ Failed to fetch seller data: ${result.message}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching seller data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Color(0xFF1A0A5B);
    const Color textPrimary = Color(0xFF1F2937);
    const Color textSecondary = Color(0xFF6B7280);
    const Color borderColor = Color(0xFFE5E7EB);
    const Color errorColor = Color(0xFFEF4444);
    const Color warningColor = Color(0xFFF59E0B);
    const Color successColor = Color(0xFF10B981);
    const Color cardColor = Colors.white;
    const Color backgroundColor = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Deactivate Account",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: errorColor,
          ),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: errorColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: errorColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Please read the information below carefully before deactivating your account.",
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Account Info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Account to be Deactivated",
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.business,
                          color: textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _fetchedSellerData?['companyName'] ??
                                widget.sellerData?['companyName'] ??
                                "Seller",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.email,
                          color: textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _fetchedSellerData?['email'] ??
                                widget.sellerData?['email'] ??
                                "No email",
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_fetchedSellerData?['customId'] != null ||
                        widget.sellerId != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.numbers,
                            color: textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Seller ID: ${_fetchedSellerData?['customId'] ?? widget.sellerId}",
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Consequences Section
              Text(
                "What happens when you deactivate:",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: warningColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: warningColor.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    _buildConsequenceItem(
                      icon: Icons.visibility_off,
                      text: "Your account will be hidden from buyers",
                      color: warningColor,
                    ),
                    const SizedBox(height: 12),
                    _buildConsequenceItem(
                      icon: Icons.store_mall_directory_outlined,
                      text: "Your products will not be visible",
                      color: warningColor,
                    ),
                    const SizedBox(height: 12),
                    _buildConsequenceItem(
                      icon: Icons.block,
                      text: "You won't receive new Orders",
                      color: warningColor,
                    ),
                    const SizedBox(height: 12),
                    _buildConsequenceItem(
                      icon: Icons.lock_clock,
                      text: "Account data will be preserved",
                      color: successColor,
                    ),
                    const SizedBox(height: 12),
                    _buildConsequenceItem(
                      icon: Icons.restore,
                      text: "You can reactivate anytime by logging in",
                      color: successColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Important Notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: errorColor.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "By clicking 'Deactivate Account', you acknowledge that you have read and understood all the consequences mentioned above.",
                        style: TextStyle(
                          fontSize: 14,
                          color: textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Deactivate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isDeactivating ? null : () => _showConfirmationDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: errorColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isDeactivating
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text("Deactivating..."),
                    ],
                  )
                      : const Text(
                    "Deactivate Account",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isDeactivating ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textSecondary,
                    side: BorderSide(color: borderColor, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Cancel"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsequenceItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    const Color textPrimary = Color(0xFF1F2937);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // Check authentication before showing dialog
  void _showConfirmationDialog(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) {
      _showErrorDialog(context, "You are not logged in. Please login first.");
      return;
    }

    // Try to refresh token
    try {
      await user.getIdToken(true); // Force refresh
    } catch (e) {
      _showErrorDialog(context, "Session expired. Please login again.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text("Confirm Deactivation"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Are you absolutely sure you want to deactivate your account?",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            RichText(
              text: const TextSpan(
                style: TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(text: "This action will:\n"),
                  TextSpan(text: "• Hide your account from buyers\n"),
                  TextSpan(text: "• Hide all your products\n"),
                  TextSpan(text: "• Stop new Orders\n"),
                  TextSpan(text: "• Preserve your data for reactivation\n\n"),
                  TextSpan(
                    text: "You can reactivate anytime by logging in.",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _performDeactivation(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Deactivate Account"),
          ),
        ],
      ),
    );
  }

  // Perform the actual deactivation
  Future<void> _performDeactivation(BuildContext context) async {
    setState(() {
      _isDeactivating = true;
    });

    try {
      // Check authentication again
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("You are not logged in. Please login first.");
      }

      // Get fresh token
      await user.getIdToken(true);

      debugPrint("👤 Current user UID: ${user.uid}");
      debugPrint("📧 Current user email: ${user.email}");

      // Call the API to deactivate account
      final result = await _api.deactivateSellerAccount(
        reason: "Seller requested account deactivation",
      );

      debugPrint("📡 API Response: ${result.status}");
      debugPrint("📡 API Message: ${result.message}");
      debugPrint("📡 API Data: ${result.data}");

      if (result.status == "success") {
        // Show success message
        _showSuccessDialog(context);
      } else {
        // Show error message
        _showErrorDialog(context, result.message ?? "Failed to deactivate account");
      }
    } catch (e) {
      debugPrint("❌ Deactivation error: $e");

      String errorMessage = "Error: ${e.toString()}";

      // Provide user-friendly error messages
      if (e.toString().contains("Authentication") ||
          e.toString().contains("login") ||
          e.toString().contains("token")) {
        errorMessage = "Authentication failed. Please login again.";
      } else if (e.toString().contains("firebaseUid")) {
        errorMessage = "Seller account not linked to Firebase. Please contact support.";
      } else if (e.toString().contains("timeout")) {
        errorMessage = "Request timed out. Please check your internet connection.";
      } else if (e.toString().contains("network")) {
        errorMessage = "Network error. Please check your internet connection.";
      }

      _showErrorDialog(context, errorMessage);
    } finally {
      setState(() {
        _isDeactivating = false;
      });
    }
  }

  // Show success dialog
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text("Account Deactivated"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your account has been successfully deactivated.",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            RichText(
              text: const TextSpan(
                style: TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(text: "What happens next:\n"),
                  TextSpan(text: "✓ Your account is now hidden\n"),
                  TextSpan(text: "✓ Your products are not visible\n"),
                  TextSpan(text: "✓ No new Orders will be received\n"),
                  TextSpan(text: "✓ You've been logged out\n\n"),
                  TextSpan(
                    text: "You can reactivate anytime by logging in.",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => _logoutAndNavigate(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text("OK, Logout"),
          ),
        ],
      ),
    );
  }

  // Show error dialog
  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text("Deactivation Failed"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorMessage),
              const SizedBox(height: 16),
              if (errorMessage.contains("Authentication") ||
                  errorMessage.contains("login"))
                const Text(
                  "Please try logging out and logging in again, then retry.",
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // Logout and navigate to login screen
  Future<void> _logoutAndNavigate(BuildContext context) async {
    try {
      // Sign out from Firebase
      await _auth.signOut();

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Navigate to login screen and remove all routes
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/seller/login', // Replace with your actual login route
            (route) => false,
      );

      // Show a final message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Account deactivated successfully. You have been logged out."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      debugPrint("❌ Logout error: $e");
      // If navigation fails, just pop to root
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/', // Your app's root route
            (route) => false,
      );
    }
  }
}