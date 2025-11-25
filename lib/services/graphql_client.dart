// lib/services/graphql_client.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../config/env.dart';  // <-- your EnvConfig baseUrl

class GraphQLService {
  // 🔥 Use your env config
  static final String _httpUrl = EnvConfig.baseUrl;
  static final String _wsUrl = EnvConfig.baseUrl.replaceFirst("http", "ws");

  /// ---------------------------------------------------------
  /// 🚀 Initialize GraphQL Client with Firebase Auth
  /// ---------------------------------------------------------
  static Future<GraphQLClient> initClient() async {
    final HttpLink httpLink = HttpLink(_httpUrl);

    // 🔐 Firebase Auth token
    final AuthLink authLink = AuthLink(
      getToken: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return '';
        final token = await user.getIdToken(true); // ALWAYS fresh
        return 'Bearer $token';
      },
    );

    // 🔔 WebSocket link for subscriptions
    final WebSocketLink wsLink = WebSocketLink(
      _wsUrl,
      config: SocketClientConfig(
        autoReconnect: true,
        inactivityTimeout: const Duration(minutes: 5),
        initialPayload: () async {
          final user = FirebaseAuth.instance.currentUser;
          final token =
          user != null ? await user.getIdToken(true) : null;

          return {
            "Authorization": token != null ? "Bearer $token" : "",
          };
        },
      ),
    );

    // 🔀 Split: websocket for subscriptions / http for queries
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

  /// ---------------------------------------------------------
  /// 📌 General Query Helper
  /// ---------------------------------------------------------
  static Future<QueryResult> runQuery(
      String query, {
        Map<String, dynamic>? variables,
      }) async {
    final client = await initClient();
    final result = await client.query(
      QueryOptions(
        document: gql(query),
        variables: variables ?? {},
      ),
    );

    if (result.hasException) {
      _logError("Query", result.exception);
    }

    return result;
  }

  /// ---------------------------------------------------------
  /// 📌 General Mutation Helper
  /// ---------------------------------------------------------
  static Future<QueryResult> runMutation(
      String mutation, {
        Map<String, dynamic>? variables,
      }) async {
    final client = await initClient();
    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: variables ?? {},
      ),
    );

    if (result.hasException) {
      _logError("Mutation", result.exception);
    }

    return result;
  }

  /// ---------------------------------------------------------
  /// 📌 GraphQL Subscription Stream
  /// ---------------------------------------------------------
  static Stream<Map<String, dynamic>?> subscribe(
      String subscription, {
        Map<String, dynamic>? variables,
      }) async* {
    final client = await initClient();
    final stream = client.subscribe(
      SubscriptionOptions(
        document: gql(subscription),
        variables: variables ?? {},
      ),
    );

    await for (final result in stream) {
      if (result.hasException) {
        _logError("Subscription", result.exception);
      } else {
        yield result.data;
      }
    }
  }
  // ---------------------------------------------------------
// 🔵 Login Buyer (Email / Phone / Buyer ID)
// ---------------------------------------------------------
  static Future<Map<String, dynamic>> loginBuyer({
    required String input,
    required String password,
  }) async {
    const mutation = """
    mutation LoginBuyer(\$input: String!, \$password: String!) {
      loginBuyer(input: \$input, password: \$password) {
        buyerId
        email
        name
      }
    }
  """;

    final res = await runMutation(
      mutation,
      variables: {
        "input": input,
        "password": password,
      },
    );

    if (res.hasException) {
      throw Exception(
        res.exception!.graphqlErrors.isNotEmpty
            ? res.exception!.graphqlErrors.first.message
            : "Login failed",
      );
    }

    return res.data!["loginBuyer"];
  }


  /// ---------------------------------------------------------
  /// 🔥 SIGNUP BUYER → Your Backend (FLYHUBB0001)
  /// ---------------------------------------------------------
  static Future<Map<String, dynamic>> signupBuyer({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String firebaseUid,
  }) async {
    const mutation = """
      mutation SignupBuyer(
        \$name: String!,
        \$email: String!,
        \$phone: String!,
        \$password: String!,
        \$firebaseUid: String!
      ) {
        signupBuyer(
          name: \$name,
          email: \$email,
          phone: \$phone,
          password: \$password,
          firebaseUid: \$firebaseUid
        ) {
          buyerId
          email
          name
        }
      }
    """;

    final res = await runMutation(
      mutation,
      variables: {
        "name": name,
        "email": email,
        "phone": phone,
        "password": password,
        "firebaseUid": firebaseUid,
      },
    );

    if (res.hasException) {
      throw Exception(
          res.exception!.graphqlErrors.isNotEmpty
              ? res.exception!.graphqlErrors.first.message
              : "Signup failed");
    }

    return res.data!["signupBuyer"];
  }

  /// ---------------------------------------------------------
  /// 🧠 Internal Error Logger
  /// ---------------------------------------------------------
  static void _logError(String type, OperationException? exception) {
    if (exception == null) return;

    if (exception.graphqlErrors.isNotEmpty) {
      for (var err in exception.graphqlErrors) {
        debugPrint("❌ [$type GraphQL Error]: ${err.message}");
      }
    } else if (exception.linkException != null) {
      debugPrint("⚠️ [$type Network Error]: ${exception.linkException}");
    } else {
      debugPrint("⚠️ [$type Unknown Error]: $exception");
    }
  }
}
