import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flyhub/HomeScreen/Dynamichome.dart';
import 'package:flyhub/Login/SellerLoginPage.dart';
import 'package:flyhub/Login/BuyerLoginPage.dart';
import 'package:flyhub/services/role_manager.dart';
import 'package:flyhub/services/local_storage_service.dart';

class FlyHubSelectionPage extends StatefulWidget {
  const FlyHubSelectionPage({super.key});

  @override
  State<FlyHubSelectionPage> createState() => _FlyHubSelectionPageState();
}

class _FlyHubSelectionPageState extends State<FlyHubSelectionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ✅ SIMPLIFIED: Check if user already has a selected role
  Future<bool> _hasSelectedRole(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString('role');
      return savedRole == role;
    } catch (e) {
      print('❌ Error checking role: $e');
      return false;
    }
  }

  // ✅ Handle Seller Navigation - SIMPLIFIED VERSION
  Future<void> _handleSellerTap() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // ALWAYS go to SellerLoginPage for new selection
      print('✅ Seller selected → Going to SellerLoginPage');

      // Save role preference
      await RoleManager.setLocalRole("seller");
      await LocalStorageService.saveUserDetails(
        userId: "",
        name: "",
        role: "seller",
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const SellerLoginPage(),
          ),
        );
      }
    } catch (e) {
      print('❌ Error in seller tap: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ Handle Buyer Navigation - SIMPLIFIED VERSION
  Future<void> _handleBuyerTap() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // ALWAYS go to BuyerLoginPage for new selection
      print('✅ Buyer selected → Going to BuyerLoginPage');

      // Save role preference
      await RoleManager.setLocalRole("buyer");
      await LocalStorageService.saveUserDetails(
        userId: "",
        name: "",
        role: "buyer",
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const BuyerLoginPage(),
          ),
        );
      }
    } catch (e) {
      print('❌ Error in buyer tap: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ Handle Guest Navigation
  Future<void> _handleGuestTap() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await RoleManager.setLocalRole("guest");
      await LocalStorageService.saveUserDetails(
        userId: "",
        name: "",
        role: "guest",
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const Dynamichome(selectedIndex: 0),
          ),
        );
      }
    } catch (e) {
      print('❌ Error in guest tap: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                _buildHeader(),
                const SizedBox(height: 50),
                _buildSelectionCards(context),
                const Spacer(),
                _buildGuestLink(context),
                const SizedBox(height: 20),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Header Section
  Widget _buildHeader() {
    return Column(
      children: [
        SvgPicture.asset(
          'assets/images/flyHub_logo.svg',
          height: 80,
          width: 80,
        ),
        const SizedBox(height: 24),
        Text(
          "Welcome to Flyhub",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A0A5B),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Choose how you'd like to continue",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // 🔹 Seller & Buyer Cards
  Widget _buildSelectionCards(BuildContext context) {
    return Column(
      children: [
        _buildAnimatedCard(
          delay: 0,
          title: "Become a Seller",
          subtitle: "List and sell your drone products",
          icon: Icons.store_outlined,
          color: const Color(0xFF1A0A5B),
          onTap: _handleSellerTap,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 12),
        _buildAnimatedCard(
          delay: 100,
          title: "Become a Buyer",
          subtitle: "Browse and purchase drones",
          icon: Icons.shopping_bag_outlined,
          color: const Color(0xFF1A0A5B),
          onTap: _handleBuyerTap,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  // ✅ TweenAnimationBuilder
  Widget _buildAnimatedCard({
    required int delay,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isLoading,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _CompactRoleCard(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        onTap: onTap,
        isLoading: isLoading,
      ),
    );
  }

  // 🔹 Guest Option
  Widget _buildGuestLink(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: InkWell(
        onTap: _isLoading ? null : _handleGuestTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_outline,
                color: Color(0xFF868F9E),
                size: 16,
              ),
              const SizedBox(width: 8),
              _isLoading
                  ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF1A0A5B),
                  ),
                ),
              )
                  : Text(
                "Continue as Guest",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w200,
                  color: const Color(0xFF1A0A5B),
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFF1A0A5B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Footer Section
  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 14,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 6),
            Text(
              "Trusted",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          "Version 1.0.0",
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}

// 🔹 Compact Animated Card for Seller / Buyer
class _CompactRoleCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _CompactRoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isLoading,
  });

  @override
  State<_CompactRoleCard> createState() => _CompactRoleCardState();
}

class _CompactRoleCardState extends State<_CompactRoleCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
      widget.isLoading ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.isLoading
          ? null
          : (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.97 : 1.0),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_isPressed ? 0.1 : 0.08),
              blurRadius: _isPressed ? 6 : 10,
              offset: Offset(0, _isPressed ? 2 : 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            widget.isLoading
                ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Icon(widget.icon, color: Colors.white, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            widget.isLoading
                ? const SizedBox.shrink()
                : Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white.withOpacity(0.9),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}