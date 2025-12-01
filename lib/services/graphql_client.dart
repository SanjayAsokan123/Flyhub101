// lib/services/graphql_client.dart

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;

import '../../config/env.dart';

class GraphQLService {
  static final String _httpUrl = EnvConfig.baseUrl;
  static final String _wsUrl = EnvConfig.baseUrl.replaceFirst("http", "ws");

  static Future<GraphQLClient> initClient() async {
    final HttpLink httpLink = HttpLink(_httpUrl);

    final AuthLink authLink = AuthLink(
      getToken: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return "";
        final token = await user.getIdToken(true);
        return "Bearer $token";
      },
    );

    final WebSocketLink wsLink = WebSocketLink(
      _wsUrl,
      config: SocketClientConfig(
        autoReconnect: true,
        inactivityTimeout: const Duration(minutes: 5),
        initialPayload: () async {
          final user = FirebaseAuth.instance.currentUser;
          final token = user != null ? await user.getIdToken(true) : null;
          return {
            "Authorization": token != null ? "Bearer $token" : "",
          };
        },
      ),
    );

    final Link link = Link.split(
          (request) => request.isSubscription,
      wsLink,
      authLink.concat(httpLink),
    );

    return GraphQLClient(
        cache: GraphQLCache(store: InMemoryStore()),
        link: link,
        defaultPolicies: DefaultPolicies(
          query: Policies(fetch: FetchPolicy.networkOnly),
          mutate: Policies(fetch: FetchPolicy.networkOnly),
          subscribe: Policies(fetch: FetchPolicy.noCache),
        ),
    );
  }

  /// ==========================================================
  /// 🔵 UNIVERSAL MUTATION
  /// ==========================================================
  static Future<Map<String, dynamic>?> performMutation(
      String mutation, {
        Map<String, dynamic>? variables,
      }) async {
    final client = await initClient();

    final result = await client.mutate(
      MutationOptions(document: gql(mutation), variables: variables ?? {}),
    );

    if (result.hasException) {
      _logError("Mutation", result.exception);
      throw Exception(
        result.exception!.graphqlErrors.isNotEmpty
            ? result.exception!.graphqlErrors.first.message
            : "Unknown mutation error",
      );
    }

    return result.data;
  }

  /// ==========================================================
  /// 🔵 UNIVERSAL QUERY
  /// ==========================================================
  static Future<Map<String, dynamic>?> performQuery(
      String query, {
        Map<String, dynamic>? variables,
      }) async {
    final client = await initClient();

    final result = await client.query(
      QueryOptions(document: gql(query), variables: variables ?? {}),
    );

    if (result.hasException) {
      _logError("Query", result.exception);
      throw Exception(
        result.exception!.graphqlErrors.isNotEmpty
            ? result.exception!.graphqlErrors.first.message
            : "Unknown query error",
      );
    }

    return result.data;
  }

  /// ==========================================================
  /// 🔵 SUBSCRIPTIONS
  /// ==========================================================
  static Stream<Map<String, dynamic>?> subscribe(
      String subscription, {
        Map<String, dynamic>? variables,
      }) async* {
    final client = await initClient();

    final stream = client.subscribe(
      SubscriptionOptions(document: gql(subscription), variables: variables ?? {}),
    );

    await for (final result in stream) {
      if (result.hasException) {
        _logError("Subscription", result.exception);
      } else {
        yield result.data;
      }
    }
  }

  // ==========================================================
  // 🔥 CREATE BUYER
  // Backend → createBuyer
  // ==========================================================
  static Future<Map<String, dynamic>> createBuyer({
    required String name,
    required String email,
    required String phone,
    String? password,
  }) async {
    const String mutation = r'''
      mutation CreateBuyer($input: BuyerInput!) {
        createBuyer(input: $input) {
          buyerId
          email
          name
          phoneNumber
        }
      }
    ''';

    final variables = {
      "input": {
        "name": name,
        "email": email,
        "phoneNumber": phone,
        if (password != null) "password": password,
      }
    };

    final data = await performMutation(mutation, variables: variables);
    return data!["createBuyer"];
  }

  // ==========================================================
  // 🔥 PASSWORD LOGIN
  // ==========================================================
  static Future<Map<String, dynamic>> loginBuyer({
    required String input,
    required String password,
  }) async {
    const String mutation = r'''
      mutation LoginBuyer($input: String!, $password: String!) {
        loginBuyer(input: $input, password: $password) {
          buyerId
          name
          email
          token
        }
      }
    ''';

    final res = await performMutation(mutation, variables: {
      "input": input,
      "password": password,
    });

    return res!["loginBuyer"];
  }

  // ==========================================================
  // 🔥 GOOGLE LOGIN
  // ==========================================================
  static Future<Map<String, dynamic>> loginBuyerGoogle({
    required String firebaseUid,
    required String email,
  }) async {
    const String mutation = r'''
      mutation LoginBuyerGoogle($firebaseUid: String!, $email: String!) {
        loginBuyerGoogle(firebaseUid: $firebaseUid, email: $email) {
          buyerId
          firebaseUid
          name
          email
          phoneNumber
          token
        }
      }
    ''';

    final data = await performMutation(
      mutation,
      variables: {"firebaseUid": firebaseUid, "email": email},
    );

    return data!["loginBuyerGoogle"];
  }

  /// ==========================================================
  /// 🔵 INTERNAL ERROR LOGGER
  /// ==========================================================
  static void _logError(String type, OperationException? exception) {
    if (exception == null) return;

    if (exception.graphqlErrors.isNotEmpty) {
      for (var err in exception.graphqlErrors) {
        debugPrint("❌ [$type GraphQL] ${err.message}");
      }
    }

    if (exception.linkException != null) {
      debugPrint("⚠️ [$type Network] ${exception.linkException}");
    }
  }
}
