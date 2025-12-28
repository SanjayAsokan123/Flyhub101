import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import './Search_models.dart';
import '../config/env.dart';

class SearchService {
  Future<SearchResponse> globalSearch({
    required String query,
    int page = 1,
    int limit = 10,
    SearchFilters? filters,
    SortOption sortBy = SortOption.RELEVANCE,
  }) async {
    try {
      debugPrint('=== GLOBAL SEARCH START ===');
      debugPrint('Query: $query');
      debugPrint('Page: $page, Limit: $limit');
      debugPrint('Filters: ${filters?.toJson()}');
      debugPrint('SortBy: $sortBy');

      // Convert SortOption to string that matches GraphQL enum
      String sortByString;
      switch (sortBy) {
        case SortOption.RELEVANCE:
          sortByString = 'RELEVANCE';
          break;
        case SortOption.PRICE_ASC:
          sortByString = 'PRICE_ASC';
          break;
        case SortOption.PRICE_DESC:
          sortByString = 'PRICE_DESC';
          break;
        case SortOption.NEWEST:
          sortByString = 'NEWEST';
          break;
        default:
          sortByString = 'RELEVANCE';
      }

      // Prepare filters for GraphQL
      final Map<String, dynamic> graphqlFilters = {};

      if (filters != null) {
        // Convert SearchableType to strings
        if (filters.types.isNotEmpty) {
          graphqlFilters['types'] = filters.types.map((type) {
            switch (type) {
              case SearchableType.DRONE:
                return 'DRONE';
              case SearchableType.PART:
                return 'PART';
              case SearchableType.ACCESSORY:
                return 'ACCESSORY';
              default:
                return 'DRONE';
            }
          }).toList();
        }

        if (filters.minPrice != null) {
          graphqlFilters['minPrice'] = filters.minPrice;
        }

        if (filters.maxPrice != null) {
          graphqlFilters['maxPrice'] = filters.maxPrice;
        }

        if (filters.brands.isNotEmpty) {
          graphqlFilters['brands'] = filters.brands;
        }

        if (filters.categories.isNotEmpty) {
          graphqlFilters['categories'] = filters.categories;
        }
      }

      debugPrint('GraphQL filters: $graphqlFilters');
      debugPrint('GraphQL sortBy: $sortByString');

      final response = await http.post(
        Uri.parse(EnvConfig.baseUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "query": """
            query GlobalSearch(\$query: String!, \$page: Int, \$limit: Int, \$filters: SearchFilters, \$sortBy: SortOption) {
              globalSearch(
                query: \$query, 
                page: \$page, 
                limit: \$limit, 
                filters: \$filters, 
                sortBy: \$sortBy
              ) {
                results {
                  __typename
                  ... on DroneSearchResult {
                    id
                    type
                    name
                    brand
                    model
                    price
                    image
                    category
                    score
                  }
                  ... on PartSearchResult {
                    id
                    type
                    name
                    brand
                    model
                    price
                    image
                    compatibleDrones
                    score
                  }
                  ... on AccessorySearchResult {
                    id
                    type
                    name
                    brand
                    category
                    price
                    image
                    description
                    score
                  }
                }
                total
                page
                totalPages
                hasNextPage
              }
            }
          """,
          "variables": {
            "query": query,
            "page": page,
            "limit": limit,
            "filters": graphqlFilters.isEmpty ? null : graphqlFilters,
            "sortBy": sortByString,
          },
        }),
      );

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('Network error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Network error: ${response.statusCode}');
      }

      final json = jsonDecode(response.body);

      if (json['errors'] != null) {
        debugPrint('GraphQL errors: ${jsonEncode(json['errors'])}');
        debugPrint('=== GLOBAL SEARCH END (GraphQL errors) ===');
        return SearchResponse(
          results: [],
          total: 0,
          page: page,
          totalPages: 0,
          hasNextPage: false,
        );
      }

      if (json['data']?['globalSearch'] == null) {
        debugPrint('No data in response');
        debugPrint('=== GLOBAL SEARCH END (no data) ===');
        return SearchResponse(
          results: [],
          total: 0,
          page: page,
          totalPages: 0,
          hasNextPage: false,
        );
      }

      final searchResponse = SearchResponse.fromJson(json['data']['globalSearch']);
      debugPrint('GraphQL search successful: ${searchResponse.results.length} results');
      debugPrint('=== GLOBAL SEARCH END ===');
      return searchResponse;
    } catch (e) {
      debugPrint('GraphQL search error: $e');
      debugPrint('=== GLOBAL SEARCH END (error) ===');
      return SearchResponse(
        results: [],
        total: 0,
        page: page,
        totalPages: 0,
        hasNextPage: false,
      );
    }
  }

  Future<List<SearchResult>> searchInMarketplace({
    required String query,
    required Map<String, List<dynamic>> marketplaceData,
    SearchFilters? filters,
    SortOption sortBy = SortOption.RELEVANCE,
  }) async {
    try {
      debugPrint('=== MARKETPLACE SEARCH START ===');
      debugPrint('Query: $query');
      debugPrint('Filters: ${filters?.toJson()}');
      debugPrint('SortBy: $sortBy');

      // Debug marketplace data
      debugPrint('Marketplace data keys: ${marketplaceData.keys}');
      debugPrint('Drones count: ${(marketplaceData["Drones"] ?? []).length}');
      debugPrint('Parts count: ${(marketplaceData["Parts"] ?? []).length}');
      debugPrint('Accessories count: ${(marketplaceData["Accessories"] ?? []).length}');

      final List<SearchResult> results = [];
      final queryLower = query.toLowerCase().trim();

      // Helper function to create search result from item
      SearchResult? createSearchResult(Map<String, dynamic> item, String type) {
        // Check status
        final status = item['status']?.toString().toLowerCase();
        if (status != 'approved') {
          debugPrint('Item rejected - status: $status');
          return null;
        }

        // Check type filter
        if (filters != null && filters.types.isNotEmpty) {
          final SearchableType itemType;
          switch (type) {
            case 'DRONE':
              itemType = SearchableType.DRONE;
              break;
            case 'PART':
              itemType = SearchableType.PART;
              break;
            case 'ACCESSORY':
              itemType = SearchableType.ACCESSORY;
              break;
            default:
              itemType = SearchableType.DRONE;
          }

          if (!filters.types.contains(itemType)) {
            debugPrint('Item rejected - type filter: $type not in ${filters.types}');
            return null;
          }
        }

        // Check other filters
        if (filters != null && !_matchesFilters(item, filters, type)) {
          debugPrint('Item rejected - filters not matched');
          return null;
        }

        // Check query match
        if (!_matchesQuery(item, queryLower, type)) {
          debugPrint('Item rejected - query not matched');
          return null;
        }

        // Create appropriate result type
        switch (type) {
          case 'DRONE':
            return DroneSearchResult(
              id: item['_id']?.toString() ?? item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              type: 'DRONE',
              name: item['name']?.toString(),
              brand: item['brand']?.toString(),
              model: item['model']?.toString(),
              price: (item['price'] as num?)?.toDouble() ?? 0.0,
              image: item['image']?.toString() ?? item['imageUrl']?.toString() ?? item['imageURL']?.toString(),
              category: item['category']?.toString(),
              score: _calculateRelevanceScore(item, queryLower, type),
            );
          case 'PART':
            return PartSearchResult(
              id: item['_id']?.toString() ?? item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              type: 'PART',
              name: item['name']?.toString(),
              brand: item['brand']?.toString(),
              model: item['model']?.toString(),
              price: (item['price'] as num?)?.toDouble() ?? 0.0,
              image: item['image']?.toString() ?? item['imageUrl']?.toString() ?? item['imageURL']?.toString(),
              compatibleDrones: (item['compatibleDrones'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
                  [],
              score: _calculateRelevanceScore(item, queryLower, type),
            );
          case 'ACCESSORY':
            return AccessorySearchResult(
              id: item['_id']?.toString() ?? item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              type: 'ACCESSORY',
              name: item['name']?.toString(),
              brand: item['brand']?.toString(),
              category: item['category']?.toString(),
              price: (item['price'] as num?)?.toDouble() ?? 0.0,
              image: item['image']?.toString() ?? item['imageUrl']?.toString() ?? item['imageURL']?.toString(),
              description: item['description']?.toString(),
              score: _calculateRelevanceScore(item, queryLower, type),
            );
          default:
            return null;
        }
      }

      // Search in all categories based on filters
      debugPrint('Searching with filters: ${filters?.toJson()}');

      // Always search in all categories if no type filter is set
      final bool searchDrones = filters == null ||
          filters.types.isEmpty ||
          filters.types.contains(SearchableType.DRONE);
      final bool searchParts = filters == null ||
          filters.types.isEmpty ||
          filters.types.contains(SearchableType.PART);
      final bool searchAccessories = filters == null ||
          filters.types.isEmpty ||
          filters.types.contains(SearchableType.ACCESSORY);

      debugPrint('Search flags - Drones: $searchDrones, Parts: $searchParts, Accessories: $searchAccessories');

      if (searchDrones) {
        debugPrint('Searching in Drones...');
        for (var drone in marketplaceData["Drones"] ?? []) {
          if (drone is Map<String, dynamic>) {
            final result = createSearchResult(drone, 'DRONE');
            if (result != null) {
              results.add(result);
              debugPrint('Added drone: ${result.name}');
            }
          }
        }
      }

      if (searchParts) {
        debugPrint('Searching in Parts...');
        for (var part in marketplaceData["Parts"] ?? []) {
          if (part is Map<String, dynamic>) {
            final result = createSearchResult(part, 'PART');
            if (result != null) {
              results.add(result);
              debugPrint('Added part: ${result.name}');
            }
          }
        }
      }

      if (searchAccessories) {
        debugPrint('Searching in Accessories...');
        for (var accessory in marketplaceData["Accessories"] ?? []) {
          if (accessory is Map<String, dynamic>) {
            final result = createSearchResult(accessory, 'ACCESSORY');
            if (result != null) {
              results.add(result);
              debugPrint('Added accessory: ${result.name}');
            }
          }
        }
      }

      debugPrint('Found ${results.length} results before sorting');

      // Apply sorting
      final sortedResults = _applySorting(results, sortBy);

      debugPrint('Marketplace search found ${sortedResults.length} results');
      debugPrint('=== MARKETPLACE SEARCH END ===');
      return sortedResults;
    } catch (e) {
      debugPrint('Marketplace search error: $e');
      debugPrint('=== MARKETPLACE SEARCH END (error) ===');
      return [];
    }
  }

  bool _matchesFilters(Map<String, dynamic> item, SearchFilters filters, String type) {
    debugPrint('Checking filters for ${item['name']}');

    // Price filter
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    debugPrint('Item price: $price, Min: ${filters.minPrice}, Max: ${filters.maxPrice}');

    if (filters.minPrice != null && price < filters.minPrice!) {
      debugPrint('❌ Price too low: $price < ${filters.minPrice}');
      return false;
    }
    if (filters.maxPrice != null && price > filters.maxPrice!) {
      debugPrint('❌ Price too high: $price > ${filters.maxPrice}');
      return false;
    }
    debugPrint('✅ Price passed');

    // Brand filter
    if (filters.brands.isNotEmpty) {
      final itemBrand = item['brand']?.toString();
      debugPrint('Item brand: $itemBrand, Filter brands: ${filters.brands}');

      if (itemBrand == null || itemBrand.isEmpty) {
        debugPrint('❌ No brand found');
        return false;
      }

      final hasBrandMatch = filters.brands.any((brand) =>
      itemBrand.toLowerCase().contains(brand.toLowerCase()) ||
          brand.toLowerCase().contains(itemBrand.toLowerCase()));

      if (!hasBrandMatch) {
        debugPrint('❌ Brand mismatch');
        return false;
      }
      debugPrint('✅ Brand passed');
    }

    // Category filter (only for drones and accessories)
    if (filters.categories.isNotEmpty && (type == 'DRONE' || type == 'ACCESSORY')) {
      final itemCategory = item['category']?.toString();
      debugPrint('Item category: $itemCategory, Filter categories: ${filters.categories}');

      if (itemCategory == null || itemCategory.isEmpty) {
        debugPrint('❌ No category found');
        return false;
      }

      final hasCategoryMatch = filters.categories.any((category) =>
      itemCategory.toLowerCase().contains(category.toLowerCase()) ||
          category.toLowerCase().contains(itemCategory.toLowerCase()));

      if (!hasCategoryMatch) {
        debugPrint('❌ Category mismatch');
        return false;
      }
      debugPrint('✅ Category passed');
    }

    debugPrint('✅ All filters passed');
    return true;
  }

  bool _matchesQuery(Map<String, dynamic> item, String query, String type) {
    if (query.isEmpty) return true;

    final searchFields = _getSearchFieldsForType(type);
    final queryWords = query.toLowerCase().split(' ').where((w) => w.length > 2).toList();

    debugPrint('Checking query: $query');
    debugPrint('Query words: $queryWords');
    debugPrint('Item: ${item['name']}');

    // Check if any query word matches any search field
    for (var word in queryWords) {
      for (var field in searchFields) {
        final fieldValue = item[field]?.toString().toLowerCase();
        if (fieldValue != null && fieldValue.contains(word)) {
          debugPrint('✅ Query matched: "$word" in field "$field" with value "$fieldValue"');
          return true;
        }
      }
    }

    // Also check for partial matches
    for (var field in searchFields) {
      final fieldValue = item[field]?.toString().toLowerCase();
      if (fieldValue != null && query.contains(fieldValue)) {
        debugPrint('✅ Query matched (reverse): field "$field" value "$fieldValue" found in query');
        return true;
      }
    }

    debugPrint('❌ Query not matched');
    return false;
  }

  List<SearchResult> _applySorting(List<SearchResult> results, SortOption sortBy) {
    if (results.isEmpty) return results;

    final List<SearchResult> sortedResults = List.from(results);

    debugPrint('=== APPLYING SORTING ===');
    debugPrint('Sort option: $sortBy');
    debugPrint('Results before sorting: ${sortedResults.length}');

    switch (sortBy) {
      case SortOption.PRICE_ASC:
        sortedResults.sort((a, b) {
          final priceA = a.price ?? 0.0;
          final priceB = b.price ?? 0.0;
          debugPrint('Sorting: ${a.name} - ₹$priceA vs ${b.name} - ₹$priceB');
          return priceA.compareTo(priceB);
        });
        debugPrint('=== SORTED BY PRICE ASC ===');
        for (int i = 0; i < min(5, sortedResults.length); i++) {
          debugPrint('${i + 1}. ₹${sortedResults[i].price} - ${sortedResults[i].name}');
        }
        break;

      case SortOption.PRICE_DESC:
        sortedResults.sort((a, b) {
          final priceA = a.price ?? 0.0;
          final priceB = b.price ?? 0.0;
          debugPrint('Sorting: ${a.name} - ₹$priceA vs ${b.name} - ₹$priceB');
          return priceB.compareTo(priceA);
        });
        debugPrint('=== SORTED BY PRICE DESC ===');
        for (int i = 0; i < min(5, sortedResults.length); i++) {
          debugPrint('${i + 1}. ₹${sortedResults[i].price} - ${sortedResults[i].name}');
        }
        break;

      case SortOption.NEWEST:
      // For newest, we'll sort by score (assuming higher score = newer)
        sortedResults.sort((a, b) {
          debugPrint('Sorting by score: ${a.name} - ${a.score} vs ${b.name} - ${b.score}');
          return b.score.compareTo(a.score);
        });
        debugPrint('=== SORTED BY NEWEST ===');
        break;

      case SortOption.RELEVANCE:
      default:
        sortedResults.sort((a, b) {
          debugPrint('Sorting by relevance: ${a.name} - ${a.score} vs ${b.name} - ${b.score}');
          return b.score.compareTo(a.score);
        });
        debugPrint('=== SORTED BY RELEVANCE ===');
        break;
    }

    return sortedResults;
  }

  List<String> _getSearchFieldsForType(String type) {
    switch (type) {
      case 'DRONE':
        return ['name', 'brand', 'model', 'category', 'uin', 'description', 'tags'];
      case 'PART':
        return ['name', 'brand', 'model', 'description', 'compatibleDrones', 'tags'];
      case 'ACCESSORY':
        return ['name', 'brand', 'category', 'description', 'tags'];
      default:
        return ['name', 'brand', 'description', 'tags'];
    }
  }

  double _calculateRelevanceScore(Map<String, dynamic> item, String query, String type) {
    if (query.isEmpty) return 1.0;

    double score = 0.0;
    final searchFields = _getSearchFieldsForType(type);

    // Split query into words
    final queryWords = query.split(' ').where((w) => w.length > 2).toList();

    for (var field in searchFields) {
      final fieldValue = item[field]?.toString().toLowerCase() ?? '';
      if (fieldValue.isEmpty) continue;

      // Exact field match bonus
      if (fieldValue == query) score += 100;

      // Field starts with query
      if (fieldValue.startsWith(query)) score += 50;

      // Field contains query
      if (fieldValue.contains(query)) score += 30;

      // Word matches
      for (var word in queryWords) {
        if (fieldValue.contains(word)) score += 20;
      }

      // Field-specific bonuses
      if (field == 'name') score *= 1.5;
      if (field == 'brand') score *= 1.3;
    }

    return (score / 200).clamp(0.0, 1.0);
  }

  Future<Map<String, List<String>>> getFilterOptions() async {
    try {
      final response = await http.post(
        Uri.parse(EnvConfig.baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "query": """
            query GetFilterOptions {
              brands: distinctBrands
              categories: distinctCategories
            }
          """
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] ?? {};
        return {
          'brands': (data['brands'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          'categories': (data['categories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        };
      }
      return {'brands': [], 'categories': []};
    } catch (e) {
      debugPrint('Get filter options error: $e');
      return {'brands': [], 'categories': []};
    }
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      if (query.length < 2) return [];

      final response = await http.post(
        Uri.parse(EnvConfig.baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "query": """
            query GetSearchSuggestions(\$query: String!) {
              searchSuggestions(query: \$query) {
                text
                type
              }
            }
          """,
          "variables": {"query": query}
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final suggestions = json['data']?['searchSuggestions'] as List<dynamic>?;
        return suggestions?.map((s) => s['text'].toString()).toList() ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Get suggestions error: $e');
      return [];
    }
  }
}