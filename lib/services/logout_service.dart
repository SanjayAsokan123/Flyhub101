import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flyhub/Login/FlyHubSelectionPage.dart';
import 'package:flyhub/Login/SellerLoginPage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';
// / <-- update path based on your project

/// Logout Workflow:
/// 1. Get user’s FCM token
/// 2. Remove token from backend
/// 3. Firebase signOut
/// 4. Clear SharedPreferences
/// 5. Clear Provider data
/// 6. Redirect to Login screen
Future<void> removeTokenFromBackendSeller(
    String customId, String? fcmToken) async {
  if (fcmToken == null) return;

  final String url = EnvConfig.baseUrl;

  const String mutation = r'''
mutation RemoveSellerFcmToken($customId: String!, $fcmToken: String!) {
  removeSellerFcmToken(customId: $customId, fcmToken: $fcmToken) {
    success
    message
    seller {
      fcmTokens
      fcmToken
    }
  }
}
''';



  final response = await http.post(
    Uri.parse(url),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "query": mutation,
      "variables": {
        "customId": customId,
        "fcmToken": fcmToken,
      },
    }),
  );

  final data = jsonDecode(response.body);
  print("REMOVE FCM RESPONSE → $data");
}
Future<void> removeBuyerTokenFromBackend(String buyerId, String? fcmToken) async {
  final String removeTokenMutation = r'''
    mutation RemoveBuyerFcmToken($buyerId: String!, $fcmToken: String!) {
      removeBuyerFcmToken(buyerId: $buyerId, fcmToken: $fcmToken) {
        success
        message
        buyer {
          fcmTokens
          fcmToken
        }
      }
    }
  ''';

  final variables = {
    "buyerId": buyerId,
    "fcmToken": fcmToken,
  };

  try {
    final client = GraphQLClient(
      link: HttpLink(EnvConfig.baseUrl),
      cache: GraphQLCache(store: InMemoryStore()),
    );

    final result = await client.mutate(
      MutationOptions(
        document: gql(removeTokenMutation),
        variables: variables,
      ),
    );

    if (result.hasException) {
      print("❌ GraphQL Error: ${result.exception.toString()}");
      return;
    }

    final data = result.data?["removeBuyerFcmToken"];

    if (data == null) {
      print("❌ No response from backend");
      return;
    }

    print("✅ Token removed successfully");
    print("Message: ${data['message']}");
    print("Updated Tokens: ${data['buyer']['fcmTokens']}");
  } catch (e) {
    print("❌ Exception while removing token: $e");
  }
}

class Env {
}


class LogoutService {
  static Future<void> logoutSeller(BuildContext context, String sellerId) async {
    try {
      // 1️⃣ Get current FCM Token
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      print("✅ got the token in LOGOUT SERVICE PAGE $fcmToken");

      // 2️⃣ Remove token from backend using customId
      if (fcmToken != null) {
        await removeTokenFromBackendSeller(sellerId, fcmToken);
        print("✅ cleared the token from the backend");
        // Optionally delete token locally so next login generates a fresh one
        try {
          await FirebaseMessaging.instance.deleteToken();
          print("✅ local FCM token deleted");
        } catch (e) {
          print("⚠ failed to delete local FCM token: $e");
        }
      }

      // 3️⃣ Firebase Logout
      await FirebaseAuth.instance.signOut();
      print("✅ cleared the auth service");

      // ... clear local prefs and navigate as before
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print("✅ cleared the local store preference");
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const FlyHubSelectionPage()),
              (route) => false,
        );
      }
    }
    catch (e) {
      print("Logout error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logout failed! Try again.")),
        );
      }
    }
  }

  static Future<void> logoutBuyer(BuildContext context,{required String buyerId}) async {
    try {
      // ------------------------------
      // 1. Get current FCM token
      // ------------------------------
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // ------------------------------
      // 2. Remove token from backend
      // ------------------------------
      await removeBuyerTokenFromBackend(buyerId ,fcmToken);

      // ------------------------------
      // 3. Firebase logout
      // ------------------------------
      await FirebaseAuth.instance.signOut();

      // ------------------------------
      // 4. Clear all local storage data
      // ------------------------------
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // ------------------------------
      // 5. Reset provider state
      // ------------------------------
      // if (context.mounted) {
      //   context.http.read<UserProvider>().clear();
      // }

      // ------------------------------
      // 6. Navigate to login page
      // ------------------------------
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
              (route) => false,
        );
      }
    } catch (e) {
      print("Logout error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logout failed! Try again.")),
        );
      }
    }
  }
}