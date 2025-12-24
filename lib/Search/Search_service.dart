// File: lib/Search/Search_service.dart
import 'dart:async';
import 'dart:convert';
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
      debugPrint('Performing GraphQL search for: $query');

      final response = await http.post(
        Uri.parse(EnvConfig.baseUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "query": """
            query GlobalSearch(\$query: String!, \$page: Int, \$limit: Int, \$filters: SearchFilters, \$sortBy: SortOption) {
              globalSearch(query: \$query, page: \$page, limit: \$limit, filters: \$filters, sortBy: \$sortBy) {
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
            "filters": filters?.toJson() ?? {},
            "sortBy": sortBy.toString().split('.').last,
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Network error: ${response.statusCode}');
      }

      final json = jsonDecode(response.body);

      if (json['errors'] != null) {
        throw Exception(json['errors'][0]['message']);
      }

      if (json['data']?['globalSearch'] == null) {
        return SearchResponse(
          results: [],
          total: 0,
          page: page,
          totalPages: 0,
          hasNextPage: false,
        );
      }

      return SearchResponse.fromJson(json['data']['globalSearch']);
    } catch (e) {
      debugPrint('GraphQL search error: $e');
      // Return empty response for fallback
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
  }) async {
    try {
      debugPrint('Starting marketplace search for: $query');

      final List<SearchResult> results = [];
      final queryLower = query.toLowerCase();

      // Helper function to create search result from item
      SearchResult? createSearchResult(Map<String, dynamic> item, String type) {
        // Check status
        if (item['status']?.toString().toLowerCase() != 'approved') {
          return null;
        }

        // Check filters
        if (filters != null && !_matchesFilters(item, filters)) {
          return null;
        }

        // Check query match
        if (!_matchesQuery(item, queryLower, type)) {
          return null;
        }

        // Create appropriate result type
        switch (type) {
          case 'DRONE':
            return DroneSearchResult(
              id: item['id']?.toString() ?? '',
              type: 'DRONE',
              name: item['name']?.toString(),
              brand: item['brand']?.toString(),
              model: item['model']?.toString(),
              price: (item['price'] as num?)?.toDouble(),
              image: item['image']?.toString() ?? item['imageUrl']?.toString(),
              category: item['category']?.toString(),
              score: _calculateRelevanceScore(item, queryLower, type),
            );
          case 'PART':
            return PartSearchResult(
              id: item['id']?.toString() ?? '',
              type: 'PART',
              name: item['name']?.toString(),
              brand: item['brand']?.toString(),
              model: item['model']?.toString(),
              price: (item['price'] as num?)?.toDouble(),
              image: item['image']?.toString() ?? item['imageUrl']?.toString(),
              compatibleDrones: (item['compatibleDrones'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
                  [],
              score: _calculateRelevanceScore(item, queryLower, type),
            );
          case 'ACCESSORY':
            return AccessorySearchResult(
              id: item['id']?.toString() ?? '',
              type: 'ACCESSORY',
              name: item['name']?.toString(),
              brand: item['brand']?.toString(),
              category: item['category']?.toString(),
              price: (item['price'] as num?)?.toDouble(),
              image: item['image']?.toString() ?? item['imageUrl']?.toString(),
              description: item['description']?.toString(),
              score: _calculateRelevanceScore(item, queryLower, type),
            );
          default:
            return null;
        }
      }

      // Search in drones if filter allows or no filters
      if (filters?.types.isEmpty ?? true || filters!.types.contains(SearchableType.DRONE)) {
        for (var drone in marketplaceData["Drones"] ?? []) {
          if (drone is Map<String, dynamic>) {
            final result = createSearchResult(drone, 'DRONE');
            if (result != null) results.add(result);
          }
        }
      }

      // Search in parts
      if (filters?.types.isEmpty ?? true || filters!.types.contains(SearchableType.PART)) {
        for (var part in marketplaceData["Parts"] ?? []) {
          if (part is Map<String, dynamic>) {
            final result = createSearchResult(part, 'PART');
            if (result != null) results.add(result);
          }
        }
      }

      // Search in accessories
      if (filters?.types.isEmpty ?? true || filters!.types.contains(SearchableType.ACCESSORY)) {
        for (var accessory in marketplaceData["Accessories"] ?? []) {
          if (accessory is Map<String, dynamic>) {
            final result = createSearchResult(accessory, 'ACCESSORY');
            if (result != null) results.add(result);
          }
        }
      }

      // Sort by relevance score
      results.sort((a, b) => b.score.compareTo(a.score));

      debugPrint('Marketplace search found ${results.length} results');
      return results;
    } catch (e) {
      debugPrint('Marketplace search error: $e');
      return [];
    }
  }

  bool _matchesQuery(Map<String, dynamic> item, String query, String type) {
    if (query.isEmpty) return true;

    final searchFields = _getSearchFieldsForType(type);
    for (var field in searchFields) {
      if (item[field]?.toString().toLowerCase().contains(query) ?? false) {
        return true;
      }
    }
    return false;
  }

  bool _matchesFilters(Map<String, dynamic> item, SearchFilters filters) {
    // Price filter
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    if (filters.minPrice != null && price < filters.minPrice!) return false;
    if (filters.maxPrice != null && price > filters.maxPrice!) return false;

    // Brand filter
    if (filters.brands.isNotEmpty) {
      final itemBrand = item['brand']?.toString().toLowerCase();
      if (itemBrand == null) return false;
      final hasBrandMatch = filters.brands.any((brand) =>
      brand.toLowerCase() == itemBrand);
      if (!hasBrandMatch) return false;
    }

    // Category filter
    if (filters.categories.isNotEmpty) {
      final itemCategory = item['category']?.toString().toLowerCase();
      if (itemCategory == null) return false;
      final hasCategoryMatch = filters.categories.any((category) =>
      category.toLowerCase() == itemCategory);
      if (!hasCategoryMatch) return false;
    }

    return true;
  }

  List<String> _getSearchFieldsForType(String type) {
    switch (type) {
      case 'DRONE':
        return ['name', 'brand', 'model', 'category', 'uin', 'description'];
      case 'PART':
        return ['name', 'brand', 'model', 'description', 'compatibleDrones'];
      case 'ACCESSORY':
        return ['name', 'brand', 'category', 'description'];
      default:
        return ['name', 'brand', 'description'];
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
      if (field == 'name') score *= 1.5; // Name matches are most important
      if (field == 'brand') score *= 1.3; // Brand matches are important
    }

    // Price proximity bonus (if query contains price)
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final priceMatch = RegExp(r'(\d+)\s*(k|thousand|grand|hundred)?').firstMatch(query);
    if (priceMatch != null) {
      final queryPrice = int.tryParse(priceMatch.group(1) ?? '0') ?? 0;
      final multiplier = priceMatch.group(2) == 'k' ? 1000 : 1;
      final actualQueryPrice = queryPrice * multiplier;

      // Bonus for price proximity
      final priceDiff = (price - actualQueryPrice).abs();
      if (priceDiff < 1000) score += 40;
      if (priceDiff < 500) score += 30;
      if (priceDiff < 100) score += 20;
    }

    return (score / 200).clamp(0.0, 1.0); // Normalize to 0-1
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

  // Get search suggestions for autocomplete
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