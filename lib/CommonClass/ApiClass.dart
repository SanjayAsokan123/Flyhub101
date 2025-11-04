import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils.dart';
import '../services/graphql_client.dart';

/// ✅ Unified API Result
class ApiResult {
  final String status;
  final dynamic data;
  final String message;

  ApiResult({required this.status, this.data, this.message = ""});

  factory ApiResult.success(dynamic d, [String msg = ""]) =>
      ApiResult(status: "success", data: d, message: msg);

  factory ApiResult.error([String msg = "Error"]) =>
      ApiResult(status: "error", data: null, message: msg);
}

/// ✅ Retry helper (safe wrapper)
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

/// 🧩 ApiClass – All FlyHub GraphQL Services
class ApiClass {
  late SharedPreferences pref;

  // ============================================================
  // 🛍 MARKETPLACE: DRONES / PARTS / ACCESSORIES
  // ============================================================

  Future<ApiResult> getDrones() async {
    const String query = r'''
    query {
      drones {
        droneId
        name
        brand
        price
        description
        image
        status
      }
    }
  ''';

    try {
      final client = await GraphQLService.initClient();
      final result = await client.query(QueryOptions(document: gql(query)));

      if (result.hasException) {
        debugPrint("❌ [getDrones] Error: ${result.exception}");
        return ApiResult.error(result.exception.toString());
      }

      final data = result.data?['drones'] ?? [];
      debugPrint("✅ [getDrones] Loaded ${data.length} drones");
      return ApiResult.success(data);
    } catch (e) {
      debugPrint("⚠️ [getDrones] Exception: $e");
      return ApiResult.error(e.toString());
    }
  }

  Future<ApiResult> getParts() async {
    const String query = r'''
    query {
      parts {
        partId
        name
        brand
        price
        description
        image
        status
      }
    }
  ''';

    try {
      final client = await GraphQLService.initClient();
      final result = await client.query(QueryOptions(document: gql(query)));

      if (result.hasException) {
        debugPrint("❌ [getParts] Error: ${result.exception}");
        return ApiResult.error(result.exception.toString());
      }

      final data = result.data?['parts'] ?? [];
      debugPrint("✅ [getParts] Loaded ${data.length} parts");
      return ApiResult.success(data);
    } catch (e) {
      debugPrint("⚠️ [getParts] Exception: $e");
      return ApiResult.error(e.toString());
    }
  }

  Future<ApiResult> getAccessories() async {
    const String query = r'''
    query {
      accessories {
        accessoryId
        name
        brand
        price
        description
        image
        status
      }
    }
  ''';

    try {
      final client = await GraphQLService.initClient();
      final result = await client.query(QueryOptions(document: gql(query)));

      if (result.hasException) {
        debugPrint("❌ [getAccessories] Error: ${result.exception}");
        return ApiResult.error(result.exception.toString());
      }

      final data = result.data?['accessories'] ?? [];
      debugPrint("✅ [getAccessories] Loaded ${data.length} accessories");
      return ApiResult.success(data);
    } catch (e) {
      debugPrint("⚠️ [getAccessories] Exception: $e");
      return ApiResult.error(e.toString());
    }
  }

  // ============================================================
// 👨‍✈️ HIRE PILOTS
// ============================================================
// ============================================================
// 👨‍✈️ HIRE PILOTS
// ============================================================
  Future<ApiResult> getHirePilots() async {
    const String query = r'''
    query {
      hirePilots {
        pilotId
        pilotName
        pilotCompany
        location
        sellerId
        availability
        specification
        description
        email
        phoneNumber
        status
        price {
          perHour
          perDay
        }
        certifications {
          url
        }
        resume {
          url
        }
        seller {
          name
          email
          phoneNumber
        }
      }
    }
  ''';

    try {
      final client = await GraphQLService.initClient();
      final result = await client.query(QueryOptions(document: gql(query)));

      if (result.hasException) {
        debugPrint("❌ [getHirePilots] Error: ${result.exception}");
        return ApiResult.error(result.exception.toString());
      }

      final data = result.data?['hirePilots'] ?? [];
      debugPrint("✅ [getHirePilots] Loaded ${data.length} pilots");
      return ApiResult.success(data);
    } catch (e) {
      debugPrint("⚠️ [getHirePilots] Exception: $e");
      return ApiResult.error(e.toString());
    }
  }

  Future<ApiResult> addHirePilot({
    required String pilotName,
    required String pilotCompany,
    required String location,
    required String email,
    required String phoneNumber,
    required String sellerId,
    required bool availability,
    required String specification,
    required double perHour,
    required double perDay,
    List<String>? certificationUrls,
    String? resumeUrl,
    String? description,
  }) async {
    const String mutation = r'''
    mutation AddHirePilot($input: HirePilotInput!) {
      addHirePilot(input: $input) {
        pilotId
        pilotName
        pilotCompany
        location
        email
        phoneNumber
        status
      }
    }
  ''';

    try {
      final client = await GraphQLService.initClient();
      final certInputs = (certificationUrls ?? []).map((url) => {"url": url}).toList();

      final variables = {
        "input": {
          "pilotName": pilotName,
          "pilotCompany": pilotCompany,
          "location": location,
          "email": email,
          "phoneNumber": phoneNumber,
          "sellerId": sellerId,
          "availability": availability,
          "specification": specification,
          "price": {"perHour": perHour, "perDay": perDay},
          "certifications": certInputs,
          "resume": resumeUrl != null ? {"url": resumeUrl} : null,
          "description": description ?? "",
        }
      };

      final result = await client.mutate(
        MutationOptions(document: gql(mutation), variables: variables),
      );

      if (result.hasException) {
        debugPrint("❌ [addHirePilot] Error: ${result.exception}");
        return ApiResult.error(result.exception.toString());
      }

      final data = result.data?['addHirePilot'];
      debugPrint("✅ [addHirePilot] Added: ${data?['pilotName']}");
      return ApiResult.success(data);
    } catch (e) {
      debugPrint("⚠️ [addHirePilot] Exception: $e");
      return ApiResult.error(e.toString());
    }
  }


  // ============================================================
  // 💼 JOBS
  // ============================================================
  Future<ApiResult> getJobs() async {
    const String query = r'''
    query {
      jobs {
        jobId
        jobName
        companyName
        jobType
        experience
        location
        salary
        description
        requirement
        email
        phoneNumber
        status
        sellerId
      }
    }
  ''';

    try {
      final client = await GraphQLService.initClient();
      final result = await client.query(QueryOptions(document: gql(query)));

      if (result.hasException) {
        debugPrint("❌ [getJobs] Error: ${result.exception}");
        return ApiResult.error(result.exception.toString());
      }

      final data = result.data?['jobs'] ?? [];
      debugPrint("✅ [getJobs] Loaded ${data.length} jobs");
      return ApiResult.success(data);
    } catch (e) {
      debugPrint("⚠️ [getJobs] Exception: $e");
      return ApiResult.error(e.toString());
    }
  }

  // ============================================================
  // 🛠 SERVICES
  // ============================================================
  Future<ApiResult> getServices() async {
    const String query = r'''
    query {
      services {
        serviceId
        name
        specificDrone
        experience
        location
        description
        price
        image
        status
        sellerId
        sellerInfo {
          email
          phoneNumber
        }
      }
    }
  ''';

    try {
      final client = await GraphQLService.initClient();
      final result = await client.query(QueryOptions(document: gql(query)));

      if (result.hasException) {
        debugPrint("❌ [getServices] Error: ${result.exception}");
        return ApiResult.error(result.exception.toString());
      }

      final data = result.data?['services'] ?? [];
      debugPrint("✅ [getServices] Loaded ${data.length} services");
      return ApiResult.success(data);
    } catch (e) {
      debugPrint("⚠️ [getServices] Exception: $e");
      return ApiResult.error(e.toString());
    }
  }

  // ============================================================
  // 🏠 RENTALS
  // ============================================================
  Future<ApiResult> getRentals() async {
    const String query = r'''
    query {
      rentals {
        rentalId
        name
        brand
        pricePerDay
        description
        image
        location
        insurance
        with_pilot
        available_today
      }
    }
  ''';

    try {
      final client = await GraphQLService.initClient();
      final result = await client.query(QueryOptions(document: gql(query)));

      if (result.hasException) {
        debugPrint("❌ [Rentals] ${result.exception}");
        return ApiResult.error(result.exception.toString());
      }

      final data = result.data?['rentals'] ?? [];
      debugPrint("✅ [Rentals] Loaded ${data.length} rentals");
      return ApiResult.success(data);
    } catch (e) {
      debugPrint("⚠️ [Rentals] Error: $e");
      return ApiResult.error(e.toString());
    }
  }

  // ============================================================
  // ✈️ ADD DRONE (Multipart Upload)
  // ============================================================
  Future<ApiResult> addDrone({
    required String dgcaApproval,
    required String purpose,
    required String price,
    required String batteryCapacity,
    required String weight,
    required String model,
    required String flyingHours,
    required String chargingHours,
    required String description,
    required String type,
    required Map<String, File?> images,
  }) async {
    try {
      final client = await GraphQLService.initClient();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return ApiResult.error("User not logged in");

      // Convert images to Base64 strings
      final imageMap = <String, String>{};
      for (final entry in images.entries) {
        if (entry.value != null) {
          final bytes = await entry.value!.readAsBytes();
          imageMap[entry.key] =
          "data:${lookupMimeType(entry.value!.path)};base64,${base64Encode(bytes)}";
        }
      }

      const String mutation = r'''
        mutation AddDrone($input: AddDroneInput!) {
          addDrone(input: $input) {
            success
            message
            drone {
              id
              name
              price
            }
          }
        }
      ''';

      final variables = {
        "input": {
          "DGCA_approval": dgcaApproval,
          "purpose": purpose,
          "price": price,
          "batteryCapacity": batteryCapacity,
          "droneWeight": weight,
          "model": model,
          "flyingTime": flyingHours,
          "chargingTime": chargingHours,
          "rentalTerms": description,
          "type": type,
          "images": imageMap,
        }
      };

      final result =
      await client.mutate(MutationOptions(document: gql(mutation), variables: variables));

      if (result.hasException) {
        debugPrint("❌ [addDrone] ${result.exception}");
        return ApiResult.error(result.exception.toString());
      }

      final data = result.data?['addDrone'];
      debugPrint("✅ [addDrone] Success: $data");
      return ApiResult.success(data);
    } catch (e) {
      debugPrint("⚠️ [addDrone] Exception: $e");
      return ApiResult.error(e.toString());
    }
  }

  // ============================================================
  // 📲 OTP MOCKS
  // ============================================================
  Future<ApiResult> getOtp(String mobileNo) async {
    debugPrint("📲 [getOtp] Simulated OTP for $mobileNo");
    await Future.delayed(const Duration(seconds: 1));
    return ApiResult.success({"otpSent": true}, "OTP sent to $mobileNo");
  }

  Future<ApiResult> verifyOTP(String otp) async {
    debugPrint("🧾 [verifyOtp] Verifying $otp");
    await Future.delayed(const Duration(seconds: 1));
    if (otp == "1234") {
      return ApiResult.success({"verified": true}, "OTP verified successfully");
    }
    return ApiResult.error("Invalid OTP");
  }

  // ============================================================
  // 🎯 PURPOSE LIST (Mock)
  // ============================================================
  Future<ApiResult> getPurpose() async {
    debugPrint("🎯 [getPurpose] Loading purposes");
    await Future.delayed(const Duration(milliseconds: 800));
    final purposes = [
      {"id": "1", "name": "Agriculture"},
      {"id": "2", "name": "Mapping"},
      {"id": "3", "name": "FPV"},
    ];
    return ApiResult.success(purposes);
  }

  // ============================================================
  // 🌐 STATIC APP CONTENT
  // ============================================================
  Future<ApiResult> getLanguage() async =>
      ApiResult.success(["English", "Hindi"]);

  Future<ApiResult> getLoginscreen() async => ApiResult.success({
    "title": "Welcome to FlyHub",
    "description": "Your one-stop drone marketplace"
  });
}
