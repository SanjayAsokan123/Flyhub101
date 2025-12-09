import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/env.dart';
import '../../services/role_manager.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<dynamic> wishlist = [];
  bool isLoading = true;

  String? buyerId;

  // Buyer ID loading states
  bool _loadingBuyerId = false;
  String? _buyerIdError;

  final Color themeColor = const Color(0xFF1A0A5B);

  @override
  void initState() {
    super.initState();
    _initializeWishlist();
  }

  // ---------------------------------------------------------
  // 🔵 Initialize: Load buyerId → Load wishlist
  // ---------------------------------------------------------
  Future<void> _initializeWishlist() async {
    await _loadBuyerId();
    if (buyerId != null) {
      await loadWishlist();
    }
  }

  // ---------------------------------------------------------
  // 🔵 Fetch buyerId from MongoDB using Firebase UID
  // ---------------------------------------------------------
  Future<void> _loadBuyerId() async {
    setState(() => _loadingBuyerId = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() => _buyerIdError = "Not logged in");
        return;
      }

      final firebaseUid = user.uid;

      const String query = r'''
        query GetBuyerfirebaseUidWish($firebaseUid: String!) {
          getBuyerfirebaseUidWish(firebaseUid: $firebaseUid) {
            buyerId
            firebaseUid
            name
            email
          }
        }
      ''';

      final res = await http.post(
        Uri.parse(EnvConfig.baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "query": query,
          "variables": {"firebaseUid": firebaseUid},
        }),
      );

      final body = jsonDecode(res.body);

      if (body["errors"] != null) {
        setState(() => _buyerIdError = body["errors"].toString());
        return;
      }

      final data = body["data"]["getBuyerfirebaseUidWish"];

      if (data != null && data["buyerId"] != null) {
        buyerId = data["buyerId"];
        await RoleManager.saveBuyerId(buyerId!);
      } else {
        setState(() => _buyerIdError = "Buyer not found in database");
      }
    } catch (e) {
      setState(() => _buyerIdError = e.toString());
    } finally {
      setState(() => _loadingBuyerId = false);
    }
  }

  // ---------------------------------------------------------
  // 🔵 GraphQL Helper
  // ---------------------------------------------------------
  Future<dynamic> _graphQL(String query, Map<String, dynamic> variables) async {
    final res = await http.post(
      Uri.parse(EnvConfig.baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"query": query, "variables": variables}),
    );

    final data = jsonDecode(res.body);

    if (data["errors"] != null) {
      print("GRAPHQL ERROR: ${data["errors"]}");
      return null;
    }

    return data["data"];
  }

  // ---------------------------------------------------------
  // 🔵 Fetch Wishlist Items
  // ---------------------------------------------------------
  Future<void> loadWishlist() async {
    if (buyerId == null) return;

    const query = r"""
      query GetWishlist($buyerId: String!) {
        getWishlist(buyerId: $buyerId) {
          id
          productId
          addedAt
          product {
            productId
            name
            price
            image
            brand
            category
          }
        }
      }
    """;

    final data = await _graphQL(query, {"buyerId": buyerId});

    setState(() {
      wishlist = data?["getWishlist"] ?? [];
      isLoading = false;
    });
  }

  // ---------------------------------------------------------
  // 🔵 Remove Item from Wishlist
  // ---------------------------------------------------------
  Future<void> _remove(String productId) async {
    const query = r"""
      mutation Remove($buyerId: String!, $productId: String!) {
        removeFromWishlist(buyerId: $buyerId, productId: $productId)
      }
    """;

    await _graphQL(query, {"buyerId": buyerId, "productId": productId});

    loadWishlist();
  }

  // ---------------------------------------------------------
  // 🔵 UI States
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // BuyerId Loading UI
    if (_loadingBuyerId) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: themeColor),
        ),
      );
    }

    // BuyerId Error UI
    if (_buyerIdError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red),
              SizedBox(height: 12),
              Text("Failed to load buyer ID",
                  style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text(_buyerIdError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadBuyerId,
                child: Text("Retry"),
              )
            ],
          ),
        ),
      );
    }

    // Normal UI after buyerId loads
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wishlist"),
        centerTitle: true,
        backgroundColor: themeColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : wishlist.isEmpty
          ? _emptyState()
          : _wishlistList(),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Text(
        "Your wishlist is empty",
        style: TextStyle(color: Colors.grey, fontSize: 18),
      ),
    );
  }

  Widget _wishlistList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: wishlist.length,
      itemBuilder: (context, index) {
        final item = wishlist[index];
        final product = item["product"];

        // ---------------------------
        // 🔥 HANDLE NULL PRODUCT SAFE
        // ---------------------------
        if (product == null) {
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: ListTile(
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.broken_image),
              ),
              title: const Text("Product unavailable"),
              subtitle: const Text(
                "This item was removed",
                style: TextStyle(color: Colors.red),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _remove(item["productId"]),
              ),
            ),
          );
        }

        // ---------------------------
        // 🔥 PRODUCT EXISTS → SHOW NORMAL TILE
        // ---------------------------
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                product["image"] ?? "",
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image),
              ),
            ),
            title: Text(product["name"] ?? "Unknown", maxLines: 1),
            subtitle: Text(
              "₹${product["price"]}",
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _remove(product["productId"]),
            ),
          ),
        );
      },
    );
  }
}