import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🚀 GraphQL Client Service with Firebase Auth + WebSocket Subscriptions
class GraphQLService {
  // ✅ Your local / production endpoints
  static const String _httpUrl = 'http://192.168.0.180:5001/graphql';
  static const String _wsUrl = 'ws://192.168.0.180:5001/graphql';

  /// 🔐 Initialize GraphQL client (with Firebase JWT and Subscriptions)
  static Future<GraphQLClient> initClient() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = user != null ? await user.getIdToken() : null;

    // 🔹 Add Firebase Auth token to HTTP headers
    final AuthLink authLink = AuthLink(
      getToken: () async => token != null ? 'Bearer $token' : '',
    );

    // 🔹 Standard HTTP link for queries & mutations
    final HttpLink httpLink = HttpLink(_httpUrl);

    // 🔹 WebSocket link for real-time subscriptions
    final WebSocketLink websocketLink = WebSocketLink(
      _wsUrl,
      config: SocketClientConfig(
        autoReconnect: true,
        inactivityTimeout: const Duration(minutes: 5),
        // Send token in WebSocket connection payload
        initialPayload: () async => {
          'Authorization': token != null ? 'Bearer $token' : '',
        },
      ),
    );

    // 🔹 Split link: subscriptions via WS, rest via HTTP
    final Link link = Link.split(
          (request) => request.isSubscription,
      websocketLink,
      authLink.concat(httpLink),
    );

    // 🔹 Build client with cache
    return GraphQLClient(
      cache: GraphQLCache(store: InMemoryStore()),
      link: link,
    );
  }

  /// 🔁 Helper for running queries
  static Future<QueryResult> runQuery(String query,
      {Map<String, dynamic>? variables}) async {
    final client = await initClient();
    return client.query(QueryOptions(
      document: gql(query),
      variables: variables ?? {},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
  }

  /// 🧩 Helper for running mutations
  static Future<QueryResult> runMutation(String mutation,
      {Map<String, dynamic>? variables}) async {
    final client = await initClient();
    return client.mutate(MutationOptions(
      document: gql(mutation),
      variables: variables ?? {},
    ));
  }

  /// 🔔 Subscription listener setup
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
      if (!result.hasException && result.data != null) {
        yield result.data;
      }
    }
  }
}
