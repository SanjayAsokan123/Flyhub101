// lib/services/graphql_pilot_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class GraphQLPilotService {
  static const String graphqlUrl = "http://localhost:5001/graphql";

  static Future<Map<String, dynamic>> checkPilotStatus(String buyerId) async {
    try {
      // FIXED: Use correct query name "buyerPilotsByBuyer" not "buyerPilotsByBuyerId"
      final query = """
        query GetBuyerPilotStatus(\$buyerId: String!) {
          buyerPilotsByBuyer(buyerId: \$buyerId) {
            buyerPilotId
            pilotName
            adminStatus
            buyerStatus
            createdAt
            updatedAt
            availability
          }
        }
      """;

      final response = await http.post(
        Uri.parse(graphqlUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'variables': {'buyerId': buyerId}
        }),
      );

      print("GraphQL Response Status: ${response.statusCode}");
      print("GraphQL Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // Check for errors
        if (jsonResponse['errors'] != null) {
          print("GraphQL Errors: ${jsonResponse['errors']}");
          return {
            'hasRegistration': false,
            'adminStatus': 'error',
            'error': jsonResponse['errors'][0]['message']
          };
        }

        final data = jsonResponse['data'];

        if (data != null && data['buyerPilotsByBuyer'] != null) {
          final pilots = data['buyerPilotsByBuyer'] as List;
          print("Found ${pilots.length} pilot registrations");

          if (pilots.isNotEmpty) {
            // Get the most recent pilot registration
            pilots.sort((a, b) =>
                DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt']))
            );

            final pilot = pilots.first;
            print("Latest pilot status: ${pilot['adminStatus']}");

            return {
              'hasRegistration': true,
              'adminStatus': pilot['adminStatus']?.toLowerCase() ?? 'pending',
              'pilotName': pilot['pilotName'],
              'buyerPilotId': pilot['buyerPilotId'],
              'availability': pilot['availability'] ?? true,
              'createdAt': pilot['createdAt'],
              'updatedAt': pilot['updatedAt'],
              'buyerStatus': pilot['buyerStatus'],
            };
          }
        }
      } else {
        print("HTTP Error: ${response.statusCode}");
      }
      return {'hasRegistration': false, 'adminStatus': 'none'};
    } catch (e) {
      print("❌ GraphQL pilot status error: $e");
      return {
        'hasRegistration': false,
        'adminStatus': 'error',
        'error': e.toString()
      };
    }
  }

  static Future<bool> isPilotApproved(String buyerId) async {
    final status = await checkPilotStatus(buyerId);
    final isApproved = status['hasRegistration'] == true &&
        status['adminStatus'] == 'approved';
    print("Is pilot approved for $buyerId: $isApproved");
    return isApproved;
  }
}