// // import 'package:flutter/material.dart';
// // import 'package:graphql_flutter/graphql_flutter.dart';
// // import '../../config/env.dart';
// //
// // class BuyerPilotBookingStatusPage extends StatefulWidget {
// //   final String buyerId;
// //   final String userType;
// //
// //   const BuyerPilotBookingStatusPage({
// //     super.key,
// //     required this.buyerId,
// //     this.userType = "buyer",
// //   });
// //
// //   @override
// //   State<BuyerPilotBookingStatusPage> createState() =>
// //       _BuyerPilotBookingStatusPageState();
// // }
// //
// // class _BuyerPilotBookingStatusPageState
// //     extends State<BuyerPilotBookingStatusPage>
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
// //   // QUERIES FOR BUYER PILOTS ONLY
// //   // ---------------------------------------------------
// //   String getQuery(String status) => '''
// //   query {
// //     getBuyerPilotOwnerBookings(
// //       buyerId: "${widget.buyerId}",
// //       status: "${status == "all" ? "" : status}"
// //     ) {
// //       bookingId
// //       pilotId
// //       pilotName
// //       buyerId
// //       buyerName
// //       buyerEmail
// //       contact
// //       location
// //       date
// //       startTime
// //       endTime
// //       duration
// //       totalAmount
// //       status
// //       paymentStatus
// //       pilotOwnerId
// //       pilotOwnerType
// //       pilotType
// //       createdAt
// //       updatedAt
// //     }
// //   }
// //   ''';
// //
// //   // ---------------------------------------------------
// //   // MUTATION FOR STATUS UPDATE
// //   // ---------------------------------------------------
// //   final String updateStatusMutation = '''
// //   mutation UpdatePilotBookingStatus(\$input: UpdateBookingStatusInput!) {
// //     updatePilotBookingStatus(input: \$input) {
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
// //           "input": {
// //             "bookingId": bookingId,
// //             "status": status,
// //             "userType": widget.userType,
// //             "userId": widget.buyerId,
// //           }
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
// //   // DELETE MUTATION
// //   // ---------------------------------------------------
// //   final String deleteBookingMutation = '''
// //   mutation DeletePilotBookingByOwner(
// //     \$bookingId: String!,
// //     \$ownerId: String!,
// //     \$pilotType: String!
// //   ) {
// //     deletePilotBookingByOwner(
// //       bookingId: \$bookingId,
// //       ownerId: \$ownerId,
// //       pilotType: \$pilotType
// //     ) {
// //       success
// //       message
// //     }
// //   }
// //   ''';
// //
// //   Future<void> deleteBooking({
// //     required String bookingId,
// //     required VoidCallback refetch,
// //   }) async {
// //     await client.mutate(
// //       MutationOptions(
// //         document: gql(deleteBookingMutation),
// //         variables: {
// //           "bookingId": bookingId,
// //           "ownerId": widget.buyerId,
// //           "pilotType": "buyer",
// //         },
// //         onCompleted: (_) {
// //           refetch();
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             const SnackBar(
// //               content: Text("Booking deleted successfully"),
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
// //   // BUILD TAB CONTENT
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
// //         final List<dynamic> bookings =
// //             result.data?['getBuyerPilotOwnerBookings'] ?? [];
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
// //                     // Booking ID and Status
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                       children: [
// //                         Text(
// //                           "Booking ID: ${b["bookingId"] ?? "N/A"}",
// //                           style: const TextStyle(
// //                             fontSize: 12,
// //                             color: Colors.grey,
// //                           ),
// //                         ),
// //                         Container(
// //                           padding: const EdgeInsets.symmetric(
// //                               horizontal: 8, vertical: 4),
// //                           decoration: BoxDecoration(
// //                             color: _getStatusColor(b["status"]),
// //                             borderRadius: BorderRadius.circular(12),
// //                           ),
// //                           child: Text(
// //                             (b["status"] ?? "pending").toUpperCase(),
// //                             style: const TextStyle(
// //                               fontSize: 11,
// //                               color: Colors.white,
// //                               fontWeight: FontWeight.bold,
// //                             ),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                     const SizedBox(height: 10),
// //
// //                     // Pilot Name
// //                     Text(
// //                       b["pilotName"] ?? "Unknown Pilot",
// //                       style: const TextStyle(
// //                         fontSize: 18,
// //                         fontWeight: FontWeight.bold,
// //                         color: Colors.blue,
// //                       ),
// //                     ),
// //                     const SizedBox(height: 8),
// //
// //                     // Buyer Information
// //                     Text(
// //                       "Booked by: ${b["buyerName"] ?? "Unknown Buyer"}",
// //                       style: const TextStyle(
// //                         fontSize: 14,
// //                         fontWeight: FontWeight.w500,
// //                       ),
// //                     ),
// //                     const SizedBox(height: 4),
// //                     Text(
// //                       "Contact: ${b["contact"] ?? "N/A"}",
// //                       style: const TextStyle(
// //                         fontSize: 14,
// //                         color: Colors.grey,
// //                       ),
// //                     ),
// //                     const SizedBox(height: 12),
// //
// //                     // Booking Details
// //                     _buildDetailRow("📅 Date", b["date"] ?? "N/A"),
// //                     _buildDetailRow(
// //                         "⏰ Time", "${b["startTime"] ?? ""} - ${b["endTime"] ?? ""}"),
// //                     _buildDetailRow("📍 Location", b["location"] ?? "N/A"),
// //                     _buildDetailRow(
// //                         "💰 Amount", "₹${b["totalAmount"]?.toStringAsFixed(2) ?? "0.00"}"),
// //                     if (b["duration"] != null)
// //                       _buildDetailRow(
// //                           "⏱️ Duration", "${b["duration"]?.toStringAsFixed(1)} hours"),
// //
// //                     const SizedBox(height: 16),
// //
// //                     // Action Buttons (Only for buyer pilots)
// //                     if (b["pilotType"] == "buyer")
// //                       _buildActionButtons(b, refetch!),
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
// //   Widget _buildDetailRow(String label, String value) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 6),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           SizedBox(
// //             width: 100,
// //             child: Text(
// //               label,
// //               style: const TextStyle(
// //                 fontSize: 14,
// //                 fontWeight: FontWeight.w500,
// //                 color: Colors.grey,
// //               ),
// //             ),
// //           ),
// //           const SizedBox(width: 8),
// //           Expanded(
// //             child: Text(
// //               value,
// //               style: const TextStyle(
// //                 fontSize: 14,
// //                 fontWeight: FontWeight.w500,
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildActionButtons(Map<String, dynamic> booking, VoidCallback refetch) {
// //     final status = booking["status"] ?? "pending";
// //
// //     if (status == "pending") {
// //       return Row(
// //         children: [
// //           Expanded(
// //             child: ElevatedButton(
// //               onPressed: () => updateStatus(
// //                 bookingId: booking["bookingId"] ?? "",
// //                 status: "approved",
// //                 refetch: refetch,
// //               ),
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: Colors.green,
// //                 foregroundColor: Colors.white,
// //               ),
// //               child: const Text("Approve"),
// //             ),
// //           ),
// //           const SizedBox(width: 10),
// //           Expanded(
// //             child: ElevatedButton(
// //               onPressed: () => updateStatus(
// //                 bookingId: booking["bookingId"] ?? "",
// //                 status: "rejected",
// //                 refetch: refetch,
// //               ),
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: Colors.red,
// //                 foregroundColor: Colors.white,
// //               ),
// //               child: const Text("Reject"),
// //             ),
// //           ),
// //           const SizedBox(width: 10),
// //           IconButton(
// //             onPressed: () => _showDeleteDialog(booking["bookingId"] ?? "", refetch),
// //             icon: const Icon(Icons.delete, color: Colors.grey),
// //             tooltip: "Delete",
// //           ),
// //         ],
// //       );
// //     } else if (status == "approved") {
// //       return Row(
// //         children: [
// //           Expanded(
// //             child: ElevatedButton(
// //               onPressed: () => updateStatus(
// //                 bookingId: booking["bookingId"] ?? "",
// //                 status: "completed",
// //                 refetch: refetch,
// //               ),
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: Colors.blue,
// //                 foregroundColor: Colors.white,
// //               ),
// //               child: const Text("Mark Completed"),
// //             ),
// //           ),
// //           const SizedBox(width: 10),
// //           IconButton(
// //             onPressed: () => _showDeleteDialog(booking["bookingId"] ?? "", refetch),
// //             icon: const Icon(Icons.delete, color: Colors.grey),
// //             tooltip: "Delete",
// //           ),
// //         ],
// //       );
// //     } else {
// //       return Align(
// //         alignment: Alignment.centerRight,
// //         child: IconButton(
// //           onPressed: () => _showDeleteDialog(booking["bookingId"] ?? "", refetch),
// //           icon: const Icon(Icons.delete, color: Colors.grey),
// //           tooltip: "Delete",
// //         ),
// //       );
// //     }
// //   }
// //
// //   Future<void> _showDeleteDialog(String bookingId, VoidCallback refetch) async {
// //     return showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: const Text("Delete Booking"),
// //         content: const Text("Are you sure you want to delete this booking?"),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: const Text("Cancel"),
// //           ),
// //           TextButton(
// //             onPressed: () {
// //               deleteBooking(bookingId: bookingId, refetch: refetch);
// //               Navigator.pop(context);
// //             },
// //             child: const Text(
// //               "Delete",
// //               style: TextStyle(color: Colors.red),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Color _getStatusColor(String status) {
// //     switch (status) {
// //       case "pending":
// //         return Colors.orange;
// //       case "approved":
// //         return Colors.green;
// //       case "completed":
// //         return Colors.blue;
// //       case "rejected":
// //         return Colors.red;
// //       default:
// //         return Colors.grey;
// //     }
// //   }
// //
// //   // ---------------------------------------------------
// //   // MAIN UI
// //   // ---------------------------------------------------
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Buyer Pilot Bookings"),
// //         bottom: TabBar(
// //           controller: _tabController,
// //           tabs: const [
// //             Tab(text: "Pending"),
// //             Tab(text: "Approved"),
// //             Tab(text: "Rejected"),
// //             Tab(text: "Completed"),
// //           ],
// //         ),
// //       ),
// //       body: TabBarView(
// //         controller: _tabController,
// //         children: [
// //           buildTab("pending"),
// //           buildTab("approved"),
// //           buildTab("rejected"),
// //           buildTab("completed"),
// //         ],
// //       ),
// //     );
// //   }
// // }
//
// import 'package:flutter/material.dart';
// import 'package:graphql_flutter/graphql_flutter.dart';
// import '../../config/env.dart';
//
// class BuyerPilotBookingStatusPage extends StatefulWidget {
//   final String buyerId;
//   final String userType;
//
//   const BuyerPilotBookingStatusPage({
//     super.key,
//     required this.buyerId,
//     this.userType = "buyer",
//   });
//
//   @override
//   State<BuyerPilotBookingStatusPage> createState() =>
//       _BuyerPilotBookingStatusPageState();
// }
//
// class _BuyerPilotBookingStatusPageState
//     extends State<BuyerPilotBookingStatusPage>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   late GraphQLClient client;
//   final Map<String, GlobalKey<RefreshIndicatorState>> _refreshKeys = {
//     'pending': GlobalKey<RefreshIndicatorState>(),
//     'approved': GlobalKey<RefreshIndicatorState>(),
//     'rejected': GlobalKey<RefreshIndicatorState>(),
//     'completed': GlobalKey<RefreshIndicatorState>(),
//   };
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
//   // QUERIES FOR BUYER PILOTS ONLY
//   // ---------------------------------------------------
//   String getQuery(String status) => '''
//   query {
//     getBuyerPilotOwnerBookings(
//       buyerId: "${widget.buyerId}",
//       status: "$status"
//     ) {
//       bookingId
//       pilotId
//       pilotName
//       buyerId
//       buyerName
//       buyerEmail
//       contact
//       location
//       date
//       startTime
//       endTime
//       duration
//       totalAmount
//       status
//       paymentStatus
//       pilotOwnerId
//       pilotOwnerType
//       pilotType
//       createdAt
//       updatedAt
//     }
//   }
//   ''';
//
//   // ---------------------------------------------------
//   // MUTATION FOR STATUS UPDATE
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
//     try {
//       final result = await client.mutate(
//         MutationOptions(
//           document: gql(updateStatusMutation),
//           variables: {
//             "input": {
//               "bookingId": bookingId,
//               "status": status,
//               "userType": widget.userType,
//               "userId": widget.buyerId,
//             }
//           },
//         ),
//       );
//
//       if (result.hasException) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text("Network Error"),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
//
//       refetch();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Status updated to $status"),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Network Error"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   // ---------------------------------------------------
//   // DELETE MUTATION
//   // ---------------------------------------------------
//   final String deleteBookingMutation = '''
//   mutation DeletePilotBookingByOwner(
//     \$bookingId: String!,
//     \$ownerId: String!,
//     \$pilotType: String!
//   ) {
//     deletePilotBookingByOwner(
//       bookingId: \$bookingId,
//       ownerId: \$ownerId,
//       pilotType: \$pilotType
//     ) {
//       success
//       message
//     }
//   }
//   ''';
//
//   Future<void> deleteBooking({
//     required String bookingId,
//     required VoidCallback refetch,
//   }) async {
//     try {
//       final result = await client.mutate(
//         MutationOptions(
//           document: gql(deleteBookingMutation),
//           variables: {
//             "bookingId": bookingId,
//             "ownerId": widget.buyerId,
//             "pilotType": "buyer",
//           },
//         ),
//       );
//
//       final response = result.data?['deletePilotBookingByOwner'];
//
//       if (response != null && response['success'] == true) {
//         refetch();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Booking deleted successfully"),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(response?['message'] ?? "Network Error"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Network Error"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   // ---------------------------------------------------
//   // BUILD TAB CONTENT WITH REFRESH
//   // ---------------------------------------------------
//   Widget buildTab(String status) {
//     final refreshKey = _refreshKeys[status.toLowerCase()] ?? GlobalKey<RefreshIndicatorState>();
//
//     return Query(
//       options: QueryOptions(
//         document: gql(getQuery(status)),
//         fetchPolicy: FetchPolicy.networkOnly,
//         pollInterval: const Duration(seconds: 5), // Auto-refresh every 5 seconds
//       ),
//       builder: (result, {refetch, fetchMore}) {
//         if (result.isLoading) {
//           return const Center(child: CircularProgressIndicator());
//         }
//
//         if (result.hasException) {
//           return RefreshIndicator(
//             key: refreshKey,
//             onRefresh: () async {
//               if (refetch != null) {
//                 await refetch();
//               }
//             },
//             child: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Text(
//                     "Network Error",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.grey,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   const Text(
//                     "Please check your connection",
//                     style: TextStyle(color: Colors.grey),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 24),
//                   ElevatedButton(
//                     onPressed: refetch,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue,
//                       foregroundColor: Colors.white,
//                     ),
//                     child: const Text("Retry"),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }
//
//         final List<dynamic> bookings =
//             result.data?['getBuyerPilotOwnerBookings'] ?? [];
//
//         return RefreshIndicator(
//           key: refreshKey,
//           onRefresh: () async {
//             if (refetch != null) {
//               await refetch();
//             }
//           },
//           child: bookings.isEmpty
//               ? const Center(
//             child: Text(
//               "No bookings",
//               style: TextStyle(fontSize: 16, color: Colors.grey),
//             ),
//           )
//               : ListView.builder(
//             itemCount: bookings.length,
//             itemBuilder: (_, i) {
//               final b = bookings[i];
//               return Card(
//                 margin: const EdgeInsets.all(12),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Booking ID and Status
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             "Booking ID: ${b["bookingId"] ?? "N/A"}",
//                             style: const TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey,
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 8, vertical: 4),
//                             decoration: BoxDecoration(
//                               color: _getStatusColor(b["status"]),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               (b["status"] ?? "pending").toUpperCase(),
//                               style: const TextStyle(
//                                 fontSize: 11,
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 10),
//
//                       // Pilot Name
//                       Text(
//                         b["pilotName"] ?? "Unknown Pilot",
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//
//                       // Buyer Information
//                       Text(
//                         "Booked by: ${b["buyerName"] ?? "Unknown Buyer"}",
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         "Contact: ${b["contact"] ?? "N/A"}",
//                         style: const TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//
//                       // Booking Details
//                       _buildDetailRow("📅 Date", b["date"] ?? "N/A"),
//                       _buildDetailRow(
//                           "⏰ Time", "${b["startTime"] ?? ""} - ${b["endTime"] ?? ""}"),
//                       _buildDetailRow("📍 Location", b["location"] ?? "N/A"),
//                       _buildDetailRow(
//                           "💰 Amount", "₹${b["totalAmount"]?.toStringAsFixed(2) ?? "0.00"}"),
//                       if (b["duration"] != null)
//                         _buildDetailRow(
//                             "⏱️ Duration", "${b["duration"]?.toStringAsFixed(1)} hours"),
//
//                       const SizedBox(height: 16),
//
//                       // Action Buttons
//                       if (b["pilotType"] == "buyer")
//                         _buildActionButtons(b, refetch!),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 100,
//             child: Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey,
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildActionButtons(Map<String, dynamic> booking, VoidCallback refetch) {
//     final status = booking["status"] ?? "pending";
//
//     if (status == "pending") {
//       return Row(
//         children: [
//           Expanded(
//             child: ElevatedButton(
//               onPressed: () => updateStatus(
//                 bookingId: booking["bookingId"] ?? "",
//                 status: "approved",
//                 refetch: refetch,
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text("Approve"),
//             ),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: ElevatedButton(
//               onPressed: () => updateStatus(
//                 bookingId: booking["bookingId"] ?? "",
//                 status: "rejected",
//                 refetch: refetch,
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text("Reject"),
//             ),
//           ),
//           const SizedBox(width: 10),
//           IconButton(
//             onPressed: () => _showDeleteDialog(booking["bookingId"] ?? "", refetch),
//             icon: const Icon(Icons.delete, color: Colors.grey),
//             tooltip: "Delete",
//           ),
//         ],
//       );
//     } else if (status == "approved") {
//       return Row(
//         children: [
//           Expanded(
//             child: ElevatedButton(
//               onPressed: () => updateStatus(
//                 bookingId: booking["bookingId"] ?? "",
//                 status: "completed",
//                 refetch: refetch,
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text("Mark Completed"),
//             ),
//           ),
//           const SizedBox(width: 10),
//           IconButton(
//             onPressed: () => _showDeleteDialog(booking["bookingId"] ?? "", refetch),
//             icon: const Icon(Icons.delete, color: Colors.grey),
//             tooltip: "Delete",
//           ),
//         ],
//       );
//     } else {
//       return Align(
//         alignment: Alignment.centerRight,
//         child: IconButton(
//           onPressed: () => _showDeleteDialog(booking["bookingId"] ?? "", refetch),
//           icon: const Icon(Icons.delete, color: Colors.grey),
//           tooltip: "Delete",
//         ),
//       );
//     }
//   }
//
//   Future<void> _showDeleteDialog(String bookingId, VoidCallback refetch) async {
//     return showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Delete Booking"),
//         content: const Text("Are you sure you want to delete this booking?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () {
//               deleteBooking(bookingId: bookingId, refetch: refetch);
//               Navigator.pop(context);
//             },
//             child: const Text(
//               "Delete",
//               style: TextStyle(color: Colors.red),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Color _getStatusColor(String status) {
//     switch (status) {
//       case "pending":
//         return Colors.orange;
//       case "approved":
//         return Colors.green;
//       case "completed":
//         return Colors.blue;
//       case "rejected":
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   // ---------------------------------------------------
//   // MAIN UI
//   // ---------------------------------------------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("My Pilot Bookings"),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: "Pending"),
//             Tab(text: "Approved"),
//             Tab(text: "Rejected"),
//             Tab(text: "Completed"),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           buildTab("pending"),
//           buildTab("approved"),
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

class BuyerPilotBookingStatusPage extends StatefulWidget {
  final String buyerId;
  final String userType;

  const BuyerPilotBookingStatusPage({
    super.key,
    required this.buyerId,
    this.userType = "buyer",
  });

  @override
  State<BuyerPilotBookingStatusPage> createState() =>
      _BuyerPilotBookingStatusPageState();
}

class _BuyerPilotBookingStatusPageState
    extends State<BuyerPilotBookingStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GraphQLClient client;
  bool _loading = true;
  List<Map<String, dynamic>> bookings = [];

  // Refresh controllers
  final RefreshController _pendingRefreshController = RefreshController();
  final RefreshController _approvedRefreshController = RefreshController();
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
    getBuyerPilotOwnerBookings(buyerId: "${widget.buyerId}") {
      bookingId
      pilotId
      pilotName
      buyerId
      buyerName
      buyerEmail
      contact
      location
      date
      startTime
      endTime
      duration
      totalAmount
      status
      paymentStatus
      pilotOwnerId
      pilotOwnerType
      pilotType
      createdAt
      updatedAt
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
            result.data?['getBuyerPilotOwnerBookings'] ?? []);
      }
    } catch (e) {
      debugPrint("Exception fetching bookings: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------------------------------------------------
  // MUTATION FOR STATUS UPDATE
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
              "userId": widget.buyerId,
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
    final isBuyerPilot = b["pilotType"] == "buyer";

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
                // Pilot icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E0E5C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.flight_takeoff_rounded,
                    color: const Color(0xFF1E0E5C),
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
                        b["pilotName"] ?? "Unknown Pilot",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E0E5C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Booked by: ${b["buyerName"] ?? "Unknown"}",
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
                        "💰 ₹${b["totalAmount"]?.toStringAsFixed(2) ?? "0.00"}",
                        style: const TextStyle(
                          color: Color(0xFF1E0E5C),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isBuyerPilot)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E0E5C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "Your Pilot",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E0E5C),
                            ),
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

            // Action buttons - Only show for buyer pilots
            if (isBuyerPilot && status.toLowerCase() == "pending")
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

            if (isBuyerPilot && status.toLowerCase() == "approved")
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
          "My Pilot Bookings",
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