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
        actions: [
          if (currentUser != null && !currentUser!.emailVerified)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: isCheckingEmailVerification
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      themeColor,
                    ),
                  ),
                )
                    : TextButton.icon(
                  onPressed: _refreshEmailVerificationStatus,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: TextButton.styleFrom(
                    foregroundColor: themeColor,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(),
              const SizedBox(height: 24),
              _buildEmailVerificationSection(),
              _buildAccountSettingsSection(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------ UI SECTIONS ------------------

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
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
                width: 60,
                height: 60,
                errorBuilder: (context, error, stackTrace) {
                  final name = widget.sellerData?['companyName'] as String?;
                  final initial = (name != null && name.isNotEmpty)
                      ? name[0].toUpperCase()
                      : 'S';
                  return Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [themeColor, primaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.sellerData?['companyName'] ?? 'Seller',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser?.email ?? 'No email',
                  style: const TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.sellerId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'ID: ${widget.sellerId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ),
                if (currentUser != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: currentUser!.emailVerified
                            ? successColor.withOpacity(0.2)
                            : warningColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: currentUser!.emailVerified
                              ? successColor.withOpacity(0.5)
                              : warningColor.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            currentUser!.emailVerified
                                ? Icons.verified
                                : Icons.warning,
                            size: 14,
                            color: currentUser!.emailVerified
                                ? successColor
                                : warningColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            currentUser!.emailVerified
                                ? 'Verified'
                                : 'Not Verified',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: currentUser!.emailVerified
                                  ? successColor
                                  : warningColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailVerificationSection() {
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    if (!currentUser!.emailVerified) {
      return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20, top: 8),
          decoration: BoxDecoration(
            color: errorColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorColor.withOpacity(0.6),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.error_outline,
                    color: errorColor,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Email verification required',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: errorColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'You must verify your email before changing your password. '
                    'A verification link has been sent to ${currentUser!.email}.',
                style: const TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Steps:\n• Open your email inbox\n• Click the verification link\n• Return here and tap Refresh',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _sendVerificationEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: errorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.mark_email_unread, size: 18),
                      label: const Text(
                        'Resend email',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isCheckingEmailVerification
                          ? null
                          : _refreshEmailVerificationStatus,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: errorColor,
                        side: const BorderSide(color: errorColor),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: isCheckingEmailVerification
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(errorColor),
                        ),
                      )
                          : const Icon(Icons.refresh, size: 18),
                      label: const Text(
                        'Refresh',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

          )
      );
    }

    // If verified, show small success card
    return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 20, top: 8),
        decoration: BoxDecoration(
          color: successColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: successColor.withOpacity(0.4),
          ),
        ),
        child: Row(
          children: const [
            Icon(
              Icons.verified,
              color: successColor,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your email is verified. You can change your password.',
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        )
    );


  }

  Widget _buildAccountSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
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
              _showErrorSnackBar(
                'Please verify your email first to change password.',
              );
              return;
            }

            // ✅ Fixed: Removed customId parameter since ChangePasswordPage doesn't need it
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) => SellerPasswordProvider(),
                  child: ChangePasswordPage(
                    user: currentUser!, // ✅ Only passing user
                  ),
                ),
              ),
            );
          },
          isDisabled: currentUser == null || !currentUser!.emailVerified,
        ),
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