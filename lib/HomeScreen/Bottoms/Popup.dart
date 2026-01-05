// lib/components/welcome_popup.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../utils/responsive_utils.dart';

class WelcomePopup extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onGetStarted;
  final bool showOnlyOnce;
  final bool showCloseButton;
  final GraphQLClient? client;

  static const _kWhiteColor = Color(0xFFFFFFFF);

  const WelcomePopup({
    super.key,
    required this.onClose,
    required this.onGetStarted,
    this.showOnlyOnce = true,
    this.showCloseButton = true,
    this.client,
  });

  @override
  State<WelcomePopup> createState() => _WelcomePopupState();
}

class _WelcomePopupState extends State<WelcomePopup> {
  bool _isLoading = true;
  bool _hasAnnouncement = false;
  List<Map<String, dynamic>> _announcements = [];
  int _currentPage = 0;
  late PageController _pageController;
  Timer? _autoScrollTimer;

  // GraphQL Query - Fetch ALL active announcements
  static const String getActiveAnnouncements = '''
    query GetAllAnnouncements {
      getAllAnnouncements {
        id
        imagePath
        imageUrl
        title
        message
        isActive
        createdAt
        updatedAt
      }
    }
  ''';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.95);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchActiveAnnouncements();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchActiveAnnouncements() async {
    try {
      final client = widget.client ?? _getClientFromContext();
      if (client == null) {
        print('No GraphQL client available');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasAnnouncement = false;
          });
        }
        widget.onClose(); // Close immediately if no client
        return;
      }

      final QueryResult result = await client.query(
        QueryOptions(
          document: gql(getActiveAnnouncements),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        print('Error fetching announcements: ${result.exception}');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasAnnouncement = false;
          });
        }
        widget.onClose(); // Close if error
        return;
      }

      if (result.data != null && result.data!['getAllAnnouncements'] != null) {
        final List<dynamic> allData = result.data!['getAllAnnouncements'] as List<dynamic>;

        final activeAnnouncements = allData.where((item) {
          final data = item as Map<String, dynamic>;
          final imageUrl = _getImageUrl(data);
          final isActive = data['isActive'] == true;

          return imageUrl.isNotEmpty && isActive;
        }).toList();

        print('Found ${activeAnnouncements.length} active announcements');

        if (activeAnnouncements.isNotEmpty) {
          if (mounted) {
            setState(() {
              _announcements = activeAnnouncements.map((item) => item as Map<String, dynamic>).toList();
              _hasAnnouncement = true;
              _isLoading = false;
            });
          }

          if (_announcements.length > 1) {
            _startAutoScroll();
          }
        } else {
          // NO ANNOUNCEMENTS FOUND - CLOSE IMMEDIATELY
          print('No active announcements found');
          if (mounted) {
            setState(() {
              _announcements = [];
              _hasAnnouncement = false;
              _isLoading = false;
            });
          }
          widget.onClose(); // Close if no announcements
        }
      } else {
        // NO DATA RETURNED - CLOSE IMMEDIATELY
        print('No announcement data returned');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasAnnouncement = false;
          });
        }
        widget.onClose(); // Close if no data
      }
    } catch (e) {
      print('Exception in fetchActiveAnnouncements: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasAnnouncement = false;
        });
      }
      widget.onClose(); // Close if exception
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_announcements.length <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_pageController.hasClients || _announcements.isEmpty) return;

      final nextPage = (_currentPage + 1) % _announcements.length;
      if (_pageController.page == nextPage.toDouble()) return;

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  GraphQLClient? _getClientFromContext() {
    try {
      return GraphQLProvider.of(context).value;
    } catch (e) {
      print('GraphQLProvider not found in context: $e');
      return null;
    }
  }

  String _getImageUrl(Map<String, dynamic> data) {
    final imageUrl = data['imageUrl']?.toString() ?? '';
    final imagePath = data['imagePath']?.toString() ?? '';
    return imageUrl.isNotEmpty ? imageUrl : imagePath;
  }

  String _getFullImageUrl(String rawUrl) {
    if (rawUrl.isEmpty) return '';

    if (rawUrl.startsWith('http')) {
      return rawUrl;
    }

    if (rawUrl.startsWith('gs://')) {
      final match = RegExp(r'gs://([^/]+)/(.+)').firstMatch(rawUrl);
      if (match != null) {
        final bucket = match.group(1);
        final path = match.group(2);
        return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(path!)}?alt=media';
      }
    }

    return rawUrl;
  }

  void _handleClose() {
    _stopAutoScroll();
    if (mounted) {
      widget.onClose();
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('Building WelcomePopup: isLoading=$_isLoading, hasAnnouncement=$_hasAnnouncement');

    // Don't show anything while loading
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    // If no announcements after loading, don't show anything
    if (!_hasAnnouncement || _announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final cardMargin = ResponsiveUtils.getCardMargin(context);

    final maxPopupWidth = screenWidth * 0.95;
    final maxPopupHeight = screenHeight * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(horizontalPadding),
      child: Container(
        width: maxPopupWidth,
        height: maxPopupHeight,
        child: Stack(
          children: [
            // Show announcements (only reach here if we have announcements)
            PageView.builder(
              controller: _pageController,
              itemCount: _announcements.length,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final announcement = _announcements[index];
                final rawImageUrl = _getImageUrl(announcement);
                final imageUrl = _getFullImageUrl(rawImageUrl);

                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 1.0;
                    if (_pageController.position.haveDimensions) {
                      value = (_pageController.page! - index).abs();
                      value = (1 - (value * 0.25)).clamp(0.8, 1.0);
                    }
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        margin: EdgeInsets.all(cardMargin),
                        child: _buildImageOnly(
                          imageUrl: imageUrl,
                          index: index,
                          maxWidth: maxPopupWidth - (cardMargin * 2),
                          maxHeight: maxPopupHeight - (cardMargin * 2),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Page Indicators (only if multiple images)
            if (_announcements.length > 1)
              Positioned(
                bottom: cardMargin * 2,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _announcements.length,
                        (index) => _buildPageIndicator(index),
                  ),
                ),
              ),

            // Close Button
            if (widget.showCloseButton)
              Positioned(
                top: cardMargin,
                right: cardMargin,
                child: GestureDetector(
                  onTap: _handleClose,
                  child: Container(
                    width: ResponsiveUtils.getIconSize(context) * 1.8,
                    height: ResponsiveUtils.getIconSize(context) * 1.8,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close,
                      color: WelcomePopup._kWhiteColor,
                      size: ResponsiveUtils.getIconSize(context) * 1.2,
                    ),
                  ),
                ),
              ),

            // Tap anywhere to close the popup
            Positioned.fill(
              child: GestureDetector(
                onTap: _handleClose,
                behavior: HitTestBehavior.translucent,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOnly({
    required String imageUrl,
    required int index,
    required double maxWidth,
    required double maxHeight,
  }) {
    return SizedBox(
      width: maxWidth,
      height: maxHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildScaledImage(imageUrl),
      ),
    );
  }

  Widget _buildScaledImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => Container(
        color: Colors.black.withOpacity(0.2),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(WelcomePopup._kWhiteColor),
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        print('Image load error: $error for URL: $url');
        return Container(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: 60,
                  color: WelcomePopup._kWhiteColor.withOpacity(0.7),
                ),
                SizedBox(height: 16),
                Text(
                  'Image Not Available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: WelcomePopup._kWhiteColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: _currentPage == index ? 28 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? WelcomePopup._kWhiteColor
            : WelcomePopup._kWhiteColor.withOpacity(0.5),
        shape: BoxShape.circle,
        boxShadow: _currentPage == index
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
    );
  }
}