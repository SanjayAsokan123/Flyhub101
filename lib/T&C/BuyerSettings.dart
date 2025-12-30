import 'package:flutter/material.dart';
import 'package:flyhub/T&C/BuyerChangePassword.dart';
import 'package:flyhub/T&C/BuyerDeleteAccount.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 20, // consistent size
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A0A5B),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Settings Options
            Expanded(
              child: ListView(
                children: [
                  // Account Settings
                  _buildSectionTitle('Account'),
                  _buildSettingItem(
                    icon: Icons.lock_outlined,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: () => _navigateToChangePasswordPage(context),
                  ),

                  const SizedBox(height: 20),

                  // Danger Zone
                  _buildSectionTitle('Danger Zone'),
                  _buildDangerItem(
                    icon: Icons.delete_outline,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account',
                    onTap: () => _navigateToDeleteAccountPage(context),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section Title Widget
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  // Regular Setting Item Widget
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1A0A5B)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A0A5B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Color(0xFF1A0A5B)),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // Danger Zone Item Widget
  Widget _buildDangerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade300),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.red),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.red,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.red[700],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.red),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // ============ DIALOGS & FUNCTIONS ============

  // Navigation to separate pages
  void _navigateToChangePasswordPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
    );
  }

  void _navigateToDeleteAccountPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DeleteAccountPage()),
    );
  }

  // Success Dialog
  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Error Dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        icon: const Icon(Icons.error, color: Colors.red, size: 40),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _updateProfile(String name, String email, String phone) {
    // Call your API to update profile
    // await userService.updateProfile(name: name, email: email, phone: phone);

    _showSuccessDialog(context, 'Profile updated successfully!');
  }

  void _updateEmail(String email) {
    // Call your API to update email
    // await userService.updateEmail(email: email);

    _showSuccessDialog(context, 'Email updated successfully!');
  }

  void _updatePhone(String phone) {
    // Call your API to update phone
    // await userService.updatePhone(phone: phone);

    _showSuccessDialog(context, 'Phone number updated successfully!');
  }

  void _toggleDarkMode(bool value) {
    // Implement dark mode logic
    // You can use Provider or Theme.of(context) to change theme

    if (value) {
      // Set dark theme
      // Theme.of(context).copyWith(brightness: Brightness.dark);
    } else {
      // Set light theme
      // Theme.of(context).copyWith(brightness: Brightness.light);
    }

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Dark mode enabled' : 'Dark mode disabled'),
        backgroundColor: const Color(0xFF1A0A5B),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}