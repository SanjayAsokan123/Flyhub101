import 'package:flutter/material.dart';

class GlobalSearchProvider extends ChangeNotifier {
  final List<dynamic> _rawItems = [];

  List<dynamic> get items => _rawItems;

  void setItems(List<dynamic> items) {
    _rawItems.clear();
    _rawItems.addAll(items);
    notifyListeners();
  }

  List<dynamic> search(String query) {
    if (query.isEmpty) return [];

    final q = query.toLowerCase();

    return _rawItems.where((item) {
      final name =
          item["name"] ??
              item["title"] ??
              item["productName"] ??
              "";

      final desc = item["description"] ?? "";

      return name.toLowerCase().contains(q) ||
          desc.toLowerCase().contains(q);
    }).toList();
  }
}
