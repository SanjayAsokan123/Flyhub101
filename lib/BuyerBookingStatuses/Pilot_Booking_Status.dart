// // // // import 'package:flutter/material.dart';
// // // // import 'package:graphql_flutter/graphql_flutter.dart';
// // // // import 'package:permission_handler/permission_handler.dart';
// // // // import '../../config/env.dart';
// // // // import 'package:intl/intl.dart';
// // // // import 'package:url_launcher/url_launcher.dart';
// // // //
// // // // class PilotBookingStatusPage extends StatefulWidget {
// // // //   final String buyerId;
// // // //
// // // //   const PilotBookingStatusPage({super.key, required this.buyerId});
// // // //
// // // //   @override
// // // //   State<PilotBookingStatusPage> createState() =>
// // // //       _PilotBookingStatusPageState();
// // // // }
// // // //
// // // // class _PilotBookingStatusPageState extends State<PilotBookingStatusPage>
// // // //     with SingleTickerProviderStateMixin {
// // // //   late TabController _tabController;
// // // //   late GraphQLClient client;
// // // //
// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _tabController = TabController(length: 3, vsync: this);
// // // //
// // // //     client = GraphQLClient(
// // // //       link: HttpLink(EnvConfig.baseUrl),
// // // //       cache: GraphQLCache(),
// // // //     );
// // // //   }
// // // //
// // // //   // Function to make phone call
// // // //   Future<void> _makePhoneCall(String phoneNumber) async {
// // // //     PermissionStatus status = await Permission.phone.status;
// // // //
// // // //     if (!status.isGranted) {
// // // //       final allow = await showDialog<bool>(
// // // //         context: context,
// // // //         builder: (_) => AlertDialog(
// // // //           title: const Text("Call Permission Required"),
// // // //           content: const Text(
// // // //             "Flyhub needs phone permission to call the seller directly.",
// // // //           ),
// // // //           actions: [
// // // //             TextButton(
// // // //               onPressed: () => Navigator.pop(context, false),
// // // //               child: const Text("Cancel"),
// // // //             ),
// // // //             TextButton(
// // // //               onPressed: () => Navigator.pop(context, true),
// // // //               child: const Text("Allow"),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       );
// // // //
// // // //       if (allow != true) {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           const SnackBar(
// // // //             content: Text("Call permission denied"),
// // // //             backgroundColor: Colors.red,
// // // //           ),
// // // //         );
// // // //         return;
// // // //       }
// // // //
// // // //       status = await Permission.phone.request();
// // // //     }
// // // //
// // // //     if (status.isPermanentlyDenied) {
// // // //       showDialog(
// // // //         context: context,
// // // //         builder: (_) => AlertDialog(
// // // //           title: const Text("Permission Disabled"),
// // // //           content: const Text(
// // // //             "Phone permission is permanently denied. Please enable it from app settings.",
// // // //           ),
// // // //           actions: [
// // // //             TextButton(
// // // //               onPressed: () => Navigator.pop(context),
// // // //               child: const Text("Cancel"),
// // // //             ),
// // // //             TextButton(
// // // //               onPressed: () {
// // // //                 Navigator.pop(context);
// // // //                 openAppSettings();
// // // //               },
// // // //               child: const Text("Open Settings"),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       );
// // // //       return;
// // // //     }
// // // //
// // // //     if (status.isGranted) {
// // // //       final Uri launchUri = Uri(
// // // //         scheme: 'tel',
// // // //         path: phoneNumber,
// // // //       );
// // // //
// // // //       if (await canLaunchUrl(launchUri)) {
// // // //         await launchUrl(launchUri);
// // // //       } else {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(
// // // //             content: Text('Could not launch $phoneNumber'),
// // // //             backgroundColor: Colors.red,
// // // //           ),
// // // //         );
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   // --------------------------------------------
// // // //   // QUERIES FOR BUYER STATUS
// // // //   // --------------------------------------------
// // // //   String getApprovedQuery() => """
// // // //     query {
// // // //       getBuyerApprovedPilotBookings(buyerId: "${widget.buyerId}") {
// // // //         bookingId
// // // //         pilotId
// // // //         pilotName
// // // //         buyerName
// // // //         location
// // // //         date
// // // //         startTime
// // // //         endTime
// // // //         status
// // // //         sellerName
// // // //         sellerPhone
// // // //       }
// // // //     }
// // // //   """;
// // // //
// // // //   String getPendingQuery() => """
// // // //     query {
// // // //       getBuyerPendingPilotBookings(buyerId: "${widget.buyerId}") {
// // // //         bookingId
// // // //         pilotId
// // // //         pilotName
// // // //         buyerName
// // // //         location
// // // //         date
// // // //         startTime
// // // //         endTime
// // // //         status
// // // //       }
// // // //     }
// // // //   """;
// // // //
// // // //   String getRejectedQuery() => """
// // // //     query {
// // // //       getBuyerRejectedPilotBookings(buyerId: "${widget.buyerId}") {
// // // //         bookingId
// // // //         pilotId
// // // //         pilotName
// // // //         buyerName
// // // //         location
// // // //         date
// // // //         startTime
// // // //         endTime
// // // //         status
// // // //       }
// // // //     }
// // // //   """;
// // // //
// // // //   String deletePendingBookingMutation() => """
// // // // mutation DeletePendingBooking(\$bookingId: String!, \$buyerId: String!) {
// // // //   deletePilotBookingByBuyer(
// // // //     bookingId: \$bookingId,
// // // //     buyerId: \$buyerId
// // // //   ) {
// // // //     success
// // // //     message
// // // //   }
// // // // }
// // // // """;
// // // //
// // // //   // Helper function to format date
// // // //   String formatDate(String? dateString) {
// // // //     if (dateString == null || dateString.isEmpty) {
// // // //       return 'Date not available';
// // // //     }
// // // //
// // // //     try {
// // // //       DateTime date = DateTime.parse(dateString);
// // // //       return DateFormat('dd MMM yyyy').format(date);
// // // //     } catch (e) {
// // // //       try {
// // // //         if (dateString.length == 13 && int.tryParse(dateString) != null) {
// // // //           DateTime date =
// // // //           DateTime.fromMillisecondsSinceEpoch(int.parse(dateString));
// // // //           return DateFormat('dd MMM yyyy').format(date);
// // // //         }
// // // //         return dateString;
// // // //       } catch (e2) {
// // // //         return dateString;
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   // Format time
// // // //   String formatTime(String? timeString) {
// // // //     if (timeString == null || timeString.isEmpty) {
// // // //       return '--';
// // // //     }
// // // //     return timeString;
// // // //   }
// // // //
// // // //   // --------------------------------------------
// // // //   // STATUS COLORS
// // // //   // --------------------------------------------
// // // //   Color getStatusColor(String? status) {
// // // //     switch (status?.toLowerCase() ?? "") {
// // // //       case "approved":
// // // //         return Colors.green;
// // // //       case "rejected":
// // // //         return Colors.red;
// // // //       case "completed":
// // // //         return Colors.blue;
// // // //       case "pending":
// // // //       default:
// // // //         return const Color(0xFF1E0E5C);
// // // //     }
// // // //   }
// // // //
// // // //   // --------------------------------------------
// // // //   // BOOKING CARD UI
// // // //   // --------------------------------------------
// // // //   Widget buildBookingCard(Map<String, dynamic> b, {bool showDelete = false}) {
// // // //     final status = b['status'] ?? "--";
// // // //     final statusColor = getStatusColor(status);
// // // //     final formattedDate = formatDate(b['date']);
// // // //     final startTime = formatTime(b['startTime']);
// // // //     final endTime = formatTime(b['endTime']);
// // // //     final sellerPhone = b['sellerPhone'] ?? '--';
// // // //     final sellerName = b['sellerName'] ?? '--';
// // // //     final pilotName = b['pilotName'] ?? '--';
// // // //     final buyerName = b['buyerName'] ?? '--';
// // // //     final buyerPhone = b['buyerPhone'] ?? '--';
// // // //
// // // //     bool isApprovedTab = status.toLowerCase() == 'approved';
// // // //     bool isPendingTab = status.toLowerCase() == 'pending';
// // // //
// // // //     return Container(
// // // //       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // //       decoration: BoxDecoration(
// // // //         color: Colors.white,
// // // //         borderRadius: BorderRadius.circular(16),
// // // //         border: Border.all(color: Colors.grey.shade300, width: 1),
// // // //         boxShadow: [
// // // //           BoxShadow(
// // // //             color: Colors.grey.withOpacity(0.1),
// // // //             blurRadius: 8,
// // // //             offset: const Offset(0, 2),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       child: Padding(
// // // //         padding: const EdgeInsets.all(16),
// // // //         child: Column(
// // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // //           children: [
// // // //             Row(
// // // //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //               children: [
// // // //                 Expanded(
// // // //                   child: Text(
// // // //                     pilotName,
// // // //                     style: const TextStyle(
// // // //                       fontSize: 16,
// // // //                       fontWeight: FontWeight.w700,
// // // //                       color: Color(0xFF1E0E5C),
// // // //                     ),
// // // //                     overflow: TextOverflow.ellipsis,
// // // //                   ),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //
// // // //             const SizedBox(height: 12),
// // // //             Divider(color: Colors.grey.shade300, height: 1),
// // // //             const SizedBox(height: 12),
// // // //
// // // //             Row(
// // // //               children: [
// // // //                 Expanded(
// // // //                   child: Row(
// // // //                     children: [
// // // //                       Container(
// // // //                         width: 54,
// // // //                         height: 54,
// // // //                         decoration: BoxDecoration(
// // // //                           color: const Color(0xFF1E0E5C).withOpacity(0.15),
// // // //                           borderRadius: BorderRadius.circular(16),
// // // //                         ),
// // // //                         child: Icon(Icons.person, size: 28, color: const Color(0xFF1E0E5C)),
// // // //                       ),
// // // //                       const SizedBox(width: 16),
// // // //                       Expanded(
// // // //                         child: Column(
// // // //                           crossAxisAlignment: CrossAxisAlignment.start,
// // // //                           children: [
// // // //                             if (isApprovedTab && sellerName != '--') ...[
// // // //                               _buildDetailRow(
// // // //                                 icon: Icons.person,
// // // //                                 text: sellerName,
// // // //                                 iconColor: const Color(0xFF1E0E5C),
// // // //                               ),
// // // //                               const SizedBox(height: 6),
// // // //                             ],
// // // //                             if (isApprovedTab && sellerPhone != '--') ...[
// // // //                               _buildDetailRow(
// // // //                                 icon: Icons.phone,
// // // //                                 text: sellerPhone,
// // // //                                 iconColor: Colors.blue,
// // // //                               ),
// // // //                               const SizedBox(height: 6),
// // // //                             ],
// // // //                             _buildDetailRow(
// // // //                               icon: Icons.calendar_today,
// // // //                               text: formattedDate,
// // // //                               iconColor: Colors.orange,
// // // //                             ),
// // // //                             const SizedBox(height: 6),
// // // //                             _buildDetailRow(
// // // //                               icon: Icons.access_time,
// // // //                               text: "$startTime - $endTime",
// // // //                               iconColor: Colors.purple,
// // // //                             ),
// // // //                             const SizedBox(height: 6),
// // // //                             if (b['location'] != null && b['location'].isNotEmpty)
// // // //                               _buildDetailRow(
// // // //                                 icon: Icons.location_on,
// // // //                                 text: b['location'] ?? '--',
// // // //                                 iconColor: Colors.red,
// // // //                               ),
// // // //                           ],
// // // //                         ),
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                 ),
// // // //                 Column(
// // // //                   children: [
// // // //                     if (isApprovedTab && sellerPhone != '--' && sellerPhone != '')
// // // //                       ElevatedButton.icon(
// // // //                         onPressed: () => _makePhoneCall(sellerPhone),
// // // //                         icon: const Icon(Icons.phone, size: 16),
// // // //                         label: const Text("Call Now"),
// // // //                         style: ElevatedButton.styleFrom(
// // // //                           backgroundColor: Colors.green,
// // // //                           foregroundColor: Colors.white,
// // // //                           shape: RoundedRectangleBorder(
// // // //                             borderRadius: BorderRadius.circular(12),
// // // //                           ),
// // // //                           padding: const EdgeInsets.symmetric(
// // // //                             horizontal: 16,
// // // //                             vertical: 10,
// // // //                           ),
// // // //                           elevation: 0,
// // // //                         ),
// // // //                       ),
// // // //                     if (isPendingTab && showDelete)
// // // //                       IconButton(
// // // //                         onPressed: () {
// // // //                           showDialog(
// // // //                             context: context,
// // // //                             builder: (context) => AlertDialog(
// // // //                               title: const Text("Delete Booking"),
// // // //                               content: const Text(
// // // //                                   "Are you sure you want to delete this pending booking?"),
// // // //                               actions: [
// // // //                                 TextButton(
// // // //                                   onPressed: () => Navigator.pop(context),
// // // //                                   child: const Text("Cancel"),
// // // //                                 ),
// // // //                                 TextButton(
// // // //                                   onPressed: () async {
// // // //                                     Navigator.pop(context);
// // // //                                     await _deleteBooking(b['bookingId']);
// // // //                                   },
// // // //                                   child: const Text(
// // // //                                     "Delete",
// // // //                                     style: TextStyle(color: Colors.red),
// // // //                                   ),
// // // //                                 ),
// // // //                               ],
// // // //                             ),
// // // //                           );
// // // //                         },
// // // //                         icon: Icon(
// // // //                           Icons.delete_outline,
// // // //                           color: Colors.red.shade600,
// // // //                           size: 28,
// // // //                         ),
// // // //                       ),
// // // //                   ],
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   Widget _buildDetailRow({
// // // //     required IconData icon,
// // // //     required String text,
// // // //     required Color iconColor,
// // // //   }) {
// // // //     return Row(
// // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // //       children: [
// // // //         Icon(
// // // //           icon,
// // // //           size: 16,
// // // //           color: iconColor,
// // // //         ),
// // // //         const SizedBox(width: 8),
// // // //         Expanded(
// // // //           child: Text(
// // // //             text,
// // // //             style: const TextStyle(
// // // //               fontSize: 13,
// // // //               color: Colors.black87,
// // // //             ),
// // // //             maxLines: 2,
// // // //             overflow: TextOverflow.ellipsis,
// // // //           ),
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ FIXED: Delete booking method - shows only "Network Error"
// // // //   Future<void> _deleteBooking(String bookingId) async {
// // // //     try {
// // // //       final result = await client.mutate(
// // // //         MutationOptions(
// // // //           document: gql(deletePendingBookingMutation()),
// // // //           variables: {
// // // //             'bookingId': bookingId,
// // // //             'buyerId': widget.buyerId,
// // // //           },
// // // //         ),
// // // //       );
// // // //
// // // //       final response = result.data?['deletePilotBookingByBuyer'];
// // // //
// // // //       if (response != null && response['success'] == true) {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           const SnackBar(
// // // //             content: Text("Booking deleted successfully"),
// // // //             backgroundColor: Colors.green,
// // // //           ),
// // // //         );
// // // //         setState(() {});
// // // //       } else {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           const SnackBar(
// // // //             content: Text("Network Error"),
// // // //             backgroundColor: Colors.red,
// // // //           ),
// // // //         );
// // // //       }
// // // //     } catch (e) {
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         const SnackBar(
// // // //           content: Text("Network Error"),
// // // //           backgroundColor: Colors.red,
// // // //         ),
// // // //       );
// // // //     }
// // // //   }
// // // //
// // // //   // --------------------------------------------
// // // //   // TAB VIEW BUILDER WITH REFRESH INDICATOR
// // // //   // --------------------------------------------
// // // //   Widget buildTab(String Function() queryBuilder, {bool isPending = false}) {
// // // //     return Query(
// // // //       options: QueryOptions(
// // // //         document: gql(queryBuilder()),
// // // //         pollInterval: const Duration(seconds: 3),
// // // //       ),
// // // //       builder: (result, {refetch, fetchMore}) {
// // // //         return RefreshIndicator(
// // // //           onRefresh: () async {
// // // //             if (refetch != null) {
// // // //               await refetch();
// // // //             }
// // // //           },
// // // //           child: _buildTabContent(result, isPending, refetch),
// // // //         );
// // // //       },
// // // //     );
// // // //   }
// // // //
// // // //   Widget _buildTabContent(QueryResult result, bool isPending, Future<QueryResult?> Function()? refetch) {
// // // //     if (result.isLoading && result.data == null) {
// // // //       return const Center(child: CircularProgressIndicator());
// // // //     }
// // // //
// // // //     // ✅ FIXED: Show ONLY "Network Error" - NO icons, NO technical details
// // // //     if (result.hasException) {
// // // //       return RefreshIndicator(
// // // //         onRefresh: () async {
// // // //           if (refetch != null) {
// // // //             await refetch!();
// // // //           }
// // // //         },
// // // //         child: Center(
// // // //           child: Column(
// // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // //             children: [
// // // //               const Text(
// // // //                 "Network Error",
// // // //                 style: TextStyle(
// // // //                   fontSize: 18,
// // // //                   fontWeight: FontWeight.w600,
// // // //                   color: Colors.grey,
// // // //                 ),
// // // //               ),
// // // //               const SizedBox(height: 16),
// // // //               const Text(
// // // //                 "Please check your connection and try again",
// // // //                 style: TextStyle(color: Colors.grey),
// // // //                 textAlign: TextAlign.center,
// // // //               ),
// // // //               const SizedBox(height: 24),
// // // //               ElevatedButton(
// // // //                 onPressed: refetch,
// // // //                 style: ElevatedButton.styleFrom(
// // // //                   backgroundColor: const Color(0xFF1E0E5C),
// // // //                   foregroundColor: Colors.white,
// // // //                 ),
// // // //                 child: const Text("Retry"),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       );
// // // //     }
// // // //
// // // //     final data = result.data ?? {};
// // // //
// // // //     String key = data.keys.firstWhere(
// // // //           (k) => k != "__typename",
// // // //       orElse: () => "",
// // // //     );
// // // //
// // // //     final list = (data[key] ?? []) as List;
// // // //
// // // //     if (list.isEmpty) {
// // // //       return RefreshIndicator(
// // // //         onRefresh: () async {
// // // //           if (refetch != null) {
// // // //             await refetch();
// // // //           }
// // // //         },
// // // //         child: ListView(
// // // //           children: [
// // // //             SizedBox(
// // // //               height: MediaQuery.of(context).size.height * 0.7,
// // // //               child: const Center(
// // // //                 child: Text("No bookings found",
// // // //                     style: TextStyle(color: Colors.grey)),
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       );
// // // //     }
// // // //
// // // //     return ListView.builder(
// // // //       itemCount: list.length,
// // // //       itemBuilder: (_, i) => buildBookingCard(list[i], showDelete: isPending),
// // // //     );
// // // //   }
// // // //
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       backgroundColor: const Color(0xFFF8F9FA),
// // // //       appBar: AppBar(
// // // //         backgroundColor: const Color(0xFF1E0E5C),
// // // //         leading: IconButton(
// // // //           icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
// // // //           onPressed: () => Navigator.pop(context),
// // // //         ),
// // // //         title: const Text(
// // // //           "Pilot Booking Status",
// // // //           style: TextStyle(color: Colors.white),
// // // //         ),
// // // //         bottom: TabBar(
// // // //           controller: _tabController,
// // // //           indicatorColor: Colors.white,
// // // //           labelColor: Colors.white,
// // // //           unselectedLabelColor: Colors.white.withOpacity(0.7),
// // // //           tabs: const [
// // // //             Tab(text: "Approved"),
// // // //             Tab(text: "Pending"),
// // // //             Tab(text: "Rejected"),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //       body: TabBarView(
// // // //         controller: _tabController,
// // // //         children: [
// // // //           buildTab(getApprovedQuery),
// // // //           buildTab(getPendingQuery, isPending: true),
// // // //           buildTab(getRejectedQuery),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   @override
// // // //   void dispose() {
// // // //     _tabController.dispose();
// // // //     super.dispose();
// // // //   }
// // // // }
// // //
// // //
// // // import 'package:flutter/material.dart';
// // // import 'package:graphql_flutter/graphql_flutter.dart';
// // // import 'package:permission_handler/permission_handler.dart';
// // // import '../../config/env.dart';
// // // import 'package:intl/intl.dart';
// // // import 'package:url_launcher/url_launcher.dart';
// // //
// // // class PilotBookingStatusPage extends StatefulWidget {
// // //   final String buyerId;
// // //
// // //   const PilotBookingStatusPage({super.key, required this.buyerId});
// // //
// // //   @override
// // //   State<PilotBookingStatusPage> createState() =>
// // //       _PilotBookingStatusPageState();
// // // }
// // //
// // // class _PilotBookingStatusPageState extends State<PilotBookingStatusPage>
// // //     with SingleTickerProviderStateMixin {
// // //   late TabController _tabController;
// // //   late GraphQLClient client;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _tabController = TabController(length: 3, vsync: this);
// // //
// // //     client = GraphQLClient(
// // //       link: HttpLink(EnvConfig.baseUrl),
// // //       cache: GraphQLCache(),
// // //     );
// // //   }
// // //
// // //   // Function to make phone call
// // //   Future<void> _makePhoneCall(String phoneNumber) async {
// // //     PermissionStatus status = await Permission.phone.status;
// // //
// // //     if (!status.isGranted) {
// // //       final allow = await showDialog<bool>(
// // //         context: context,
// // //         builder: (_) => AlertDialog(
// // //           title: const Text("Call Permission Required"),
// // //           content: const Text(
// // //             "Flyhub needs phone permission to call the seller directly.",
// // //           ),
// // //           actions: [
// // //             TextButton(
// // //               onPressed: () => Navigator.pop(context, false),
// // //               child: const Text("Cancel"),
// // //             ),
// // //             TextButton(
// // //               onPressed: () => Navigator.pop(context, true),
// // //               child: const Text("Allow"),
// // //             ),
// // //           ],
// // //         ),
// // //       );
// // //
// // //       if (allow != true) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(
// // //             content: Text("Call permission denied"),
// // //             backgroundColor: Colors.red,
// // //           ),
// // //         );
// // //         return;
// // //       }
// // //
// // //       status = await Permission.phone.request();
// // //     }
// // //
// // //     if (status.isPermanentlyDenied) {
// // //       showDialog(
// // //         context: context,
// // //         builder: (_) => AlertDialog(
// // //           title: const Text("Permission Disabled"),
// // //           content: const Text(
// // //             "Phone permission is permanently denied. Please enable it from app settings.",
// // //           ),
// // //           actions: [
// // //             TextButton(
// // //               onPressed: () => Navigator.pop(context),
// // //               child: const Text("Cancel"),
// // //             ),
// // //             TextButton(
// // //               onPressed: () {
// // //                 Navigator.pop(context);
// // //                 openAppSettings();
// // //               },
// // //               child: const Text("Open Settings"),
// // //             ),
// // //           ],
// // //         ),
// // //       );
// // //       return;
// // //     }
// // //
// // //     if (status.isGranted) {
// // //       final Uri launchUri = Uri(
// // //         scheme: 'tel',
// // //         path: phoneNumber,
// // //       );
// // //
// // //       if (await canLaunchUrl(launchUri)) {
// // //         await launchUrl(launchUri);
// // //       } else {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(
// // //             content: Text('Could not launch $phoneNumber'),
// // //             backgroundColor: Colors.red,
// // //           ),
// // //         );
// // //       }
// // //     }
// // //   }
// // //
// // //   // --------------------------------------------
// // //   // UPDATED QUERIES - Get ALL bookings for buyer (both as booker and pilot owner)
// // //   // --------------------------------------------
// // //   String getApprovedQuery() => '''
// // //     query {
// // //       getBuyerPilotBookings(buyerId: "${widget.buyerId}", status: "approved") {
// // //         bookingId
// // //         pilotId
// // //         pilotName
// // //         buyerName
// // //         location
// // //         date
// // //         startTime
// // //         endTime
// // //         status
// // //         pilotType
// // //
// // //         # For seller pilots
// // //         sellerName
// // //         sellerPhone
// // //
// // //         # For buyer pilots - we need owner info
// // //         pilotOwnerId
// // //         pilotOwnerType
// // //
// // //         # Include contact info
// // //         contact
// // //         totalAmount
// // //         duration
// // //       }
// // //     }
// // //   ''';
// // //
// // //   String getPendingQuery() => '''
// // //     query {
// // //       getBuyerPilotBookings(buyerId: "${widget.buyerId}", status: "pending") {
// // //         bookingId
// // //         pilotId
// // //         pilotName
// // //         buyerName
// // //         location
// // //         date
// // //         startTime
// // //         endTime
// // //         status
// // //         pilotType
// // //         pilotOwnerId
// // //         pilotOwnerType
// // //         contact
// // //         totalAmount
// // //       }
// // //     }
// // //   ''';
// // //
// // //   String getRejectedQuery() => '''
// // //     query {
// // //       getBuyerPilotBookings(buyerId: "${widget.buyerId}", status: "rejected") {
// // //         bookingId
// // //         pilotId
// // //         pilotName
// // //         buyerName
// // //         location
// // //         date
// // //         startTime
// // //         endTime
// // //         status
// // //         pilotType
// // //         pilotOwnerId
// // //         pilotOwnerType
// // //         contact
// // //         totalAmount
// // //       }
// // //     }
// // //   ''';
// // //
// // //   // Helper function to get contact info based on pilot type
// // //   Future<Map<String, String>> _getContactInfo(Map<String, dynamic> booking) async {
// // //     String contactName = "Unknown";
// // //     String contactPhone = "--";
// // //
// // //     final pilotType = booking['pilotType'] ?? 'seller';
// // //
// // //     // For seller pilots, use seller info
// // //     if (pilotType == 'seller') {
// // //       contactName = booking['sellerName'] ?? 'Seller';
// // //       contactPhone = booking['sellerPhone'] ?? '--';
// // //     }
// // //     // For buyer pilots, we need to fetch buyer info
// // //     else if (pilotType == 'buyer') {
// // //       final pilotOwnerId = booking['pilotOwnerId'];
// // //       if (pilotOwnerId != null) {
// // //         try {
// // //           // Query to get buyer details
// // //           final buyerQuery = '''
// // //             query {
// // //               getBuyerById(buyerId: "$pilotOwnerId") {
// // //                 name
// // //                 phoneNumber
// // //               }
// // //             }
// // //           ''';
// // //
// // //           final result = await client.query(QueryOptions(
// // //             document: gql(buyerQuery),
// // //             fetchPolicy: FetchPolicy.networkOnly,
// // //           ));
// // //
// // //           if (result.hasException) {
// // //             debugPrint("Error fetching buyer info: ${result.exception}");
// // //           } else {
// // //             final buyerData = result.data?['getBuyerById'];
// // //             if (buyerData != null) {
// // //               contactName = buyerData['name'] ?? 'Buyer Pilot Owner';
// // //               contactPhone = buyerData['phoneNumber'] ?? '--';
// // //             }
// // //           }
// // //         } catch (e) {
// // //           debugPrint("Exception fetching buyer contact info: $e");
// // //         }
// // //       }
// // //     }
// // //
// // //     // Fallback to contact field if available
// // //     if (contactPhone == '--' && booking['contact'] != null) {
// // //       contactPhone = booking['contact'];
// // //     }
// // //
// // //     return {
// // //       'name': contactName,
// // //       'phone': contactPhone,
// // //     };
// // //   }
// // //
// // //   // Helper function to format date
// // //   String formatDate(String? dateString) {
// // //     if (dateString == null || dateString.isEmpty) {
// // //       return 'Date not available';
// // //     }
// // //
// // //     try {
// // //       DateTime date = DateTime.parse(dateString);
// // //       return DateFormat('dd MMM yyyy').format(date);
// // //     } catch (e) {
// // //       try {
// // //         if (dateString.length == 13 && int.tryParse(dateString) != null) {
// // //           DateTime date =
// // //           DateTime.fromMillisecondsSinceEpoch(int.parse(dateString));
// // //           return DateFormat('dd MMM yyyy').format(date);
// // //         }
// // //         return dateString;
// // //       } catch (e2) {
// // //         return dateString;
// // //       }
// // //     }
// // //   }
// // //
// // //   // Format time
// // //   String formatTime(String? timeString) {
// // //     if (timeString == null || timeString.isEmpty) {
// // //       return '--';
// // //     }
// // //     return timeString;
// // //   }
// // //
// // //   // --------------------------------------------
// // //   // STATUS COLORS
// // //   // --------------------------------------------
// // //   Color getStatusColor(String? status) {
// // //     switch (status?.toLowerCase() ?? "") {
// // //       case "approved":
// // //         return Colors.green;
// // //       case "rejected":
// // //         return Colors.red;
// // //       case "completed":
// // //         return Colors.blue;
// // //       case "pending":
// // //       default:
// // //         return const Color(0xFF1E0E5C);
// // //     }
// // //   }
// // //
// // //   // --------------------------------------------
// // //   // UPDATED BOOKING CARD UI
// // //   // --------------------------------------------
// // //   Widget buildBookingCard(Map<String, dynamic> b, {bool showDelete = false}) {
// // //     final status = b['status'] ?? "--";
// // //     final statusColor = getStatusColor(status);
// // //     final formattedDate = formatDate(b['date']);
// // //     final startTime = formatTime(b['startTime']);
// // //     final endTime = formatTime(b['endTime']);
// // //     final pilotName = b['pilotName'] ?? '--';
// // //     final buyerName = b['buyerName'] ?? '--';
// // //     final pilotType = b['pilotType'] ?? 'seller';
// // //     final totalAmount = b['totalAmount'] ?? 0;
// // //     final duration = b['duration'] ?? 0;
// // //
// // //     bool isApprovedTab = status.toLowerCase() == 'approved';
// // //     bool isPendingTab = status.toLowerCase() == 'pending';
// // //     bool isBuyerPilot = pilotType == 'buyer';
// // //
// // //     return FutureBuilder<Map<String, String>>(
// // //       future: _getContactInfo(b),
// // //       builder: (context, snapshot) {
// // //         final contactInfo = snapshot.data ?? {'name': 'Loading...', 'phone': '--'};
// // //         final contactName = contactInfo['name']!;
// // //         final contactPhone = contactInfo['phone']!;
// // //
// // //         return Container(
// // //           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // //           decoration: BoxDecoration(
// // //             color: Colors.white,
// // //             borderRadius: BorderRadius.circular(16),
// // //             border: Border.all(color: Colors.grey.shade300, width: 1),
// // //             boxShadow: [
// // //               BoxShadow(
// // //                 color: Colors.grey.withOpacity(0.1),
// // //                 blurRadius: 8,
// // //                 offset: const Offset(0, 2),
// // //               ),
// // //             ],
// // //           ),
// // //           child: Padding(
// // //             padding: const EdgeInsets.all(16),
// // //             child: Column(
// // //               crossAxisAlignment: CrossAxisAlignment.start,
// // //               children: [
// // //                 Row(
// // //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                   children: [
// // //                     Expanded(
// // //                       child: Text(
// // //                         pilotName,
// // //                         style: const TextStyle(
// // //                           fontSize: 16,
// // //                           fontWeight: FontWeight.w700,
// // //                           color: Color(0xFF1E0E5C),
// // //                         ),
// // //                         overflow: TextOverflow.ellipsis,
// // //                       ),
// // //                     ),
// // //                     if (isBuyerPilot)
// // //                       Container(
// // //                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // //                         decoration: BoxDecoration(
// // //                           color: const Color(0xFF1E0E5C).withOpacity(0.1),
// // //                           borderRadius: BorderRadius.circular(8),
// // //                         ),
// // //                         child: Text(
// // //                           "Buyer Pilot",
// // //                           style: TextStyle(
// // //                             fontSize: 10,
// // //                             fontWeight: FontWeight.w600,
// // //                             color: const Color(0xFF1E0E5C),
// // //                           ),
// // //                         ),
// // //                       ),
// // //                   ],
// // //                 ),
// // //
// // //                 const SizedBox(height: 12),
// // //                 Divider(color: Colors.grey.shade300, height: 1),
// // //                 const SizedBox(height: 12),
// // //
// // //                 Row(
// // //                   children: [
// // //                     Expanded(
// // //                       child: Row(
// // //                         children: [
// // //                           Container(
// // //                             width: 54,
// // //                             height: 54,
// // //                             decoration: BoxDecoration(
// // //                               color: const Color(0xFF1E0E5C).withOpacity(0.15),
// // //                               borderRadius: BorderRadius.circular(16),
// // //                             ),
// // //                             child: Icon(
// // //                               Icons.person,
// // //                               size: 28,
// // //                               color: const Color(0xFF1E0E5C),
// // //                             ),
// // //                           ),
// // //                           const SizedBox(width: 16),
// // //                           Expanded(
// // //                             child: Column(
// // //                               crossAxisAlignment: CrossAxisAlignment.start,
// // //                               children: [
// // //                                 // Contact info for approved bookings
// // //                                 if (isApprovedTab && contactName != 'Loading...') ...[
// // //                                   _buildDetailRow(
// // //                                     icon: Icons.person,
// // //                                     text: contactName,
// // //                                     iconColor: const Color(0xFF1E0E5C),
// // //                                   ),
// // //                                   const SizedBox(height: 6),
// // //                                 ],
// // //                                 if (isApprovedTab && contactPhone != '--' && contactPhone.isNotEmpty) ...[
// // //                                   _buildDetailRow(
// // //                                     icon: Icons.phone,
// // //                                     text: contactPhone,
// // //                                     iconColor: Colors.blue,
// // //                                   ),
// // //                                   const SizedBox(height: 6),
// // //                                 ],
// // //
// // //                                 // Booking details
// // //                                 _buildDetailRow(
// // //                                   icon: Icons.calendar_today,
// // //                                   text: formattedDate,
// // //                                   iconColor: Colors.orange,
// // //                                 ),
// // //                                 const SizedBox(height: 6),
// // //                                 _buildDetailRow(
// // //                                   icon: Icons.access_time,
// // //                                   text: "$startTime - $endTime",
// // //                                   iconColor: Colors.purple,
// // //                                 ),
// // //                                 const SizedBox(height: 6),
// // //                                 if (duration > 0)
// // //                                   _buildDetailRow(
// // //                                     icon: Icons.timer,
// // //                                     text: "${duration.toStringAsFixed(1)} hours",
// // //                                     iconColor: Colors.teal,
// // //                                   ),
// // //                                 const SizedBox(height: 6),
// // //                                 if (totalAmount > 0)
// // //                                   _buildDetailRow(
// // //                                     icon: Icons.currency_rupee,
// // //                                     text: "₹${totalAmount.toStringAsFixed(2)}",
// // //                                     iconColor: Colors.green,
// // //                                   ),
// // //                                 const SizedBox(height: 6),
// // //                                 if (b['location'] != null && b['location'].isNotEmpty)
// // //                                   _buildDetailRow(
// // //                                     icon: Icons.location_on,
// // //                                     text: b['location'] ?? '--',
// // //                                     iconColor: Colors.red,
// // //                                   ),
// // //
// // //                                 // Pilot type indicator
// // //                                 if (isBuyerPilot)
// // //                                   Padding(
// // //                                     padding: const EdgeInsets.only(top: 4),
// // //                                     child: Text(
// // //                                       "📱 Booked from another buyer's pilot listing",
// // //                                       style: TextStyle(
// // //                                         fontSize: 11,
// // //                                         color: Colors.grey[600],
// // //                                         fontStyle: FontStyle.italic,
// // //                                       ),
// // //                                     ),
// // //                                   ),
// // //                               ],
// // //                             ),
// // //                           ),
// // //                         ],
// // //                       ),
// // //                     ),
// // //                     Column(
// // //                       children: [
// // //                         if (isApprovedTab && contactPhone != '--' && contactPhone.isNotEmpty)
// // //                           ElevatedButton.icon(
// // //                             onPressed: () => _makePhoneCall(contactPhone),
// // //                             icon: const Icon(Icons.phone, size: 16),
// // //                             label: const Text("Call Now"),
// // //                             style: ElevatedButton.styleFrom(
// // //                               backgroundColor: Colors.green,
// // //                               foregroundColor: Colors.white,
// // //                               shape: RoundedRectangleBorder(
// // //                                 borderRadius: BorderRadius.circular(12),
// // //                               ),
// // //                               padding: const EdgeInsets.symmetric(
// // //                                 horizontal: 16,
// // //                                 vertical: 10,
// // //                               ),
// // //                               elevation: 0,
// // //                             ),
// // //                           ),
// // //                         if (isPendingTab && showDelete)
// // //                           IconButton(
// // //                             onPressed: () {
// // //                               showDialog(
// // //                                 context: context,
// // //                                 builder: (context) => AlertDialog(
// // //                                   title: const Text("Delete Booking"),
// // //                                   content: const Text(
// // //                                       "Are you sure you want to delete this pending booking?"),
// // //                                   actions: [
// // //                                     TextButton(
// // //                                       onPressed: () => Navigator.pop(context),
// // //                                       child: const Text("Cancel"),
// // //                                     ),
// // //                                     TextButton(
// // //                                       onPressed: () async {
// // //                                         Navigator.pop(context);
// // //                                         await _deleteBooking(b['bookingId']);
// // //                                       },
// // //                                       child: const Text(
// // //                                         "Delete",
// // //                                         style: TextStyle(color: Colors.red),
// // //                                       ),
// // //                                     ),
// // //                                   ],
// // //                                 ),
// // //                               );
// // //                             },
// // //                             icon: Icon(
// // //                               Icons.delete_outline,
// // //                               color: Colors.red.shade600,
// // //                               size: 28,
// // //                             ),
// // //                           ),
// // //                       ],
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         );
// // //       },
// // //     );
// // //   }
// // //
// // //   Widget _buildDetailRow({
// // //     required IconData icon,
// // //     required String text,
// // //     required Color iconColor,
// // //   }) {
// // //     return Row(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Icon(
// // //           icon,
// // //           size: 16,
// // //           color: iconColor,
// // //         ),
// // //         const SizedBox(width: 8),
// // //         Expanded(
// // //           child: Text(
// // //             text,
// // //             style: const TextStyle(
// // //               fontSize: 13,
// // //               color: Colors.black87,
// // //             ),
// // //             maxLines: 2,
// // //             overflow: TextOverflow.ellipsis,
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   // ✅ FIXED: Delete booking method - shows only "Network Error"
// // //   Future<void> _deleteBooking(String bookingId) async {
// // //     try {
// // //       final result = await client.mutate(
// // //         MutationOptions(
// // //           document: gql(_deletePendingBookingMutation()),
// // //           variables: {
// // //             'bookingId': bookingId,
// // //             'buyerId': widget.buyerId,
// // //           },
// // //         ),
// // //       );
// // //
// // //       final response = result.data?['deletePilotBookingByBuyer'];
// // //
// // //       if (response != null && response['success'] == true) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(
// // //             content: Text("Booking deleted successfully"),
// // //             backgroundColor: Colors.green,
// // //           ),
// // //         );
// // //         setState(() {});
// // //       } else {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(
// // //             content: Text("Network Error"),
// // //             backgroundColor: Colors.red,
// // //           ),
// // //         );
// // //       }
// // //     } catch (e) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(
// // //           content: Text("Network Error"),
// // //           backgroundColor: Colors.red,
// // //         ),
// // //       );
// // //     }
// // //   }
// // //
// // //   String _deletePendingBookingMutation() => '''
// // //     mutation DeletePendingBooking(\$bookingId: String!, \$buyerId: String!) {
// // //       deletePilotBookingByBuyer(
// // //         bookingId: \$bookingId,
// // //         buyerId: \$buyerId
// // //       ) {
// // //         success
// // //         message
// // //       }
// // //     }
// // //   ''';
// // //
// // //   // --------------------------------------------
// // //   // TAB VIEW BUILDER WITH REFRESH INDICATOR
// // //   // --------------------------------------------
// // //   Widget buildTab(String Function() queryBuilder, {bool isPending = false}) {
// // //     return Query(
// // //       options: QueryOptions(
// // //         document: gql(queryBuilder()),
// // //         pollInterval: const Duration(seconds: 3),
// // //       ),
// // //       builder: (result, {refetch, fetchMore}) {
// // //         return RefreshIndicator(
// // //           onRefresh: () async {
// // //             if (refetch != null) {
// // //               await refetch();
// // //             }
// // //           },
// // //           child: _buildTabContent(result, isPending, refetch),
// // //         );
// // //       },
// // //     );
// // //   }
// // //
// // //   Widget _buildTabContent(QueryResult result, bool isPending, Future<QueryResult?> Function()? refetch) {
// // //     if (result.isLoading && result.data == null) {
// // //       return const Center(child: CircularProgressIndicator());
// // //     }
// // //
// // //     // ✅ FIXED: Show ONLY "Network Error" - NO icons, NO technical details
// // //     if (result.hasException) {
// // //       return RefreshIndicator(
// // //         onRefresh: () async {
// // //           if (refetch != null) {
// // //             await refetch!();
// // //           }
// // //         },
// // //         child: Center(
// // //           child: Column(
// // //             mainAxisAlignment: MainAxisAlignment.center,
// // //             children: [
// // //               const Text(
// // //                 "Network Error",
// // //                 style: TextStyle(
// // //                   fontSize: 18,
// // //                   fontWeight: FontWeight.w600,
// // //                   color: Colors.grey,
// // //                 ),
// // //               ),
// // //               const SizedBox(height: 16),
// // //               const Text(
// // //                 "Please check your connection and try again",
// // //                 style: TextStyle(color: Colors.grey),
// // //                 textAlign: TextAlign.center,
// // //               ),
// // //               const SizedBox(height: 24),
// // //               ElevatedButton(
// // //                 onPressed: refetch,
// // //                 style: ElevatedButton.styleFrom(
// // //                   backgroundColor: const Color(0xFF1E0E5C),
// // //                   foregroundColor: Colors.white,
// // //                 ),
// // //                 child: const Text("Retry"),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       );
// // //     }
// // //
// // //     final data = result.data ?? {};
// // //
// // //     String key = data.keys.firstWhere(
// // //           (k) => k != "__typename",
// // //       orElse: () => "",
// // //     );
// // //
// // //     final list = (data[key] ?? []) as List;
// // //
// // //     if (list.isEmpty) {
// // //       return RefreshIndicator(
// // //         onRefresh: () async {
// // //           if (refetch != null) {
// // //             await refetch();
// // //           }
// // //         },
// // //         child: ListView(
// // //           children: [
// // //             SizedBox(
// // //               height: MediaQuery.of(context).size.height * 0.7,
// // //               child: const Center(
// // //                 child: Text("No bookings found",
// // //                     style: TextStyle(color: Colors.grey)),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       );
// // //     }
// // //
// // //     return ListView.builder(
// // //       itemCount: list.length,
// // //       itemBuilder: (_, i) => buildBookingCard(list[i], showDelete: isPending),
// // //     );
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       backgroundColor: const Color(0xFFF8F9FA),
// // //       appBar: AppBar(
// // //         backgroundColor: const Color(0xFF1E0E5C),
// // //         leading: IconButton(
// // //           icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
// // //           onPressed: () => Navigator.pop(context),
// // //         ),
// // //         title: const Text(
// // //           "My Pilot Bookings",
// // //           style: TextStyle(color: Colors.white),
// // //         ),
// // //         bottom: TabBar(
// // //           controller: _tabController,
// // //           indicatorColor: Colors.white,
// // //           labelColor: Colors.white,
// // //           unselectedLabelColor: Colors.white.withOpacity(0.7),
// // //           tabs: const [
// // //             Tab(text: "Approved"),
// // //             Tab(text: "Pending"),
// // //             Tab(text: "Rejected"),
// // //           ],
// // //         ),
// // //       ),
// // //       body: TabBarView(
// // //         controller: _tabController,
// // //         children: [
// // //           buildTab(getApprovedQuery),
// // //           buildTab(getPendingQuery, isPending: true),
// // //           buildTab(getRejectedQuery),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   @override
// // //   void dispose() {
// // //     _tabController.dispose();
// // //     super.dispose();
// // //   }
// // // }
// //
// // import 'package:flutter/material.dart';
// // import 'package:graphql_flutter/graphql_flutter.dart';
// // import 'package:permission_handler/permission_handler.dart';
// // import '../../config/env.dart';
// // import 'package:intl/intl.dart';
// // import 'package:url_launcher/url_launcher.dart';
// //
// // class PilotBookingStatusPage extends StatefulWidget {
// //   final String buyerId;
// //
// //   const PilotBookingStatusPage({super.key, required this.buyerId});
// //
// //   @override
// //   State<PilotBookingStatusPage> createState() =>
// //       _PilotBookingStatusPageState();
// // }
// //
// // class _PilotBookingStatusPageState extends State<PilotBookingStatusPage>
// //     with SingleTickerProviderStateMixin {
// //   late TabController _tabController;
// //   late GraphQLClient client;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _tabController = TabController(length: 3, vsync: this);
// //
// //     client = GraphQLClient(
// //       link: HttpLink(EnvConfig.baseUrl),
// //       cache: GraphQLCache(),
// //     );
// //   }
// //
// //   // Function to make phone call
// //   Future<void> _makePhoneCall(String phoneNumber) async {
// //     PermissionStatus status = await Permission.phone.status;
// //
// //     if (!status.isGranted) {
// //       final allow = await showDialog<bool>(
// //         context: context,
// //         builder: (_) => AlertDialog(
// //           title: const Text("Call Permission Required"),
// //           content: const Text(
// //             "Flyhub needs phone permission to call the seller directly.",
// //           ),
// //           actions: [
// //             TextButton(
// //               onPressed: () => Navigator.pop(context, false),
// //               child: const Text("Cancel"),
// //             ),
// //             TextButton(
// //               onPressed: () => Navigator.pop(context, true),
// //               child: const Text("Allow"),
// //             ),
// //           ],
// //         ),
// //       );
// //
// //       if (allow != true) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text("Call permission denied"),
// //             backgroundColor: Colors.red,
// //           ),
// //         );
// //         return;
// //       }
// //
// //       status = await Permission.phone.request();
// //     }
// //
// //     if (status.isPermanentlyDenied) {
// //       showDialog(
// //         context: context,
// //         builder: (_) => AlertDialog(
// //           title: const Text("Permission Disabled"),
// //           content: const Text(
// //             "Phone permission is permanently denied. Please enable it from app settings.",
// //           ),
// //           actions: [
// //             TextButton(
// //               onPressed: () => Navigator.pop(context),
// //               child: const Text("Cancel"),
// //             ),
// //             TextButton(
// //               onPressed: () {
// //                 Navigator.pop(context);
// //                 openAppSettings();
// //               },
// //               child: const Text("Open Settings"),
// //             ),
// //           ],
// //         ),
// //       );
// //       return;
// //     }
// //
// //     if (status.isGranted) {
// //       final Uri launchUri = Uri(
// //         scheme: 'tel',
// //         path: phoneNumber,
// //       );
// //
// //       if (await canLaunchUrl(launchUri)) {
// //         await launchUrl(launchUri);
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('Could not launch $phoneNumber'),
// //             backgroundColor: Colors.red,
// //           ),
// //         );
// //       }
// //     }
// //   }
// //
// //   // --------------------------------------------
// //   // UPDATED QUERIES - Get bookings with owner contact info
// //   // --------------------------------------------
// //   String getApprovedQuery() => '''
// //     query {
// //       getBuyerApprovedPilotBookings(buyerId: "${widget.buyerId}") {
// //         bookingId
// //         pilotId
// //         pilotName
// //         buyerName
// //         location
// //         date
// //         startTime
// //         endTime
// //         status
// //         pilotType
// //
// //         # For seller pilots
// //         sellerName
// //         sellerPhone
// //
// //         # For buyer pilots - owner contact info
// //         pilotOwnerId
// //         pilotOwnerType
// //         contact
// //
// //         # Additional info
// //         totalAmount
// //         duration
// //         createdAt
// //       }
// //     }
// //   ''';
// //
// //   String getPendingQuery() => '''
// //     query {
// //       getBuyerPendingPilotBookings(buyerId: "${widget.buyerId}") {
// //         bookingId
// //         pilotId
// //         pilotName
// //         buyerName
// //         location
// //         date
// //         startTime
// //         endTime
// //         status
// //         pilotType
// //         pilotOwnerId
// //         pilotOwnerType
// //         contact
// //         totalAmount
// //       }
// //     }
// //   ''';
// //
// //   String getRejectedQuery() => '''
// //     query {
// //       getBuyerRejectedPilotBookings(buyerId: "${widget.buyerId}") {
// //         bookingId
// //         pilotId
// //         pilotName
// //         buyerName
// //         location
// //         date
// //         startTime
// //         endTime
// //         status
// //         pilotType
// //         pilotOwnerId
// //         pilotOwnerType
// //         contact
// //         totalAmount
// //       }
// //     }
// //   ''';
// //
// //   // Helper function to get contact info
// //   Future<Map<String, String>> _getContactInfo(Map<String, dynamic> booking) async {
// //     final pilotType = booking['pilotType'] ?? 'seller';
// //
// //     // For seller pilots
// //     if (pilotType == 'seller') {
// //       return {
// //         'name': booking['sellerName'] ?? 'Seller',
// //         'phone': booking['sellerPhone'] ?? '--',
// //       };
// //     }
// //     // For buyer pilots
// //     else if (pilotType == 'buyer') {
// //       final pilotOwnerId = booking['pilotOwnerId'];
// //
// //       if (pilotOwnerId != null && pilotOwnerId.isNotEmpty) {
// //         try {
// //           // First, try to get buyer details from the database
// //           final buyerQuery = '''
// //             query GetBuyerDetails {
// //               getBuyer(buyerId: "$pilotOwnerId") {
// //                 name
// //                 phoneNumber
// //               }
// //             }
// //           ''';
// //
// //           final result = await client.query(QueryOptions(
// //             document: gql(buyerQuery),
// //             fetchPolicy: FetchPolicy.networkOnly,
// //           ));
// //
// //           if (!result.hasException && result.data != null) {
// //             final buyerData = result.data?['getBuyer'];
// //             if (buyerData != null) {
// //               return {
// //                 'name': buyerData['name'] ?? 'Buyer Pilot Owner',
// //                 'phone': buyerData['phoneNumber'] ?? '--',
// //               };
// //             }
// //           }
// //         } catch (e) {
// //           debugPrint("Error fetching buyer details: $e");
// //         }
// //       }
// //
// //       // Fallback: use contact field or default values
// //       return {
// //         'name': 'Buyer Pilot Owner',
// //         'phone': booking['contact'] ?? '--',
// //       };
// //     }
// //
// //     // Default fallback
// //     return {
// //       'name': 'Contact',
// //       'phone': '--',
// //     };
// //   }
// //
// //   // Helper function to format date
// //   String formatDate(String? dateString) {
// //     if (dateString == null || dateString.isEmpty) {
// //       return 'Date not available';
// //     }
// //
// //     try {
// //       DateTime date = DateTime.parse(dateString);
// //       return DateFormat('dd MMM yyyy').format(date);
// //     } catch (e) {
// //       try {
// //         if (dateString.length == 13 && int.tryParse(dateString) != null) {
// //           DateTime date =
// //           DateTime.fromMillisecondsSinceEpoch(int.parse(dateString));
// //           return DateFormat('dd MMM yyyy').format(date);
// //         }
// //         return dateString;
// //       } catch (e2) {
// //         return dateString;
// //       }
// //     }
// //   }
// //
// //   // Format time
// //   String formatTime(String? timeString) {
// //     if (timeString == null || timeString.isEmpty) {
// //       return '--';
// //     }
// //     return timeString;
// //   }
// //
// //   // --------------------------------------------
// //   // STATUS COLORS
// //   // --------------------------------------------
// //   Color getStatusColor(String? status) {
// //     switch (status?.toLowerCase() ?? "") {
// //       case "approved":
// //         return Colors.green;
// //       case "rejected":
// //         return Colors.red;
// //       case "completed":
// //         return Colors.blue;
// //       case "pending":
// //       default:
// //         return const Color(0xFF1E0E5C);
// //     }
// //   }
// //
// //   // --------------------------------------------
// //   // BOOKING CARD UI
// //   // --------------------------------------------
// //   Widget buildBookingCard(Map<String, dynamic> b, {bool showDelete = false}) {
// //     final status = b['status'] ?? "--";
// //     final statusColor = getStatusColor(status);
// //     final formattedDate = formatDate(b['date']);
// //     final startTime = formatTime(b['startTime']);
// //     final endTime = formatTime(b['endTime']);
// //     final pilotName = b['pilotName'] ?? '--';
// //     final pilotType = b['pilotType'] ?? 'seller';
// //     final totalAmount = b['totalAmount'] ?? 0;
// //     final duration = b['duration'] ?? 0;
// //     final location = b['location'] ?? '--';
// //
// //     bool isApprovedTab = status.toLowerCase() == 'approved';
// //     bool isPendingTab = status.toLowerCase() == 'pending';
// //     bool isBuyerPilot = pilotType == 'buyer';
// //
// //     return FutureBuilder<Map<String, String>>(
// //       future: _getContactInfo(b),
// //       builder: (context, snapshot) {
// //         final contactInfo = snapshot.data ?? {'name': 'Loading...', 'phone': '--'};
// //         final contactName = contactInfo['name']!;
// //         final contactPhone = contactInfo['phone']!;
// //
// //         return Container(
// //           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //           decoration: BoxDecoration(
// //             color: Colors.white,
// //             borderRadius: BorderRadius.circular(16),
// //             border: Border.all(color: Colors.grey.shade300, width: 1),
// //             boxShadow: [
// //               BoxShadow(
// //                 color: Colors.grey.withOpacity(0.1),
// //                 blurRadius: 8,
// //                 offset: const Offset(0, 2),
// //               ),
// //             ],
// //           ),
// //           child: Padding(
// //             padding: const EdgeInsets.all(16),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Row(
// //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                   children: [
// //                     Expanded(
// //                       child: Text(
// //                         pilotName,
// //                         style: const TextStyle(
// //                           fontSize: 16,
// //                           fontWeight: FontWeight.w700,
// //                           color: Color(0xFF1E0E5C),
// //                         ),
// //                         overflow: TextOverflow.ellipsis,
// //                       ),
// //                     ),
// //                     if (isBuyerPilot)
// //                       Container(
// //                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// //                         decoration: BoxDecoration(
// //                           color: Colors.orange.withOpacity(0.1),
// //                           borderRadius: BorderRadius.circular(8),
// //                         ),
// //                         child: Text(
// //                           "Buyer Pilot",
// //                           style: TextStyle(
// //                             fontSize: 10,
// //                             fontWeight: FontWeight.w600,
// //                             color: Colors.orange,
// //                           ),
// //                         ),
// //                       ),
// //                   ],
// //                 ),
// //
// //                 const SizedBox(height: 12),
// //                 Divider(color: Colors.grey.shade300, height: 1),
// //                 const SizedBox(height: 12),
// //
// //                 Row(
// //                   children: [
// //                     Container(
// //                       width: 54,
// //                       height: 54,
// //                       decoration: BoxDecoration(
// //                         color: const Color(0xFF1E0E5C).withOpacity(0.15),
// //                         borderRadius: BorderRadius.circular(16),
// //                       ),
// //                       child: Icon(
// //                         isBuyerPilot ? Icons.person : Icons.business,
// //                         size: 28,
// //                         color: const Color(0xFF1E0E5C),
// //                       ),
// //                     ),
// //                     const SizedBox(width: 16),
// //                     Expanded(
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           // Contact info for approved bookings
// //                           if (isApprovedTab && contactName != 'Loading...') ...[
// //                             _buildDetailRow(
// //                               icon: Icons.person,
// //                               text: contactName,
// //                               iconColor: const Color(0xFF1E0E5C),
// //                             ),
// //                             const SizedBox(height: 6),
// //                           ],
// //                           if (isApprovedTab && contactPhone != '--' && contactPhone.isNotEmpty) ...[
// //                             _buildDetailRow(
// //                               icon: Icons.phone,
// //                               text: contactPhone,
// //                               iconColor: Colors.blue,
// //                             ),
// //                             const SizedBox(height: 6),
// //                           ],
// //
// //                           // Booking details
// //                           _buildDetailRow(
// //                             icon: Icons.calendar_today,
// //                             text: formattedDate,
// //                             iconColor: Colors.orange,
// //                           ),
// //                           const SizedBox(height: 6),
// //                           _buildDetailRow(
// //                             icon: Icons.access_time,
// //                             text: "$startTime - $endTime",
// //                             iconColor: Colors.purple,
// //                           ),
// //                           const SizedBox(height: 6),
// //                           if (duration > 0)
// //                             _buildDetailRow(
// //                               icon: Icons.timer,
// //                               text: "${duration.toStringAsFixed(1)} hours",
// //                               iconColor: Colors.teal,
// //                             ),
// //                           const SizedBox(height: 6),
// //                           if (totalAmount > 0)
// //                             _buildDetailRow(
// //                               icon: Icons.currency_rupee,
// //                               text: "₹${totalAmount.toStringAsFixed(2)}",
// //                               iconColor: Colors.green,
// //                             ),
// //                           const SizedBox(height: 6),
// //                           if (location.isNotEmpty && location != '--')
// //                             _buildDetailRow(
// //                               icon: Icons.location_on,
// //                               text: location,
// //                               iconColor: Colors.red,
// //                             ),
// //                           const SizedBox(height: 6),
// //
// //                           // Pilot type indicator
// //                           if (isBuyerPilot)
// //                             _buildDetailRow(
// //                               icon: Icons.info_outline,
// //                               text: "Booked from another buyer's pilot listing",
// //                               iconColor: Colors.blueGrey,
// //                             ),
// //                         ],
// //                       ),
// //                     ),
// //                     Column(
// //                       children: [
// //                         if (isApprovedTab && contactPhone != '--' && contactPhone.isNotEmpty)
// //                           ElevatedButton.icon(
// //                             onPressed: () => _makePhoneCall(contactPhone),
// //                             icon: const Icon(Icons.phone, size: 16),
// //                             label: const Text("Call"),
// //                             style: ElevatedButton.styleFrom(
// //                               backgroundColor: Colors.green,
// //                               foregroundColor: Colors.white,
// //                               shape: RoundedRectangleBorder(
// //                                 borderRadius: BorderRadius.circular(12),
// //                               ),
// //                               padding: const EdgeInsets.symmetric(
// //                                 horizontal: 16,
// //                                 vertical: 10,
// //                               ),
// //                               elevation: 0,
// //                             ),
// //                           ),
// //                         if (isPendingTab && showDelete)
// //                           IconButton(
// //                             onPressed: () {
// //                               showDialog(
// //                                 context: context,
// //                                 builder: (context) => AlertDialog(
// //                                   title: const Text("Delete Booking"),
// //                                   content: const Text(
// //                                       "Are you sure you want to delete this pending booking?"),
// //                                   actions: [
// //                                     TextButton(
// //                                       onPressed: () => Navigator.pop(context),
// //                                       child: const Text("Cancel"),
// //                                     ),
// //                                     TextButton(
// //                                       onPressed: () async {
// //                                         Navigator.pop(context);
// //                                         await _deleteBooking(b['bookingId']);
// //                                       },
// //                                       child: const Text(
// //                                         "Delete",
// //                                         style: TextStyle(color: Colors.red),
// //                                       ),
// //                                     ),
// //                                   ],
// //                                 ),
// //                               );
// //                             },
// //                             icon: Icon(
// //                               Icons.delete_outline,
// //                               color: Colors.red.shade600,
// //                               size: 28,
// //                             ),
// //                           ),
// //                       ],
// //                     ),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //           ),
// //         );
// //       },
// //     );
// //   }
// //
// //   Widget _buildDetailRow({
// //     required IconData icon,
// //     required String text,
// //     required Color iconColor,
// //   }) {
// //     return Row(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Icon(
// //           icon,
// //           size: 16,
// //           color: iconColor,
// //         ),
// //         const SizedBox(width: 8),
// //         Expanded(
// //           child: Text(
// //             text,
// //             style: const TextStyle(
// //               fontSize: 13,
// //               color: Colors.black87,
// //             ),
// //             maxLines: 2,
// //             overflow: TextOverflow.ellipsis,
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   // Delete booking method
// //   Future<void> _deleteBooking(String bookingId) async {
// //     try {
// //       final result = await client.mutate(
// //         MutationOptions(
// //           document: gql(_deletePendingBookingMutation()),
// //           variables: {
// //             'bookingId': bookingId,
// //             'buyerId': widget.buyerId,
// //           },
// //         ),
// //       );
// //
// //       final response = result.data?['deletePilotBookingByBuyer'];
// //
// //       if (response != null && response['success'] == true) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text("Booking deleted successfully"),
// //             backgroundColor: Colors.green,
// //           ),
// //         );
// //         setState(() {});
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text("Network Error"),
// //             backgroundColor: Colors.red,
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(
// //           content: Text("Network Error"),
// //           backgroundColor: Colors.red,
// //         ),
// //       );
// //     }
// //   }
// //
// //   String _deletePendingBookingMutation() => '''
// //     mutation DeletePendingBooking(\$bookingId: String!, \$buyerId: String!) {
// //       deletePilotBookingByBuyer(
// //         bookingId: \$bookingId,
// //         buyerId: \$buyerId
// //       ) {
// //         success
// //         message
// //       }
// //     }
// //   ''';
// //
// //   // --------------------------------------------
// //   // TAB VIEW BUILDER WITH REFRESH INDICATOR
// //   // --------------------------------------------
// //   Widget buildTab(String Function() queryBuilder, {bool isPending = false}) {
// //     return Query(
// //       options: QueryOptions(
// //         document: gql(queryBuilder()),
// //         pollInterval: const Duration(seconds: 3),
// //       ),
// //       builder: (result, {refetch, fetchMore}) {
// //         return RefreshIndicator(
// //           onRefresh: () async {
// //             if (refetch != null) {
// //               await refetch();
// //             }
// //           },
// //           child: _buildTabContent(result, isPending, refetch),
// //         );
// //       },
// //     );
// //   }
// //
// //   Widget _buildTabContent(QueryResult result, bool isPending, Future<QueryResult?> Function()? refetch) {
// //     if (result.isLoading && result.data == null) {
// //       return const Center(child: CircularProgressIndicator());
// //     }
// //
// //     if (result.hasException) {
// //       return RefreshIndicator(
// //         onRefresh: () async {
// //           if (refetch != null) {
// //             await refetch!();
// //           }
// //         },
// //         child: Center(
// //           child: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               const Text(
// //                 "Network Error",
// //                 style: TextStyle(
// //                   fontSize: 18,
// //                   fontWeight: FontWeight.w600,
// //                   color: Colors.grey,
// //                 ),
// //               ),
// //               const SizedBox(height: 16),
// //               const Text(
// //                 "Please check your connection and try again",
// //                 style: TextStyle(color: Colors.grey),
// //                 textAlign: TextAlign.center,
// //               ),
// //               const SizedBox(height: 24),
// //               ElevatedButton(
// //                 onPressed: refetch,
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: const Color(0xFF1E0E5C),
// //                   foregroundColor: Colors.white,
// //                 ),
// //                 child: const Text("Retry"),
// //               ),
// //             ],
// //           ),
// //         ),
// //       );
// //     }
// //
// //     final data = result.data ?? {};
// //
// //     String key = data.keys.firstWhere(
// //           (k) => k != "__typename",
// //       orElse: () => "",
// //     );
// //
// //     final list = (data[key] ?? []) as List;
// //
// //     if (list.isEmpty) {
// //       return RefreshIndicator(
// //         onRefresh: () async {
// //           if (refetch != null) {
// //             await refetch();
// //           }
// //         },
// //         child: ListView(
// //           children: [
// //             SizedBox(
// //               height: MediaQuery.of(context).size.height * 0.7,
// //               child: const Center(
// //                 child: Text("No bookings found",
// //                     style: TextStyle(color: Colors.grey)),
// //               ),
// //             ),
// //           ],
// //         ),
// //       );
// //     }
// //
// //     return ListView.builder(
// //       itemCount: list.length,
// //       itemBuilder: (_, i) => buildBookingCard(list[i], showDelete: isPending),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF8F9FA),
// //       appBar: AppBar(
// //         backgroundColor: const Color(0xFF1E0E5C),
// //         leading: IconButton(
// //           icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
// //           onPressed: () => Navigator.pop(context),
// //         ),
// //         title: const Text(
// //           "My Pilot Bookings",
// //           style: TextStyle(color: Colors.white),
// //         ),
// //         bottom: TabBar(
// //           controller: _tabController,
// //           indicatorColor: Colors.white,
// //           labelColor: Colors.white,
// //           unselectedLabelColor: Colors.white.withOpacity(0.7),
// //           tabs: const [
// //             Tab(text: "Approved"),
// //             Tab(text: "Pending"),
// //             Tab(text: "Rejected"),
// //           ],
// //         ),
// //       ),
// //       body: TabBarView(
// //         controller: _tabController,
// //         children: [
// //           buildTab(getApprovedQuery),
// //           buildTab(getPendingQuery, isPending: true),
// //           buildTab(getRejectedQuery),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   @override
// //   void dispose() {
// //     _tabController.dispose();
// //     super.dispose();
// //   }
// // }
//
//
// import 'package:flutter/material.dart';
// import 'package:graphql_flutter/graphql_flutter.dart';
// import 'package:permission_handler/permission_handler.dart';
// import '../../config/env.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class PilotBookingStatusPage extends StatefulWidget {
//   final String buyerId;
//
//   const PilotBookingStatusPage({super.key, required this.buyerId});
//
//   @override
//   State<PilotBookingStatusPage> createState() =>
//       _PilotBookingStatusPageState();
// }
//
// class _PilotBookingStatusPageState extends State<PilotBookingStatusPage>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   late GraphQLClient client;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//
//     client = GraphQLClient(
//       link: HttpLink(EnvConfig.baseUrl),
//       cache: GraphQLCache(),
//     );
//   }
//
//   // Function to make phone call
//   Future<void> _makePhoneCall(String phoneNumber) async {
//     PermissionStatus status = await Permission.phone.status;
//
//     if (!status.isGranted) {
//       final allow = await showDialog<bool>(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text("Call Permission Required"),
//           content: const Text(
//             "Flyhub needs phone permission to call the seller directly.",
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text("Cancel"),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: const Text("Allow"),
//             ),
//           ],
//         ),
//       );
//
//       if (allow != true) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Call permission denied"),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
//
//       status = await Permission.phone.request();
//     }
//
//     if (status.isPermanentlyDenied) {
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text("Permission Disabled"),
//           content: const Text(
//             "Phone permission is permanently denied. Please enable it from app settings.",
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Cancel"),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 openAppSettings();
//               },
//               child: const Text("Open Settings"),
//             ),
//           ],
//         ),
//       );
//       return;
//     }
//
//     if (status.isGranted) {
//       final Uri launchUri = Uri(
//         scheme: 'tel',
//         path: phoneNumber,
//       );
//
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Could not launch $phoneNumber'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   // --------------------------------------------
//   // UPDATED QUERIES - Get bookings with pilot owner contact info
//   // --------------------------------------------
//   String getApprovedQuery() => '''
//     query {
//       getBuyerApprovedPilotBookings(buyerId: "${widget.buyerId}") {
//         bookingId
//         pilotId
//         pilotName
//         buyerName
//         location
//         date
//         startTime
//         endTime
//         status
//         pilotType
//
//         # For seller pilots
//         sellerName
//         sellerPhone
//
//         # For buyer pilots - owner contact info
//         pilotOwnerId
//         pilotOwnerType
//         contact
//
//         # Pilot owner details for buyer pilots
//         pilotOwnerName
//         pilotOwnerPhone
//
//         # Additional info
//         totalAmount
//         duration
//         createdAt
//       }
//     }
//   ''';
//
//   String getPendingQuery() => '''
//     query {
//       getBuyerPendingPilotBookings(buyerId: "${widget.buyerId}") {
//         bookingId
//         pilotId
//         pilotName
//         buyerName
//         location
//         date
//         startTime
//         endTime
//         status
//         pilotType
//
//         # For seller pilots
//         sellerName
//         sellerPhone
//
//         # For buyer pilots - owner contact info
//         pilotOwnerId
//         pilotOwnerType
//         contact
//
//         # Pilot owner details for buyer pilots
//         pilotOwnerName
//         pilotOwnerPhone
//
//         totalAmount
//       }
//     }
//   ''';
//
//   String getRejectedQuery() => '''
//     query {
//       getBuyerRejectedPilotBookings(buyerId: "${widget.buyerId}") {
//         bookingId
//         pilotId
//         pilotName
//         buyerName
//         location
//         date
//         startTime
//         endTime
//         status
//         pilotType
//
//         # For seller pilots
//         sellerName
//         sellerPhone
//
//         # For buyer pilots - owner contact info
//         pilotOwnerId
//         pilotOwnerType
//         contact
//
//         # Pilot owner details for buyer pilots
//         pilotOwnerName
//         pilotOwnerPhone
//
//         totalAmount
//       }
//     }
//   ''';
//
//   // Helper function to get contact info - FIXED VERSION
//   Future<Map<String, String>> _getContactInfo(Map<String, dynamic> booking) async {
//     final pilotType = booking['pilotType'] ?? 'seller';
//
//     // For seller pilots - show seller contact
//     if (pilotType == 'seller') {
//       return {
//         'name': booking['sellerName'] ?? 'Seller',
//         'phone': booking['sellerPhone'] ?? '--',
//       };
//     }
//     // For buyer pilots - show pilot owner (not the booking buyer)
//     else if (pilotType == 'buyer') {
//       // First, check if pilotOwnerName is already in the booking data
//       if (booking['pilotOwnerName'] != null && booking['pilotOwnerName'].toString().isNotEmpty) {
//         return {
//           'name': booking['pilotOwnerName']!,
//           'phone': booking['pilotOwnerPhone'] ?? booking['contact'] ?? '--',
//         };
//       }
//
//       // If not, fetch from database using pilotOwnerId
//       final pilotOwnerId = booking['pilotOwnerId'];
//
//       if (pilotOwnerId != null && pilotOwnerId.isNotEmpty) {
//         try {
//           // Fetch the actual pilot owner (buyer who listed the pilot)
//           final pilotOwnerQuery = '''
//             query GetPilotOwnerDetails {
//               buyer(buyerId: "$pilotOwnerId") {
//                 name
//                 phoneNumber
//               }
//             }
//           ''';
//
//           final result = await client.query(QueryOptions(
//             document: gql(pilotOwnerQuery),
//             fetchPolicy: FetchPolicy.networkOnly,
//           ));
//
//           if (!result.hasException && result.data != null) {
//             final pilotOwnerData = result.data?['buyer'];
//             if (pilotOwnerData != null) {
//               return {
//                 'name': pilotOwnerData['name'] ?? 'Pilot Owner',
//                 'phone': pilotOwnerData['phoneNumber'] ?? booking['contact'] ?? '--',
//               };
//             }
//           }
//         } catch (e) {
//           debugPrint("Error fetching pilot owner details: $e");
//         }
//       }
//
//       // Fallback: use contact field if available
//       return {
//         'name': booking['buyerName'] != widget.buyerId ? 'Pilot Owner' : 'You',
//         'phone': booking['contact'] ?? '--',
//       };
//     }
//
//     // Default fallback
//     return {
//       'name': 'Contact',
//       'phone': '--',
//     };
//   }
//
//   // Helper function to format date
//   String formatDate(String? dateString) {
//     if (dateString == null || dateString.isEmpty) {
//       return 'Date not available';
//     }
//
//     try {
//       DateTime date = DateTime.parse(dateString);
//       return DateFormat('dd MMM yyyy').format(date);
//     } catch (e) {
//       try {
//         if (dateString.length == 13 && int.tryParse(dateString) != null) {
//           DateTime date =
//           DateTime.fromMillisecondsSinceEpoch(int.parse(dateString));
//           return DateFormat('dd MMM yyyy').format(date);
//         }
//         return dateString;
//       } catch (e2) {
//         return dateString;
//       }
//     }
//   }
//
//   // Format time
//   String formatTime(String? timeString) {
//     if (timeString == null || timeString.isEmpty) {
//       return '--';
//     }
//     return timeString;
//   }
//
//   // --------------------------------------------
//   // STATUS COLORS
//   // --------------------------------------------
//   Color getStatusColor(String? status) {
//     switch (status?.toLowerCase() ?? "") {
//       case "approved":
//         return Colors.green;
//       case "rejected":
//         return Colors.red;
//       case "completed":
//         return Colors.blue;
//       case "pending":
//       default:
//         return const Color(0xFF1E0E5C);
//     }
//   }
//
//   // --------------------------------------------
//   // BOOKING CARD UI - UPDATED
//   // --------------------------------------------
//   Widget buildBookingCard(Map<String, dynamic> b, {bool showDelete = false}) {
//     final status = b['status'] ?? "--";
//     final statusColor = getStatusColor(status);
//     final formattedDate = formatDate(b['date']);
//     final startTime = formatTime(b['startTime']);
//     final endTime = formatTime(b['endTime']);
//     final pilotName = b['pilotName'] ?? '--';
//     final pilotType = b['pilotType'] ?? 'seller';
//     final totalAmount = b['totalAmount'] ?? 0;
//     final duration = b['duration'] ?? 0;
//     final location = b['location'] ?? '--';
//     final buyerName = b['buyerName'] ?? '--';
//
//     bool isApprovedTab = status.toLowerCase() == 'approved';
//     bool isPendingTab = status.toLowerCase() == 'pending';
//     bool isBuyerPilot = pilotType == 'buyer';
//
//     // Determine if current user is the pilot owner
//     bool isPilotOwner = isBuyerPilot && (b['pilotOwnerId'] == widget.buyerId);
//
//     return FutureBuilder<Map<String, String>>(
//       future: _getContactInfo(b),
//       builder: (context, snapshot) {
//         final contactInfo = snapshot.data ?? {'name': 'Loading...', 'phone': '--'};
//         final contactName = contactInfo['name']!;
//         final contactPhone = contactInfo['phone']!;
//
//         return Container(
//           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: Colors.grey.shade300, width: 1),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.grey.withOpacity(0.1),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Pilot Name Row
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Expanded(
//                       child: Text(
//                         pilotName,
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFF1E0E5C),
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     // Pilot Type Badge
//                     if (isBuyerPilot)
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: isPilotOwner ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(
//                           isPilotOwner ? "Your Pilot" : "Buyer Pilot",
//                           style: TextStyle(
//                             fontSize: 10,
//                             fontWeight: FontWeight.w600,
//                             color: isPilotOwner ? Colors.green : Colors.orange,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//
//                 // Booking Information Row
//                 const SizedBox(height: 12),
//                 Divider(color: Colors.grey.shade300, height: 1),
//                 const SizedBox(height: 12),
//
//                 Row(
//                   children: [
//                     // Icon
//                     Container(
//                       width: 54,
//                       height: 54,
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF1E0E5C).withOpacity(0.15),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Icon(
//                         isPilotOwner ? Icons.person_outline :
//                         (isBuyerPilot ? Icons.person : Icons.business),
//                         size: 28,
//                         color: const Color(0xFF1E0E5C),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Show who booked (for pilot owners)
//                           if (isPilotOwner && isApprovedTab)
//                             _buildDetailRow(
//                               icon: Icons.person_add,
//                               text: "Booked by: $buyerName",
//                               iconColor: Colors.purple,
//                             ),
//
//                           // Contact info for approved bookings (if not the owner)
//                           if (isApprovedTab && !isPilotOwner && contactName != 'Loading...') ...[
//                             _buildDetailRow(
//                               icon: Icons.person,
//                               text: "Contact: $contactName",
//                               iconColor: const Color(0xFF1E0E5C),
//                             ),
//                             const SizedBox(height: 6),
//                           ],
//
//                           // Phone number for approved bookings (if not the owner)
//                           if (isApprovedTab && !isPilotOwner && contactPhone != '--' && contactPhone.isNotEmpty) ...[
//                             _buildDetailRow(
//                               icon: Icons.phone,
//                               text: "Phone: $contactPhone",
//                               iconColor: Colors.blue,
//                             ),
//                             const SizedBox(height: 6),
//                           ],
//
//                           // Booking details
//                           _buildDetailRow(
//                             icon: Icons.calendar_today,
//                             text: "Date: $formattedDate",
//                             iconColor: Colors.orange,
//                           ),
//                           const SizedBox(height: 6),
//                           _buildDetailRow(
//                             icon: Icons.access_time,
//                             text: "Time: $startTime - $endTime",
//                             iconColor: Colors.purple,
//                           ),
//                           const SizedBox(height: 6),
//                           if (duration > 0)
//                             _buildDetailRow(
//                               icon: Icons.timer,
//                               text: "Duration: ${duration.toStringAsFixed(1)} hours",
//                               iconColor: Colors.teal,
//                             ),
//                           const SizedBox(height: 6),
//                           if (totalAmount > 0)
//                             _buildDetailRow(
//                               icon: Icons.currency_rupee,
//                               text: "Amount: ₹${totalAmount.toStringAsFixed(2)}",
//                               iconColor: Colors.green,
//                             ),
//                           const SizedBox(height: 6),
//                           if (location.isNotEmpty && location != '--')
//                             _buildDetailRow(
//                               icon: Icons.location_on,
//                               text: "Location: $location",
//                               iconColor: Colors.red,
//                             ),
//                           const SizedBox(height: 6),
//
//                           // Pilot type indicator
//                           if (isBuyerPilot && !isPilotOwner)
//                             _buildDetailRow(
//                               icon: Icons.info_outline,
//                               text: "Booked from another buyer's pilot listing",
//                               iconColor: Colors.blueGrey,
//                             ),
//                         ],
//                       ),
//                     ),
//                     // Action Buttons Column
//                     Column(
//                       children: [
//                         // Call button for approved bookings (if not the owner)
//                         if (isApprovedTab && !isPilotOwner && contactPhone != '--' && contactPhone.isNotEmpty)
//                           ElevatedButton.icon(
//                             onPressed: () => _makePhoneCall(contactPhone),
//                             icon: const Icon(Icons.phone, size: 16),
//                             label: const Text("Call"),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.green,
//                               foregroundColor: Colors.white,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 10,
//                               ),
//                               elevation: 0,
//                             ),
//                           ),
//                         // Delete button for pending bookings
//                         if (isPendingTab && showDelete && !isPilotOwner)
//                           IconButton(
//                             onPressed: () {
//                               showDialog(
//                                 context: context,
//                                 builder: (context) => AlertDialog(
//                                   title: const Text("Delete Booking"),
//                                   content: const Text(
//                                       "Are you sure you want to delete this pending booking?"),
//                                   actions: [
//                                     TextButton(
//                                       onPressed: () => Navigator.pop(context),
//                                       child: const Text("Cancel"),
//                                     ),
//                                     TextButton(
//                                       onPressed: () async {
//                                         Navigator.pop(context);
//                                         await _deleteBooking(b['bookingId']);
//                                       },
//                                       child: const Text(
//                                         "Delete",
//                                         style: TextStyle(color: Colors.red),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             },
//                             icon: Icon(
//                               Icons.delete_outline,
//                               color: Colors.red.shade600,
//                               size: 28,
//                             ),
//                           ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildDetailRow({
//     required IconData icon,
//     required String text,
//     required Color iconColor,
//   }) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Icon(
//           icon,
//           size: 16,
//           color: iconColor,
//         ),
//         const SizedBox(width: 8),
//         Expanded(
//           child: Text(
//             text,
//             style: const TextStyle(
//               fontSize: 13,
//               color: Colors.black87,
//             ),
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     );
//   }
//
//   // Delete booking method
//   Future<void> _deleteBooking(String bookingId) async {
//     try {
//       final result = await client.mutate(
//         MutationOptions(
//           document: gql(_deletePendingBookingMutation()),
//           variables: {
//             'bookingId': bookingId,
//             'buyerId': widget.buyerId,
//           },
//         ),
//       );
//
//       final response = result.data?['deletePilotBookingByBuyer'];
//
//       if (response != null && response['success'] == true) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Booking deleted successfully"),
//             backgroundColor: Colors.green,
//           ),
//         );
//         setState(() {});
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Network Error"),
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
//   String _deletePendingBookingMutation() => '''
//     mutation DeletePendingBooking(\$bookingId: String!, \$buyerId: String!) {
//       deletePilotBookingByBuyer(
//         bookingId: \$bookingId,
//         buyerId: \$buyerId
//       ) {
//         success
//         message
//       }
//     }
//   ''';
//
//   // --------------------------------------------
//   // TAB VIEW BUILDER WITH REFRESH INDICATOR
//   // --------------------------------------------
//   Widget buildTab(String Function() queryBuilder, {bool isPending = false}) {
//     return Query(
//       options: QueryOptions(
//         document: gql(queryBuilder()),
//         pollInterval: const Duration(seconds: 3),
//       ),
//       builder: (result, {refetch, fetchMore}) {
//         return RefreshIndicator(
//           onRefresh: () async {
//             if (refetch != null) {
//               await refetch();
//             }
//           },
//           child: _buildTabContent(result, isPending, refetch),
//         );
//       },
//     );
//   }
//
//   Widget _buildTabContent(QueryResult result, bool isPending, Future<QueryResult?> Function()? refetch) {
//     if (result.isLoading && result.data == null) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     if (result.hasException) {
//       return RefreshIndicator(
//         onRefresh: () async {
//           if (refetch != null) {
//             await refetch!();
//           }
//         },
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Text(
//                 "Network Error",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.grey,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 "Please check your connection and try again",
//                 style: TextStyle(color: Colors.grey),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 24),
//               ElevatedButton(
//                 onPressed: refetch,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF1E0E5C),
//                   foregroundColor: Colors.white,
//                 ),
//                 child: const Text("Retry"),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     final data = result.data ?? {};
//
//     String key = data.keys.firstWhere(
//           (k) => k != "__typename",
//       orElse: () => "",
//     );
//
//     final list = (data[key] ?? []) as List;
//
//     if (list.isEmpty) {
//       return RefreshIndicator(
//         onRefresh: () async {
//           if (refetch != null) {
//             await refetch();
//           }
//         },
//         child: ListView(
//           children: [
//             SizedBox(
//               height: MediaQuery.of(context).size.height * 0.7,
//               child: const Center(
//                 child: Text("No bookings found",
//                     style: TextStyle(color: Colors.grey)),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return ListView.builder(
//       itemCount: list.length,
//       itemBuilder: (_, i) => buildBookingCard(list[i], showDelete: isPending),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FA),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF1E0E5C),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           "My Pilot Bookings",
//           style: TextStyle(color: Colors.white),
//         ),
//         bottom: TabBar(
//           controller: _tabController,
//           indicatorColor: Colors.white,
//           labelColor: Colors.white,
//           unselectedLabelColor: Colors.white.withOpacity(0.7),
//           tabs: const [
//             Tab(text: "Approved"),
//             Tab(text: "Pending"),
//             Tab(text: "Rejected"),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           buildTab(getApprovedQuery),
//           buildTab(getPendingQuery, isPending: true),
//           buildTab(getRejectedQuery),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
// }
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/env.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PilotBookingStatusPage extends StatefulWidget {
  final String buyerId;

  const PilotBookingStatusPage({super.key, required this.buyerId});

  @override
  State<PilotBookingStatusPage> createState() =>
      _PilotBookingStatusPageState();
}

class _PilotBookingStatusPageState extends State<PilotBookingStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GraphQLClient client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    client = GraphQLClient(
      link: HttpLink(EnvConfig.baseUrl),
      cache: GraphQLCache(),
    );
  }

  // Function to make phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    PermissionStatus status = await Permission.phone.status;

    if (!status.isGranted) {
      final allow = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Call Permission Required"),
          content: const Text(
            "Flyhub needs phone permission to call the seller directly.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Allow"),
            ),
          ],
        ),
      );

      if (allow != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Call permission denied"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      status = await Permission.phone.request();
    }

    if (status.isPermanentlyDenied) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Permission Disabled"),
          content: const Text(
            "Phone permission is permanently denied. Please enable it from app settings.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text("Open Settings"),
            ),
          ],
        ),
      );
      return;
    }

    if (status.isGranted) {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );

      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $phoneNumber'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --------------------------------------------
  // SIMPLIFIED QUERIES - Use only existing fields
  // --------------------------------------------
  String getApprovedQuery() => '''
    query {
      getBuyerApprovedPilotBookings(buyerId: "${widget.buyerId}") {
        bookingId
        pilotId
        pilotName
        buyerName
        location
        date
        startTime
        endTime
        status
        pilotType
        
        # For seller pilots
        sellerName
        sellerPhone
        
        # For buyer pilots - owner contact info
        pilotOwnerId
        pilotOwnerType
        contact
        
        # Additional info
        totalAmount
        duration
        createdAt
      }
    }
  ''';

  String getPendingQuery() => '''
    query {
      getBuyerPendingPilotBookings(buyerId: "${widget.buyerId}") {
        bookingId
        pilotId
        pilotName
        buyerName
        location
        date
        startTime
        endTime
        status
        pilotType
        pilotOwnerId
        pilotOwnerType
        contact
        totalAmount
      }
    }
  ''';

  String getRejectedQuery() => '''
    query {
      getBuyerRejectedPilotBookings(buyerId: "${widget.buyerId}") {
        bookingId
        pilotId
        pilotName
        buyerName
        location
        date
        startTime
        endTime
        status
        pilotType
        pilotOwnerId
        pilotOwnerType
        contact
        totalAmount
      }
    }
  ''';

  // Helper function to get contact info - SIMPLIFIED VERSION
  Future<Map<String, String>> _getContactInfo(Map<String, dynamic> booking) async {
    final pilotType = booking['pilotType'] ?? 'seller';

    // For seller pilots - show seller contact
    if (pilotType == 'seller') {
      return {
        'name': booking['sellerName'] ?? 'Seller',
        'phone': booking['sellerPhone'] ?? '--',
      };
    }
    // For buyer pilots
    else if (pilotType == 'buyer') {
      final pilotOwnerId = booking['pilotOwnerId'];

      // Try to fetch pilot owner details
      if (pilotOwnerId != null && pilotOwnerId.isNotEmpty) {
        try {
          // Use a simpler query that matches your schema
          final pilotOwnerQuery = '''
            query {
              getBuyer(buyerId: "$pilotOwnerId") {
                name
                phoneNumber
              }
            }
          ''';

          final result = await client.query(QueryOptions(
            document: gql(pilotOwnerQuery),
            fetchPolicy: FetchPolicy.networkOnly,
          ));

          if (!result.hasException && result.data != null) {
            // Try different possible response structures
            final responseData = result.data;

            // Check for getBuyer field
            if (responseData?['getBuyer'] != null) {
              final pilotOwnerData = responseData?['getBuyer'];
              return {
                'name': pilotOwnerData['name'] ?? 'Pilot Owner',
                'phone': pilotOwnerData['phoneNumber'] ?? booking['contact'] ?? '--',
              };
            }
            // Check for buyer field
            else if (responseData?['buyer'] != null) {
              final pilotOwnerData = responseData?['buyer'];
              return {
                'name': pilotOwnerData['name'] ?? 'Pilot Owner',
                'phone': pilotOwnerData['phoneNumber'] ?? booking['contact'] ?? '--',
              };
            }
          }
        } catch (e) {
          debugPrint("Error fetching pilot owner details: $e");
          debugPrint("Error details: ${e.toString()}");
        }
      }

      // Fallback: show contact info from booking
      return {
        'name': 'Pilot Owner',
        'phone': booking['contact'] ?? '--',
      };
    }

    // Default fallback
    return {
      'name': 'Contact',
      'phone': '--',
    };
  }

  // Helper function to format date
  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Date not available';
    }

    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      try {
        if (dateString.length == 13 && int.tryParse(dateString) != null) {
          DateTime date =
          DateTime.fromMillisecondsSinceEpoch(int.parse(dateString));
          return DateFormat('dd MMM yyyy').format(date);
        }
        return dateString;
      } catch (e2) {
        return dateString;
      }
    }
  }

  // Format time
  String formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return '--';
    }
    return timeString;
  }

  // --------------------------------------------
  // STATUS COLORS
  // --------------------------------------------
  Color getStatusColor(String? status) {
    switch (status?.toLowerCase() ?? "") {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "completed":
        return Colors.blue;
      case "pending":
      default:
        return const Color(0xFF1E0E5C);
    }
  }

  // --------------------------------------------
  // BOOKING CARD UI - SIMPLIFIED
  // --------------------------------------------
  Widget buildBookingCard(Map<String, dynamic> b, {bool showDelete = false}) {
    final status = b['status'] ?? "--";
    final formattedDate = formatDate(b['date']);
    final startTime = formatTime(b['startTime']);
    final endTime = formatTime(b['endTime']);
    final pilotName = b['pilotName'] ?? '--';
    final pilotType = b['pilotType'] ?? 'seller';
    final totalAmount = b['totalAmount'] ?? 0;
    final duration = b['duration'] ?? 0;
    final location = b['location'] ?? '--';
    final buyerName = b['buyerName'] ?? '--';

    bool isApprovedTab = status.toLowerCase() == 'approved';
    bool isPendingTab = status.toLowerCase() == 'pending';
    bool isBuyerPilot = pilotType == 'buyer';

    // Determine if current user is the pilot owner
    bool isPilotOwner = isBuyerPilot && (b['pilotOwnerId'] == widget.buyerId);

    return FutureBuilder<Map<String, String>>(
      future: _getContactInfo(b),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError) {
          return _buildErrorCard("Error loading contact info");
        }

        final contactInfo = snapshot.data ?? {'name': 'Unknown', 'phone': '--'};
        final contactName = contactInfo['name']!;
        final contactPhone = contactInfo['phone']!;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pilot Name Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        pilotName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E0E5C),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: getStatusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),

                // Pilot type indicator
                if (isBuyerPilot)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 12,
                          color: isPilotOwner ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPilotOwner ? "Your Pilot Listing" : "Buyer Pilot",
                          style: TextStyle(
                            fontSize: 11,
                            color: isPilotOwner ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade300, height: 1),
                const SizedBox(height: 12),

                Row(
                  children: [
                    // Icon
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E0E5C).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isBuyerPilot ? Icons.person : Icons.business,
                        size: 28,
                        color: const Color(0xFF1E0E5C),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // For buyer pilots: show contact info
                          if (isBuyerPilot && !isPilotOwner && isApprovedTab)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  icon: Icons.person,
                                  text: contactName,
                                  iconColor: const Color(0xFF1E0E5C),
                                ),
                                const SizedBox(height: 6),
                                if (contactPhone != '--')
                                  _buildDetailRow(
                                    icon: Icons.phone,
                                    text: contactPhone,
                                    iconColor: Colors.blue,
                                  ),
                                const SizedBox(height: 6),
                              ],
                            ),

                          // For seller pilots or pilot owners
                          if (pilotType == 'seller' || isPilotOwner)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isPilotOwner && isApprovedTab)
                                  _buildDetailRow(
                                    icon: Icons.person_add,
                                    text: "Booked by: $buyerName",
                                    iconColor: Colors.purple,
                                  ),
                                if (pilotType == 'seller' && isApprovedTab)
                                  _buildDetailRow(
                                    icon: Icons.person,
                                    text: b['sellerName'] ?? 'Seller',
                                    iconColor: const Color(0xFF1E0E5C),
                                  ),
                                const SizedBox(height: 6),
                              ],
                            ),

                          // Booking details
                          _buildDetailRow(
                            icon: Icons.calendar_today,
                            text: formattedDate,
                            iconColor: Colors.orange,
                          ),
                          const SizedBox(height: 6),
                          _buildDetailRow(
                            icon: Icons.access_time,
                            text: "$startTime - $endTime",
                            iconColor: Colors.purple,
                          ),
                          const SizedBox(height: 6),
                          if (duration > 0)
                            _buildDetailRow(
                              icon: Icons.timer,
                              text: "${duration.toStringAsFixed(1)} hours",
                              iconColor: Colors.teal,
                            ),
                          const SizedBox(height: 6),
                          if (totalAmount > 0)
                            _buildDetailRow(
                              icon: Icons.currency_rupee,
                              text: "₹${totalAmount.toStringAsFixed(2)}",
                              iconColor: Colors.green,
                            ),
                          const SizedBox(height: 6),
                          if (location.isNotEmpty && location != '--')
                            _buildDetailRow(
                              icon: Icons.location_on,
                              text: location,
                              iconColor: Colors.red,
                            ),
                        ],
                      ),
                    ),
                    // Action Buttons Column
                    if (isApprovedTab || isPendingTab)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Call button for approved buyer pilot bookings
                          if (isApprovedTab && isBuyerPilot && !isPilotOwner && contactPhone != '--')
                            ElevatedButton.icon(
                              onPressed: () => _makePhoneCall(contactPhone),
                              icon: const Icon(Icons.phone, size: 16),
                              label: const Text("Call"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                elevation: 0,
                              ),
                            ),
                          // Call button for approved seller pilot bookings
                          if (isApprovedTab && pilotType == 'seller' && b['sellerPhone'] != null)
                            ElevatedButton.icon(
                              onPressed: () => _makePhoneCall(b['sellerPhone']),
                              icon: const Icon(Icons.phone, size: 16),
                              label: const Text("Call"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                elevation: 0,
                              ),
                            ),
                          // Delete button for pending bookings
                          if (isPendingTab && showDelete && !isPilotOwner)
                            IconButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Delete Booking"),
                                    content: const Text(
                                        "Are you sure you want to delete this pending booking?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await _deleteBooking(b['bookingId']);
                                        },
                                        child: const Text(
                                          "Delete",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red.shade600,
                                size: 28,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: const Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text("Loading booking details..."),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String text,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Delete booking method
  Future<void> _deleteBooking(String bookingId) async {
    try {
      final result = await client.mutate(
        MutationOptions(
          document: gql(_deletePendingBookingMutation()),
          variables: {
            'bookingId': bookingId,
            'buyerId': widget.buyerId,
          },
        ),
      );

      final response = result.data?['deletePilotBookingByBuyer'];

      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Booking deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.exception?.graphqlErrors.first.message ?? "Failed to delete booking"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _deletePendingBookingMutation() => '''
    mutation DeletePendingBooking(\$bookingId: String!, \$buyerId: String!) {
      deletePilotBookingByBuyer(
        bookingId: \$bookingId,
        buyerId: \$buyerId
      ) {
        success
        message
      }
    }
  ''';

  // --------------------------------------------
  // TAB VIEW BUILDER WITH REFRESH INDICATOR
  // --------------------------------------------
  Widget buildTab(String Function() queryBuilder, {bool isPending = false}) {
    return Query(
      options: QueryOptions(
        document: gql(queryBuilder()),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {refetch, fetchMore}) {
        return _buildTabContent(result, isPending, refetch);
      },
    );
  }

  Widget _buildTabContent(QueryResult result, bool isPending, Future<QueryResult?> Function()? refetch) {
    if (result.isLoading && result.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (result.hasException) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              "Network Error",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                result.exception?.graphqlErrors.first.message ?? "Please check your connection",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (refetch != null) {
                  refetch();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E0E5C),
                foregroundColor: Colors.white,
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    final data = result.data ?? {};

    // Find the correct key in the response
    String key = data.keys.firstWhere(
          (k) => k.startsWith('getBuyer') && k.endsWith('PilotBookings'),
      orElse: () => data.keys.firstWhere(
            (k) => k != "__typename",
        orElse: () => "",
      ),
    );

    if (key.isEmpty) {
      return const Center(
        child: Text("No data found", style: TextStyle(color: Colors.grey)),
      );
    }

    final list = (data[key] ?? []) as List;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "No bookings found",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your bookings will appear here",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (refetch != null) {
          await refetch();
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 20),
        itemCount: list.length,
        itemBuilder: (_, i) => buildBookingCard(list[i], showDelete: isPending),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E0E5C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Pilot Bookings",
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: "Approved"),
            Tab(text: "Pending"),
            Tab(text: "Rejected"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildTab(getApprovedQuery),
          buildTab(getPendingQuery, isPending: true),
          buildTab(getRejectedQuery),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}