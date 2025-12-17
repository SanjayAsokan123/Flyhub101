// lib/utils/responsive_utils.dart
import 'package:flutter/material.dart';

class ResponsiveUtils {

  static double getMarketGridAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 0.75;
    if (width < 600) return 0.95;
    return 0.9;
  }

  static int getProductGridCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 2;
    if (width < 600) return 2;
    return 3;
  }

  static double getProductCardHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 220;
    if (width < 600) return 240;
    return 260;
  }

  static double getProductCardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 160;
    if (width < 600) return 180;
    return 200;
  }
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
    if (width < 360) return 0.20;
    if (width < 600) return 0.19;
    if (width < 800) return 0.18;
    return 0.16;
  }

  static double getCategoryIconSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) return 0.14;
    if (width < 600) return 0.13;
    if (width < 800) return 0.12;
    return 0.10;
  }


  // Banner height
  static double getBannerHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.23;
  }

  // Grid layouts
  static int getCategoryGridCount(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) return 3;
    if (width < 600) return 4;
    if (width < 800) return 4;
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
    return width * 0.75;
  }

  static double getJobBannerHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.22;
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
    return width * 0.032;
  }

  static double getMarketGridSpacing(BuildContext context) {
    final width = getScreenWidth(context);
    return width * 0.024;
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

  // MARKET PAGE FULL SCREEN METHODS
  static double getMarketFullScreenHeight(BuildContext context) {
    return getScreenHeight(context);
  }

  static double getMarketFullScreenWidth(BuildContext context) {
    return getScreenWidth(context);
  }

  static double getMarketContentHeight(BuildContext context) {
    final fullHeight = getMarketFullScreenHeight(context);
    final appBarHeight = getAppBarHeight(context);
    final tabBarHeight = getMarketTabBarHeight(context);
    final safeAreaTop = getSafeAreaTop(context);
    final safeAreaBottom = getSafeAreaBottom(context);

    return fullHeight - appBarHeight - tabBarHeight - safeAreaTop - safeAreaBottom;
  }

  static double getMarketGridHeight(BuildContext context) {
    return getMarketContentHeight(context);
  }

  static double getMarketProductItemWidth(BuildContext context) {
    final width = getMarketFullScreenWidth(context);
    final crossCount = getMarketGridCrossAxisCount(context);
    final padding = getMarketGridPadding(context);
    final spacing = getMarketGridSpacing(context);

    final availableWidth = width - (padding * 2) - (spacing * (crossCount - 1));
    return availableWidth / crossCount;
  }

  static double getMarketProductItemHeight(BuildContext context) {
    return getMarketProductItemWidth(context) * getMarketGridAspectRatio(context);
  }

  static double getMarketProductImageFullHeight(BuildContext context) {
    final itemWidth = getMarketProductItemWidth(context);
    return itemWidth * 0.7;
  }

  static EdgeInsets getMarketFullScreenPadding(BuildContext context) {
    return EdgeInsets.zero;
  }

  static double getMarketSearchBarFullWidth(BuildContext context) {
    final width = getMarketFullScreenWidth(context);
    final horizontalPadding = getHorizontalPadding(context);
    return width - (horizontalPadding * 2);
  }

  static double getMarketSearchBarFullHeight(BuildContext context) {
    final height = getMarketFullScreenHeight(context);
    return height * 0.06;
  }

  static double getMarketFilterModalFullHeight(BuildContext context) {
    final height = getMarketFullScreenHeight(context);
    return height * 0.9;
  }

  static double getMarketEmptyStateFullHeight(BuildContext context) {
    return getMarketContentHeight(context);
  }

  static double getMarketEmptyStateFullWidth(BuildContext context) {
    return getMarketFullScreenWidth(context);
  }

  static EdgeInsets getMarketProductItemPadding(BuildContext context) {
    final width = getMarketFullScreenWidth(context);
    return EdgeInsets.all(width * 0.015);
  }

  static double getMarketFavoriteButtonSize(BuildContext context) {
    final width = getMarketFullScreenWidth(context);
    return width * 0.08;
  }

  static double getMarketPriceFontSize(BuildContext context) {
    final width = getMarketFullScreenWidth(context);
    double baseSize = width * 0.04;
    return baseSize.clamp(14.0, 20.0);
  }

  static double getMarketBrandFontSize(BuildContext context) {
    final width = getMarketFullScreenWidth(context);
    double baseSize = width * 0.03;
    return baseSize.clamp(10.0, 14.0);
  }

  static double getMarketNameFontSize(BuildContext context) {
    final width = getMarketFullScreenWidth(context);
    double baseSize = width * 0.035;
    return baseSize.clamp(12.0, 16.0);
  }

  // SHIMMER METHODS
  static double getShimmerProductImageHeight(BuildContext context) {
    return getMarketProductImageFullHeight(context);
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

  // ===========================================================================
  // WISHLIST PAGE SPECIFIC METHODS (UPDATED)
  // ===========================================================================

  /// Get wishlist grid cross axis count based on screen width
  static int getWishlistGridCrossAxisCount(BuildContext context) {
    final width = getScreenWidth(context);
    final isPortrait = !isLandscape(context);

    if (isPortrait) {
      if (width < 400) return 2;
      if (width < 600) return 2;
      if (width < 800) return 3;
      if (width < 1200) return 4;
      return 5;
    } else {
      // Landscape mode adjustments
      if (width < 600) return 3;
      if (width < 800) return 4;
      if (width < 1200) return 5;
      return 6;
    }
  }

  /// Get wishlist card aspect ratio
  static double getWishlistCardAspectRatio(BuildContext context) {
    final width = getScreenWidth(context);
    final isPortrait = !isLandscape(context);

    if (isPortrait) {
      if (width < 400) return 0.65;
      if (width < 600) return 0.68;
      if (width < 800) return 0.70;
      return 0.72;
    } else {
      // Landscape adjustments
      if (width < 600) return 0.75;
      if (width < 800) return 0.78;
      return 0.80;
    }
  }

  /// Get wishlist card width dynamically
  static double getWishlistCardWidth(BuildContext context, {int desiredColumns = 0}) {
    final width = getScreenWidth(context);
    final crossCount = desiredColumns > 0 ? desiredColumns : getWishlistGridCrossAxisCount(context);
    final padding = getWishlistGridPadding(context);
    final spacing = getWishlistGridSpacing(context);

    final availableWidth = width - (padding * 2) - (spacing * (crossCount - 1));
    return (availableWidth / crossCount).clamp(120.0, double.infinity);
  }

  /// Get wishlist card height dynamically
  static double getWishlistCardHeight(BuildContext context) {
    final aspectRatio = getWishlistCardAspectRatio(context);
    return getWishlistCardWidth(context) * aspectRatio;
  }

  /// Get wishlist image height
  static double getWishlistImageHeight(BuildContext context) {
    final cardWidth = getWishlistCardWidth(context);
    final isPortrait = !isLandscape(context);

    if (isPortrait) {
      return cardWidth * 0.55;
    } else {
      return cardWidth * 0.50;
    }
  }

  /// Get wishlist grid padding
  static double getWishlistGridPadding(BuildContext context) {
    final width = getScreenWidth(context);
    if (isLandscape(context)) {
      return width * 0.03;
    }
    if (width < 400) return width * 0.04;
    if (width < 600) return width * 0.035;
    return width * 0.03;
  }

  /// Get wishlist grid spacing
  static double getWishlistGridSpacing(BuildContext context) {
    final width = getScreenWidth(context);
    if (isLandscape(context)) {
      return width * 0.025;
    }
    if (width < 400) return width * 0.03;
    if (width < 600) return width * 0.028;
    return width * 0.025;
  }

  /// Get wishlist card corner radius
  static double getWishlistCardRadius(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 12.0;
    if (width < 600) return 14.0;
    if (width < 800) return 16.0;
    return 18.0;
  }

  /// Get wishlist card padding
  static EdgeInsets getWishlistCardPadding(BuildContext context) {
    final width = getScreenWidth(context);
    final isPortrait = !isLandscape(context);

    if (isPortrait) {
      if (width < 400) return EdgeInsets.all(width * 0.03);
      if (width < 600) return EdgeInsets.all(width * 0.025);
      return EdgeInsets.all(width * 0.02);
    } else {
      return EdgeInsets.all(width * 0.015);
    }
  }

  /// Get wishlist card margin
  static EdgeInsets getWishlistCardMargin(BuildContext context) {
    final spacing = getWishlistGridSpacing(context) * 0.5;
    return EdgeInsets.all(spacing);
  }

  /// Get wishlist title font size
  static double getWishlistTitleFontSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 14.0;
    if (width < 600) return 14.5;
    if (width < 800) return 15.0;
    if (width < 1200) return 16.0;
    return 17.0;
  }

  /// Get wishlist brand font size
  static double getWishlistBrandFontSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 12.0;
    if (width < 600) return 12.5;
    if (width < 800) return 13.0;
    if (width < 1200) return 13.5;
    return 14.0;
  }

  /// Get wishlist price font size
  static double getWishlistPriceFontSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 15.0;
    if (width < 600) return 15.5;
    if (width < 800) return 16.0;
    if (width < 1200) return 17.0;
    return 18.0;
  }

  /// Get wishlist button font size
  static double getWishlistButtonFontSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 12.0;
    if (width < 600) return 12.5;
    if (width < 800) return 13.0;
    return 14.0;
  }

  /// Get wishlist button height
  static double getWishlistButtonHeight(BuildContext context) {
    final height = getScreenHeight(context);
    if (height < 650) return 36.0;
    if (height < 800) return 40.0;
    if (height < 1000) return 44.0;
    return 48.0;
  }

  /// Get wishlist button width
  static double getWishlistButtonWidth(BuildContext context, {double percentage = 0.9}) {
    final cardWidth = getWishlistCardWidth(context);
    return cardWidth * percentage;
  }

  /// Get wishlist grid delegate
  static SliverGridDelegate getWishlistGridDelegate(BuildContext context, {int? customCrossAxisCount}) {
    final crossCount = customCrossAxisCount ?? getWishlistGridCrossAxisCount(context);
    final aspectRatio = getWishlistCardAspectRatio(context);
    final spacing = getWishlistGridSpacing(context);

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossCount,
      childAspectRatio: aspectRatio,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
    );
  }

  /// Get wishlist empty state icon size
  static double getWishlistEmptyStateIconSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 80.0;
    if (width < 600) return 100.0;
    if (width < 800) return 120.0;
    return 140.0;
  }

  /// Get wishlist badge size
  static double getWishlistBadgeSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 16.0;
    if (width < 600) return 18.0;
    if (width < 800) return 20.0;
    return 22.0;
  }

  /// Get wishlist action button size
  static double getWishlistActionButtonSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 22.0;
    if (width < 600) return 24.0;
    if (width < 800) return 26.0;
    return 28.0;
  }

  /// Get wishlist remove button size
  static double getWishlistRemoveButtonSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 24.0;
    if (width < 600) return 28.0;
    if (width < 800) return 32.0;
    return 36.0;
  }

  /// Get wishlist saved badge height
  static double getWishlistSavedBadgeHeight(BuildContext context) {
    return getWishlistButtonHeight(context) * 0.7;
  }

  /// Get wishlist item count font size
  static double getWishlistItemCountFontSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 10.0;
    if (width < 600) return 11.0;
    return 12.0;
  }

  /// Get wishlist shimmer item count
  static int getWishlistShimmerItemCount(BuildContext context) {
    final crossCount = getWishlistGridCrossAxisCount(context);
    return crossCount * 2;
  }

  /// Get wishlist card elevation
  static double getWishlistCardElevation(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 600) return 2.0;
    if (width < 800) return 3.0;
    return 4.0;
  }

  /// Get wishlist card border width
  static double getWishlistCardBorderWidth(BuildContext context) {
    return 0.5;
  }

  /// Get wishlist section header font size
  static double getWishlistSectionHeaderFontSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 16.0;
    if (width < 600) return 18.0;
    if (width < 800) return 20.0;
    return 22.0;
  }

  /// Get wishlist item count padding
  static EdgeInsets getWishlistItemCountPadding(BuildContext context) {
    final width = getScreenWidth(context);
    final isPortrait = !isLandscape(context);

    if (isPortrait) {
      if (width < 400) return EdgeInsets.symmetric(horizontal: 10, vertical: 4);
      if (width < 600) return EdgeInsets.symmetric(horizontal: 12, vertical: 5);
      return EdgeInsets.symmetric(horizontal: 14, vertical: 6);
    } else {
      return EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  /// Get wishlist empty state button padding
  static EdgeInsets getWishlistEmptyStateButtonPadding(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    if (width < 600) return EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    if (width < 800) return EdgeInsets.symmetric(horizontal: 28, vertical: 16);
    return EdgeInsets.symmetric(horizontal: 32, vertical: 18);
  }

  /// Get wishlist empty state text spacing
  static double getWishlistEmptyStateTextSpacing(BuildContext context) {
    final height = getScreenHeight(context);
    if (height < 650) return 12.0;
    if (height < 800) return 16.0;
    if (height < 1000) return 20.0;
    return 24.0;
  }

  /// Get wishlist empty state container size
  static double getWishlistEmptyStateContainerSize(BuildContext context) {
    final width = getScreenWidth(context);
    return width * 0.6;
  }

  /// Get wishlist grid view padding
  static EdgeInsets getWishlistGridViewPadding(BuildContext context) {
    final padding = getWishlistGridPadding(context);
    final spacing = getWishlistGridSpacing(context) * 0.5;
    return EdgeInsets.symmetric(horizontal: padding, vertical: spacing);
  }

  /// Get wishlist section header padding
  static EdgeInsets getWishlistSectionHeaderPadding(BuildContext context) {
    final horizontal = getWishlistGridPadding(context);
    final vertical = getVerticalPadding(context);
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  /// Get wishlist image placeholder icon size
  static double getWishlistImagePlaceholderSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 32.0;
    if (width < 600) return 40.0;
    if (width < 800) return 48.0;
    return 56.0;
  }

  /// Get wishlist product name max lines
  static int getWishlistProductNameMaxLines(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 2;
    if (width < 600) return 2;
    if (width < 800) return 2;
    return 3;
  }

  /// Get wishlist brand name max lines
  static int getWishlistBrandNameMaxLines(BuildContext context) {
    return 1;
  }

  /// Get wishlist price section height
  static double getWishlistPriceSectionHeight(BuildContext context) {
    final fontSize = getWishlistPriceFontSize(context);
    return fontSize * 1.8;
  }

  /// Get wishlist button section height
  static double getWishlistButtonSectionHeight(BuildContext context) {
    return getWishlistButtonHeight(context) * 1.3;
  }

  /// Get wishlist empty state image size
  static double getWishlistEmptyStateImageSize(BuildContext context) {
    final width = getScreenWidth(context);
    return width * 0.5;
  }

  /// Get wishlist item spacing
  static double getWishlistItemSpacing(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 8.0;
    if (width < 600) return 10.0;
    if (width < 800) return 12.0;
    return 16.0;
  }

  /// Get wishlist scroll physics
  static ScrollPhysics getWishlistScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }

  // ===========================================================================
  // PILOT PAGE SPECIFIC METHODS
  // ===========================================================================

  static int getPilotGridCrossAxisCount(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 1;
    if (width < 600) return 1;
    if (width < 800) return 1;
    if (width < 1200) return 2;
    return 3;
  }

  static double getPilotCardAspectRatio(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 1.7;
    if (width < 600) return 1.6;
    if (width < 800) return 1.8;
    return 1.5;
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
  static double getPilotCardWidth(BuildContext context, {int desiredColumns = 0}) {
    final width = getScreenWidth(context);
    final crossCount = desiredColumns > 0 ? desiredColumns : getPilotGridCrossAxisCount(context);
    final padding = getPilotGridPadding(context);
    final spacing = getPilotGridSpacing(context);

    final availableWidth = width - (padding * 2) - (spacing * (crossCount - 1));
    return availableWidth / crossCount;
  }

  static double getPilotCardHeight(BuildContext context, {double contentRatio = 1.5}) {
    return getPilotCardWidth(context) * contentRatio;
  }

  static double getPilotImageSize(BuildContext context, {double percentage = 0.22}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getPilotButtonWidth(BuildContext context, {double percentage = 0.25}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getPilotButtonHeight(BuildContext context, {double percentage = 0.06}) {
    final height = getScreenHeight(context);
    return height * percentage;
  }

  static double getPilotCardSpacing(BuildContext context, {double percentage = 0.02}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getPilotSectionPadding(BuildContext context, {double percentage = 0.04}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getPilotAvatarSize(BuildContext context, {double percentage = 0.12}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getPilotNameFontSize(BuildContext context, {double percentage = 0.045}) {
    final cardWidth = getPilotCardWidth(context);
    return cardWidth * percentage;
  }

  static double getPilotRatingSize(BuildContext context, {double percentage = 0.08}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getPilotCertIconSize(BuildContext context, {double percentage = 0.04}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getPilotExperienceBadgeSize(BuildContext context, {double percentage = 0.1}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getPilotGridPadding(BuildContext context, {double percentage = 0.035}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getPilotGridSpacing(BuildContext context, {double percentage = 0.025}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getPilotFilterButtonSize(BuildContext context, {double percentage = 0.1}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getPilotSearchBarWidth(BuildContext context, {double percentage = 0.8}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getPilotModalHeight(BuildContext context, {double percentage = 0.7}) {
    final height = getScreenHeight(context);
    return height * percentage;
  }

  static double getPilotListItemHeight(BuildContext context, {double percentage = 0.15}) {
    final height = getScreenHeight(context);
    return height * percentage;
  }

  static double getPilotAvailabilitySize(BuildContext context, {double percentage = 0.03}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getPilotCardRadius(BuildContext context, {double percentage = 0.02}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getPilotActionSpacing(BuildContext context, {double percentage = 0.015}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

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

  static Size getPilotCardDimensions(BuildContext context, {int columns = 0, double ratio = 1.5}) {
    return Size(
      getPilotCardWidth(context, desiredColumns: columns),
      getPilotCardHeight(context, contentRatio: ratio),
    );
  }

  static EdgeInsets getPilotCardPadding(BuildContext context, {double percentage = 0.03}) {
    final padding = getScreenWidth(context) * percentage;
    return EdgeInsets.all(padding);
  }

  static EdgeInsets getPilotCardMargin(BuildContext context, {double percentage = 0.015}) {
    final margin = getScreenWidth(context) * percentage;
    return EdgeInsets.all(margin);
  }

  // ===========================================================================
  // RENTALS PAGE SPECIFIC METHODS
  // ===========================================================================

  static double getRentalCardImageSize(BuildContext context) {
    return getPilotImageSize(context);
  }

  static double getRentalFeatureChipPadding(BuildContext context) {
    return getDynamicWidth(context, 0.025);
  }

  static double getRentalPriceFontSize(BuildContext context) {
    return getBodyFontSize(context) * 1.3;
  }

  static double getRentalButtonWidth(BuildContext context) {
    return getPilotButtonWidth(context, percentage: 0.3);
  }

  static double getRentalButtonHeight(BuildContext context) {
    return getPilotButtonHeight(context, percentage: 0.045);
  }

  static int getRentalGridCrossAxisCount(BuildContext context) {
    return getPilotGridCrossAxisCount(context);
  }

  static double getRentalGridAspectRatio(BuildContext context) {
    return getPilotCardAspectRatio(context);
  }

  static double getRentalGridPadding(BuildContext context) {
    return getPilotGridPadding(context);
  }

  static double getRentalGridSpacing(BuildContext context) {
    return getPilotGridSpacing(context);
  }

  static SliverGridDelegate getRentalGridDelegate(BuildContext context) {
    return getPilotGridDelegate(context);
  }

  // ===========================================================================
  // SERVICES PAGE SPECIFIC METHODS
  // ===========================================================================

  static int getServicesGridCrossAxisCount(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 2;
    if (width < 600) return 2;
    if (width < 800) return 3;
    if (width < 1200) return 4;
    return 5;
  }

  static double getServicesCardAspectRatio(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 0.68;
    if (width < 600) return 0.70;
    if (width < 800) return 0.72;
    return 0.75;
  }

  static double getServicesCardWidth(BuildContext context, {int desiredColumns = 0}) {
    final width = getScreenWidth(context);
    final crossCount = desiredColumns > 0 ? desiredColumns : getServicesGridCrossAxisCount(context);
    final padding = getServicesGridPadding(context);
    final spacing = getServicesGridSpacing(context);

    final availableWidth = width - (padding * 2) - (spacing * (crossCount - 1));
    return availableWidth / crossCount;
  }

  static double getServicesCardHeight(BuildContext context, {double contentRatio = 1.45}) {
    return getServicesCardWidth(context) * contentRatio;
  }

  static double getServicesImageHeight(BuildContext context) {
    final cardWidth = getServicesCardWidth(context);
    return cardWidth * 0.6;
  }

  static double getServicesGridPadding(BuildContext context, {double percentage = 0.04}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getServicesGridSpacing(BuildContext context, {double percentage = 0.03}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getServicesSearchBarHeight(BuildContext context, {double percentage = 0.065}) {
    final height = getScreenHeight(context);
    return height * percentage;
  }

  static double getServicesFilterButtonSize(BuildContext context, {double percentage = 0.1}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getServicesCardRadius(BuildContext context, {double percentage = 0.025}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static EdgeInsets getServicesCardPadding(BuildContext context, {double percentage = 0.025}) {
    final padding = getScreenWidth(context) * percentage;
    return EdgeInsets.all(padding);
  }

  static EdgeInsets getServicesCardMargin(BuildContext context, {double percentage = 0.015}) {
    final margin = getScreenWidth(context) * percentage;
    return EdgeInsets.all(margin);
  }

  static double getServicesTitleFontSize(BuildContext context) {
    final width = getScreenWidth(context);
    double baseSize = width * 0.038;
    return baseSize.clamp(14.0, 18.0);
  }

  static double getServicesPriceFontSize(BuildContext context) {
    final width = getScreenWidth(context);
    double baseSize = width * 0.034;
    return baseSize.clamp(12.0, 16.0);
  }

  static double getServicesButtonHeight(BuildContext context, {double percentage = 0.045}) {
    final height = getScreenHeight(context);
    return height * percentage;
  }

  static double getServicesButtonWidth(BuildContext context, {double percentage = 1.0}) {
    final cardWidth = getServicesCardWidth(context);
    return cardWidth * percentage;
  }

  static SliverGridDelegate getServicesGridDelegate(BuildContext context, {int? customCrossAxisCount}) {
    final crossCount = customCrossAxisCount ?? getServicesGridCrossAxisCount(context);
    final aspectRatio = getServicesCardAspectRatio(context);
    final spacing = getServicesGridSpacing(context);

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossCount,
      childAspectRatio: aspectRatio,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
    );
  }

  static double getServicesFilterModalHeight(BuildContext context, {double percentage = 0.5}) {
    final height = getScreenHeight(context);
    return height * percentage;
  }

  static double getServicesEmptyStateIconSize(BuildContext context) {
    return getIconSize(context) * 2.8;
  }

  static double getServicesRatingBadgeSize(BuildContext context) {
    return getIconSize(context) * 0.7;
  }

  static double getServicesFeatureIconSize(BuildContext context) {
    return getIconSize(context) * 0.5;
  }

  // ===========================================================================
  // TRAINING PAGE SPECIFIC METHODS
  // ===========================================================================

  static int getTrainingGridCrossAxisCount(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 1;
    if (width < 600) return 1;
    if (width < 800) return 2;
    if (width < 1200) return 2;
    return 3;
  }

  static double getTrainingCardAspectRatio(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 1.4;
    if (width < 600) return 1.3;
    if (width < 800) return 1.2;
    return 1.1;
  }

  static double getTrainingCardWidth(BuildContext context, {int desiredColumns = 0}) {
    final width = getScreenWidth(context);
    final crossCount = desiredColumns > 0 ? desiredColumns : getTrainingGridCrossAxisCount(context);
    final padding = getTrainingGridPadding(context);
    final spacing = getTrainingGridSpacing(context);

    final availableWidth = width - (padding * 2) - (spacing * (crossCount - 1));
    return availableWidth / crossCount;
  }

  static double getTrainingCardHeight(BuildContext context, {double contentRatio = 1.4}) {
    return getTrainingCardWidth(context) * contentRatio;
  }

  static double getTrainingImageHeight(BuildContext context) {
    final cardWidth = getTrainingCardWidth(context);
    return cardWidth * 0.5;
  }

  static double getTrainingImageWidth(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return width * 0.8;
    if (width < 600) return width * 0.75;
    if (width < 800) return width * 0.7;
    return width * 0.65;
  }

  static double getTrainingGridPadding(BuildContext context, {double percentage = 0.04}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getTrainingGridSpacing(BuildContext context, {double percentage = 0.03}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getTrainingCardRadius(BuildContext context, {double percentage = 0.025}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static EdgeInsets getTrainingCardPadding(BuildContext context, {double percentage = 0.04}) {
    final padding = getScreenWidth(context) * percentage;
    return EdgeInsets.all(padding);
  }

  static EdgeInsets getTrainingCardMargin(BuildContext context, {double percentage = 0.02}) {
    final margin = getScreenWidth(context) * percentage;
    return EdgeInsets.all(margin);
  }

  static double getTrainingTitleFontSize(BuildContext context) {
    final width = getScreenWidth(context);
    double baseSize = width * 0.042;
    return baseSize.clamp(16.0, 22.0);
  }

  static double getTrainingDescriptionFontSize(BuildContext context) {
    final width = getScreenWidth(context);
    double baseSize = width * 0.032;
    return baseSize.clamp(12.0, 16.0);
  }

  static double getTrainingPriceFontSize(BuildContext context) {
    final width = getScreenWidth(context);
    double baseSize = width * 0.038;
    return baseSize.clamp(14.0, 20.0);
  }

  static double getTrainingButtonHeight(BuildContext context, {double percentage = 0.05}) {
    final height = getScreenHeight(context);
    return height * percentage;
  }

  static double getTrainingButtonWidth(BuildContext context, {double percentage = 0.7}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getTrainingDurationIconSize(BuildContext context) {
    return getIconSize(context) * 0.7;
  }

  static double getTrainingEmptyStateIconSize(BuildContext context) {
    return getIconSize(context) * 3.0;
  }

  static SliverGridDelegate getTrainingGridDelegate(BuildContext context, {int? customCrossAxisCount}) {
    final crossCount = customCrossAxisCount ?? getTrainingGridCrossAxisCount(context);
    final aspectRatio = getTrainingCardAspectRatio(context);
    final spacing = getTrainingGridSpacing(context);

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossCount,
      childAspectRatio: aspectRatio,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
    );
  }

  static int getTrainingShimmerItemCount(BuildContext context) {
    final crossCount = getTrainingGridCrossAxisCount(context);
    return crossCount * 3;
  }

  // ===========================================================================
  // ENHANCED RESPONSIVE METHODS FOR BETTER ADAPTATION
  // ===========================================================================

  static double getOptimalFontSize(BuildContext context, {double minSize = 12, double maxSize = 24, double scaleFactor = 0.035}) {
    final width = getScreenWidth(context);
    final baseSize = width * scaleFactor;
    return baseSize.clamp(minSize, maxSize);
  }

  static double getOptimalSpacing(BuildContext context, {double scaleFactor = 0.02}) {
    final width = getScreenWidth(context);
    return width * scaleFactor;
  }

  static double getOptimalIconSize(BuildContext context, {double scaleFactor = 0.06}) {
    final width = getScreenWidth(context);
    return width * scaleFactor;
  }

  static EdgeInsets getOptimalPadding(BuildContext context, {double horizontalScale = 0.04, double verticalScale = 0.02}) {
    return EdgeInsets.symmetric(
      horizontal: getScreenWidth(context) * horizontalScale,
      vertical: getScreenHeight(context) * verticalScale,
    );
  }

  static double getOptimalCardRadius(BuildContext context, {double scaleFactor = 0.02}) {
    final width = getScreenWidth(context);
    return width * scaleFactor;
  }

  // DENSITY-AWARE SIZING
  static double getDensityAwareSize(BuildContext context, double baseSize) {
    final mediaQuery = MediaQuery.of(context);
    final devicePixelRatio = mediaQuery.devicePixelRatio;
    final textScaleFactor = mediaQuery.textScaleFactor;

    // Adjust size based on device pixel ratio and text scale
    return baseSize * (1 + (devicePixelRatio - 1) * 0.1) * textScaleFactor;
  }

  // ORIENTATION-AWARE SIZING
  static double getOrientationAwareSize(BuildContext context, double portraitSize, double landscapeSize) {
    return isLandscape(context) ? landscapeSize : portraitSize;
  }

  // ACCESSIBILITY-AWARE SIZING
  static double getAccessibilityAwareSize(BuildContext context, double baseSize) {
    final mediaQuery = MediaQuery.of(context);
    final textScaleFactor = mediaQuery.textScaleFactor;

    // Ensure minimum touch target size for accessibility
    final minTouchSize = getMinTouchSize(context);
    return (baseSize * textScaleFactor).clamp(minTouchSize, baseSize * 2);
  }

  // ===========================================================================
  // JOBS PAGE SPECIFIC METHODS
  // ===========================================================================

  static int getJobsGridCrossAxisCount(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 1;
    if (width < 600) return 1;
    if (width < 800) return 2;
    if (width < 1200) return 3;
    return 4;
  }

  static double getJobsCardAspectRatio(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 1.6;
    if (width < 600) return 1.5;
    if (width < 800) return 1.4;
    return 1.3;
  }

  static double getJobsCardWidth(BuildContext context, {int desiredColumns = 0}) {
    final width = getScreenWidth(context);
    final crossCount = desiredColumns > 0 ? desiredColumns : getJobsGridCrossAxisCount(context);
    final padding = getJobsGridPadding(context);
    final spacing = getJobsGridSpacing(context);

    final availableWidth = width - (padding * 2) - (spacing * (crossCount - 1));
    return availableWidth / crossCount;
  }

  static double getJobsCardHeight(BuildContext context, {double contentRatio = 1.6}) {
    return getJobsCardWidth(context) * contentRatio;
  }

  static double getJobsGridPadding(BuildContext context, {double percentage = 0.04}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getJobsGridSpacing(BuildContext context, {double percentage = 0.03}) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  static double getJobsCompanyLogoSize(BuildContext context) {
    return getIconSize(context) * 1.5;
  }

  static double getJobsSalaryFontSize(BuildContext context) {
    return getBodyFontSize(context) * 1.1;
  }

  static SliverGridDelegate getJobsGridDelegate(BuildContext context, {int? customCrossAxisCount}) {
    final crossCount = customCrossAxisCount ?? getJobsGridCrossAxisCount(context);
    final aspectRatio = getJobsCardAspectRatio(context);
    final spacing = getJobsGridSpacing(context);

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossCount,
      childAspectRatio: aspectRatio,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
    );
  }

  // ===========================================================================
  // CART PAGE SPECIFIC METHODS
  // ===========================================================================

  static double getCartItemHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.15;
  }

  static double getCartImageSize(BuildContext context) {
    return getCartItemHeight(context) * 0.8;
  }

  static double getCartQuantityButtonSize(BuildContext context) {
    return getIconSize(context) * 1.2;
  }

  static double getCartTotalSectionHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.25;
  }

  static double getCartActionButtonHeight(BuildContext context) {
    return getButtonHeight(context) * 0.8;
  }

  static EdgeInsets getCartItemPadding(BuildContext context) {
    final horizontal = getHorizontalPadding(context);
    final vertical = getVerticalPadding(context) * 0.8;
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  // ===========================================================================
  // PROFILE PAGE SPECIFIC METHODS
  // ===========================================================================

  static double getProfileAvatarSize(BuildContext context) {
    final width = getScreenWidth(context);
    return width * 0.25;
  }

  static double getProfileSectionHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.08;
  }

  static double getProfileMenuItemHeight(BuildContext context) {
    return getProfileSectionHeight(context) * 0.8;
  }

  static double getProfileStatsCardWidth(BuildContext context) {
    final width = getScreenWidth(context);
    return width * 0.4;
  }

  // ===========================================================================
  // NOTIFICATIONS PAGE SPECIFIC METHODS
  // ===========================================================================

  static double getNotificationItemHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.1;
  }

  static double getNotificationIconSize(BuildContext context) {
    return getIconSize(context) * 1.1;
  }

  static double getNotificationTimeFontSize(BuildContext context) {
    return getSmallFontSize(context);
  }

  // ===========================================================================
  // SETTINGS PAGE SPECIFIC METHODS
  // ===========================================================================

  static double getSettingsSectionSpacing(BuildContext context) {
    return getSectionSpacing(context) * 1.5;
  }

  static double getSettingsSwitchSize(BuildContext context) {
    return getIconSize(context) * 0.8;
  }

  static double getSettingsDividerHeight(BuildContext context) {
    return getBorderWidth(context) * 2;
  }

  // ===========================================================================
  // AUTHENTICATION PAGE SPECIFIC METHODS
  // ===========================================================================

  static double getAuthLogoSize(BuildContext context) {
    final width = getScreenWidth(context);
    return width * 0.3;
  }

  static double getAuthFormWidth(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 600) return width * 0.9;
    if (width < 800) return width * 0.7;
    return width * 0.5;
  }

  static double getAuthButtonHeight(BuildContext context) {
    return getButtonHeight(context) * 1.1;
  }

  static double getAuthSocialButtonSize(BuildContext context) {
    return getIconSize(context) * 2.0;
  }

  // ===========================================================================
  // ONBOARDING PAGE SPECIFIC METHODS
  // ===========================================================================

  static double getOnboardingImageHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.5;
  }

  static double getOnboardingIndicatorSize(BuildContext context) {
    return getIconSize(context) * 0.6;
  }

  static double getOnboardingButtonWidth(BuildContext context) {
    final width = getScreenWidth(context);
    return width * 0.4;
  }

  // ===========================================================================
  // SEARCH PAGE SPECIFIC METHODS
  // ===========================================================================

  static double getSearchHistoryItemHeight(BuildContext context) {
    return getButtonHeight(context) * 0.8;
  }

  static double getSearchSuggestionHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.4;
  }

  static double getSearchFilterPanelWidth(BuildContext context) {
    final width = getScreenWidth(context);
    return width * 0.8;
  }

  // ===========================================================================
  // CHECKOUT PAGE SPECIFIC METHODS
  // ===========================================================================

  static double getCheckoutStepIndicatorSize(BuildContext context) {
    return getIconSize(context) * 1.5;
  }

  static double getCheckoutFormSectionHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.3;
  }

  static double getCheckoutSummaryHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.4;
  }

  // ===========================================================================
  // ORDER HISTORY PAGE SPECIFIC METHODS
  // ===========================================================================

  static double getOrderHistoryItemHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.12;
  }

  static double getOrderStatusIndicatorSize(BuildContext context) {
    return getIconSize(context) * 0.8;
  }

  static double getOrderTrackingHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.2;
  }

  // ===========================================================================
  // REVIEWS & RATINGS PAGE SPECIFIC METHODS
  // ===========================================================================

  static double getReviewItemHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.15;
  }

  static double getRatingStarSize(BuildContext context) {
    return getIconSize(context) * 0.9;
  }

  static double getReviewFormHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.4;
  }

  // ===========================================================================
  // HELP & SUPPORT PAGE SPECIFIC METHODS
  // ===========================================================================

  static double getFaqItemHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.1;
  }

  static double getSupportChatHeight(BuildContext context) {
    final height = getScreenHeight(context);
    return height * 0.7;
  }

  static double getSupportInputHeight(BuildContext context) {
    return getButtonHeight(context) * 0.8;
  }
}