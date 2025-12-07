import 'package:flutter/material.dart';
import 'graphql_client.dart';
import 'role_manager.dart';

class CartWishlistProvider with ChangeNotifier {
  List<Map<String, dynamic>> cartItems = [];
  List<Map<String, dynamic>> wishlistItems = [];

  Set<String> cartIds = {};
  Set<String> wishlistIds = {};

  int cartCount = 0;
  String? buyerId;

  // ================================
  // INIT
  // ================================
  Future<void> initialize() async {
    buyerId = await RoleManager.getBuyerId();

    if (buyerId == null) {
      cartItems.clear();
      wishlistItems.clear();
      cartIds.clear();
      wishlistIds.clear();
      notifyListeners();
      return;
    }

    await fetchCart();
    await fetchWishlist();
  }

  // ================================
  // GRAPHQL QUERIES / MUTATIONS
  // ================================

  static const String getCartQuery = r'''
    query GetCart($buyerId: String!) {
      getCart(buyerId: $buyerId) {
        id
        productId
        quantity
        addedAt
      }
    }
  ''';

  static const String addToCartMutation = r'''
    mutation AddToCart($buyerId: String!, $productId: String!) {
      addToCart(buyerId: $buyerId, productId: $productId) {
        id
        productId
        quantity
      }
    }
  ''';

  static const String updateCartQtyMutation = r'''
    mutation UpdateCartQty($buyerId: String!, $productId: String!, $quantity: Int!) {
      updateCartQty(buyerId: $buyerId, productId: $productId, quantity: $quantity) {
        id
        quantity
      }
    }
  ''';

  static const String removeFromCartMutation = r'''
    mutation RemoveFromCart($buyerId: String!, $productId: String!) {
      removeFromCart(buyerId: $buyerId, productId: $productId)
    }
  ''';

  static const String getWishlistQuery = r'''
    query GetWishlist($buyerId: String!) {
      getWishlist(buyerId: $buyerId) {
        id
        productId
        addedAt
      }
    }
  ''';

  static const String addWishlistMutation = r'''
    mutation AddWishlist($buyerId: String!, $productId: String!) {
      addToWishlist(buyerId: $buyerId, productId: $productId) {
        id
        productId
      }
    }
  ''';

  static const String removeWishlistMutation = r'''
    mutation RemoveWishlist($buyerId: String!, $productId: String!) {
      removeFromWishlist(buyerId: $buyerId, productId: $productId)
    }
  ''';

  // ================================
  // FETCH CART
  // ================================
  Future<void> fetchCart() async {
    if (buyerId == null) return;

    final res = await GraphQLService.performQuery(
      getCartQuery,
      variables: {"buyerId": buyerId},
    );

    final data = res?["getCart"] ?? [];

    cartItems = List<Map<String, dynamic>>.from(data);
    cartIds = cartItems.map((e) => e["productId"].toString()).toSet();
    cartCount = cartItems.length;

    notifyListeners();
  }

  // ================================
  // ADD TO CART
  // ================================
  Future<void> addToCart(String productId) async {
    if (buyerId == null) return;

    await GraphQLService.performMutation(
      addToCartMutation,
      variables: {
        "buyerId": buyerId,
        "productId": productId,
      },
    );

    await fetchCart();
  }

  // ================================
  // UPDATE QUANTITY
  // ================================
  Future<void> updateCartQty(String productId, int qty) async {
    await GraphQLService.performMutation(
      updateCartQtyMutation,
      variables: {
        "buyerId": buyerId,
        "productId": productId,
        "quantity": qty,
      },
    );

    await fetchCart();
  }

  // ================================
  // REMOVE CART ITEM
  // ================================
  Future<void> removeFromCart(String productId) async {
    await GraphQLService.performMutation(
      removeFromCartMutation,
      variables: {
        "buyerId": buyerId,
        "productId": productId,
      },
    );

    await fetchCart();
  }

  // ================================
  // FETCH WISHLIST
  // ================================
  Future<void> fetchWishlist() async {
    if (buyerId == null) return;

    final res = await GraphQLService.performQuery(
      getWishlistQuery,
      variables: {"buyerId": buyerId},
    );

    final data = res?["getWishlist"] ?? [];

    wishlistItems = List<Map<String, dynamic>>.from(data);
    wishlistIds = wishlistItems.map((e) => e["productId"].toString()).toSet();

    notifyListeners();
  }

  // ================================
  // ADD TO WISHLIST
  // ================================
  Future<void> addToWishlist(String productId) async {
    if (buyerId == null) return;

    await GraphQLService.performMutation(
      addWishlistMutation,
      variables: {
        "buyerId": buyerId,
        "productId": productId,
      },
    );

    await fetchWishlist();
  }

  // ================================
  // REMOVE WISHLIST
  // ================================
  Future<void> removeFromWishlist(String productId) async {
    if (buyerId == null) return;

    await GraphQLService.performMutation(
      removeWishlistMutation,
      variables: {
        "buyerId": buyerId,
        "productId": productId,
      },
    );

    await fetchWishlist();
  }

  // ================================
  // TOGGLE WISHLIST
  // ================================
  Future<bool> toggleWishlist(String productId) async {
    if (wishlistIds.contains(productId)) {
      await removeFromWishlist(productId);
      return false;
    } else {
      await addToWishlist(productId);
      return true;
    }
  }
}
