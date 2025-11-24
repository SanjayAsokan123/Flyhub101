import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../config/env.dart';

/// 🚀 FlyHub GraphQL Client with Firebase Auth + Subscriptions + Auto-Reconnect
class GraphQLService {
  // 🌍 Endpoints (update for prod if needed)
  static const String _httpUrl = 'http://192.168.1.178:5001/graphql';
  static const String _wsUrl = 'ws://192.168.1.178:5001/graphql';

  /// 🔐 Initialize GraphQL Client
  static Future<GraphQLClient> initClient() async {
    final user = FirebaseAuth.instance.currentUser;
    // ✅ Always fetch a fresh Firebase token
    final AuthLink authLink = AuthLink(
      getToken: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return '';
        final freshToken = await user.getIdToken(true); // 🔥 ALWAYS fresh
        return 'Bearer $freshToken';
      },
    );

    final HttpLink httpLink = HttpLink(_httpUrl);

    // 🔔 WebSocket link for live subscriptions
    final WebSocketLink websocketLink = WebSocketLink(
      _wsUrl,
      config: SocketClientConfig(
        autoReconnect: true,
        inactivityTimeout: const Duration(minutes: 5),
        // reconnectInterval: const Duration(seconds: 5), // ✅ Reconnect every 5s
        initialPayload: () async {
          final user = FirebaseAuth.instance.currentUser;
          final freshToken = user != null ? await user.getIdToken(true) : null;

          return {
            'Authorization': freshToken != null ? 'Bearer $freshToken' : '',
          };
        },
      ),
    );

    // 🔀 Split link: HTTP for queries/mutations, WS for subscriptions
    final Link link = Link.split(
          (request) => request.isSubscription,
      websocketLink,
      authLink.concat(httpLink),
    );

    // ✅ Create GraphQL client with cache & network-only fetch policy
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

  // ============================================================
  // 🔁 HELPER METHODS
  // ============================================================

  /// 🔎 Run a GraphQL Query
  static Future<QueryResult> runQuery(
      String query, {
        Map<String, dynamic>? variables,
      }) async {
    final client = await initClient();
    final result = await client.query(
      QueryOptions(
        document: gql(query),
        variables: variables ?? {},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      _logGraphQLError("Query", result.exception);
    }
    return result;
  }

  /// 🧩 Run a GraphQL Mutation
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
      _logGraphQLError("Mutation", result.exception);
    }
    return result;
  }

  /// 🔔 Subscribe to a GraphQL stream (real-time updates)
  static Stream<Map<String, dynamic>?> subscribe(
      String subscription, {
        Map<String, dynamic>? variables,
      }) async* {
    final client = await initClient();
    final Stream<QueryResult> stream = client.subscribe(
      SubscriptionOptions(
        document: gql(subscription),
        variables: variables ?? {},
      ),
    );

    await for (final result in stream) {
      if (result.hasException) {
        _logGraphQLError("Subscription", result.exception);
      } else if (result.data != null) {
        yield result.data;
      }
    }
  }

  // ============================================================
  // 🧠 INTERNAL HELPERS
  // ============================================================

  /// Logs and formats GraphQL errors cleanly
  static void _logGraphQLError(String type, OperationException? exception) {
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
