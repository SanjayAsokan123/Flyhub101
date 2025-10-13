import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Utils.dart';

class ApiClass {
  late SharedPreferences pref;

  // ============================================================
  // 🌐 GET LANGUAGE
  // ============================================================
  Future<dynamic> getLanguage() async {
    var langList = [];

    var _body = {"action": "getLang"};
    print("🌍 Request data from getLang action : $_body");

    try {
      var response = await http.post(Uri.parse(Utils.graphqlUrl), body: _body);

      if (response.statusCode == 200) {
        langList = json.decode(response.body);
        print("✅ Response data from getLang : $langList");
      } else {
        print("❌ Server responded with ${response.statusCode}");
        throw Exception("Failed to load languages");
      }
    } catch (e) {
      print("⚠️ Exception in getLanguage: $e");
    }

    return langList;
  }

  // ============================================================
  // 🔑 GET LOGIN SCREEN
  // ============================================================
  Future<Map<String, dynamic>> getLoginscreen() async {
    Map<String, dynamic> langMap = {};
    pref = await SharedPreferences.getInstance();
    var lanId = pref.getInt("langId");

    var _body = {"action": "getLoginscreen", "lang": "$lanId"};
    print("🧩 Request data from getLoginscreen: $_body");

    try {
      var response = await http.post(Uri.parse(Utils.graphqlUrl), body: _body);
      if (response.statusCode == 200) {
        langMap = json.decode(response.body);
        print("✅ Login screen data: $langMap");
      } else {
        print("❌ Server responded with ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Exception in getLoginscreen: $e");
    }

    return langMap;
  }

  // ============================================================
  // 📱 SEND OTP
  // ============================================================
  Future<dynamic> getOtp(String mobileNo) async {
    pref = await SharedPreferences.getInstance();

    var deviceId = pref.getString("deviceId") ?? "";
    var deviceVersion = pref.getString("deviceVersion") ?? "";
    var platform = pref.getString("platform") ?? "";
    var deviceModel = pref.getString("deviceModel") ?? "";
    var versionCode = pref.getString("vCode") ?? "";

    var _body = {
      "action": "checkUser",
      "mobile": mobileNo,
      "deviceId": deviceId,
      "device_version": deviceVersion,
      "platform": platform,
      "device_Model": deviceModel,
      "vcode": versionCode,
      "fcmId": "",
    };

    print("📲 Request data from checkUser: $_body");

    try {
      var response = await http.post(Uri.parse(Utils.graphqlUrl), body: _body);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print("✅ OTP Response: $data");
        return data;
      } else {
        print("❌ OTP failed: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Exception in getOtp: $e");
    }
    return null;
  }

  // ============================================================
  // 🔐 VERIFY OTP
  // ============================================================
  Future<dynamic> verifyOTP(String otp) async {
    pref = await SharedPreferences.getInstance();
    var mobile_number = pref.getString("mobile_number") ?? "";
    var userId = pref.getString("userId") ?? "";

    var _body = {
      "action": "verifyOtp",
      "mobile": mobile_number,
      "otp": otp,
      "user_id": userId,
    };

    print("🧾 Request data from verifyOtp: $_body");

    try {
      var response = await http.post(Uri.parse(Utils.graphqlUrl), body: _body);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print("✅ Verify OTP Response: $data");
        return data;
      } else {
        print("❌ OTP verification failed: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Exception in verifyOTP: $e");
    }

    return null;
  }

  // ============================================================
  // 🏠 HOME DATA (Mock Data for Flutter UI)
  // ============================================================
  Future<dynamic> gethomedata() async {
    await Future.delayed(Duration(milliseconds: 500)); // simulate network delay

    return {
      "status": "success",
      "items": [
        {
          "template": "template_1",
          "items": [
            {"title": "Buy Drones", "icon": "🛩️"},
            {"title": "Rent Drones", "icon": "🚁"},
            {"title": "Buy Parts", "icon": "⚙️"},
            {"title": "Accessories", "icon": "🎒"},
          ]
        }
      ]
    };
  }

  // ============================================================
  // 🧭 PURPOSE MASTER DATA
  // ============================================================
  Future<dynamic> getPurpose() async {
    pref = await SharedPreferences.getInstance();
    var lanId = pref.getInt("langId");
    var _body = {"action": "getMaster", "lang": "$lanId"};
    print("🎯 Request data from getPurpose $_body");

    try {
      var response = await http.post(Uri.parse(Utils.graphqlUrl), body: _body);
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print("✅ getPurpose data: $data");
        return data;
      } else {
        print("❌ Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Exception in getPurpose: $e");
    }
    return null;
  }

  // ============================================================
  // 🛍 UNIFIED MARKETPLACE QUERY (Drones / Parts / Accessories)
  // ============================================================
  Future<List<dynamic>> getMarketplaceItems(String type) async {
    final query = '''
      query {
        marketplace(type: "$type") {
          id
          name
          price
          image
          category
        }
      }
    ''';

    print("🚀 Sending marketplace query for $type");

    try {
      final response = await http.post(
        Uri.parse(Utils.graphqlUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"query": query}),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded["data"] != null && decoded["data"]["marketplace"] != null) {
          print("✅ Marketplace $type data loaded");
          return decoded["data"]["marketplace"];
        } else {
          print("⚠️ No marketplace data found for $type");
        }
      } else {
        print("❌ Marketplace query failed: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Exception in getMarketplaceItems($type): $e");
    }
    return [];
  }

  // ============================================================
  // ✈️ ADD DRONE (Multipart Upload)
  // ============================================================
  Future<dynamic> addDrone(
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
      "charging_time": "${f_hours}h : ${f_minutes}m",
      "flying_time": "${c_hours}h : ${c_minutes}m",
      "rental_terms": description,
      "price": amount,
      "drone_weight": weight,
      "battery_capacity": "${batteryCapacity}mAh",
    });

    // ✅ Add images safely
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

    print("📤 Uploading drone data: ${request.fields}");

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final responseData = json.decode(responseBody);
        print("✅ Drone uploaded: $responseData");
        return responseData;
      } else {
        print("❌ Drone upload failed: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Exception in addDrone: $e");
    }

    return null;
  }
}
