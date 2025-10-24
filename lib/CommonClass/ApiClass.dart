import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils.dart';

/// ✅ Unified API Result (for consistent responses)
class ApiResult {
  final String status; // "success" | "error"
  final dynamic data;
  final String message;

  ApiResult({required this.status, this.data, this.message = ""});

  factory ApiResult.success(dynamic d, [String msg = ""]) =>
      ApiResult(status: "success", data: d, message: msg);

  factory ApiResult.error([String msg = "Error"]) =>
      ApiResult(status: "error", data: null, message: msg);
}

/// ✅ Retry helper (to prevent transient network issues)
Future<T?> _retry<T>(
    Future<T> Function() action, {
      int retries = 2,
      Duration timeout = const Duration(seconds: 8),
    }) async {
  for (int attempt = 0; attempt <= retries; attempt++) {
    try {
      return await action().timeout(timeout);
    } on TimeoutException catch (e) {
      debugPrint("⏱️ Timeout (attempt ${attempt + 1}): $e");
      if (attempt == retries) rethrow;
    } catch (e) {
      debugPrint("⚠️ Error (attempt ${attempt + 1}): $e");
      if (attempt == retries) rethrow;
    }
  }
  return null;
}

/// 🧩 ApiClass – All API Services (FlyHub)
class ApiClass {
  late SharedPreferences pref;

  // ============================================================
  // 🌍 GET LANGUAGE
  // ============================================================
  Future<ApiResult> getLanguage() async {
    var body = {"action": "getLang"};
    debugPrint("🌍 [getLang] Request: $body");

    try {
      final resp = await _retry(() =>
          http.post(Uri.parse(Utils.graphqlUrl), body: body));

      if (resp == null) return ApiResult.error("Network timeout");

      if (resp.statusCode == 200) {
        final langList = json.decode(resp.body);
        debugPrint("✅ [getLang] Response: $langList");
        return ApiResult.success(langList);
      }
      return ApiResult.error("Server ${resp.statusCode}");
    } catch (e) {
      debugPrint("⚠️ Exception in getLanguage: $e");
      return ApiResult.error(e.toString());
    }
  }

  // ============================================================
  // 🔑 GET LOGIN SCREEN (Dynamic)
  // ============================================================
  Future<ApiResult> getLoginscreen() async {
    pref = await SharedPreferences.getInstance();
    var lanId = pref.getInt("langId") ?? 0;
    var body = {"action": "getLoginscreen", "lang": "$lanId"};
    debugPrint("🧩 [getLoginscreen] Request: $body");

    try {
      final resp = await _retry(() =>
          http.post(Uri.parse(Utils.graphqlUrl), body: body));
      if (resp == null) return ApiResult.error("Timeout");

      if (resp.statusCode == 200) {
        final langMap = json.decode(resp.body);
        debugPrint("✅ [getLoginscreen] Response: $langMap");
        return ApiResult.success(langMap);
      }
      return ApiResult.error("Server ${resp.statusCode}");
    } catch (e) {
      debugPrint("⚠️ Exception in getLoginscreen: $e");
      return ApiResult.error(e.toString());
    }
  }

  // ============================================================
  // 📲 SEND OTP
  // ============================================================
  Future<ApiResult> getOtp(String mobileNo) async {
    pref = await SharedPreferences.getInstance();

    var deviceId = pref.getString("deviceId") ?? "";
    var deviceVersion = pref.getString("deviceVersion") ?? "";
    var platform = pref.getString("platform") ?? "";
    var deviceModel = pref.getString("deviceModel") ?? "";
    var versionCode = pref.getString("vCode") ?? "";

    var body = {
      "action": "checkUser",
      "mobile": mobileNo,
      "deviceId": deviceId,
      "device_version": deviceVersion,
      "platform": platform,
      "device_Model": deviceModel,
      "vcode": versionCode,
      "fcmId": "",
    };

    debugPrint("📲 [getOtp] Request: $body");

    try {
      final resp = await _retry(() =>
          http.post(Uri.parse(Utils.graphqlUrl), body: body));
      if (resp == null) return ApiResult.error("Timeout");

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        debugPrint("✅ [getOtp] Response: $data");
        return ApiResult.success(data);
      }
      return ApiResult.error("Server ${resp.statusCode}");
    } catch (e) {
      debugPrint("⚠️ Exception in getOtp: $e");
      return ApiResult.error(e.toString());
    }
  }

  // ============================================================
  // 🔐 VERIFY OTP
  // ============================================================
  Future<ApiResult> verifyOTP(String otp) async {
    pref = await SharedPreferences.getInstance();
    var mobileNumber = pref.getString("mobile_number") ?? "";
    var userId = pref.getString("userId") ?? "";

    var body = {
      "action": "verifyOtp",
      "mobile": mobileNumber,
      "otp": otp,
      "user_id": userId,
    };

    debugPrint("🧾 [verifyOtp] Request: $body");

    try {
      final resp = await _retry(() =>
          http.post(Uri.parse(Utils.graphqlUrl), body: body));
      if (resp == null) return ApiResult.error("Timeout");

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        debugPrint("✅ [verifyOtp] Response: $data");
        return ApiResult.success(data);
      }
      return ApiResult.error("Server ${resp.statusCode}");
    } catch (e) {
      debugPrint("⚠️ Exception in verifyOTP: $e");
      return ApiResult.error(e.toString());
    }
  }

  // ============================================================
  // 🛍 MARKETPLACE (GraphQL)
  // ============================================================
  Future<ApiResult> getMarketplaceItems(String type) async {
    final query = '''
    query {
      marketplace(type: "$type") {
        id
        name
        brand
        price
        description
        image
        category
        status
      }
    }
  ''';

    try {
      final response = await http.post(
        Uri.parse(Utils.graphqlUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"query": query}),
      );

      debugPrint("🛰️ [Marketplace] Query Sent for $type");
      debugPrint("📦 Status: ${response.statusCode}");
      debugPrint("📦 Body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded["data"] != null && decoded["data"]["marketplace"] != null) {
          final List<dynamic> items = decoded["data"]["marketplace"];

          debugPrint("✅ [Marketplace] Loaded ${items.length} items for $type");
          return ApiResult.success(items);
        } else {
          debugPrint("⚠️ [Marketplace] Empty data for type: $type");
          return ApiResult.error("No items found for $type");
        }
      } else {
        return ApiResult.error("Server returned ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Exception in getMarketplaceItems($type): $e");
      return ApiResult.error(e.toString());
    }
  }



  // ============================================================
  // 🎯 GET PURPOSE LIST
  // ============================================================
  Future<ApiResult> getPurpose() async {
    debugPrint("🎯 [getPurpose] Fetching drone purposes...");

    try {
      final resp = await _retry(() => http.post(
        Uri.parse(Utils.graphqlUrl),
        body: {"action": "getPurpose"},
      ));

      if (resp == null) return ApiResult.error("Network timeout");

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        debugPrint("✅ [getPurpose] Response: $data");

        if (data["status"] == "success" && data["purpose_master"] != null) {
          return ApiResult.success(data["purpose_master"], "Fetched successfully");
        } else {
          return ApiResult.error(data["message"] ?? "No purpose data found");
        }
      } else {
        return ApiResult.error("Server ${resp.statusCode}");
      }
    } catch (e) {
      debugPrint("⚠️ Exception in getPurpose: $e");
      return ApiResult.error(e.toString());
    }
  }

  // ============================================================
  // ✈️ ADD DRONE (Multipart Upload)
  // ============================================================
  Future<ApiResult> addDrone(
      String dgcaApproval,
      String selectedPurposeId,
      String amount,
      String batteryCapacity,
      String weight,
      String model,
      String f_hours,
      String f_minutes,
      String c_hours,
      String c_minutes,
      String description,
      String type,
      Map<String, File?> images,
      ) async {
    pref = await SharedPreferences.getInstance();
    var userId = pref.getString("userId") ?? "";

    var request = http.MultipartRequest('POST', Uri.parse(Utils.graphqlUrl));

    request.fields.addAll({
      "action": "addDrone",
      "user_id": userId,
      "DGCA_approval": dgcaApproval,
      "model": model,
      "type": type,
      "purpose": selectedPurposeId,
      "charging_time": "${c_hours}h : ${c_minutes}m",
      "flying_time": "${f_hours}h : ${f_minutes}m",
      "rental_terms": description,
      "price": amount,
      "drone_weight": weight,
      "battery_capacity": "${batteryCapacity}mAh",
    });

    // ✅ Map image keys for backend
    Map<String, String> imageFieldMap = {
      'top': 'image1',
      'right': 'image2',
      'left': 'image3',
      'full': 'image4',
    };

    for (String key in images.keys) {
      final imageFile = images[key];
      final fieldKey = imageFieldMap[key];
      if (imageFile != null && fieldKey != null) {
        final mimeType = lookupMimeType(imageFile.path)?.split('/');
        if (mimeType != null && mimeType.length == 2) {
          request.files.add(await http.MultipartFile.fromPath(
            fieldKey,
            imageFile.path,
            contentType: MediaType(mimeType[0], mimeType[1]),
          ));
        }
      }
    }

    debugPrint("📤 [addDrone] Uploading data: ${request.fields}");

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        debugPrint("✅ [addDrone] Success: $data");
        return ApiResult.success(data);
      } else {
        debugPrint("❌ [addDrone] Failed: ${response.statusCode}");
        return ApiResult.error("Server ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("⚠️ [addDrone] Exception: $e");
      return ApiResult.error(e.toString());
    }
  }
}
