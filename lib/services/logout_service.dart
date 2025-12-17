import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flyhub/Login/FlyHubSelectionPage.dart';
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

  final String url = EnvConfig.baseUrl; // your GraphQL endpoint

  const String mutation = """
    mutation removeSellerFcmToken(\$customId: String!, \$fcmToken: String!) {
      removeSellerFcmToken(customId: \$customId, fcmToken: \$fcmToken) {
        success
        message
      }
    }
  """;

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

class LogoutService {
  static Future<void> logoutSeller(
      BuildContext context, String customId) async {
    try {
      // 1️⃣ Get current FCM Token
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // 2️⃣ Remove token from backend using customId
      await removeTokenFromBackendSeller(customId, fcmToken);

      // 3️⃣ Firebase Logout
      await FirebaseAuth.instance.signOut();

      // 4️⃣ Clear local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 6️⃣ Navigate to login
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const FlyHubSelectionPage()),
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

  static Future<void> logoutBuyer(BuildContext context, String customId) async {
    try {
      // ------------------------------
      // 1. Get current FCM token
      // ------------------------------
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // ------------------------------
      // 2. Remove token from backend
      // ------------------------------
      // await removeTokenFromBackend(BuyerId , fcmToken);

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
      //   context.read<UserProvider>().clear();
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