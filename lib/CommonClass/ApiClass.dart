import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils.dart';
import '../services/graphql_client.dart';

/// ✅ Unified API Result for all network operations
class ApiResult {
  final String status;
  final dynamic data;
  final String message;

  ApiResult({required this.status, this.data, this.message = ""});

  factory ApiResult.success(dynamic data, [String msg = ""]) =>
      ApiResult(status: "success", data: data, message: msg);

  factory ApiResult.error([String msg = "Error"]) =>
      ApiResult(status: "error", data: null, message: msg);
}

/// 🧩 FlyHub GraphQL + Firebase API Manager
class ApiClass {
  late SharedPreferences pref;

  // ============================================================
  // ☁️ Firebase File Upload via Backend REST API
  // ============================================================
  Future<ApiResult> uploadToFirebaseServer(File file, String folder) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return ApiResult.error("User not authenticated with Firebase");
      }

      final token = await user.getIdToken();
      final uri = Uri.parse(
          "http://192.168.1.178:5001/upload"); // ✅ Use /upload

      final request = http.MultipartRequest("POST", uri)
        ..headers["Authorization"] = "Bearer $token"
        ..fields["folder"] = folder
        ..files.add(await http.MultipartFile.fromPath("file", file.path));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(resBody);
        debugPrint("✅ Uploaded to Firebase Storage: ${data['url']}");
        return ApiResult.success(data['url']);
      } else {
        debugPrint("❌ Upload failed: $resBody");
        return ApiResult.error(resBody);
      }
    } catch (e) {
      debugPrint("⚠️ Upload exception: $e");
      return ApiResult.error(e.toString());
    }
  }


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
    return _runQuery("getDrones", query, "drones");
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
    return _runQuery("getParts", query, "parts");
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
    return _runQuery("getAccessories", query, "accessories");
  }

  // ============================================================
  // 👨‍✈️ HIRE PILOTS
  // ============================================================
  Future<ApiResult> getApprovedHirePilots() async {
    const String query = r'''
      query {
        approvedHirePilotsByStatus {
          pilotId
          pilotName
          pilotCompany
          location
          sellerId
          availability
          specification
          description
          newemail
          newphoneNumber
          adminStatus
          price {
            perHour
            perDay
          }
          certifications { url }
          resume { url }
          seller {
            name
            email
            phoneNumber
          }
        }
      }
    ''';
    return _runQuery(
        "getApprovedHirePilots", query, "approvedHirePilotsByStatus");
  }

  Future<ApiResult> addHirePilot({
    required String pilotName,
    required String pilotCompany,
    required String location,
    required String newemail,
    required String newphoneNumber,
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
          newemail
          newphoneNumber
          adminStatus
        }
      }
    ''';

    try {
      final client = await GraphQLService.initClient();
      final certInputs =
      (certificationUrls ?? []).map((url) => {"url": url}).toList();

      final variables = {
        "input": {
          "pilotName": pilotName,
          "pilotCompany": pilotCompany,
          "location": location,
          "newemail": newemail,
          "newphoneNumber": newphoneNumber,
          "sellerId": sellerId,
          "availability": availability,
          "specification": specification,
          "price": {"perHour": perHour, "perDay": perDay},
          "certifications": certInputs,
          "resume": resumeUrl != null ? {"url": resumeUrl} : null,
          "description": description ?? "",
        }
      };

      final result =
      await client.mutate(
          MutationOptions(document: gql(mutation), variables: variables));

      if (result.hasException) {
        debugPrint("❌ [addHirePilot] ${result.exception}");
        return ApiResult.error(result.exception.toString());
      }

      final data = result.data?['addHirePilot'];
      debugPrint("✅ Added Pilot: ${data?['pilotName']}");
      return ApiResult.success(data);
    } catch (e) {
      debugPrint("⚠️ [addHirePilot] Exception: $e");
      return ApiResult.error(e.toString());
    }
  }

  Future<ApiResult> bookPilot({
    required String pilotId,
    required String buyerName,
    required String buyerEmail,
    required String contact,
    required String location,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    const String mutation = r'''
      mutation BookPilot($input: BookPilotInput!) {
        bookPilot(input: $input) {
          success
          message
        }
      }
    ''';

    try {
      final client = await GraphQLService.initClient();
      final result = await client.mutate(MutationOptions(
        document: gql(mutation),
        variables: {
          "input": {
            "pilotId": pilotId,
            "buyerName": buyerName,
            "buyerEmail": buyerEmail,
            "contact": contact,
            "location": location,
            "date": date,
            "startTime": startTime,
            "endTime": endTime,
          }
        },
      ));

      if (result.hasException) {
        debugPrint("❌ [bookPilot] Error: ${result.exception}");
        return ApiResult.error(result.exception.toString());
      }

      final data = result.data?['bookPilot'];
      debugPrint("✅ Pilot booked: ${data?['message']}");
      return ApiResult.success(data);
    } catch (e) {
      debugPrint("⚠️ [bookPilot] Exception: $e");
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
    return _runQuery("getJobs", query, "jobs");
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
    return _runQuery("getServices", query, "services");
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
  pricePerHour
  description
  image
  location
  insurance
  with_pilot
  available_today
  status        # 👈 ADD THIS FIELD
}

      }
    ''';
    return _runQuery("getRentals", query, "rentals");
  }


  Future<ApiResult> enrollTraining(Map<String, dynamic> data) async {
    const String mutation = r'''
    mutation EnrollTraining($input: TrainingEnrollInput!) {
      enrollTraining(input: $input) {
        id
        name
        email
        phone
        address
        status
      }
    }
  ''';

    try {
      final client = await GraphQLService.initClient();
      final result = await client.mutate(MutationOptions(
        document: gql(mutation),
        variables: {"input": data},
      ));

      if (result.hasException) {
        debugPrint("❌ [EnrollTraining] ${result.exception}");
        return ApiResult.error(result.exception.toString());
      }

      return ApiResult.success(result.data?['enrollTraining']);
    } catch (e) {
      debugPrint("⚠️ [EnrollTraining] Exception: $e");
      return ApiResult.error(e.toString());
    }
  }

  Future<ApiResult> getCourses() async {
    const String query = r'''
    query {
      courses {
        id
        title
        description
        image
        duration
        format
        certificate
        price
      }
    }
  ''';
    return _runQuery("getCourses", query, "courses");
  }

  Future<ApiResult> getTrainingById(String id) async {
    const query = r'''
    query($id: ID!) {
      getTrainingById(id: $id) {
        id
        title
        amount
        gst
        days
        totalAmount
        imagePath
        shortDescription
        fullDescription
      }
    }
  ''';
    return _runQuery(
        "getTrainingById", query, "getTrainingById", variables: {"id": id});
  }

  // ============================================================
  // 🧠 Helper for Queries
  // ============================================================
  Future<ApiResult> _runQuery(String tag,
      String query,
      String field, {
        Map<String, dynamic>? variables,
      }) async {
    try {
      final client = await GraphQLService.initClient();
      final result = await client.query(
        QueryOptions(
          document: gql(query),
          variables: variables ?? {},
        ),
      );

      if (result.hasException) {
        debugPrint("❌ [$tag] ${result.exception}");
        return ApiResult.error(result.exception.toString());
      }

      final data = result.data?[field] ?? [];
      debugPrint("✅ [$tag] Loaded ${data is List ? data.length : 1} items");
      return ApiResult.success(data);
    } catch (e) {
      debugPrint("⚠️ [$tag] Exception: $e");
      return ApiResult.error(e.toString());
    }
  }
}
