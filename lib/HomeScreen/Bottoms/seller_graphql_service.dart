import 'package:graphql_flutter/graphql_flutter.dart';

class SellerGraphQLService {
  static HttpLink httpLink = HttpLink(
    'http://localhost:5001/graphql', // Replace with your actual backend URL
  );

  static GraphQLClient getClient() {
    return GraphQLClient(cache: GraphQLCache(), link: httpLink);
  }

  // Create Seller Mutation
  static const String createSellerMutation = r'''
    mutation CreateSeller($input: SellerInput!) {
      createSeller(input: $input) {
        id
        name
        companyName
        PANnumber
        gstNumber
        address
        bankIFCnumber
        bankAccountNumber
        authorized
        email
        phoneNumber
        status
        shippingAddresses
        pickupAddresses
        companyPan
        bankName
      }
    }
  ''';

  // Login Query (you'll need to add this to your backend)
  static const String loginQuery = r'''
    query Login($email: String!, $password: String!) {
      login(email: $email, password: $password) {
        id
        name
        email
        token
      }
    }
  ''';

  // Get Seller Query
  static const String getSellerQuery = r'''
    query GetSeller($id: ID!) {
      getSeller(id: $id) {
        id
        name
        companyName
        PANnumber
        gstNumber
        address
        bankIFCnumber
        bankAccountNumber
        authorized
        email
        phoneNumber
        status
        shippingAddresses
        pickupAddresses
        companyPan
        bankName
      }
    }
  ''';

  // Create Seller
  static Future<Map<String, dynamic>?> createSeller({
    required String name,
    required String companyName,
    required String panNumber,
    String? gstNumber,
    required String address,
    required String bankIFCnumber,
    required String bankAccountNumber,
    required String authorized,
    required String email,
    required String phoneNumber,
    List<String>? shippingAddresses,
    List<String>? pickupAddresses,
    required String companyPan,
    required String bankName,
  }) async {
    final client = getClient();

    final result = await client.mutate(
      MutationOptions(
        document: gql(createSellerMutation),
        variables: {
          'input': {
            'name': name,
            'companyName': companyName,
            'PANnumber': panNumber,
            'gstNumber': gstNumber,
            'address': address,
            'bankIFCnumber': bankIFCnumber,
            'bankAccountNumber': bankAccountNumber,
            'authorized': authorized,
            'email': email,
            'phoneNumber': phoneNumber,
            'shippingAddresses': shippingAddresses ?? [],
            'pickupAddresses': pickupAddresses ?? [],
            'companyPan': companyPan,
            'bankName': bankName,
          },
        },
      ),
    );

    if (result.hasException) {
      print('GraphQL Exception: ${result.exception.toString()}');
      return null;
    }

    return result.data?['createSeller'];
  }

  // Login Seller
  static Future<Map<String, dynamic>?> loginSeller({
    required String email,
    required String password,
  }) async {
    final client = getClient();

    final result = await client.query(
      QueryOptions(
        document: gql(loginQuery),
        variables: {'email': email, 'password': password},
      ),
    );

    if (result.hasException) {
      print('Login Exception: ${result.exception.toString()}');
      return null;
    }

    return result.data?['login'];
  }

  // Get Seller by ID
  static Future<Map<String, dynamic>?> getSeller(String id) async {
    final client = getClient();

    final result = await client.query(
      QueryOptions(document: gql(getSellerQuery), variables: {'id': id}),
    );

    if (result.hasException) {
      print('Get Seller Exception: ${result.exception.toString()}');
      return null;
    }

    return result.data?['getSeller'];
  }
}