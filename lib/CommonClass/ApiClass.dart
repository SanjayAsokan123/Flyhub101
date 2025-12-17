// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flyhub/config/env.dart';
// import 'package:graphql_flutter/graphql_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:developer' as developer;
// import '../services/graphql_client.dart';
//
// /// ✅ Unified API Result for all network operations
// class ApiResult {
//   final String status;
//   final dynamic data;
//   final String message;
//
//   ApiResult({required this.status, this.data, this.message = ""});
//
//   factory ApiResult.success(dynamic data, [String msg = ""]) =>
//       ApiResult(status: "success", data: data, message: msg);
//
//   factory ApiResult.error([String msg = "Error"]) =>
//       ApiResult(status: "error", data: null, message: msg);
// }
//
// /// ✅ API Response class for Job Application
// class ApiResponse {
//   final bool success;
//   final String? message;
//   final dynamic data;
//
//   ApiResponse({
//     required this.success,
//     this.message,
//     this.data,
//   });
//
//
//
//   @override
//   String toString() {
//     return 'ApiResponse(success: $success, message: $message, data: $data)';
//   }
// }
//
// /// 🧩 FlyHub GraphQL + Firebase API Manager
// class ApiClass {
//   late SharedPreferences pref;
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//   // ============================================================
//   // ☁ Firebase File Upload via Backend REST API
//   // ============================================================
//   Future<String?> uploadToFirebaseStorage(File file, String folder, {String? fileName}) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) throw Exception("User not authenticated");
//
//       final timestamp = DateTime.now().millisecondsSinceEpoch;
//       final fileName = "${timestamp}_${file.path.split('/').last}";
//       final path = "$folder/${user.uid}/$fileName";
//
//       final ref = _storage.ref().child(path);
//       await ref.putFile(file);
//
//       final downloadUrl = await ref.getDownloadURL();
//       debugPrint("✅ Uploaded to Firebase: $downloadUrl");
//       return downloadUrl;
//     } catch (e) {
//       debugPrint("❌ Firebase upload error: $e");
//       return null;
//     }
//   }
//
//
//   // ============================================================
//   // 🚫 ACCOUNT DEACTIVATION & MANAGEMENT
//   // ============================================================
//
//   /// Deactivate seller account (self-deactivation)
//   Future<ApiResult> deactivateSellerAccount({required String reason}) async {
//     const String mutation = r'''
//     mutation DeactivateSellerAccount($reason: String!) {
//       deactivateSellerAccount(reason: $reason) {
//         success
//         message
//         seller {
//           customId
//           email
//           name
//           companyName
//           status
//           deactivatedAt
//           deactivatedReason
//         }
//       }
//     }
//   ''';
//
//     try {
//       debugPrint("🔐 Attempting to deactivate seller account...");
//
//       // Get current user for debugging
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         return ApiResult.error("User not authenticated. Please login.");
//       }
//
//       debugPrint("👤 Current Firebase user: ${user.uid}");
//       debugPrint("📧 User email: ${user.email}");
//
//       final variables = {
//         "reason": reason,
//       };
//
//       // Use the performMutationWithAuth method from GraphQLService
//       final data = await GraphQLService.performMutationWithAuth(
//         mutation,
//         variables: variables,
//       );
//
//       if (data == null) {
//         return ApiResult.error("No response received from server");
//       }
//
//       final responseData = data['deactivateSellerAccount'];
//
//       if (responseData != null) {
//         final bool success = responseData['success'] ?? false;
//         final String message = responseData['message'] ?? "";
//
//         if (success) {
//           debugPrint("✅ Account deactivated successfully");
//           return ApiResult.success(
//               {
//                 "success": true,
//                 "message": message,
//                 "seller": responseData['seller']
//               },
//               message.isEmpty ? "Account deactivated successfully" : message
//           );
//         } else {
//           debugPrint("❌ Deactivation failed: $message");
//           return ApiResult.error(message.isEmpty ? "Failed to deactivate account" : message);
//         }
//       } else {
//         debugPrint("❌ No response data in deactivation");
//         return ApiResult.error("No response data received");
//       }
//     } catch (e) {
//       debugPrint("⚠ [deactivateSellerAccount] Exception: $e");
//
//       // Provide more specific error messages
//       if (e.toString().contains("Authentication") || e.toString().contains("login")) {
//         return ApiResult.error("Authentication failed. Please login again.");
//       } else if (e.toString().contains("firebaseUid")) {
//         return ApiResult.error("Seller account not linked to Firebase. Contact support.");
//       }
//
//       return ApiResult.error(e.toString());
//     }
//   }
//
//   /// Get seller data for deactivation page
//   Future<ApiResult> getSellerDataForDeactivation() async {
//     const String query = r'''
//     query GetSellerForDeactivation {
//       sellerByEmail {
//         customId
//         name
//         companyName
//         email
//         phoneNumber
//         status
//         deactivatedAt
//         deactivatedReason
//         fcmTokens
//         createdAt
//       }
//     }
//   ''';
//
//     try {
//       debugPrint("📋 Fetching seller data for deactivation...");
//
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         return ApiResult.error("User not authenticated");
//       }
//
//       debugPrint("👤 Fetching data for user: ${user.email}");
//
//       final client = await GraphQLService.initClient();
//       final result = await client.query(
//         QueryOptions(
//           document: gql(query),
//         ),
//       );
//
//       if (result.hasException) {
//         debugPrint("❌ [getSellerDataForDeactivation] ${result.exception}");
//         return ApiResult.error(_parseGraphQLError(result.exception));
//       }
//
//       final sellerData = result.data?['sellerByEmail'];
//       if (sellerData == null) {
//         return ApiResult.error("Seller data not found");
//       }
//
//       debugPrint("✅ Seller data retrieved successfully");
//       return ApiResult.success(sellerData);
//     } catch (e) {
//       debugPrint("⚠ [getSellerDataForDeactivation] Exception: $e");
//       return ApiResult.error(e.toString());
//     }
//   }
//
//   // ============================================================
//   // 📧 OTP PASSWORD CHANGE (Corrected for your backend)
//   // ============================================================
//
//   /// Request OTP for password change
//   Future<ApiResult> requestSellerPasswordOtp({
//     required String email,
//   }) async {
//     const String mutation = r'''
//     mutation RequestSellerPasswordOtp($email: String!) {
//       requestSellerPasswordOtp(email: $email) {
//         success
//         message
//         seller {
//           customId
//           email
//           name
//         }
//       }
//     }
//   ''';
//
//     try {
//       final client = await GraphQLService.initClient();
//
//       final variables = {
//         "email": email,
//       };
//
//       final result = await client.mutate(
//         MutationOptions(
//           document: gql(mutation),
//           variables: variables,
//         ),
//       );
//
//       if (result.hasException) {
//         debugPrint("❌ [requestSellerPasswordOtp] ${result.exception}");
//         return ApiResult.error(result.exception.toString());
//       }
//
//       final responseData = result.data?['requestSellerPasswordOtp'];
//
//       if (responseData != null) {
//         final bool success = responseData['success'] ?? false;
//         final String message = responseData['message'] ?? "";
//
//         if (success) {
//           return ApiResult.success(
//               {
//                 "success": true,
//                 "message": message,
//                 "seller": responseData['seller']
//               },
//               message.isEmpty ? "OTP sent successfully" : message
//           );
//         } else {
//           return ApiResult.error(message.isEmpty ? "Failed to send OTP" : message);
//         }
//       } else {
//         return ApiResult.error("No response data received");
//       }
//     } catch (e) {
//       debugPrint("⚠ [requestSellerPasswordOtp] Exception: $e");
//       return ApiResult.error(e.toString());
//     }
//   }
//
//   /// Verify OTP for password change
//   Future<ApiResult> verifySellerPasswordOtp({
//     required String email,
//     required String otp,
//   }) async {
//     const String mutation = r'''
//     mutation VerifySellerPasswordOtp($email: String!, $otp: String!) {
//       verifySellerPasswordOtp(email: $email, otp: $otp) {
//         success
//         message
//         seller {
//           customId
//           email
//           name
//         }
//       }
//     }
//   ''';
//
//     try {
//       final client = await GraphQLService.initClient();
//
//       final variables = {
//         "email": email,
//         "otp": otp,
//       };
//
//       final result = await client.mutate(
//         MutationOptions(
//           document: gql(mutation),
//           variables: variables,
//         ),
//       );
//
//       if (result.hasException) {
//         debugPrint("❌ [verifySellerPasswordOtp] ${result.exception}");
//         return ApiResult.error(result.exception.toString());
//       }
//
//       final responseData = result.data?['verifySellerPasswordOtp'];
//
//       if (responseData != null) {
//         final bool success = responseData['success'] ?? false;
//         final String message = responseData['message'] ?? "";
//
//         if (success) {
//           return ApiResult.success(
//               {
//                 "success": true,
//                 "message": message,
//                 "seller": responseData['seller']
//               },
//               message.isEmpty ? "OTP verified successfully" : message
//           );
//         } else {
//           return ApiResult.error(message.isEmpty ? "Invalid OTP" : message);
//         }
//       } else {
//         return ApiResult.error("No response data received");
//       }
//     } catch (e) {
//       debugPrint("⚠ [verifySellerPasswordOtp] Exception: $e");
//       return ApiResult.error(e.toString());
//     }
//   }
//
//   /// Change seller password with OTP verification
//   Future<ApiResult> changeSellerPassword({
//     required String email,
//     required String newPassword,
//     String? otp,
//   }) async {
//     const String mutation = r'''
//     mutation ChangeSellerPassword($email: String!, $newPassword: String!, $otp: String) {
//       changeSellerPassword(email: $email, newPassword: $newPassword, otp: $otp) {
//         success
//         message
//         seller {
//           customId
//           email
//           name
//         }
//       }
//     }
//   ''';
//
//     try {
//       final client = await GraphQLService.initClient();
//
//       final variables = {
//         "email": email,
//         "newPassword": newPassword,
//         "otp": otp,
//       };
//
//       final result = await client.mutate(
//         MutationOptions(
//           document: gql(mutation),
//           variables: variables,
//         ),
//       );
//
//       if (result.hasException) {
//         debugPrint("❌ [changeSellerPassword] ${result.exception}");
//         return ApiResult.error(result.exception.toString());
//       }
//
//       final responseData = result.data?['changeSellerPassword'];
//
//       if (responseData != null) {
//         final bool success = responseData['success'] ?? false;
//         final String message = responseData['message'] ?? "";
//
//         if (success) {
//           return ApiResult.success(
//               {
//                 "success": true,
//                 "message": message,
//                 "seller": responseData['seller']
//               },
//               message.isEmpty ? "Password changed successfully" : message
//           );
//         } else {
//           return ApiResult.error(message.isEmpty ? "Failed to change password" : message);
//         }
//       } else {
//         return ApiResult.error("No response data received");
//       }
//     } catch (e) {
//       debugPrint("⚠ [changeSellerPassword] Exception: $e");
//       return ApiResult.error(e.toString());
//     }
//   }
//
//
//   // ============================================================
//   // 🛍 MARKETPLACE: DRONES / PARTS / ACCESSORIES
//   // ============================================================
//
//
//   Future<ApiResult> getDrones() async {
//     const String query = r'''
//       query {
//         drones {
//           droneId
//           name
//           brand
//           price
//           description
//           image
//           status
//         }
//       }
//     ''';
//     return _runQuery("getDrones", query, "drones");
//   }
//
//
//   Future<ApiResult> getDronesPaginated({
//     required int page,
//     required int limit,
//   }) async {
//     const String query = r'''
//     query ApprovedDronePaginated($page: Int!, $limit: Int!) {
//       approvedDronePaginated(page: $page, limit: $limit) {
//         items {
//           droneId
//           name
//           brand
//           price
//           description
//           image
//           status
//         }
//         totalCount
//         page
//         limit
//         pageCount
//       }
//     }
//   ''';
//
//     return _runQuery(
//       "getDronesPaginated",
//       query,
//       "approvedDronePaginated",
//       variables: {"page": page, "limit": limit},
//     );
//   }
//
//
//
//   Future<ApiResult> getPartsPaginated({
//     required int page,
//     required int limit,
//   }) async {
//     const String query = r'''
//     query ApprovedPartPaginated($page: Int!, $limit: Int!) {
//       approvedPartPaginated(page: $page, limit: $limit) {
//         items {
//           partId
//           name
//           brand
//           price
//           description
//           image
//           status
//            }
//         totalCount
//         page
//         limit
//         pageCount
//         }
//       }
//     ''';
//     return _runQuery(
//       "getPartsPaginated",
//       query,
//       "approvedPartPaginated",
//       variables: {"page": page, "limit": limit},);
//   }
//
//   Future<ApiResult> getAccessoriesPaginated({
//     required int page,
//     required int limit,
//   }) async {
//     const String query = r'''
//     query ApprovedAccessoriesPaginated($page: Int!, $limit: Int!) {
//       approvedAccessoriesPaginated(page: $page, limit: $limit) {
//       items {
//           accessoryId
//           name
//           brand
//           price
//           description
//           image
//           status
//            }
//         totalCount
//         page
//         limit
//         pageCount
//         }
//       }
//     ''';
//     return _runQuery(
//       "getAccessoriesPaginated",
//       query,
//       "approvedAccessoriesPaginated",
//       variables: {"page": page, "limit": limit},);
//   }
//
//   // ============================================================
//   // 👨‍✈ HIRE PILOTS
//   // ============================================================
//   Future<ApiResult> getApprovedHirePilots() async {
//     const String query = r'''
//       query {
//         approvedHirePilotsByStatus {
//           pilotId
//           pilotName
//           pilotCompany
//           location
//           sellerId
//           availability
//           specification
//           description
//           email
//           phoneNumber
//           adminStatus
//           price {
//             perHour
//             perDay
//           }
//           certifications { url }
//           resume { url }
//           seller {
//             name
//             email
//             phoneNumber
//           }
//         }
//       }
//     ''';
//     return _runQuery(
//         "getApprovedHirePilots", query, "approvedHirePilotsByStatus");
//   }
//
//   // ===================== BOOK DRONE SERVICE ======================
//
//   Future<ApiResponse> bookDroneService(Map<String, dynamic> variables) async {
//     const String mutation = r'''
//       mutation CreateContact($input: CreateContactInput!) {
//         createContact(input: $input) {
//           success
//           message
//           data {
//             id
//             name
//             email
//             location
//             information
//             phone
//             date
//             serviceId
//             sellerId
//             serviceBookingId
//           }
//         }
//       }
//     ''';
//
//     developer.log("📤 Calling Mutation With: $variables");
//
//     // FIX: use your GraphQLService
//     final client = await GraphQLService.initClient();
//
//     final result = await client.mutate(
//       MutationOptions(
//         document: gql(mutation),
//         variables: variables,
//       ),
//     );
//
//     if (result.hasException) {
//       developer.log("❌ GraphQL Error: ${result.exception}");
//       return ApiResponse(
//         success: false,
//         message: result.exception.toString(),
//         data: null,
//       );
//     }
//
//     final data = result.data?["createContact"];
//
//     return ApiResponse(
//       success: data["success"] == true,
//       message: data["message"],
//       data: data["data"],
//     );
//   }
//
//
//   // --------------------------------------------------------------
//   // Final Add Hire Pilot (GraphQL Mutation)
//   // --------------------------------------------------------------
//   Future<ApiResult> addHirePilot({
//     required String pilotName,
//     required String pilotCompany,
//     required String location,
//     required String email,
//     required String phoneNumber,
//     required String sellerId,
//     required bool availability,
//     required String specification,
//     required double perHour,
//     required double perDay,
//     List<String>? certificationUrls,
//     String? resumeUrl,
//     String? description,
//   }) async {
//     const mutation = r'''
//       mutation AddHirePilot($input: HirePilotInput!) {
//         addHirePilot(input: $input) {
//           pilotId
//           pilotName
//           pilotCompany
//           location
//           email
//           phoneNumber
//           adminStatus
//         }
//       }
//     ''';
//
//     try {
//       final client = await GraphQLService.initClient();
//
//       final certInputs =
//           certificationUrls?.map((url) => {"url": url}).toList() ?? [];
//
//       final variables = {
//         "input": {
//           "pilotName": pilotName,
//           "pilotCompany": pilotCompany,
//           "location": location,
//           "newemail": email,
//           "newphoneNumber": phoneNumber,
//           "sellerId": sellerId,
//           "availability": availability,
//           "specification": specification,
//           "price": {"perHour": perHour, "perDay": perDay},
//           "certifications": certInputs,
//           "resume": resumeUrl != null ? {"url": resumeUrl} : null,
//           "description": description ?? "",
//         }
//       };
//
//       final result = await client.mutate(
//         MutationOptions(document: gql(mutation), variables: variables),
//       );
//
//       if (result.hasException) {
//         debugPrint("❌ GraphQL Error: ${result.exception}");
//         return ApiResult.error(result.exception.toString());
//       }
//
//       return ApiResult.success(result.data?["addHirePilot"]);
//     } catch (e) {
//       return ApiResult.error(e.toString());
//     }
//   }
//   Future<Map<String, dynamic>> bookPilot({
//     required String pilotId,
//     required String buyerId,
//     required String buyerName,
//     required String buyerEmail,
//     required String contact,
//     required String location,
//     required String date,
//     required String startTime,
//     required String endTime,
//   }) async {
//     final url = EnvConfig.baseUrl;
//
//     const mutation = """
//     mutation BookPilot(\$input: BookPilotInput!) {
//       bookPilot(input: \$input) {
//         success
//         message
//         booking {
//           bookingId
//           status
//         }
//       }
//     }
//   """;
//
//     final variables = {
//       "input": {
//         "pilotId": pilotId,
//         "buyerId": buyerId,
//         "buyerName": buyerName,
//         "buyerEmail": buyerEmail,
//         "contact": contact,
//         "location": location,
//         "date": date,
//         "startTime": startTime,
//         "endTime": endTime
//       }
//     };
//
//     final body = jsonEncode({
//       "query": mutation,
//       "variables": variables
//     });
//
//     try {
//       final res = await http.post(
//         Uri.parse(url),
//         headers: {"Content-Type": "application/json"},
//         body: body,
//       );
//
//       final json = jsonDecode(res.body);
//
//       if (json["errors"] != null) {
//         return {
//           "status": "error",
//           "message": json["errors"][0]["message"]
//         };
//       }
//
//       return {"status": "success", "data": json["data"]["bookPilot"]};
//     } catch (e) {
//       return {"status": "error", "message": e.toString()};
//     }
//   }
//
//
//
//   // ============================================================
//   // 💼 JOBS
//   // ============================================================
//   Future<ApiResult> getJobs() async {
//     const String query = r'''
//       query {
//         jobs {
//           jobId
//           jobName
//           companyName
//           jobType
//           experience
//           location
//           salary
//           description
//           requirement
//           email
//           phoneNumber
//           status
//           sellerId
//         }
//       }
//     ''';
//     return _runQuery("getJobs", query, "jobs");
//   }
//
//   Future<ApiResponse> submitJobApplication({
//     required String jobBookingId,
//     required String name,
//     required String email,
//     required String phoneNumber,
//     required String resumeUrl,
//   }) async {
//     const String mutation = r'''
//       mutation SubmitJobApplication($input: JobApplicationInput!) {
//         submitJobApplication(input: $input) {
//           success
//           message
//           application {
//             _id
//             name
//             email
//             phoneNumber
//             resumeUrl
//             jobBookingId
//             status
//             createdAt
//           }
//         }
//       }
//     ''';
//
//     final variables = {
//       "input": {
//         "jobBookingId": jobBookingId,
//         "name": name,
//         "email": email,
//         "phoneNumber": phoneNumber,
//         "resumeUrl": resumeUrl,
//       }
//     };
//
//     try {
//       debugPrint("📤 Submitting job application...");
//       debugPrint("jobBookingId: $jobBookingId");
//       debugPrint("Name: $name");
//       debugPrint("Email: $email");
//       debugPrint("Phone: $phoneNumber");
//       debugPrint("Resume URL: $resumeUrl");
//
//       final client = await GraphQLService.initClient();
//       final result = await client.mutate(
//         MutationOptions(
//           document: gql(mutation),
//           variables: variables,
//         ),
//       );
//
//       debugPrint("📥 Response received");
//
//       if (result.hasException) {
//         debugPrint("❌ GraphQL Exception: ${result.exception}");
//         return ApiResponse(
//           success: false,
//           message: result.exception.toString(),
//         );
//       }
//
//       final data = result.data?['submitJobApplication'];
//
//       if (data != null && data['success'] == true) {
//         debugPrint("✅ Application submitted successfully");
//         return ApiResponse(
//           success: true,
//           message: data['message'] ?? "Application submitted successfully",
//           data: data['application'],
//         );
//       } else {
//         final errorMessage = data?['message'] ?? "Failed to submit application";
//         debugPrint("❌ Application failed: $errorMessage");
//         return ApiResponse(
//           success: false,
//           message: errorMessage,
//         );
//       }
//     } catch (e) {
//       debugPrint("❌ submitJobApplication error: $e");
//       return ApiResponse(
//         success: false,
//         message: "Error: $e",
//       );
//     }
//   }
//
//   // ============================================================
//   // 🛠 SERVICES
//   // ============================================================
//   Future<ApiResult> getServices() async {
//     const String query = r'''
//       query {
//         services {
//           serviceId
//           name
//           specificDrone
//           experience
//           location
//           description
//           price
//           image
//           status
//           sellerId
//           sellerInfo {
//             email
//             phoneNumber
//           }
//         }
//       }
//     ''';
//     return _runQuery("getServices", query, "services");
//   }
//
//   // ============================================================
//   // 🏠 RENTALS
//   // ============================================================
//   Future<ApiResult> getRentals() async {
//     const String query = r'''
//       query {
//         rentals {
//           rentalId
//           name
//           brand
//           pricePerDay
//           pricePerHour
//           description
//           image
//           location
//           insurance
//           with_pilot
//           available_today
//           status
//         }
//       }
//     ''';
//     return _runQuery("getRentals", query, "rentals");
//   }
//
//
//   Future<Map<String, dynamic>> getRentalsPaginated({
//     required int page,
//     required int limit,
//   }) async {
//     final client = await GraphQLService.initClient();   // ⭐ FIX
//
//     final QueryOptions options = QueryOptions(
//       document: gql(approvedRentalsPaginatedQuery),
//       variables: {
//         "page": page,
//         "limit": limit,
//       },
//     );
//
//     final result = await client.query(options);
//
//     if (result.hasException) {
//       throw Exception(result.exception.toString());
//     }
//
//     return result.data!["approvedRentalsPaginated"];
//   }
//
//
//   static const String approvedRentalsPaginatedQuery = """
// query ApprovedRentalsPaginated(\$page: Int!, \$limit: Int!) {
//   approvedRentalsPaginated(page: \$page, limit: \$limit) {
//     items {
//       rentalId
//       name
//       brand
//       location
//       pricePerHour
//       pricePerDay
//       image
//       sellerInfo {
//         email
//         phoneNumber
//       }
//     }
//     totalCount
//     page
//     limit
//     pageCount
//   }
// }
// """;
//
//   Future<ApiResult> enrollTraining(Map<String, dynamic> data) async {
//     const String mutation = r'''
//     mutation EnrollTraining($input: TrainingEnrollInput!) {
//       enrollTraining(input: $input) {
//         id
//         name
//         email
//         phone
//         address
//         status
//       }
//     }
//   ''';
//
//     try {
//       final client = await GraphQLService.initClient();
//       final result = await client.mutate(
//         MutationOptions(
//           document: gql(mutation),
//           variables: {"input": data},
//         ),
//       ).timeout(const Duration(seconds: 30)); // Match the client timeout
//
//       if (result.hasException) {
//         debugPrint("❌ [EnrollTraining] ${result.exception}");
//         return ApiResult.error(result.exception.toString());
//       }
//
//       return ApiResult.success(result.data?['enrollTraining']);
//     } on TimeoutException {
//       return ApiResult.error("Request timed out. Please check your internet connection and try again.");
//     } on Exception catch (e) {
//       debugPrint("⚠ [EnrollTraining] Exception: $e");
//       return ApiResult.error(e.toString());
//     }
//   }
//
//   Future<ApiResult> getCourses() async {
//     const String query = r'''
//       query {
//         courses {
//           id
//           title
//           description
//           image
//           duration
//           format
//           certificate
//           price
//         }
//       }
//     ''';
//     return _runQuery("getCourses", query, "courses");
//   }
//
//   Future<ApiResult> getTrainingById(String id) async {
//     const query = r'''
//       query($id: ID!) {
//         getTrainingById(id: $id) {
//           id
//           title
//           amount
//           gst
//           days
//           totalAmount
//           imagePath
//           shortDescription
//           fullDescription
//         }
//       }
//     ''';
//     return _runQuery("getTrainingById", query, "getTrainingById",
//         variables: {"id": id});
//   }
//
//
//   Future<ApiResult> getApprovedHirePilotsPaginated({
//     required int page,
//     required int limit,
//   }) async {
//     const String query = r'''
//     query ApprovedHirePilotsPaginated($page: Int!, $limit: Int!) {
//       approvedHirePilotsPaginated(page: $page, limit: $limit) {
//         items {
//           pilotId
//           pilotName
//           pilotCompany
//           location
//           availability
//           specification
//           price { perHour perDay }
//           certifications { url filename uploadedAt }
//           resume { url filename uploadedAt }
//           description
//           newemail
//           newphoneNumber
//           adminStatus
//           buyerStatus
//           seller {
//             name
//             email
//             phoneNumber
//           }
//         }
//         totalCount
//         page
//         limit
//         pageCount
//       }
//     }
//   ''';
//
//     return _runQuery(
//         "getApprovedHirePilotsPaginated",
//         query,
//         "approvedHirePilotsPaginated",
//         variables: {"page": page, "limit": limit}
//         );
//     }
//
//   // ============================================================
//   // 🧠 Helper for Queries
//   // ============================================================
//   Future<ApiResult> _runQuery(
//       String tag,
//       String query,
//       String field, {
//         Map<String, dynamic>? variables,
//       }) async {
//     try {
//       final client = await GraphQLService.initClient();
//       final result = await client.query(
//         QueryOptions(
//           document: gql(query),
//           variables: variables ?? {},
//         ),
//       );
//
//       if (result.hasException) {
//         debugPrint("❌ [$tag] ${result.exception}");
//         return ApiResult.error(result.exception.toString());
//       }
//
//       final data = result.data?[field] ?? [];
//       debugPrint("✅ [$tag] Loaded ${data is List ? data.length : 1} items");
//       return ApiResult.success(data);
//     } catch (e) {
//       debugPrint("⚠ [$tag] Exception: $e");
//       return ApiResult.error(e.toString());
//     }
//   }
//
// }



import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flyhub/config/env.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
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

/// ✅ API Response class for Job Application
class ApiResponse {
  final bool success;
  final String? message;
  final dynamic data;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, data: $data)';
  }
}

/// 🧩 FlyHub GraphQL + Firebase API Manager
class ApiClass {
  late SharedPreferences pref;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ============================================================
  // 🚫 ACCOUNT DEACTIVATION & MANAGEMENT
  // ============================================================

  /// Deactivate seller account (self-deactivation)
  Future<ApiResult> deactivateSellerAccount({required String reason}) async {
    const String mutation = r'''
    mutation DeactivateSellerAccount($reason: String!) {
      deactivateSellerAccount(reason: $reason) {
        success
        message
        seller {
          customId
          email
          name
          companyName
          status
          deactivatedAt
          deactivatedReason
        }
      }
    }
  ''';

    try {
      debugPrint("🔐 Attempting to deactivate seller account...");

      // Get current user for debugging
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return ApiResult.error("User not authenticated. Please login.");
      }

      debugPrint("👤 Current Firebase user: ${user.uid}");
      debugPrint("📧 User email: ${user.email}");

      final variables = {
        "reason": reason,
      };

      // Use the performMutationWithAuth method from GraphQLService
      final data = await GraphQLService.performMutationWithAuth(
        mutation,
        variables: variables,
      );

      if (data == null) {
        return ApiResult.error("No response received from server");
      }

      final responseData = data['deactivateSellerAccount'];

      if (responseData != null) {
        final bool success = responseData['success'] ?? false;
        final String message = responseData['message'] ?? "";

        if (success) {
          debugPrint("✅ Account deactivated successfully");
          return ApiResult.success(
              {
                "success": true,
                "message": message,
                "seller": responseData['seller']
              },
              message.isEmpty ? "Account deactivated successfully" : message
          );
        } else {
          debugPrint("❌ Deactivation failed: $message");
          return ApiResult.error(message.isEmpty ? "Failed to deactivate account" : message);
        }
      } else {
        debugPrint("❌ No response data in deactivation");
        return ApiResult.error("No response data received");
      }
    } catch (e) {
      debugPrint("⚠ [deactivateSellerAccount] Exception: $e");

      // Provide more specific error messages
      if (e.toString().contains("Authentication") || e.toString().contains("login")) {
        return ApiResult.error("Authentication failed. Please login again.");
      } else if (e.toString().contains("firebaseUid")) {
        return ApiResult.error("Seller account not linked to Firebase. Contact support.");
      }

      return ApiResult.error(e.toString());
    }
  }

  /// Get seller data for deactivation page
  Future<ApiResult> getSellerDataForDeactivation() async {
    const String query = r'''
    query GetSellerForDeactivation {
      sellerByEmail {
        customId
        name
        companyName
        email
        phoneNumber
        status
        deactivatedAt
        deactivatedReason
        fcmTokens
        createdAt
      }
    }
  ''';

    try {
      debugPrint("📋 Fetching seller data for deactivation...");

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return ApiResult.error("User not authenticated");
      }

      debugPrint("👤 Fetching data for user: ${user.email}");

      final client = await GraphQLService.initClient();
      final result = await client.query(
        QueryOptions(
          document: gql(query),
        ),
      );

      if (result.hasException) {
        debugPrint("❌ [getSellerDataForDeactivation] ${result.exception}");
        return ApiResult.error(_parseGraphQLError(result.exception));
      }

      final sellerData = result.data?['sellerByEmail'];
      if (sellerData == null) {
        return ApiResult.error("Seller data not found");
      }

      debugPrint("✅ Seller data retrieved successfully");
      return ApiResult.success(sellerData);
    } catch (e) {
      debugPrint("⚠ [getSellerDataForDeactivation] Exception: $e");
      return ApiResult.error(e.toString());
    }
  }

  // ============================================================
  // 📧 OTP PASSWORD CHANGE (Corrected for your backend)
  // ============================================================

  /// Request OTP for password change
  Future<ApiResult> requestSellerPasswordOtp({
    required String email,
  }) async {
    const String mutation = r'''
    mutation RequestSellerPasswordOtp($email: String!) {
      requestSellerPasswordOtp(email: $email) {
        success
        message
        seller {
          customId
          email
          name
        }
      }
    }
  ''';

    try {
      final client = await GraphQLService.initClient();

      final variables = {
        "email": email,
      };

      final result = await client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: variables,
        ),
      );

      if (result.hasException) {
        debugPrint("❌ [requestSellerPasswordOtp] ${result.exception}");
        return ApiResult.error(result.exception.toString());
      }

      final responseData = result.data?['requestSellerPasswordOtp'];

      if (responseData != null) {
        final bool success = responseData['success'] ?? false;
        final String message = responseData['message'] ?? "";

        if (success) {
          return ApiResult.success(
              {
                "success": true,
                "message": message,
                "seller": responseData['seller']
              },
              message.isEmpty ? "OTP sent successfully" : message
          );
        } else {
          return ApiResult.error(message.isEmpty ? "Failed to send OTP" : message);
        }
      } else {
        return ApiResult.error("No response data received");
      }
    } catch (e) {
      debugPrint("⚠ [requestSellerPasswordOtp] Exception: $e");
      return ApiResult.error(e.toString());
    }
  }

  /// Verify OTP for password change
  Future<ApiResult> verifySellerPasswordOtp({
    required String email,
    required String otp,
  }) async {
    const String mutation = r'''
    mutation VerifySellerPasswordOtp($email: String!, $otp: String!) {
      verifySellerPasswordOtp(email: $email, otp: $otp) {
        success
        message
        seller {
          customId
          email
          name
        }
      }
    }
  ''';

    try {
      final client = await GraphQLService.initClient();

      final variables = {
        "email": email,
        "otp": otp,
      };

      final result = await client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: variables,
        ),
      );

      if (result.hasException) {
        debugPrint("❌ [verifySellerPasswordOtp] ${result.exception}");
        return ApiResult.error(result.exception.toString());
      }

      final responseData = result.data?['verifySellerPasswordOtp'];

      if (responseData != null) {
        final bool success = responseData['success'] ?? false;
        final String message = responseData['message'] ?? "";

        if (success) {
          return ApiResult.success(
              {
                "success": true,
                "message": message,
                "seller": responseData['seller']
              },
              message.isEmpty ? "OTP verified successfully" : message
          );
        } else {
          return ApiResult.error(message.isEmpty ? "Invalid OTP" : message);
        }
      } else {
        return ApiResult.error("No response data received");
      }
    } catch (e) {
      debugPrint("⚠ [verifySellerPasswordOtp] Exception: $e");
      return ApiResult.error(e.toString());
    }
  }

  /// Change seller password with OTP verification
  Future<ApiResult> changeSellerPassword({
    required String email,
    required String newPassword,
    String? otp,
  }) async {
    const String mutation = r'''
    mutation ChangeSellerPassword($email: String!, $newPassword: String!, $otp: String) {
      changeSellerPassword(email: $email, newPassword: $newPassword, otp: $otp) {
        success
        message
        seller {
          customId
          email
          name
        }
      }
    }
  ''';

    try {
      final client = await GraphQLService.initClient();

      final variables = {
        "email": email,
        "newPassword": newPassword,
        "otp": otp,
      };

      final result = await client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: variables,
        ),
      );

      if (result.hasException) {
        debugPrint("❌ [changeSellerPassword] ${result.exception}");
        return ApiResult.error(result.exception.toString());
      }

      final responseData = result.data?['changeSellerPassword'];

      if (responseData != null) {
        final bool success = responseData['success'] ?? false;
        final String message = responseData['message'] ?? "";

        if (success) {
          return ApiResult.success(
              {
                "success": true,
                "message": message,
                "seller": responseData['seller']
              },
              message.isEmpty ? "Password changed successfully" : message
          );
        } else {
          return ApiResult.error(message.isEmpty ? "Failed to change password" : message);
        }
      } else {
        return ApiResult.error("No response data received");
      }
    } catch (e) {
      debugPrint("⚠ [changeSellerPassword] Exception: $e");
      return ApiResult.error(e.toString());
    }
  }

  // ============================================================
  // ☁ Firebase File Upload via Backend REST API
  // ============================================================
  Future<String?> uploadToFirebaseStorage(File file, String folder, {String? fileName}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = "${timestamp}_${file.path.split('/').last}";
      final path = "$folder/${user.uid}/$fileName";

      final ref = _storage.ref().child(path);
      await ref.putFile(file);

      final downloadUrl = await ref.getDownloadURL();
      debugPrint("✅ Uploaded to Firebase: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      debugPrint("❌ Firebase upload error: $e");
      return null;
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

  Future<ApiResult> getDronesPaginated({
    required int page,
    required int limit,
  }) async {
    const String query = r'''
    query ApprovedDronePaginated($page: Int!, $limit: Int!) {
      approvedDronePaginated(page: $page, limit: $limit) {
        items {
          droneId
          name
          brand
          price
          description
          image
          status
        }
        totalCount
        page
        limit
        pageCount
      }
    }
  ''';

    return _runQuery(
      "getDronesPaginated",
      query,
      "approvedDronePaginated",
      variables: {"page": page, "limit": limit},
    );
  }

  Future<ApiResult> getPartsPaginated({
    required int page,
    required int limit,
  }) async {
    const String query = r'''
    query ApprovedPartPaginated($page: Int!, $limit: Int!) {
      approvedPartPaginated(page: $page, limit: $limit) {
        items {
          partId
          name
          brand
          price
          description
          image
          status
           }
        totalCount
        page
        limit
        pageCount
        }
      }
    ''';
    return _runQuery(
      "getPartsPaginated",
      query,
      "approvedPartPaginated",
      variables: {"page": page, "limit": limit},);
  }

  Future<ApiResult> getAccessoriesPaginated({
    required int page,
    required int limit,
  }) async {
    const String query = r'''
    query ApprovedAccessoriesPaginated($page: Int!, $limit: Int!) {
      approvedAccessoriesPaginated(page: $page, limit: $limit) {
      items {
          accessoryId
          name
          brand
          price
          description
          image
          status
           }
        totalCount
        page
        limit
        pageCount
        }
      }
    ''';
    return _runQuery(
      "getAccessoriesPaginated",
      query,
      "approvedAccessoriesPaginated",
      variables: {"page": page, "limit": limit},);
  }

  // ============================================================
  // 👨‍✈ HIRE PILOTS
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
          email
          phoneNumber
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

  // ===================== BOOK DRONE SERVICE ======================

  Future<ApiResponse> bookDroneService(Map<String, dynamic> variables) async {
    const String mutation = r'''
      mutation CreateContact($input: CreateContactInput!) {
        createContact(input: $input) {
          success
          message
          data {
            id
            name
            email
            location
            information
            phone
            date
            serviceId
            sellerId
            serviceBookingId
          }
        }
      }
    ''';

    developer.log("📤 Calling Mutation With: $variables");

    final client = await GraphQLService.initClient();

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: variables,
      ),
    );

    if (result.hasException) {
      developer.log("❌ GraphQL Error: ${result.exception}");
      return ApiResponse(
        success: false,
        message: result.exception.toString(),
        data: null,
      );
    }

    final data = result.data?["createContact"];

    return ApiResponse(
      success: data["success"] == true,
      message: data["message"],
      data: data["data"],
    );
  }

  // --------------------------------------------------------------
  // Final Add Hire Pilot (GraphQL Mutation)
  // --------------------------------------------------------------
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
    const mutation = r'''
      mutation AddHirePilot($input: HirePilotInput!) {
        addHirePilot(input: $input) {
          pilotId
          pilotName
          pilotCompany
          location
          email
          phoneNumber
          adminStatus
        }
      }
    ''';

    try {
      final client = await GraphQLService.initClient();

      final certInputs =
          certificationUrls?.map((url) => {"url": url}).toList() ?? [];

      final variables = {
        "input": {
          "pilotName": pilotName,
          "pilotCompany": pilotCompany,
          "location": location,
          "newemail": email,
          "newphoneNumber": phoneNumber,
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
        debugPrint("❌ GraphQL Error: ${result.exception}");
        return ApiResult.error(result.exception.toString());
      }

      return ApiResult.success(result.data?["addHirePilot"]);
    } catch (e) {
      return ApiResult.error(e.toString());
    }
  }

  Future<Map<String, dynamic>> bookPilot({
    required String pilotId,
    required String buyerId,
    required String buyerName,
    required String buyerEmail,
    required String contact,
    required String location,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    final url = EnvConfig.baseUrl;

    const mutation = """
    mutation BookPilot(\$input: BookPilotInput!) {
      bookPilot(input: \$input) {
        success
        message
        booking {
          bookingId
          status
        }
      }
    }
  """;

    final variables = {
      "input": {
        "pilotId": pilotId,
        "buyerId": buyerId,
        "buyerName": buyerName,
        "buyerEmail": buyerEmail,
        "contact": contact,
        "location": location,
        "date": date,
        "startTime": startTime,
        "endTime": endTime
      }
    };

    final body = jsonEncode({
      "query": mutation,
      "variables": variables
    });

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      final json = jsonDecode(res.body);

      if (json["errors"] != null) {
        return {
          "status": "error",
          "message": json["errors"][0]["message"]
        };
      }

      return {"status": "success", "data": json["data"]["bookPilot"]};
    } catch (e) {
      return {"status": "error", "message": e.toString()};
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

  Future<ApiResponse> submitJobApplication({
    required String jobBookingId,
    required String name,
    required String email,
    required String phoneNumber,
    required String resumeUrl,
  }) async {
    const String mutation = r'''
      mutation SubmitJobApplication($input: JobApplicationInput!) {
        submitJobApplication(input: $input) {
          success
          message
          application {
            _id
            name
            email
            phoneNumber
            resumeUrl
            jobBookingId
            status
            createdAt
          }
        }
      }
    ''';

    final variables = {
      "input": {
        "jobBookingId": jobBookingId,
        "name": name,
        "email": email,
        "phoneNumber": phoneNumber,
        "resumeUrl": resumeUrl,
      }
    };

    try {
      debugPrint("📤 Submitting job application...");
      debugPrint("jobBookingId: $jobBookingId");
      debugPrint("Name: $name");
      debugPrint("Email: $email");
      debugPrint("Phone: $phoneNumber");
      debugPrint("Resume URL: $resumeUrl");

      final client = await GraphQLService.initClient();
      final result = await client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: variables,
        ),
      );

      debugPrint("📥 Response received");

      if (result.hasException) {
        debugPrint("❌ GraphQL Exception: ${result.exception}");
        return ApiResponse(
          success: false,
          message: result.exception.toString(),
        );
      }

      final data = result.data?['submitJobApplication'];

      if (data != null && data['success'] == true) {
        debugPrint("✅ Application submitted successfully");
        return ApiResponse(
          success: true,
          message: data['message'] ?? "Application submitted successfully",
          data: data['application'],
        );
      } else {
        final errorMessage = data?['message'] ?? "Failed to submit application";
        debugPrint("❌ Application failed: $errorMessage");
        return ApiResponse(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e) {
      debugPrint("❌ submitJobApplication error: $e");
      return ApiResponse(
        success: false,
        message: "Error: $e",
      );
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
          status
        }
      }
    ''';
    return _runQuery("getRentals", query, "rentals");
  }

  Future<Map<String, dynamic>> getRentalsPaginated({
    required int page,
    required int limit,
  }) async {
    final client = await GraphQLService.initClient();

    final QueryOptions options = QueryOptions(
      document: gql(approvedRentalsPaginatedQuery),
      variables: {
        "page": page,
        "limit": limit,
      },
    );

    final result = await client.query(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return result.data!["approvedRentalsPaginated"];
  }

  static const String approvedRentalsPaginatedQuery = """
query ApprovedRentalsPaginated(\$page: Int!, \$limit: Int!) {
  approvedRentalsPaginated(page: \$page, limit: \$limit) {
    items {
      rentalId
      name
      brand
      location
      pricePerHour
      pricePerDay
      image
      sellerInfo {
        email
        phoneNumber
      }
    }
    totalCount
    page
    limit
    pageCount
  }
}
""";

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
      final result = await client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {"input": data},
        ),
      ).timeout(const Duration(seconds: 30));

      if (result.hasException) {
        debugPrint("❌ [EnrollTraining] ${result.exception}");
        return ApiResult.error(result.exception.toString());
      }

      return ApiResult.success(result.data?['enrollTraining']);
    } on TimeoutException {
      return ApiResult.error("Request timed out. Please check your internet connection and try again.");
    } on Exception catch (e) {
      debugPrint("⚠ [EnrollTraining] Exception: $e");
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
    return _runQuery("getTrainingById", query, "getTrainingById",
        variables: {"id": id});
  }

  Future<ApiResult> getApprovedHirePilotsPaginated({
    required int page,
    required int limit,
  }) async {
    const String query = r'''
    query ApprovedHirePilotsPaginated($page: Int!, $limit: Int!) {
      approvedHirePilotsPaginated(page: $page, limit: $limit) {
        items {
          pilotId
          pilotName
          pilotCompany
          location
          availability
          specification
          price { perHour perDay }
          certifications { url filename uploadedAt }
          resume { url filename uploadedAt }
          description
          newemail
          newphoneNumber
          adminStatus
          buyerStatus
          seller {
            name
            email
            phoneNumber
          }
        }
        totalCount
        page
        limit
        pageCount
      }
    }
  ''';

    return _runQuery(
        "getApprovedHirePilotsPaginated",
        query,
        "approvedHirePilotsPaginated",
        variables: {"page": page, "limit": limit}
    );
  }

  // ============================================================
  // 🧠 Helper Methods
  // ============================================================

  /// Helper for running GraphQL queries
  Future<ApiResult> _runQuery(
      String tag,
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
        return ApiResult.error(_parseGraphQLError(result.exception));
      }

      final data = result.data?[field] ?? [];
      debugPrint("✅ [$tag] Loaded ${data is List ? data.length : 1} items");
      return ApiResult.success(data);
    } catch (e) {
      debugPrint("⚠ [$tag] Exception: $e");
      return ApiResult.error(e.toString());
    }
  }

  /// Parse GraphQL errors into user-friendly messages
  String _parseGraphQLError(OperationException? exception) {
    if (exception == null) return "Unknown GraphQL error";

    if (exception.graphqlErrors.isNotEmpty) {
      return exception.graphqlErrors.first.message;
    }

    if (exception.linkException != null) {
      return "Network error: ${exception.linkException}";
    }

    return "GraphQL operation failed";
  }
}