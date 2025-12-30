import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'seller_changePassword.dart';
import 'Seller_deactivate.dart';
import '../Login/SellerEditProfile.dart';
import '../services/seller_password_provider.dart';

class SellerSettingsPage extends StatefulWidget {
  final User? user;
  final Map<String, dynamic>? sellerData;
  final String? sellerId;

  const SellerSettingsPage({
    super.key,
    required this.user,
    required this.sellerData,
    required this.sellerId,
  });

  @override
  State<SellerSettingsPage> createState() => _SellerSettingsPageState();
}

class _SellerSettingsPageState extends State<SellerSettingsPage> {
  User? currentUser;
  bool isCheckingEmailVerification = false;

  // Colors
  static const Color themeColor = Color(0xFF1A0A5B);
  static const Color primaryColor = Color(0xFF1E0E5C);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    _refreshEmailVerificationStatus();
  }

  Future<void> _refreshEmailVerificationStatus() async {
    if (currentUser == null) return;

    try {
      setState(() {
        isCheckingEmailVerification = true;
      });

      await currentUser!.reload();
      setState(() {
        currentUser = FirebaseAuth.instance.currentUser;
        isCheckingEmailVerification = false;
      });
    } catch (e) {
      setState(() {
        isCheckingEmailVerification = false;
      });
      debugPrint('Error refreshing email verification: $e');
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (currentUser == null) {
      _showErrorSnackBar('User not found');
      return;
    }

    try {
      await currentUser!.sendEmailVerification();
      _showSuccessSnackBar(
        'Verification email sent to ${currentUser!.email}. Please check your inbox and spam folder.',
      );
    } catch (e) {
      _showErrorSnackBar(
        'Failed to send verification email: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAccountSettingsSection(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(
          color: Color(0xFFE5E7EB),
          thickness: 1,
        ),
        const SizedBox(height: 16),

        // Edit Profile Card
        _buildSettingsCard(
          context: context,
          icon: Icons.edit,
          iconColor: successColor,
          title: 'Edit Profile',
          subtitle: 'Update your personal information',
          onTap: () {
            if (widget.sellerId != null && widget.sellerData != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditSellerProfile(
                    sellerId: widget.sellerId!,
                    sellerData: widget.sellerData!,
                  ),
                ),
              );
            } else {
              _showErrorSnackBar('Cannot edit profile: Missing data');
            }
          },
          isDisabled: false,
        ),

        // Change Password Card
        _buildSettingsCard(
          context: context,
          icon: Icons.lock_reset,
          iconColor: Colors.blue,
          title: 'Change Password',
          subtitle: (currentUser == null || !currentUser!.emailVerified)
              ? 'Verify your email first'
              : 'Update your password securely',
          onTap: () {
            if (currentUser == null) {
              _showErrorSnackBar('User not found. Please log in again.');
              return;
            }
            if (!currentUser!.emailVerified) {
              _showEmailVerificationDialog();
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) => SellerPasswordProvider(),
                  child: ChangePasswordPage(
                    user: currentUser!,
                  ),
                ),
              ),
            );
          },
          isDisabled: currentUser == null || !currentUser!.emailVerified,
        ),

        // Deactivate Account Card
        _buildSettingsCard(
          context: context,
          icon: Icons.person_remove,
          iconColor: errorColor,
          title: 'Deactivate Account',
          subtitle: 'Temporarily disable your account',
          onTap: () {
            if (widget.sellerId != null && widget.sellerData != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeactivateAccountPage(
                    sellerId: widget.sellerId!,
                    sellerData: widget.sellerData!,
                  ),
                ),
              );
            } else {
              _showErrorSnackBar(
                'Cannot deactivate account: Missing data',
              );
            }
          },
          isDisabled: false,
          titleColor: errorColor,
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDisabled,
    Color? titleColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey[100] : cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(isDisabled ? 0.05 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isDisabled ? Colors.grey[400] : iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDisabled
                              ? Colors.grey[400]
                              : (titleColor ?? textPrimary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDisabled ? Colors.grey[400] : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isDisabled ? Colors.grey[400] : textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.email, color: errorColor),
            SizedBox(width: 10),
            Text('Email Verification Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You need to verify your email before changing your password.',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${currentUser?.email ?? 'Not available'}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textSecondary,
                      side: BorderSide(color: textSecondary.withOpacity(0.3)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _sendVerificationEmail();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: errorColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Send Email'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ SNACKBARS ------------------

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}