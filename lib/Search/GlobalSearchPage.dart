import 'dart:async';
import 'dart:math';
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


  static const _kPrimaryColor = Color(0xFF1A0A5B);
  static const _kWhiteColor = Color(0xFFFFFFFF);
  static const _kDarkTextColor = Color(0xFF1A1A1A);
  static const _kMediumTextColor = Color(0xFF666666);
  static const _kLightTextColor = Color(0xFF999999);
  static const _kBorderColor = Color(0xFFE5E5E5);
  static const _kCardBackgroundColor = Color(0xFFF5F5F5);

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

    debugPrint('\n\n=== PERFORMING SEARCH ===');
    debugPrint('Search Query: "$query"');
    debugPrint('Active Filters: ${_filters.toJson()}');
    debugPrint('Sort By: $_sortBy');
    debugPrint('Has active filters: ${_hasActiveFilters()}');

    try {
      final response = await _searchService.globalSearch(
        query: query,
        filters: _filters,
        sortBy: _sortBy,
      );

      debugPrint('GraphQL returned: ${response.results.length} results');

      if (response.results.isNotEmpty) {
        setState(() => _searchResults = response.results);
        debugPrint('Displaying ${response.results.length} results from GraphQL');
      } else {
        debugPrint('No results from GraphQL, trying marketplace fallback...');
        final localResults = await _searchService.searchInMarketplace(
          query: query,
          marketplaceData: widget.marketplaceData,
          filters: _filters,
          sortBy: _sortBy,
        );
        debugPrint('Marketplace returned: ${localResults.length} results');
        setState(() => _searchResults = localResults);
      }
    } catch (e) {
      debugPrint('Search error: $e');
      debugPrint('Trying marketplace search as fallback...');
      final localResults = await _searchService.searchInMarketplace(
        query: query,
        marketplaceData: widget.marketplaceData,
        filters: _filters,
        sortBy: _sortBy,
      );
      debugPrint('Marketplace fallback: ${localResults.length} results');
      setState(() => _searchResults = localResults);
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
      debugPrint('=== SEARCH COMPLETE ===\n');
    }
  }

  Widget _buildShimmerLoader() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFFE5E5E5),
          highlightColor: const Color(0xFFF5F5F5),
          child: Container(
            decoration: BoxDecoration(
              color: _kWhiteColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoResults() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 80,
                  color: _kLightTextColor,
                ),
                const SizedBox(height: 20),
                Text(
                  'No results found for "$_searchQuery"',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _kDarkTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Try different keywords or adjust your filters',
                  style: GoogleFonts.inter(
                    color: _kMediumTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_hasActiveFilters()) ...[
                  const SizedBox(height: 15),
                  Text(
                    'Active filters: ${_getActiveFiltersText()}',
                    style: GoogleFonts.inter(
                      color: _kPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults.clear();
                      _searchQuery = '';
                      _filters = SearchFilters();
                      _sortBy = SortOption.RELEVANCE;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Clear Search & Filters',
                    style: GoogleFonts.inter(
                      color: _kWhiteColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getActiveFiltersText() {
    final filters = [];

    if (_filters.types.isNotEmpty) {
      final typeNames = _filters.types.map((t) {
        switch (t) {
          case SearchableType.DRONE:
            return 'Drones';
          case SearchableType.PART:
            return 'Parts';
          case SearchableType.ACCESSORY:
            return 'Accessories';
          default:
            return 'Unknown';
        }
      }).join(', ');
      filters.add(typeNames);
    }

    if (_filters.minPrice != null || _filters.maxPrice != null) {
      final priceRange = [];
      if (_filters.minPrice != null) priceRange.add('Min: ₹${_filters.minPrice}');
      if (_filters.maxPrice != null) priceRange.add('Max: ₹${_filters.maxPrice}');
      filters.add(priceRange.join(' '));
    }

    if (_filters.brands.isNotEmpty) {
      filters.add('Brands: ${_filters.brands.take(2).join(', ')}${_filters.brands.length > 2 ? '...' : ''}');
    }

    if (_filters.categories.isNotEmpty) {
      filters.add('Categories: ${_filters.categories.take(2).join(', ')}${_filters.categories.length > 2 ? '...' : ''}');
    }

    if (_sortBy != SortOption.RELEVANCE) {
      filters.add('Sorted by: ${_getSortName(_sortBy)}');
    }

    return filters.join(' • ');
  }

  String _getSortName(SortOption sort) {
    switch (sort) {
      case SortOption.RELEVANCE:
        return 'Most Relevant';
      case SortOption.PRICE_ASC:
        return 'Price: Low to High';
      case SortOption.PRICE_DESC:
        return 'Price: High to Low';
      case SortOption.NEWEST:
        return 'Newest First';
    }
  }

  Widget _buildSearchResultItem(SearchResult result) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 280, // Minimum height constraint
        maxHeight: 320, // Maximum height constraint
      ),
      decoration: BoxDecoration(
        color: _kWhiteColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorderColor, width: 1),
      ),
      child: InkWell(
        onTap: () => _handleResultTap(result),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Changed to min
          children: [
            // Product Image - Fixed height
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _kCardBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: CachedNetworkImage(
                  imageUrl: result.image ?? 'https://via.placeholder.com/150',
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      color: _kPrimaryColor,
                      strokeWidth: 1.5,
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: _kCardBackgroundColor,
                    child: Center(
                      child: Icon(
                        Icons.photo,
                        color: _kLightTextColor,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),


            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              Text(
                                result.name ?? 'Unnamed Product',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: _kDarkTextColor,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),


                              if (_getSubtitle(result).isNotEmpty)
                                Text(
                                  _getSubtitle(result),
                                  style: GoogleFonts.inter(
                                    color: _kMediumTextColor,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),


                              const SizedBox(height: 6),
                              Text(
                                '₹${result.price?.toStringAsFixed(0) ?? "0"}',
                                style: GoogleFonts.inter(
                                  color: _kPrimaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),


                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _kPrimaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getCategoryText(result),
                                  style: GoogleFonts.inter(
                                    color: _kPrimaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),


                              if (result.description != null && result.description!.isNotEmpty)
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      result.description!,
                                      style: GoogleFonts.inter(
                                        color: _kMediumTextColor,
                                        fontSize: 11,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),


                              const Spacer(),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_shipping_outlined,
                                    size: 12,
                                    color: _kMediumTextColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Free Delivery',
                                      style: GoogleFonts.inter(
                                        color: _kMediumTextColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSubtitle(SearchResult result) {
    if (result is DroneSearchResult) {
      return '${result.brand ?? ''} ${result.model ?? ''}'.trim();
    } else if (result is PartSearchResult) {
      return result.brand ?? 'Drone Part';
    } else if (result is AccessorySearchResult) {
      return result.brand ?? 'Accessory';
    }
    return '';
  }

  String _getCategoryText(SearchResult result) {
    if (result is DroneSearchResult) {
      return result.category ?? 'Drone';
    } else if (result is PartSearchResult) {
      return 'Part';
    } else if (result is AccessorySearchResult) {
      return result.category ?? 'Accessory';
    }
    return 'Product';
  }

  void _handleResultTap(SearchResult result) {
    final Map<String, dynamic> normalized = {
      'id': result.id,
      'name': result.name ?? 'Product',
      'price': result.price ?? 0,
      'image': result.image,
      'description': result.description ?? '',
      'status': 'approved',
    };

    if (result is DroneSearchResult) {
      normalized['model'] = result.model;
      normalized['category'] = result.category;
      normalized['uin'] = result.uin;
      normalized['type'] = 'DRONE';
    } else if (result is PartSearchResult) {
      normalized['model'] = result.model;
      normalized['compatibleDrones'] = result.compatibleDrones;
      normalized['type'] = 'PART';
    } else if (result is AccessorySearchResult) {
      normalized['category'] = result.category;
      normalized['type'] = 'ACCESSORY';
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

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
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
          Navigator.pop(context, {'filters': filters, 'sortBy': sortBy});
        },
      ),
    );

    if (result != null && mounted) {
      debugPrint('Applying new filters: ${result['filters'].toJson()}');
      debugPrint('Applying new sort: ${result['sortBy']}');

      setState(() {
        _filters = result['filters'];
        _sortBy = result['sortBy'];
      });

      if (_searchQuery.isNotEmpty) {
        _performSearch(_searchQuery);
      }
    }
  }

  void _clearFilters() {
    debugPrint('Clearing all filters');
    setState(() {
      _filters = SearchFilters();
      _sortBy = SortOption.RELEVANCE;
    });

    if (_searchQuery.isNotEmpty) {
      _performSearch(_searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _kPrimaryColor,
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _kWhiteColor),
          onPressed: () => Navigator.pop(context),
          padding: const EdgeInsets.only(left: 8),
        ),
        title: Container(
          height: 36,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: _kWhiteColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search drone names, brands, models...',
              hintStyle: GoogleFonts.inter(
                color: _kLightTextColor,
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              prefixIcon: Icon(Icons.search, color: _kPrimaryColor, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 16, color: _kMediumTextColor),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchResults.clear();
                    _searchQuery = '';
                  });
                },
                padding: const EdgeInsets.all(4),
              )
                  : null,
            ),
            style: GoogleFonts.inter(
              color: _kDarkTextColor,
              fontSize: 13,
            ),
          ),
        ),
        actions: [
          // Clear Filters Button (if filters are active)
          if (_hasActiveFilters())
            IconButton(
              icon: const Icon(Icons.filter_alt_off_rounded, color: _kWhiteColor, size: 20),
              onPressed: _clearFilters,
              tooltip: 'Clear Filters',
            ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: _kWhiteColor, size: 22),
            onPressed: _showFilterDialog,
            padding: const EdgeInsets.only(right: 8),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [

                if (_searchQuery.isNotEmpty && _searchResults.isNotEmpty)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_searchResults.length} results${_hasActiveFilters() ? ' (Filtered)' : ''}',
                          style: GoogleFonts.inter(
                            color: _kDarkTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        InkWell(
                          onTap: _showFilterDialog,
                          child: Row(
                            children: [
                              Icon(Icons.sort, size: 14, color: _kPrimaryColor),
                              const SizedBox(width: 4),
                              Text(
                                'Sort/Filter',
                                style: GoogleFonts.inter(
                                  color: _kPrimaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),


                Expanded(
                  child: _isSearching
                      ? _buildShimmerLoader()
                      : _searchResults.isEmpty && _searchQuery.isNotEmpty
                      ? _buildNoResults()
                      : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: constraints.maxWidth > 400 ? 0.7 : 0.65,
                    ),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      return _buildSearchResultItem(_searchResults[index]);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    bool hasActive = false;

    if (_filters.types.isNotEmpty) {
      hasActive = true;
    }

    if (_filters.minPrice != null) {
      hasActive = true;
    }

    if (_filters.maxPrice != null) {
      hasActive = true;
    }

    if (_filters.brands.isNotEmpty) {
      hasActive = true;
    }

    if (_filters.categories.isNotEmpty) {
      hasActive = true;
    }

    if (_sortBy != SortOption.RELEVANCE) {
      hasActive = true;
    }

    return hasActive;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}

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
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  List<String> _selectedBrands = [];
  List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _tempFilters = widget.currentFilters;
    _tempSort = widget.currentSort;
    _selectedBrands = List.from(_tempFilters.brands);
    _selectedCategories = List.from(_tempFilters.categories);
    _minPriceController = TextEditingController(
      text: _tempFilters.minPrice != null ? _tempFilters.minPrice!.toStringAsFixed(0) : '',
    );
    _maxPriceController = TextEditingController(
      text: _tempFilters.maxPrice != null ? _tempFilters.maxPrice!.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _updatePriceFilters() {
    double? minPrice;
    double? maxPrice;

    // Parse min price
    if (_minPriceController.text.isNotEmpty) {
      final parsedMin = double.tryParse(_minPriceController.text);
      if (parsedMin != null && parsedMin > 0) {
        minPrice = parsedMin;
      } else {
        _minPriceController.clear();
      }
    }

    // Parse max price
    if (_maxPriceController.text.isNotEmpty) {
      final parsedMax = double.tryParse(_maxPriceController.text);
      if (parsedMax != null && parsedMax > 0) {
        maxPrice = parsedMax;
      } else {
        _maxPriceController.clear();
      }
    }


    if (minPrice != null && maxPrice != null && minPrice > maxPrice) {

      final temp = minPrice;
      minPrice = maxPrice;
      maxPrice = temp;


      _minPriceController.text = minPrice.toStringAsFixed(0);
      _maxPriceController.text = maxPrice.toStringAsFixed(0);
    }

    _tempFilters = _tempFilters.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
              ),
            ],
          ),

          const Divider(height: 20),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  _buildFilterSection(
                    title: 'Product Types',
                    children: [
                      _buildTypeChip(
                        label: 'Drones',
                        selected: _tempFilters.types.contains(SearchableType.DRONE),
                        onTap: () => _toggleType(SearchableType.DRONE),
                      ),
                      _buildTypeChip(
                        label: 'Parts',
                        selected: _tempFilters.types.contains(SearchableType.PART),
                        onTap: () => _toggleType(SearchableType.PART),
                      ),
                      _buildTypeChip(
                        label: 'Accessories',
                        selected: _tempFilters.types.contains(SearchableType.ACCESSORY),
                        onTap: () => _toggleType(SearchableType.ACCESSORY),
                      ),
                    ],
                  ),


                  _buildFilterSection(
                    title: 'Price Range',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _minPriceController,
                              decoration: InputDecoration(
                                labelText: 'Min Price',
                                prefixText: '₹',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _updatePriceFilters();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _maxPriceController,
                              decoration: InputDecoration(
                                labelText: 'Max Price',
                                prefixText: '₹',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _updatePriceFilters();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),


                  if (widget.brands.isNotEmpty)
                    _buildFilterSection(
                      title: 'Brands',
                      children: widget.brands.map((brand) {
                        return _buildFilterChip(
                          label: brand,
                          selected: _selectedBrands.contains(brand),
                          onTap: () => _toggleBrand(brand),
                        );
                      }).toList(),
                    ),


                  if (widget.categories.isNotEmpty)
                    _buildFilterSection(
                      title: 'Categories',
                      children: widget.categories.map((category) {
                        return _buildFilterChip(
                          label: category,
                          selected: _selectedCategories.contains(category),
                          onTap: () => _toggleCategory(category),
                        );
                      }).toList(),
                    ),


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
                ],
              ),
            ),
          ),


          Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _tempFilters = SearchFilters();
                        _tempSort = SortOption.RELEVANCE;
                        _selectedBrands.clear();
                        _selectedCategories.clear();
                        _minPriceController.clear();
                        _maxPriceController.clear();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A0A5B),
                      side: const BorderSide(color: Color(0xFF1A0A5B)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Clear All',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1A0A5B),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_tempFilters, _tempSort);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A0A5B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Apply',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
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

  Widget _buildFilterSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTypeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A0A5B) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF1A0A5B) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A0A5B) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF1A0A5B) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            fontSize: 13,
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
      title: Text(
        label,
        style: GoogleFonts.inter(fontSize: 14),
      ),
      value: value,
      groupValue: _tempSort,
      contentPadding: EdgeInsets.zero,
      dense: true,
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

  void _toggleBrand(String brand) {
    setState(() {
      if (_selectedBrands.contains(brand)) {
        _selectedBrands.remove(brand);
      } else {
        _selectedBrands.add(brand);
      }
      _tempFilters = _tempFilters.copyWith(brands: _selectedBrands);
    });
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
      _tempFilters = _tempFilters.copyWith(categories: _selectedCategories);
    });
  }
}