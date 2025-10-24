import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class GraphQLConfig {
  static HttpLink httpLink = HttpLink(
    "http://192.168.1.178:5001/graphql", // Android emulator
    // Or "http://localhost:5001/graphql" for web/iOS
    // Or "https://flyhub-api.onrender.com/graphql" if deployed
  );

  static ValueNotifier<GraphQLClient> initClient() {
    return ValueNotifier(
      GraphQLClient(
        link: httpLink,
        cache: GraphQLCache(store: InMemoryStore()),
      ),
    );
  }
}
