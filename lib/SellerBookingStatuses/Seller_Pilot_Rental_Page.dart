// // import 'package:flutter/material.dart';
// // import 'package:graphql_flutter/graphql_flutter.dart';
// // import '../../config/env.dart';
// //
// // class SellerPilotBookingStatusPage extends StatefulWidget {
// //   final String sellerId;
// //   final String userType;
// //
// //   const SellerPilotBookingStatusPage({
// //     super.key,
// //     required this.sellerId,
// //     this.userType = "seller",
// //   });
// //
// //   @override
// //   State<SellerPilotBookingStatusPage> createState() =>
// //       _SellerPilotBookingStatusPageState();
// // }
// //
// // class _SellerPilotBookingStatusPageState
// //     extends State<SellerPilotBookingStatusPage>
// //     with SingleTickerProviderStateMixin {
// //   late TabController _tabController;
// //   late GraphQLClient client;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _tabController = TabController(length: 4, vsync: this);
// //
// //     client = GraphQLClient(
// //       link: HttpLink(EnvConfig.baseUrl),
// //       cache: GraphQLCache(),
// //     );
// //   }
// //
// //   // ---------------------------------------------------
// //   // QUERIES
// //   // ---------------------------------------------------
// //   String getQuery(String status) => '''
// //   query {
// //     getSellerPilotBookings(sellerId: "${widget.sellerId}", status: "$status") {
// //       bookingId
// //       pilotName
// //       buyerName
// //       location
// //       date
// //       startTime
// //       endTime
// //       totalAmount
// //       status
// //       createdAt
// //     }
// //   }
// //   ''';
// //
// //   // ---------------------------------------------------
// //   // ✅ CORRECT MUTATION (MATCHES BACKEND)
// //   // ---------------------------------------------------
// //   final String updateStatusMutation = '''
// //   mutation UpdatePilotBookingStatus(
// //     \$bookingId: String!,
// //     \$status: String!,
// //     \$userType: String!,
// //     \$userId: String!
// //   ) {
// //     updatePilotBookingStatus(
// //       bookingId: \$bookingId,
// //       status: \$status,
// //       userType: \$userType,
// //       userId: \$userId
// //     ) {
// //       bookingId
// //       status
// //     }
// //   }
// //   ''';
// //
// //   Future<void> updateStatus({
// //     required String bookingId,
// //     required String status,
// //     required VoidCallback refetch,
// //   }) async {
// //     await client.mutate(
// //       MutationOptions(
// //         document: gql(updateStatusMutation),
// //         variables: {
// //           "bookingId": bookingId,
// //           "status": status,
// //           "userType": widget.userType,
// //           "userId": widget.sellerId,
// //         },
// //         onCompleted: (_) {
// //           refetch();
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(
// //               content: Text("Status updated to $status"),
// //               backgroundColor: Colors.green,
// //             ),
// //           );
// //         },
// //         onError: (error) {
// //           String message = "Something went wrong";
// //
// //           if (error != null) {
// //             if (error.graphqlErrors.isNotEmpty) {
// //               message = error.graphqlErrors.first.message;
// //             } else if (error.linkException != null) {
// //               message = error.linkException.toString();
// //             }
// //           }
// //
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(
// //               content: Text(message),
// //               backgroundColor: Colors.red,
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// //
// //   // ---------------------------------------------------
// //   // UI
// //   // ---------------------------------------------------
// //   Widget buildTab(String status) {
// //     return Query(
// //       options: QueryOptions(
// //         document: gql(getQuery(status)),
// //         fetchPolicy: FetchPolicy.networkOnly,
// //       ),
// //       builder: (result, {refetch, fetchMore}) {
// //         if (result.isLoading) {
// //           return const Center(child: CircularProgressIndicator());
// //         }
// //
// //         if (result.hasException) {
// //           return Center(
// //             child: Text(result.exception.toString()),
// //           );
// //         }
// //
// //         // ✅ FIXED: Access the data using the correct key
// //         // Instead of result.data?.values.first which was causing the error
// //         final List<dynamic> bookings =
// //             result.data?['getSellerPilotBookings'] ?? [];
// //
// //         if (bookings.isEmpty) {
// //           return const Center(
// //             child: Text(
// //               "No bookings",
// //               style: TextStyle(fontSize: 16, color: Colors.grey),
// //             ),
// //           );
// //         }
// //
// //         return ListView.builder(
// //           itemCount: bookings.length,
// //           itemBuilder: (_, i) {
// //             final b = bookings[i];
// //             return Card(
// //               margin: const EdgeInsets.all(12),
// //               child: Padding(
// //                 padding: const EdgeInsets.all(16),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Text(
// //                       b["buyerName"] ?? "Unknown Buyer",
// //                       style: const TextStyle(
// //                           fontSize: 16, fontWeight: FontWeight.bold),
// //                     ),
// //                     const SizedBox(height: 6),
// //                     Text("Pilot: ${b["pilotName"] ?? "Unknown Pilot"}"),
// //                     Text("Date: ${b["date"] ?? "N/A"}"),
// //                     Text("Time: ${b["startTime"] ?? ""} - ${b["endTime"] ?? ""}"),
// //                     Text("Amount: ₹${b["totalAmount"] ?? 0}"),
// //                     const SizedBox(height: 12),
// //
// //                     if (status == "pending")
// //                       Row(
// //                         children: [
// //                           ElevatedButton(
// //                             onPressed: () => updateStatus(
// //                               bookingId: b["bookingId"] ?? "",
// //                               status: "approved",
// //                               refetch: refetch!,
// //                             ),
// //                             child: const Text("Approve"),
// //                           ),
// //                           const SizedBox(width: 10),
// //                           ElevatedButton(
// //                             style: ElevatedButton.styleFrom(
// //                                 backgroundColor: Colors.red),
// //                             onPressed: () => updateStatus(
// //                               bookingId: b["bookingId"] ?? "",
// //                               status: "rejected",
// //                               refetch: refetch!,
// //                             ),
// //                             child: const Text("Reject"),
// //                           ),
// //                         ],
// //                       ),
// //
// //                     if (status == "approved")
// //                       ElevatedButton(
// //                         onPressed: () => updateStatus(
// //                           bookingId: b["bookingId"] ?? "",
// //                           status: "completed",
// //                           refetch: refetch!,
// //                         ),
// //                         child: const Text("Mark Completed"),
// //                       ),
// //                   ],
// //                 ),
// //               ),
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }
// //
// //   // ---------------------------------------------------
// //   // MAIN
// //   // ---------------------------------------------------
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Pilot Bookings"),
// //         bottom: TabBar(
// //           controller: _tabController,
// //           tabs: const [
// //             Tab(text: "Approved"),
// //             Tab(text: "Pending"),
// //             Tab(text: "Rejected"),
// //             Tab(text: "Completed"),
// //           ],
// //         ),
// //       ),
// //       body: TabBarView(
// //         controller: _tabController,
// //         children: [
// //           buildTab("approved"),
// //           buildTab("pending"),
// //           buildTab("rejected"),
// //           buildTab("completed"),
// //         ],
// //       ),
// //     );
// //   }
// // }
//
//
// import 'package:flutter/material.dart';
// import 'package:graphql_flutter/graphql_flutter.dart';
// import '../../config/env.dart';
//
// class SellerPilotBookingStatusPage extends StatefulWidget {
//   final String sellerId;
//   final String userType;
//
//   const SellerPilotBookingStatusPage({
//     super.key,
//     required this.sellerId,
//     this.userType = "seller",
//   });
//
//   @override
//   State<SellerPilotBookingStatusPage> createState() =>
//       _SellerPilotBookingStatusPageState();
// }
//
// class _SellerPilotBookingStatusPageState
//     extends State<SellerPilotBookingStatusPage>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   late GraphQLClient client;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 4, vsync: this);
//
//     client = GraphQLClient(
//       link: HttpLink(EnvConfig.baseUrl),
//       cache: GraphQLCache(),
//     );
//   }
//
//   // ---------------------------------------------------
//   // QUERIES
//   // ---------------------------------------------------
//   String getQuery(String status) => '''
//   query {
//     getSellerPilotBookings(sellerId: "${widget.sellerId}", status: "$status") {
//       bookingId
//       pilotName
//       buyerName
//       location
//       date
//       startTime
//       endTime
//       totalAmount
//       status
//       createdAt
//     }
//   }
//   ''';
//
//   // ---------------------------------------------------
//   // ✅ FIXED MUTATION - Now uses input object as per schema
//   // ---------------------------------------------------
//   final String updateStatusMutation = '''
//   mutation UpdatePilotBookingStatus(\$input: UpdateBookingStatusInput!) {
//     updatePilotBookingStatus(input: \$input) {
//       bookingId
//       status
//     }
//   }
//   ''';
//
//   Future<void> updateStatus({
//     required String bookingId,
//     required String status,
//     required VoidCallback refetch,
//   }) async {
//     await client.mutate(
//       MutationOptions(
//         document: gql(updateStatusMutation),
//         variables: {
//           "input": {
//             "bookingId": bookingId,
//             "status": status,
//             "userType": widget.userType,
//             "userId": widget.sellerId,
//           }
//         },
//         onCompleted: (_) {
//           refetch();
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text("Status updated to $status"),
//               backgroundColor: Colors.green,
//             ),
//           );
//         },
//         onError: (error) {
//           String message = "Something went wrong";
//
//           if (error != null) {
//             if (error.graphqlErrors.isNotEmpty) {
//               message = error.graphqlErrors.first.message;
//             } else if (error.linkException != null) {
//               message = error.linkException.toString();
//             }
//           }
//
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(message),
//               backgroundColor: Colors.red,
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   // ---------------------------------------------------
//   // UI
//   // ---------------------------------------------------
//   Widget buildTab(String status) {
//     return Query(
//       options: QueryOptions(
//         document: gql(getQuery(status)),
//         fetchPolicy: FetchPolicy.networkOnly,
//       ),
//       builder: (result, {refetch, fetchMore}) {
//         if (result.isLoading) {
//           return const Center(child: CircularProgressIndicator());
//         }
//
//         if (result.hasException) {
//           return Center(
//             child: Text(result.exception.toString()),
//           );
//         }
//
//         final List<dynamic> bookings =
//             result.data?['getSellerPilotBookings'] ?? [];
//
//         if (bookings.isEmpty) {
//           return const Center(
//             child: Text(
//               "No bookings",
//               style: TextStyle(fontSize: 16, color: Colors.grey),
//             ),
//           );
//         }
//
//         return ListView.builder(
//           itemCount: bookings.length,
//           itemBuilder: (_, i) {
//             final b = bookings[i];
//             return Card(
//               margin: const EdgeInsets.all(12),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       b["buyerName"] ?? "Unknown Buyer",
//                       style: const TextStyle(
//                           fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 6),
//                     Text("Pilot: ${b["pilotName"] ?? "Unknown Pilot"}"),
//                     Text("Date: ${b["date"] ?? "N/A"}"),
//                     Text("Time: ${b["startTime"] ?? ""} - ${b["endTime"] ?? ""}"),
//                     Text("Amount: ₹${b["totalAmount"] ?? 0}"),
//                     const SizedBox(height: 12),
//
//                     if (status == "pending")
//                       Row(
//                         children: [
//                           ElevatedButton(
//                             onPressed: () => updateStatus(
//                               bookingId: b["bookingId"] ?? "",
//                               status: "approved",
//                               refetch: refetch!,
//                             ),
//                             child: const Text("Approve"),
//                           ),
//                           const SizedBox(width: 10),
//                           ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.red),
//                             onPressed: () => updateStatus(
//                               bookingId: b["bookingId"] ?? "",
//                               status: "rejected",
//                               refetch: refetch!,
//                             ),
//                             child: const Text("Reject"),
//                           ),
//                         ],
//                       ),
//
//                     if (status == "approved")
//                       ElevatedButton(
//                         onPressed: () => updateStatus(
//                           bookingId: b["bookingId"] ?? "",
//                           status: "completed",
//                           refetch: refetch!,
//                         ),
//                         child: const Text("Mark Completed"),
//                       ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   // ---------------------------------------------------
//   // MAIN
//   // ---------------------------------------------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Pilot Bookings"),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: "Approved"),
//             Tab(text: "Pending"),
//             Tab(text: "Rejected"),
//             Tab(text: "Completed"),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           buildTab("approved"),
//           buildTab("pending"),
//           buildTab("rejected"),
//           buildTab("completed"),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:intl/intl.dart';
import '../../config/env.dart';

class SellerPilotBookingStatusPage extends StatefulWidget {
  final String sellerId;
  final String userType;

  const SellerPilotBookingStatusPage({
    super.key,
    required this.sellerId,
    this.userType = "seller",
  });

  @override
  State<SellerPilotBookingStatusPage> createState() =>
      _SellerPilotBookingStatusPageState();
}

class _SellerPilotBookingStatusPageState
    extends State<SellerPilotBookingStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GraphQLClient client;
  bool _loading = true;
  List<Map<String, dynamic>> bookings = [];

  // Refresh controllers for each tab
  final RefreshController _approvedRefreshController = RefreshController();
  final RefreshController _pendingRefreshController = RefreshController();
  final RefreshController _rejectedRefreshController = RefreshController();
  final RefreshController _completedRefreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);

    client = GraphQLClient(
      link: HttpLink(EnvConfig.baseUrl),
      cache: GraphQLCache(),
    );

    fetchBookings();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  // ---------------------------------------------------
  // QUERY
  // ---------------------------------------------------
  String getQuery() => '''
  query {
    getSellerPilotBookings(sellerId: "${widget.sellerId}") {
      bookingId
      pilotName
      buyerName
      location
      date
      startTime
      endTime
      totalAmount
      status
      createdAt
    }
  }
  ''';

  Future<void> fetchBookings() async {
    setState(() => _loading = true);

    try {
      final result = await client.query(QueryOptions(
        document: gql(getQuery()),
        fetchPolicy: FetchPolicy.networkOnly,
      ));

      if (result.hasException) {
        debugPrint("Error fetching bookings: ${result.exception}");
      } else {
        bookings = List<Map<String, dynamic>>.from(
            result.data?['getSellerPilotBookings'] ?? []);
      }
    } catch (e) {
      debugPrint("Exception fetching bookings: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------------------------------------------------
  // MUTATION - Now uses input object as per schema
  // ---------------------------------------------------
  final String updateStatusMutation = '''
  mutation UpdatePilotBookingStatus(\$input: UpdateBookingStatusInput!) {
    updatePilotBookingStatus(input: \$input) {
      bookingId
      status
    }
  }
  ''';

  Future<void> updateStatus({
    required String bookingId,
    required String status,
  }) async {
    try {
      await client.mutate(
        MutationOptions(
          document: gql(updateStatusMutation),
          variables: {
            "input": {
              "bookingId": bookingId,
              "status": status,
              "userType": widget.userType,
              "userId": widget.sellerId,
            }
          },
        ),
      );

      // Update local state
      int index = bookings.indexWhere((b) => b['bookingId'] == bookingId);
      if (index != -1) {
        setState(() {
          bookings[index]['status'] = status;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Status updated to $status"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      String message = "Something went wrong";

      if (error != null) {
        if (error is GraphQLError) {
          message = error.message;
        } else if (error is LinkException) {
          message = error.toString();
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---------------------------------------------------
  // DATE FORMATTING
  // ---------------------------------------------------
  String formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return "—";

    try {
      DateTime date;

      if (value is String) {
        if (value.contains('T')) {
          date = DateTime.parse(value);
        } else {
          try {
            if (value.contains('-') && value.length == 10) {
              date = DateFormat('yyyy-MM-dd').parse(value);
            } else if (int.tryParse(value) != null) {
              final timestamp = int.tryParse(value)!;
              if (timestamp > 1000000000000) {
                date = DateTime.fromMillisecondsSinceEpoch(timestamp);
              } else {
                date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
              }
            } else {
              return "—";
            }
          } catch (e) {
            return "—";
          }
        }
      } else if (value is Map && value.containsKey(r'$date')) {
        date = DateTime.parse(value[r'$date']);
      } else if (value is DateTime) {
        date = value;
      } else if (value is int) {
        if (value > 1000000000000) {
          date = DateTime.fromMillisecondsSinceEpoch(value);
        } else {
          date = DateTime.fromMillisecondsSinceEpoch(value * 1000);
        }
      } else {
        return "—";
      }

      return DateFormat("MMMM d, yyyy").format(date.toLocal());
    } catch (e) {
      return "—";
    }
  }

  // ---------------------------------------------------
  // COLORS BASED ON STATUS
  // ---------------------------------------------------
  Color getStatusColor(String? status) {
    switch (status?.toLowerCase() ?? "") {
      case "approved":
      case "confirmed":
        return Colors.green;
      case "rejected":
      case "cancelled":
        return Colors.red;
      case "completed":
        return Colors.blue;
      case "pending":
      default:
        return const Color(0xFF1E0E5C);
    }
  }

  // ---------------------------------------------------
  // REFRESH HANDLERS
  // ---------------------------------------------------
  Future<void> _onRefresh(int tabIndex) async {
    await fetchBookings();

    await Future.delayed(const Duration(milliseconds: 500));

    switch (tabIndex) {
      case 0:
        _pendingRefreshController.refreshCompleted();
        break;
      case 1:
        _approvedRefreshController.refreshCompleted();
        break;
      case 2:
        _rejectedRefreshController.refreshCompleted();
        break;
      case 3:
        _completedRefreshController.refreshCompleted();
        break;
    }
  }

  RefreshController _getRefreshController(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return _pendingRefreshController;
      case 1:
        return _approvedRefreshController;
      case 2:
        return _rejectedRefreshController;
      case 3:
        return _completedRefreshController;
      default:
        return _pendingRefreshController;
    }
  }

  // ---------------------------------------------------
  // CARD UI - MATCHING DRONE RENTAL DESIGN
  // ---------------------------------------------------
  Widget bookingCard(Map<String, dynamic> b) {
    final status = b["status"] ?? "--";
    final statusColor = getStatusColor(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE7E3FA), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // Customer icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E0E5C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF1E0E5C),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),

                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b["buyerName"] ?? "Unknown Buyer",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E0E5C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Pilot: ${b["pilotName"] ?? "Unknown Pilot"}",
                        style: const TextStyle(color: Colors.black54),
                      ),
                      Text(
                        "📍 ${b["location"] ?? '--'}",
                        style: const TextStyle(color: Colors.black54),
                      ),
                      Text(
                        "📅 ${formatDate(b["date"])}",
                        style: const TextStyle(color: Colors.black54),
                      ),
                      Text(
                        "⏰ ${b["startTime"] ?? ""} - ${b["endTime"] ?? ""}",
                        style: const TextStyle(color: Colors.black54),
                      ),
                      Text(
                        "💰 ₹${b["totalAmount"] ?? 0}",
                        style: const TextStyle(
                          color: Color(0xFF1E0E5C),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Action buttons based on status
            if (status.toLowerCase() == "pending")
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => updateStatus(
                      bookingId: b["bookingId"] ?? "",
                      status: "approved",
                    ),
                    child: const Text(
                      "Approve",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => updateStatus(
                      bookingId: b["bookingId"] ?? "",
                      status: "rejected",
                    ),
                    child: const Text(
                      "Reject",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

            if (status.toLowerCase() == "approved")
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => updateStatus(
                      bookingId: b["bookingId"] ?? "",
                      status: "completed",
                    ),
                    child: const Text(
                      "Mark as Completed",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------
  // TAB BUILDER
  // ---------------------------------------------------
  Widget buildTab(String statusFilter, int tabIndex) {
    if (_loading && bookings.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1E0E5C),
        ),
      );
    }

    final filteredBookings = bookings.where((b) {
      final status = (b["status"] ?? "").toLowerCase();
      return status == statusFilter.toLowerCase();
    }).toList();

    if (filteredBookings.isEmpty) {
      return SmartRefresher(
        enablePullDown: true,
        enablePullUp: false,
        controller: _getRefreshController(tabIndex),
        onRefresh: () => _onRefresh(tabIndex),
        child: const Center(
          child: Text(
            "No bookings found",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return SmartRefresher(
      enablePullDown: true,
      enablePullUp: false,
      controller: _getRefreshController(tabIndex),
      onRefresh: () => _onRefresh(tabIndex),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: filteredBookings.length,
        itemBuilder: (_, i) => bookingCard(filteredBookings[i]),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pendingRefreshController.dispose();
    _approvedRefreshController.dispose();
    _rejectedRefreshController.dispose();
    _completedRefreshController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------
  // MAIN BUILD
  // ---------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E0E5C),
        title: const Text(
          "Pilot Bookings",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Approved"),
            Tab(text: "Rejected"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildTab("pending", 0),
          buildTab("approved", 1),
          buildTab("rejected", 2),
          buildTab("completed", 3),
        ],
      ),
    );
  }
}