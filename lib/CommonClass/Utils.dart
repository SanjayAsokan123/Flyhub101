import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Utils {
  // ============================================================
  // 🌐 GRAPHQL ENDPOINT (ONLY ONE)
  // ============================================================

  /// ✅ Single GraphQL endpoint
  static const String graphqlUrl = "http://192.168.1.178:5001/graphql";

  // ============================================================
  // 🔥 TOAST
  // ============================================================

  static Widget bottomToast(BuildContext context, String message) {
    Fluttertoast.showToast(
      msg: safeString(message, "Something went wrong"),
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 15.0,
    );

    return const SizedBox.shrink();
  }

  // ============================================================
  // 🌐 INTERNET CHECK
  // ============================================================

  static Future<bool> checkInternetConnection() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    return connectivityResults.contains(ConnectivityResult.mobile) ||
        connectivityResults.contains(ConnectivityResult.wifi);
  }

  // ============================================================
  // 📱 DEVICE INFORMATION
  // ============================================================

  /// Get unique device ID
  static Future<String> getDeviceId() async {
    String? deviceId = '';

    if (Platform.isAndroid) {
      deviceId = await FlutterUdid.udid;
    } else if (Platform.isIOS) {
      final iosInfo = await DeviceInfoPlugin().iosInfo;
      deviceId = iosInfo.identifierForVendor;
    }

    return deviceId ?? '';
  }

  /// Get Android / iOS version
  static Future<String> checkAndroidVersion() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceVersion = '';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceVersion = androidInfo.version.release;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceVersion = iosInfo.systemVersion;
    }

    return deviceVersion;
  }

  /// Get platform name
  static Future<String> platform() async {
    String devicePlatform = '';

    if (Platform.isAndroid) {
      devicePlatform = 'Android';
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      print(
          'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt}), ${androidInfo.manufacturer} ${androidInfo.model}');
    } else if (Platform.isIOS) {
      devicePlatform = 'iOS';
      final iosInfo = await DeviceInfoPlugin().iosInfo;
      print(
          '${iosInfo.systemName} ${iosInfo.systemVersion}, ${iosInfo.name} ${iosInfo.model}');
    }

    return devicePlatform;
  }

  /// Get device model
  static Future<String> getDeviceModel(BuildContext context) async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      print("Device: ${androidInfo.model}, Version: ${androidInfo.version.release}");
      return androidInfo.model;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return '${iosInfo.name} ${iosInfo.systemVersion}';
    }

    return 'Device information not available';
  }

  // ============================================================
  // 🎨 COLOR UTILS
  // ============================================================

  static Color hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) {
      return const Color(0xFFE7F3EF); // fallback color
    }

    hex = hex.replaceAll("#", "");
    if (hex.length == 6) hex = "FF$hex";

    try {
      return Color(int.parse("0x$hex"));
    } catch (_) {
      return const Color(0xFFE7F3EF);
    }
  }

  // ============================================================
  // 🧩 SAFE HELPERS (to avoid Null type crashes)
  // ============================================================

  /// Safely convert any value to String (avoids null errors)
  static String safeString(dynamic value, [String fallback = ""]) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  /// Safely parse number or return 0
  static double safeDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  /// Safely get a network image (avoids null URLs)
  static Widget safeNetworkImage(String? url,
      {double? height, double? width, BoxFit? fit}) {
    if (url == null || url.isEmpty) {
      return Container(
        height: height,
        width: width,
        color: Colors.grey.shade300,
        child: const Icon(Icons.image, color: Colors.white, size: 40),
      );
    }

    return Image.network(
      url,
      height: height,
      width: width,
      fit: fit ?? BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: height,
        width: width,
        color: Colors.grey.shade400,
        child: const Icon(Icons.image_not_supported, color: Colors.white, size: 40),
      ),
    );
  }
}
