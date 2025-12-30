import 'package:flutter/material.dart';

enum SearchableType {
  DRONE,
  PART,
  ACCESSORY,
}

enum SortOption {
  RELEVANCE,
  PRICE_ASC,
  PRICE_DESC,
  NEWEST,
}

class SearchFilters {
  final List<SearchableType> types;
  final double? minPrice;
  final double? maxPrice;
  final List<String> brands;
  final List<String> categories;

  SearchFilters({
    this.types = const [],
    this.minPrice,
    this.maxPrice,
    this.brands = const [],
    this.categories = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'types': types.map((e) {
        switch (e) {
          case SearchableType.DRONE:
            return 'DRONE';
          case SearchableType.PART:
            return 'PART';
          case SearchableType.ACCESSORY:
            return 'ACCESSORY';
          default:
            return 'DRONE';
        }
      }).toList(),
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'brands': brands,
      'categories': categories,
    };
  }

  SearchFilters copyWith({
    List<SearchableType>? types,
    double? minPrice,
    double? maxPrice,
    List<String>? brands,
    List<String>? categories,
  }) {
    return SearchFilters(
      types: types ?? this.types,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      brands: brands ?? this.brands,
      categories: categories ?? this.categories,
    );
  }

  @override
  String toString() {
    return 'SearchFilters(types: $types, minPrice: $minPrice, maxPrice: $maxPrice, brands: $brands, categories: $categories)';
  }
}

abstract class SearchResult {
  final String id;
  final String type;
  final String? name;
  final double? price;
  final String? image;
  final String? brand;
  final String? description;
  final double score;

  SearchResult({
    required this.id,
    required this.type,
    this.name,
    this.price,
    this.image,
    this.brand,
    this.description,
    this.score = 0.0,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final type = json['type'] ?? json['_type'] ?? 'DRONE';
    final typename = json['__typename'] ?? '';

    if (typename == 'DroneSearchResult' || type == 'DRONE') {
      return DroneSearchResult.fromJson(json);
    } else if (typename == 'PartSearchResult' || type == 'PART') {
      return PartSearchResult.fromJson(json);
    } else if (typename == 'AccessorySearchResult' || type == 'ACCESSORY') {
      return AccessorySearchResult.fromJson(json);
    }
    return DroneSearchResult.fromJson(json);
  }

  @override
  String toString() {
    return '$runtimeType(id: $id, name: $name, price: $price, type: $type)';
  }
}

class DroneSearchResult extends SearchResult {
  final String? model;
  final String? category;
  final String? uin;
  // Removed duplicate description field here

  DroneSearchResult({
    required String id,
    required String type,
    String? name,
    double? price,
    String? image,
    String? brand,
    String? description,
    double score = 0.0,
    this.model,
    this.category,
    this.uin,
  }) : super(
    id: id,
    type: type,
    name: name,
    price: price,
    image: image,
    brand: brand,
    description: description,
    score: score,
  );

  factory DroneSearchResult.fromJson(Map<String, dynamic> json) {
    return DroneSearchResult(
      id: json['id']?.toString() ?? '',
      type: 'DRONE',
      name: json['name']?.toString(),
      price: (json['price'] as num?)?.toDouble(),
      image: json['image']?.toString(),
      brand: json['brand']?.toString(),
      description: json['description']?.toString(),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      model: json['model']?.toString(),
      category: json['category']?.toString(),
      uin: json['uin']?.toString(),
    );
  }
}

class PartSearchResult extends SearchResult {
  final String? model;
  final List<String> compatibleDrones;

  PartSearchResult({
    required String id,
    required String type,
    String? name,
    double? price,
    String? image,
    String? brand,
    String? description,
    double score = 0.0,
    this.model,
    this.compatibleDrones = const [],
  }) : super(
    id: id,
    type: type,
    name: name,
    price: price,
    image: image,
    brand: brand,
    description: description,
    score: score,
  );

  factory PartSearchResult.fromJson(Map<String, dynamic> json) {
    return PartSearchResult(
      id: json['id']?.toString() ?? '',
      type: 'PART',
      name: json['name']?.toString(),
      price: (json['price'] as num?)?.toDouble(),
      image: json['image']?.toString(),
      brand: json['brand']?.toString(),
      description: json['description']?.toString(),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      model: json['model']?.toString(),
      compatibleDrones: (json['compatibleDrones'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
    );
  }
}

class AccessorySearchResult extends SearchResult {
  final String? category;

  AccessorySearchResult({
    required String id,
    required String type,
    String? name,
    double? price,
    String? image,
    String? brand,
    String? description,
    double score = 0.0,
    this.category,
  }) : super(
    id: id,
    type: type,
    name: name,
    price: price,
    image: image,
    brand: brand,
    description: description,
    score: score,
  );

  factory AccessorySearchResult.fromJson(Map<String, dynamic> json) {
    return AccessorySearchResult(
      id: json['id']?.toString() ?? '',
      type: 'ACCESSORY',
      name: json['name']?.toString(),
      price: (json['price'] as num?)?.toDouble(),
      image: json['image']?.toString(),
      brand: json['brand']?.toString(),
      description: json['description']?.toString(),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      category: json['category']?.toString(),
    );
  }
}

class SearchResponse {
  final List<SearchResult> results;
  final int total;
  final int page;
  final int totalPages;
  final bool hasNextPage;

  SearchResponse({
    required this.results,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.hasNextPage,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    final resultsJson = json['results'] as List<dynamic>? ?? [];
    final results = resultsJson.map((item) {
      try {
        return SearchResult.fromJson(item);
      } catch (e) {
        debugPrint('Error parsing search result: $e');
        return DroneSearchResult(id: '', type: 'DRONE');
      }
    }).where((result) => result.id.isNotEmpty).toList();

    return SearchResponse(
      results: results,
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 1,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
    );
  }
}