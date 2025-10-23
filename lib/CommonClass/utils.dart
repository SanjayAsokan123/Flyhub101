import 'dart:io';
import 'package:flutter/foundation.dart'; // ✅ Needed for kReleaseMode
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Utils {
  // ============================================================
  // 🌐 GRAPHQL ENDPOINT
  // ============================================================
  static const String graphqlUrl = "http://192.168.0.178:5001/graphql";

  // ============================================================
  // 🔔 TOAST MESSAGES
  // ============================================================
  static void bottomToast(BuildContext context, String message,
      {Color backgroundColor = Colors.black,
        Color textColor = Colors.white,
        int duration = 1}) {
    Fluttertoast.showToast(
      msg: safeString(message, "Something went wrong"),
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: duration,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 15.0,
    );
  }

  // ============================================================
  // 🍬 SNACKBAR HELPER
  // ============================================================
  static void showSnackBar(BuildContext context, String message,
      {Color bgColor = Colors.black87,
        Color textColor = Colors.white,
        int seconds = 2}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
        backgroundColor: bgColor,
        duration: Duration(seconds: seconds),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // 🌐 INTERNET CHECK (FIXED)
  // ============================================================
  static Future<bool> checkInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi;
    } catch (e) {
      logError("Internet check failed: $e");
      return false;
    }
  }

  // ============================================================
  // 📱 DEVICE INFORMATION
  // ============================================================
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Get unique device ID
  static Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        return await FlutterUdid.udid;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? "unknown_ios_device";
      }
    } catch (e) {
      logError("Device ID fetch failed: $e");
    }
    return "unknown_device";
  }

  /// Get Android / iOS version
  static Future<String> checkAndroidVersion() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.version.release;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.systemVersion;
      }
    } catch (e) {
      logError("OS version fetch failed: $e");
    }
    return "unknown";
  }

  /// Get platform name
  static Future<String> platform() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        logInfo(
            'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt}), ${androidInfo.manufacturer} ${androidInfo.model}');
        return "Android";
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        logInfo(
            '${iosInfo.systemName} ${iosInfo.systemVersion}, ${iosInfo.name} ${iosInfo.model}');
        return "iOS";
      }
    } catch (e) {
      logError("Platform info fetch failed: $e");
    }
    return "Unknown";
  }

  /// Get device model
  static Future<String> getDeviceModel(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        logInfo("Device: ${androidInfo.model}");
        return androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return '${iosInfo.name} ${iosInfo.systemVersion}';
      }
    } catch (e) {
      logError("Device model fetch failed: $e");
    }
    return "Unknown Model";
  }

  // ============================================================
  // 🎨 COLOR HELPERS
  // ============================================================
  static Color hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFFE7F3EF);

    hex = hex.replaceAll("#", "");
    if (hex.length == 6) hex = "FF$hex"; // Add opacity if missing

    try {
      return Color(int.parse("0x$hex"));
    } catch (_) {
      logError("Invalid color hex: $hex");
      return const Color(0xFFE7F3EF);
    }
  }

  // ============================================================
  // 🧩 SAFE HELPERS
  // ============================================================
  static String safeString(dynamic value, [String fallback = ""]) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  static double safeDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  /// Safely get a network image (with fallback)
  static Widget safeNetworkImage(String? url,
      {double? height, double? width, BoxFit? fit}) {
    if (url == null || url.isEmpty) {
      return _placeholderBox(height, width, Icons.image);
    }

    return Image.network(
      url,
      height: height,
      width: width,
      fit: fit ?? BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          _placeholderBox(height, width, Icons.broken_image),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey[500],
            ),
          ),
        );
      },
    );
  }

  static Widget _placeholderBox(double? height, double? width, IconData icon) {
    return Container(
      height: height,
      width: width,
      color: Colors.grey.shade300,
      child: Icon(icon, color: Colors.grey.shade700, size: 36),
    );
  }

  // ============================================================
  // 🪶 LOGGING HELPERS (FIXED)
  // ============================================================
  static void logInfo(String msg) {
    if (!kReleaseMode) {
      debugPrint("ℹ️ [INFO] $msg");
    }
  }

  static void logError(String msg) {
    if (!kReleaseMode) {
      debugPrint("❌ [ERROR] $msg");
    }
  }

  // ============================================================
  // 💾 SHARED PREFERENCES SHORTCUTS
  // ============================================================
  static Future<void> saveToPrefs(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is String) await prefs.setString(key, value);
      if (value is bool) await prefs.setBool(key, value);
      if (value is int) await prefs.setInt(key, value);
      if (value is double) await prefs.setDouble(key, value);
    } catch (e) {
      logError("Failed to save $key: $e");
    }
  }

  static Future<dynamic> readFromPrefs(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.get(key);
    } catch (e) {
      logError("Failed to read $key: $e");
      return null;
    }
  }
}
