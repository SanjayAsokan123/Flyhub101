import 'package:graphql_flutter/graphql_flutter.dart';
import '../config/env.dart';   // <-- import your EnvConfig

/// Use your backend GraphQL URL here
final String graphqlUrl = EnvConfig.baseUrl;

/// HTTP Link for queries/mutations
final HttpLink httpLink = HttpLink(graphqlUrl);

/// Orders Query
final String getOrdersQuery = r'''
query {
  orders {
    orderId
    buyer {
      name
      phone
    }
    items {
      name
      type
      price
      quantity
    }
    totalAmount
    status
    createdAt
  }
}
''';
