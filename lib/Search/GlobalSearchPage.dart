// File: lib/Search/GlobalSearchPage.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../CommonClass/ApiClass.dart';
import '../services/cart_wishlist_provider.dart';
import '../BuyerDetails/DroneDetailPage.dart';
import '../../utils/responsive_utils.dart';
import 'Search_models.dart';
import 'Search_service.dart';

class GlobalSearchPage extends StatefulWidget {
  final ApiClass apiClass;
  final CartWishlistProvider? cartProvider;
  final Map<String, List<dynamic>> marketplaceData;

  const GlobalSearchPage({
    Key? key,
    required this.apiClass,
    this.cartProvider,
    required this.marketplaceData,
  }) : super(key: key);

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();
  Timer? _debounceTimer;

  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';
  SearchFilters _filters = SearchFilters();
  SortOption _sortBy = SortOption.RELEVANCE;

  // Colors
  static const _kPrimaryColor = Color(0xFF1E0E5C);
  static const _kWhiteColor = Color(0xFFFFFFFF);
  static const _kDarkTextColor = Color(0xFF0F172A);
  static const _kMediumTextColor = Color(0xFF64748B);
  static const _kLightTextColor = Color(0xFF94A3B8);
  static const _kBorderColor = Color(0xFFE2E8F0);
  static const _kCardBackgroundColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      } else {
        setState(() => _searchResults.clear());
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted || query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      // Try GraphQL search first
      final response = await _searchService.globalSearch(
        query: query,
        filters: _filters,
        sortBy: _sortBy,
      );

      if (response.results.isNotEmpty) {
        setState(() => _searchResults = response.results);
      } else {
        // Fallback to local marketplace search
        final localResults = await _searchService.searchInMarketplace(
          query: query,
          marketplaceData: widget.marketplaceData,
          filters: _filters,
        );
        setState(() => _searchResults = localResults);
      }
    } catch (e) {
      debugPrint('Search error: $e');
      // Fallback to local search
      final localResults = await _searchService.searchInMarketplace(
        query: query,
        marketplaceData: widget.marketplaceData,
        filters: _filters,
      );
      setState(() => _searchResults = localResults);
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Widget _buildShimmerLoader() {
    final cardHeight = ResponsiveUtils.getProductCardHeight(context) / 2;
    final cardMargin = ResponsiveUtils.getCardMargin(context);
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);

    return ListView.builder(
      padding: EdgeInsets.all(horizontalPadding),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFFE2E8F0),
          highlightColor: const Color(0xFFF8FAFC),
          child: Container(
            height: cardHeight,
            margin: EdgeInsets.only(bottom: cardMargin),
            decoration: BoxDecoration(
              color: _kWhiteColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: _kLightTextColor,
          ),
          SizedBox(height: 16),
          Text(
            'No results found for "$_searchQuery"',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _kDarkTextColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try different keywords or check spelling',
            style: GoogleFonts.inter(
              color: _kMediumTextColor,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchResults.clear();
                _searchQuery = '';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryColor,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Clear Search',
              style: GoogleFonts.inter(
                color: _kWhiteColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(SearchResult result) {
    final cardMargin = ResponsiveUtils.getCardMargin(context);
    final bodyFontSize = ResponsiveUtils.getBodyFontSize(context);
    final smallFontSize = ResponsiveUtils.getSmallFontSize(context);

    String getCategoryText() {
      if (result is DroneSearchResult) {
        return result.category ?? 'Drone';
      } else if (result is PartSearchResult) {
        return 'Part';
      } else if (result is AccessorySearchResult) {
        return result.category ?? 'Accessory';
      }
      return 'Product';
    }

    String getSubtitle() {
      if (result is DroneSearchResult) {
        return '${result.brand ?? ''} ${result.model ?? ''}'.trim();
      } else if (result is PartSearchResult) {
        return result.brand ?? 'Drone Part';
      } else if (result is AccessorySearchResult) {
        return result.brand ?? 'Accessory';
      }
      return '';
    }

    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(vertical: cardMargin / 2, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(cardMargin),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _kCardBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: result.image ?? 'https://via.placeholder.com/150',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Icon(
                Icons.photo,
                color: _kLightTextColor,
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.name ?? 'Unnamed Product',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: bodyFontSize,
                color: _kDarkTextColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              getSubtitle(),
              style: GoogleFonts.inter(
                color: _kMediumTextColor,
                fontSize: smallFontSize,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  getCategoryText(),
                  style: GoogleFonts.inter(
                    color: _kPrimaryColor,
                    fontSize: smallFontSize - 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Spacer(),
              Text(
                '₹${result.price ?? 0}',
                style: GoogleFonts.inter(
                  color: _kDarkTextColor,
                  fontWeight: FontWeight.w800,
                  fontSize: bodyFontSize,
                ),
              ),
            ],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: _kMediumTextColor,
        ),
        onTap: () => _handleResultTap(result),
      ),
    );
  }

  void _handleResultTap(SearchResult result) {
    final Map<String, dynamic> normalized = {
      'id': result.id,
      'name': result.name ?? 'Product',
      'price': result.price ?? 0,
      'image': result.image,
      'description': '',
      'status': 'approved',
    };

    // Add type-specific fields
    if (result is DroneSearchResult) {
      normalized['model'] = result.model;
      normalized['category'] = result.category;
      normalized['uin'] = result.uin;
    } else if (result is PartSearchResult) {
      normalized['model'] = result.model;
    } else if (result is AccessorySearchResult) {
      normalized['category'] = result.category;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DroneDetailPage(
          drone: normalized,
          Drone: normalized,
          initialIsFavorite: false,
        ),
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    final brandsAndCategories = await _searchService.getFilterOptions();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => FilterBottomSheet(
        currentFilters: _filters,
        currentSort: _sortBy,
        brands: brandsAndCategories['brands'] ?? [],
        categories: brandsAndCategories['categories'] ?? [],
        onApply: (filters, sortBy) {
          setState(() {
            _filters = filters;
            _sortBy = sortBy;
          });

          if (_searchQuery.isNotEmpty) {
            _performSearch(_searchQuery);
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final verticalPadding = ResponsiveUtils.getVerticalPadding(context);

    return Scaffold(
      backgroundColor: _kWhiteColor,
      appBar: AppBar(
        backgroundColor: _kWhiteColor,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: _kDarkTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: _kCardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search drones, parts, accessories...',
              hintStyle: GoogleFonts.inter(
                color: _kLightTextColor,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear_rounded, size: 20),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchResults.clear();
                    _searchQuery = '';
                  });
                },
              )
                  : null,
            ),
            style: GoogleFonts.inter(
              color: _kDarkTextColor,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: _kDarkTextColor),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Recent searches section (when no query)
          if (_searchQuery.isEmpty && _searchResults.isEmpty)
            _buildRecentSearches(),

          // Search results
          Expanded(
            child: _isSearching
                ? _buildShimmerLoader()
                : _searchResults.isEmpty && _searchQuery.isNotEmpty
                ? _buildNoResults()
                : ListView.builder(
              padding: EdgeInsets.only(top: verticalPadding),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                return _buildSearchResultItem(_searchResults[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    // You'll need to implement getRecentSearches from SharedPreferences
    return FutureBuilder<List<String>>(
      future: _getRecentSearches(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return SizedBox();

        final recentSearches = snapshot.data!;
        final cardMargin = ResponsiveUtils.getCardMargin(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Recent Searches',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: _kDarkTextColor,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: recentSearches.length,
              itemBuilder: (context, index) {
                final search = recentSearches[index];
                return ListTile(
                  leading: Icon(Icons.history_rounded, color: _kMediumTextColor),
                  title: Text(
                    search,
                    style: GoogleFonts.inter(
                      color: _kDarkTextColor,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.close_rounded, size: 18),
                    onPressed: () => _removeRecentSearch(search),
                  ),
                  onTap: () {
                    _searchController.text = search;
                    _performSearch(search);
                  },
                );
              },
            ),
            Divider(height: 1),
          ],
        );
      },
    );
  }

  Future<List<String>> _getRecentSearches() async {
    // Implement using SharedPreferences
    return []; // Placeholder
  }

  Future<void> _removeRecentSearch(String search) async {
    // Implement using SharedPreferences
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}

// FilterBottomSheet Widget
class FilterBottomSheet extends StatefulWidget {
  final SearchFilters currentFilters;
  final SortOption currentSort;
  final List<String> brands;
  final List<String> categories;
  final Function(SearchFilters, SortOption) onApply;

  const FilterBottomSheet({
    Key? key,
    required this.currentFilters,
    required this.currentSort,
    required this.brands,
    required this.categories,
    required this.onApply,
  }) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late SearchFilters _tempFilters;
  late SortOption _tempSort;

  @override
  void initState() {
    super.initState();
    _tempFilters = widget.currentFilters;
    _tempSort = widget.currentSort;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter & Sort',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          Divider(),

          // Product Types
          _buildFilterSection(
            title: 'Product Types',
            children: [
              _buildFilterChip(
                label: 'Drones',
                selected: _tempFilters.types.contains(SearchableType.DRONE),
                onTap: () => _toggleType(SearchableType.DRONE),
              ),
              _buildFilterChip(
                label: 'Parts',
                selected: _tempFilters.types.contains(SearchableType.PART),
                onTap: () => _toggleType(SearchableType.PART),
              ),
              _buildFilterChip(
                label: 'Accessories',
                selected: _tempFilters.types.contains(SearchableType.ACCESSORY),
                onTap: () => _toggleType(SearchableType.ACCESSORY),
              ),
            ],
          ),

          // Price Range
          _buildFilterSection(
            title: 'Price Range',
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Min Price',
                        prefixText: '₹',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _tempFilters = _tempFilters.copyWith(
                          minPrice: value.isEmpty ? null : double.tryParse(value),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Max Price',
                        prefixText: '₹',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _tempFilters = _tempFilters.copyWith(
                          maxPrice: value.isEmpty ? null : double.tryParse(value),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Sort Options
          _buildFilterSection(
            title: 'Sort By',
            children: [
              _buildSortOption(
                label: 'Most Relevant',
                value: SortOption.RELEVANCE,
              ),
              _buildSortOption(
                label: 'Price: Low to High',
                value: SortOption.PRICE_ASC,
              ),
              _buildSortOption(
                label: 'Price: High to Low',
                value: SortOption.PRICE_DESC,
              ),
              _buildSortOption(
                label: 'Newest First',
                value: SortOption.NEWEST,
              ),
            ],
          ),

          // Apply Button
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => widget.onApply(_tempFilters, _tempSort),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1E0E5C),
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Apply Filters',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E0E5C) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF1E0E5C) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption({
    required String label,
    required SortOption value,
  }) {
    return RadioListTile<SortOption>(
      title: Text(label),
      value: value,
      groupValue: _tempSort,
      onChanged: (value) {
        if (value != null) {
          setState(() => _tempSort = value);
        }
      },
    );
  }

  void _toggleType(SearchableType type) {
    setState(() {
      final List<SearchableType> newTypes = List.from(_tempFilters.types);
      if (newTypes.contains(type)) {
        newTypes.remove(type);
      } else {
        newTypes.add(type);
      }
      _tempFilters = _tempFilters.copyWith(types: newTypes);
    });
  }
}