// lib/utils/responsive_utils.dart
import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Basic screen dimensions
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double getAspectRatio(BuildContext context) {
    return getScreenWidth(context) / getScreenHeight(context);
  }

  // Device type detection
  static bool isSmallPhone(BuildContext context) => getScreenWidth(context) < 360;
  static bool isNormalPhone(BuildContext context) => getScreenWidth(context) < 600;
  static bool isLargePhone(BuildContext context) => getScreenWidth(context) < 800;
  static bool isTablet(BuildContext context) => getScreenWidth(context) >= 800;
  static bool isLargeTablet(BuildContext context) => getScreenWidth(context) >= 1200;

  // Responsive font sizes
  static double getTitleFontSize(BuildContext context) {
    final width = getScreenWidth(context);
    final height = getScreenHeight(context);
    final aspectRatio = getAspectRatio(context);

    double baseSize = width * 0.045;

    if (width < 360) baseSize = width * 0.05;
    else if (width < 600) baseSize = width * 0.048;
    else if (width < 800) baseSize = width * 0.046;
    else baseSize = width * 0.044;

    if (height < 700) baseSize *= 0.95;
    else if (height > 1000) baseSize *= 1.05;

    if (aspectRatio > 1.5) baseSize *= 0.95;

    return baseSize.clamp(16.0, 28.0);
  }

  static double getBodyFontSize(BuildContext context) {
    final width = getScreenWidth(context);
    final height = getScreenHeight(context);

    double baseSize = width * 0.035;

    if (width < 360) baseSize = width * 0.038;
    else if (width < 600) baseSize = width * 0.036;
    else if (width < 800) baseSize = width * 0.034;
    else baseSize = width * 0.032;

    if (height < 700) baseSize *= 0.95;
    else if (height > 1000) baseSize *= 1.05;

    return baseSize.clamp(12.0, 20.0);
  }

  static double getSmallFontSize(BuildContext context) {
    return getBodyFontSize(context) * 0.8;
  }

  // Responsive padding
  static double getHorizontalPadding(BuildContext context) {
    final width = getScreenWidth(context);
    return width * 0.04;
  }

  static double getVerticalPadding(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.02;
  }

  // Category items
  static double getCategoryItemSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) return 0.22;
    if (width < 600) return 0.20;
    if (width < 800) return 0.18;
    return 0.16;
  }

  static double getCategoryIconSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) return 0.16;
    if (width < 600) return 0.14;
    if (width < 800) return 0.12;
    return 0.10;
  }

  // Product card dimensions
  static double getProductCardWidth(BuildContext context) {
    final width = getScreenWidth(context);
    final crossCount = getMarketGridCrossAxisCount(context);
    final padding = getMarketGridPadding(context);
    final spacing = getMarketGridSpacing(context);

    final availableWidth = width - (padding * 2) - (spacing * (crossCount - 1));
    return availableWidth / crossCount;
  }

  static double getProductCardHeight(BuildContext context) {
    return getProductCardWidth(context) * 1.4;
  }

  // Banner height
  static double getBannerHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.22;
  }

  // Grid layouts
  static int getCategoryGridCount(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) return 3;
    if (width < 600) return 4;
    if (width < 800) return 5;
    return 6;
  }

  static SliverGridDelegate getProductGridDelegate(BuildContext context) {
    final crossCount = getMarketGridCrossAxisCount(context);
    final aspectRatio = getMarketGridAspectRatio(context);
    final spacing = getMarketGridSpacing(context);

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossCount,
      childAspectRatio: aspectRatio,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
    );
  }

  // UI elements
  static double getButtonHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.06;
  }

  static double getIconSize(BuildContext context) {
    final width = getScreenWidth(context);
    return width * 0.055;
  }

  // Job banner dimensions
  static double getJobBannerWidth(BuildContext context) {
    final width = getScreenWidth(context);
    return width * 0.85;
  }

  static double getJobBannerHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.18;
  }

  // Feature card dimensions
  static double getFeatureCardWidth(BuildContext context) {
    final width = getScreenWidth(context);
    return width * 0.42;
  }

  static double getFeatureCardHeight(BuildContext context) {
    return getFeatureCardWidth(context) * 0.8;
  }

  // Section spacing
  static double getSectionSpacing(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.02;
  }

  // Card margin
  static double getCardMargin(BuildContext context) {
    final width = getScreenWidth(context);
    return width * 0.025;
  }

  // Image ratios
  static double getProductImageRatio(BuildContext context) => 0.75;
  static double getBannerImageRatio(BuildContext context) => 1.8;
  static double getCategoryImageRatio(BuildContext context) => 1.0;

  // Orientation and safe area
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static double getSafeAreaTop(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  static double getSafeAreaBottom(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  // App bar and search
  static double getAppBarHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.07;
  }

  static double getSearchBarHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.055;
  }

  // MARKET PAGE METHODS
  static int getMarketGridCrossAxisCount(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 2;
    if (width < 600) return 2;
    if (width < 800) return 3;
    if (width < 1200) return 4;
    return 5;
  }

  static double getMarketGridAspectRatio(BuildContext context) {
    final width = getScreenWidth(context);
    final height = getScreenHeight(context);
    final aspectRatio = width / height;

    if (width < 400) return 0.65;
    if (width < 600) return 0.68;
    if (width < 800) return 0.72;
    if (aspectRatio > 1.5) return 0.8;
    return 0.75;
  }

  static double getMarketProductImageHeight(BuildContext context) {
    final cardWidth = getProductCardWidth(context);
    return cardWidth * 0.7;
  }

  static double getMarketTabBarHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.12;
  }

  static double getMarketSearchFilterHeight(BuildContext context) {
    return getSearchBarHeight(context);
  }

  static double getMarketGridPadding(BuildContext context) {
    final width = getScreenWidth(context);
    return width * 0.035;
  }

  static double getMarketGridSpacing(BuildContext context) {
    final width = getScreenWidth(context);
    return width * 0.025;
  }

  static EdgeInsets getMarketFilterModalPadding(BuildContext context) {
    final horizontal = getHorizontalPadding(context);
    final vertical = getVerticalPadding(context);
    return EdgeInsets.fromLTRB(horizontal, vertical, horizontal, vertical);
  }

  static double getMarketBadgeSize(BuildContext context) {
    return getIconSize(context) * 0.8;
  }

  static int getMarketProductNameLines(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 2;
    if (width < 600) return 2;
    return 3;
  }

  static double getMarketEmptyStateIconSize(BuildContext context) {
    return getIconSize(context) * 2.5;
  }

  // SHIMMER METHODS
  static double getShimmerProductImageHeight(BuildContext context) {
    return getMarketProductImageHeight(context);
  }

  static double getShimmerTextHeight(BuildContext context, {bool isSmall = false}) {
    if (isSmall) {
      return getSmallFontSize(context);
    }
    return getBodyFontSize(context);
  }

  static double getShimmerPriceHeight(BuildContext context) {
    return getBodyFontSize(context) + 2;
  }

  static int getShimmerItemCount(BuildContext context) {
    final crossCount = getMarketGridCrossAxisCount(context);
    return crossCount * 3;
  }

  static double getShimmerTextWidth(BuildContext context, {double percentage = 0.6}) {
    final cardWidth = getProductCardWidth(context);
    return cardWidth * percentage;
  }

  // Safe container dimensions
  static double getSafeContainerHeight(BuildContext context, {double percentage = 0.9}) {
    final height = getScreenHeight(context);
    return height * percentage;
  }

  static double getSafeContainerWidth(BuildContext context, {double percentage = 0.9}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  // Category section
  static double getCategorySectionHeight(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 600) return width * 0.28;
    return width * 0.20;
  }

  static double getCategoryItemPadding(BuildContext context) {
    final width = getScreenWidth(context);
    return width * 0.012;
  }

  // UNIVERSAL DYNAMIC METHODS
  static double getDynamicWidth(BuildContext context, double percentage) {
    return getScreenWidth(context) * percentage;
  }

  static double getDynamicHeight(BuildContext context, double percentage) {
    return getScreenHeight(context) * percentage;
  }

  static double getDynamicFontSize(BuildContext context, double percentage) {
    return getScreenWidth(context) * percentage;
  }

  static double getDynamicPadding(BuildContext context, double percentage) {
    return getScreenWidth(context) * percentage;
  }

  // Adaptive methods for orientation
  static double getAdaptiveSize(BuildContext context, {double portrait = 0.05, double landscape = 0.04}) {
    return isLandscape(context)
        ? getScreenWidth(context) * landscape
        : getScreenWidth(context) * portrait;
  }

  // Accessibility
  static double getMinTouchSize(BuildContext context) {
    return getScreenWidth(context) * 0.12;
  }

  // Visual effects
  static double getElevation(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 600) return 2.0;
    if (width < 800) return 3.0;
    return 4.0;
  }

  static double getBorderWidth(BuildContext context) {
    final width = getScreenWidth(context);
    return width * 0.002;
  }

  // PILOT PAGE STATIC METHODS
  static int getPilotGridCrossAxisCount(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 1;
    if (width < 600) return 1;
    if (width < 800) return 2;
    if (width < 1200) return 3;
    return 4;
  }

  static double getPilotCardAspectRatio(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 1.7;
    if (width < 600) return 1.6;
    if (width < 800) return 1.5;
    return 1.4;
  }

  static double getPilotCardImageSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return width * 0.22;
    if (width < 600) return width * 0.20;
    if (width < 800) return width * 0.18;
    return width * 0.16;
  }

  static double getPilotCardButtonWidth(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return width * 0.28;
    if (width < 600) return width * 0.26;
    return width * 0.24;
  }

  static double getPilotCardButtonHeight(BuildContext context) {
    return getButtonHeight(context) * 0.7;
  }

  static double getPilotCertButtonSize(BuildContext context) {
    final width = getScreenWidth(context);
    return width * 0.22;
  }

  static double getPilotBadgeSize(BuildContext context) {
    return getIconSize(context) * 0.9;
  }

  static double getPilotFilterModalHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.7;
  }

  static double getPilotEmptyStateIconSize(BuildContext context) {
    return getIconSize(context) * 3.0;
  }

  static int getPilotShimmerItemCount(BuildContext context) {
    final crossCount = getPilotGridCrossAxisCount(context);
    return crossCount * 2;
  }

  // PILOT PAGE DYNAMIC SIZING METHODS

  /// Dynamic pilot card width based on screen size and desired columns
  /// [desiredColumns]: Number of columns you want in the grid (0 for auto)
  static double getPilotCardWidth(BuildContext context, {int desiredColumns = 0}) {
    final width = getScreenWidth(context);
    final crossCount = desiredColumns > 0 ? desiredColumns : getPilotGridCrossAxisCount(context);
    final padding = getPilotGridPadding(context);
    final spacing = getPilotGridSpacing(context);

    final availableWidth = width - (padding * 2) - (spacing * (crossCount - 1));
    return availableWidth / crossCount;
  }

  /// Dynamic pilot card height based on content ratio
  /// [contentRatio]: Aspect ratio for the card (width/height)
  static double getPilotCardHeight(BuildContext context, {double contentRatio = 1.5}) {
    return getPilotCardWidth(context) * contentRatio;
  }

  /// Dynamic pilot image size based on card width percentage
  /// [percentage]: Percentage of card width for the image
  static double getPilotImageSize(BuildContext context, {double percentage = 0.22}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  /// Dynamic pilot button width based on screen percentage
  /// [percentage]: Percentage of screen width for button
  static double getPilotButtonWidth(BuildContext context, {double percentage = 0.25}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  /// Dynamic pilot button height based on screen percentage
  /// [percentage]: Percentage of screen height for button
  static double getPilotButtonHeight(BuildContext context, {double percentage = 0.06}) {
    final height = getScreenHeight(context);
    return height * percentage;
  }

  /// Dynamic pilot spacing between cards
  /// [percentage]: Percentage of screen width for spacing
  static double getPilotCardSpacing(BuildContext context, {double percentage = 0.02}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  /// Dynamic pilot section padding
  /// [percentage]: Percentage of screen width for padding
  static double getPilotSectionPadding(BuildContext context, {double percentage = 0.04}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  /// Dynamic pilot avatar size
  /// [percentage]: Percentage of screen width for avatar
  static double getPilotAvatarSize(BuildContext context, {double percentage = 0.12}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  /// Dynamic pilot name font size based on card width
  /// [percentage]: Percentage of card width for font size
  static double getPilotNameFontSize(BuildContext context, {double percentage = 0.045}) {
    final cardWidth = getPilotCardWidth(context);
    return cardWidth * percentage;
  }

  /// Dynamic pilot rating size
  /// [percentage]: Percentage of screen width for rating widget
  static double getPilotRatingSize(BuildContext context, {double percentage = 0.08}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  /// Dynamic pilot certification icon size
  /// [percentage]: Percentage of screen width for certification icon
  static double getPilotCertIconSize(BuildContext context, {double percentage = 0.04}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  /// Dynamic pilot experience badge size
  /// [percentage]: Percentage of screen width for experience badge
  static double getPilotExperienceBadgeSize(BuildContext context, {double percentage = 0.1}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  /// Dynamic pilot grid padding
  static double getPilotGridPadding(BuildContext context, {double percentage = 0.035}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  /// Dynamic pilot grid spacing
  static double getPilotGridSpacing(BuildContext context, {double percentage = 0.025}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  /// Dynamic pilot filter button size
  static double getPilotFilterButtonSize(BuildContext context, {double percentage = 0.1}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  /// Dynamic pilot search bar width
  static double getPilotSearchBarWidth(BuildContext context, {double percentage = 0.8}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  /// Dynamic pilot modal bottom sheet height
  static double getPilotModalHeight(BuildContext context, {double percentage = 0.7}) {
    final height = getScreenHeight(context);
    return height * percentage;
  }

  /// Dynamic pilot list item height for horizontal lists
  static double getPilotListItemHeight(BuildContext context, {double percentage = 0.15}) {
    final height = getScreenHeight(context);
    return height * percentage;
  }

  /// Dynamic pilot availability indicator size
  static double getPilotAvailabilitySize(BuildContext context, {double percentage = 0.03}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  /// Dynamic pilot card corner radius
  static double getPilotCardRadius(BuildContext context, {double percentage = 0.02}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  /// Dynamic pilot action button spacing
  static double getPilotActionSpacing(BuildContext context, {double percentage = 0.015}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  /// Get optimal pilot grid delegate with dynamic sizing
  static SliverGridDelegate getPilotGridDelegate(BuildContext context, {int? customCrossAxisCount}) {
    final crossCount = customCrossAxisCount ?? getPilotGridCrossAxisCount(context);
    final aspectRatio = getPilotCardAspectRatio(context);
    final spacing = getPilotGridSpacing(context);

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossCount,
      childAspectRatio: aspectRatio,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
    );
  }

  /// Get pilot card dimensions as Size object
  static Size getPilotCardDimensions(BuildContext context, {int columns = 0, double ratio = 1.5}) {
    return Size(
      getPilotCardWidth(context, desiredColumns: columns),
      getPilotCardHeight(context, contentRatio: ratio),
    );
  }

  /// Get pilot card padding dynamically
  static EdgeInsets getPilotCardPadding(BuildContext context, {double percentage = 0.03}) {
    final padding = getScreenWidth(context) * percentage;
    return EdgeInsets.all(padding);
  }

  /// Get pilot card margin dynamically
  static EdgeInsets getPilotCardMargin(BuildContext context, {double percentage = 0.015}) {
    final margin = getScreenWidth(context) * percentage;
    return EdgeInsets.all(margin);
  }
}