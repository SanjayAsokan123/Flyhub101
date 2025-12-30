// lib/components/welcome_popup.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/responsive_utils.dart';

class WelcomePopup extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onGetStarted;
  final bool showOnlyOnce;
  final bool showCloseButton;

  static const _kPrimaryColor = Color(0xFF1E0E5C);
  static const _kWhiteColor = Color(0xFFFFFFFF);
  static const _kMediumTextColor = Color(0xFF64748B);
  static const _kLightTextColor = Color(0xFF94A3B8);

  const WelcomePopup({
    super.key,
    required this.onClose,
    required this.onGetStarted,
    this.showOnlyOnce = true,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final popupWidth = screenWidth * 0.9;
    final popupHeight = screenHeight * 0.7;
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final cardMargin = ResponsiveUtils.getCardMargin(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(horizontalPadding),
      child: Container(
        width: popupWidth,
        height: popupHeight,
        decoration: BoxDecoration(
          color: _kWhiteColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Image Section
            Container(
              height: popupHeight * 0.6,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: CachedNetworkImage(
                  imageUrl: "https://images.unsplash.com/photo-1473968512647-3e447244af8f?w=800&auto=format&fit=crop",
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: _kPrimaryColor.withOpacity(0.1),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_kPrimaryColor),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: _kPrimaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.photo_camera,
                      size: 60,
                      color: _kPrimaryColor.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),

            // Content Section
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: popupHeight * 0.45,
                padding: EdgeInsets.all(horizontalPadding * 1.5),
                decoration: const BoxDecoration(
                  color: _kWhiteColor,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Welcome to Flyhub! ✨",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveUtils.getTitleFontSize(context) + 4,
                        fontWeight: FontWeight.w800,
                        color: _kPrimaryColor,
                        height: 1.2,
                      ),
                    ),

                    SizedBox(height: cardMargin),

                    Text(
                      "Discover the world of drones - buy, sell, rent, and get services all in one place. Start your drone journey with us!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveUtils.getBodyFontSize(context),
                        fontWeight: FontWeight.w500,
                        color: _kMediumTextColor,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: cardMargin * 1.5),

                    Container(
                      width: double.infinity,
                      height: ResponsiveUtils.getSearchBarHeight(context),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kPrimaryColor, Color(0xFF4338CA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _kPrimaryColor.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: onGetStarted,
                          child: Center(
                            child: Text(
                              "Get Started",
                              style: GoogleFonts.inter(
                                fontSize: ResponsiveUtils.getBodyFontSize(context) + 2,
                                fontWeight: FontWeight.w700,
                                color: _kWhiteColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: cardMargin),
                    if (showOnlyOnce)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                      ),
                  ],
                ),
              ),
            ),
            // Close Button
            if (showCloseButton)
              Positioned(
                top: cardMargin,
                right: cardMargin,
                child: GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: ResponsiveUtils.getIconSize(context) * 1.5,
                    height: ResponsiveUtils.getIconSize(context) * 1.5,
                    decoration: BoxDecoration(
                      color: _kWhiteColor.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close,
                      color: _kMediumTextColor,
                      size: ResponsiveUtils.getIconSize(context),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}