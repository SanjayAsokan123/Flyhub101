// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:flutter_svg/flutter_svg.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:url_launcher/url_launcher.dart';
// // import 'package:flyhub/T&C/Help_Support_Page.dart';
// // import 'package:flyhub/T&C/PrivacyPolicy.dart';
// // import 'package:flyhub/T&C/Terms_Conditions.dart';
// // import 'package:flyhub/T&C/feedback_form.dart';
// // import 'package:flyhub/T&C/BuyerSettings.dart';
// // import '../../BuyerBookingStatuses/Buyer_Shipping_Policy.dart';
// // import '../../HomeScreen/Dynamichome.dart';
// // import '../../HomeScreen/Bottoms/SellerPage.dart';
// // import '../../HomeScreen/Bottoms/GuestProfilePage.dart';
// // import '../../BuyerBookingStatuses/Buyer_Return_Refund_Policy.dart';
// // import '../../services/role_manager.dart';
// // import '../../BuyerDetails/WishlistPage.dart';
// // import '../../BuyerDetails/MyCartPage.dart';
// // import '../../orders/MyOrderPage.dart';
// // import '../../Login/SellerLoginPage.dart';
// // import '../../BuyerBookingStatuses/DroneRentalConfirmation.dart';
// // import '../../BuyerBookingStatuses/Pilot_Booking_Status.dart';
// // import '../../BuyerBookingStatuses/BuyerServiceBookingStatus.dart';
// // import '../../BuyerBookingStatuses/BuyerJobApplyStatus.dart';
// //
// // class BuyerProfilePage extends StatefulWidget {
// //   const BuyerProfilePage({super.key});
// //
// //   @override
// //   State<BuyerProfilePage> createState() => _BuyerProfilePageState();
// // }
// //
// // class _BuyerProfilePageState extends State<BuyerProfilePage> {
// //   final FirebaseAuth _auth = FirebaseAuth.instance;
// //   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
// //
// //   User? _user;
// //   Map<String, dynamic>? _buyerData;
// //   bool _loading = true;
// //
// //   static const Color primaryColor = Color(0xFF1A0A5B);
// //   static const Color backgroundColor = Color(0xFFF8F9FA);
// //   static const Color textSecondary = Color(0xFF6B7280);
// //
// //   // Social Media URLs - Fixed with proper URLs
// //   final Map<String, String> socialMediaUrls = {
// //     'instagram': 'https://www.instagram.com/flyhub_info',
// //     'linkedin': 'https://www.linkedin.com/company/flyhubinfo',
// //     'facebook': 'https://www.facebook.com/share/1A8fBiqxmt/',
// //     'whatsapp': 'https://wa.me/6379800193',
// //   };
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _initBuyerPage();
// //   }
// //
// //   Future<void> _initBuyerPage() async {
// //     try {
// //       _user = _auth.currentUser;
// //
// //       if (_user == null) {
// //         await RoleManager.setLocalRole("guest");
// //         if (!mounted) return;
// //         Navigator.pushReplacement(
// //           context,
// //           MaterialPageRoute(builder: (_) => const GuestProfilePage()),
// //         );
// //         return;
// //       }
// //
// //       final snap = await _firestore
// //           .collection('buyers')
// //           .where('firebaseUid', isEqualTo: _user!.uid)
// //           .limit(1)
// //           .get();
// //
// //       if (snap.docs.isEmpty) {
// //         await RoleManager.setLocalRole("buyer");
// //         setState(() {
// //           _buyerData = {
// //             'name': _user?.displayName ?? 'User',
// //             'email': _user?.email ?? '',
// //             'buyerId': '',
// //           };
// //         });
// //         return;
// //       }
// //
// //       final doc = snap.docs.first;
// //       final data = doc.data();
// //       final buyerDocId = doc.id;
// //
// //       data['buyerId'] = buyerDocId;
// //
// //       final role = data['role']?.toString().toLowerCase() ?? "buyer";
// //
// //       if (role != "buyer") {
// //         await RoleManager.setLocalRole("seller");
// //         if (!mounted) return;
// //         Navigator.pushReplacement(
// //           context,
// //           MaterialPageRoute(builder: (_) => const SellerPage()),
// //         );
// //         return;
// //       }
// //
// //       await RoleManager.setLocalRole("buyer");
// //       setState(() => _buyerData = data);
// //     } catch (e) {
// //       debugPrint("⚠ BuyerPage init error: $e");
// //     } finally {
// //       if (mounted) setState(() => _loading = false);
// //     }
// //   }
// //
// //   Future<void> _switchToSeller() async {
// //     HapticFeedback.selectionClick();
// //     try {
// //       if (!mounted) return;
// //       Navigator.pushReplacement(
// //         context,
// //         MaterialPageRoute(builder: (_) => const SellerPage()),
// //       );
// //     } catch (e) {
// //       debugPrint("⚠ Switch to seller error: $e");
// //     }
// //   }
// //
// //   Future<void> _logout() async {
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: const Text("Logout"),
// //         content: const Text("Are you sure you want to logout?"),
// //         actions: [
// //           Row(
// //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //             children: [
// //               TextButton(
// //                 onPressed: () => Navigator.pop(context),
// //                 child: const Text("Cancel"),
// //               ),
// //               Align(
// //                 alignment: Alignment.centerRight,
// //                 child: TextButton(
// //                   onPressed: () async {
// //                     Navigator.pop(context);
// //                     await _auth.signOut();
// //                     await RoleManager.clearRole();
// //                     if (!mounted) return;
// //                     Navigator.pushAndRemoveUntil(
// //                       context,
// //                       MaterialPageRoute(
// //                         builder: (_) => const Dynamichome(selectedIndex: 0),
// //                       ),
// //                           (route) => false,
// //                     );
// //                   },
// //                   child: const Text(
// //                     "Logout",
// //                     style: TextStyle(color: Colors.red),
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Future<void> _launchSocialMedia(String platform) async {
// //     final url = socialMediaUrls[platform];
// //
// //     if (url == null) {
// //       _showMessage("Link not available for $platform");
// //       return;
// //     }
// //
// //     try {
// //       final uri = Uri.parse(url);
// //
// //       if (platform == 'whatsapp' && url.contains('wa.me')) {
// //         if (await canLaunchUrl(uri)) {
// //           await launchUrl(uri);
// //         } else {
// //           final webUri = Uri.parse('https://web.whatsapp.com/');
// //           if (await canLaunchUrl(webUri)) {
// //             await launchUrl(webUri);
// //           } else {
// //             _showMessage("Could not launch WhatsApp");
// //           }
// //         }
// //       } else {
// //         if (await canLaunchUrl(uri)) {
// //           await launchUrl(
// //             uri,
// //             mode: LaunchMode.externalApplication,
// //           );
// //         } else {
// //           _showMessage("Could not launch $platform");
// //         }
// //       }
// //     } catch (e) {
// //       debugPrint("Error launching $platform: $e");
// //       _showMessage("Error opening $platform");
// //     }
// //   }
// //
// //   Widget _buildProfileHeader() {
// //     final name = _buyerData?['name'] ??
// //         _buyerData?['firstName'] ??
// //         _user?.displayName ??
// //         "Buyer";
// //     final email = _buyerData?['email'] ?? _user?.email ?? "";
// //
// //     return Container(
// //       color: Colors.white,
// //       padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Container(
// //             width: 70,
// //             height: 70,
// //             decoration: BoxDecoration(
// //               color: primaryColor.withOpacity(0.1),
// //               shape: BoxShape.circle,
// //             ),
// //             child: Center(
// //               child: Text(
// //                 name.isNotEmpty ? name[0].toUpperCase() : "B",
// //                 style: TextStyle(
// //                   fontSize: 28,
// //                   fontWeight: FontWeight.w600,
// //                   color: primaryColor,
// //                 ),
// //               ),
// //             ),
// //           ),
// //           const SizedBox(width: 16),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   name,
// //                   style: const TextStyle(
// //                     fontSize: 20,
// //                     fontWeight: FontWeight.w600,
// //                     color: Colors.black87,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 4),
// //                 Text(
// //                   email,
// //                   style: const TextStyle(
// //                     fontSize: 14,
// //                     color: Colors.grey,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 8),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildActionButton({
// //     required IconData icon,
// //     required String label,
// //     required Color color,
// //     required VoidCallback onTap,
// //   }) {
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Container(
// //         width: 80,
// //         padding: const EdgeInsets.symmetric(vertical: 12),
// //         decoration: BoxDecoration(
// //           color: Colors.white,
// //           borderRadius: BorderRadius.circular(12),
// //           boxShadow: [
// //             BoxShadow(
// //               color: Colors.black.withOpacity(0.05),
// //               blurRadius: 8,
// //               offset: const Offset(0, 2),
// //             ),
// //           ],
// //         ),
// //         child: Column(
// //           children: [
// //             Container(
// //               width: 36,
// //               height: 36,
// //               decoration: BoxDecoration(
// //                 color: color.withOpacity(0.1),
// //                 shape: BoxShape.circle,
// //               ),
// //               child: Icon(icon, size: 20, color: color),
// //             ),
// //             const SizedBox(height: 8),
// //             Text(
// //               label,
// //               style: TextStyle(
// //                 fontSize: 11,
// //                 fontWeight: FontWeight.w500,
// //                 color: color,
// //               ),
// //               textAlign: TextAlign.center,
// //               maxLines: 1,
// //               overflow: TextOverflow.ellipsis,
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildSection({
// //     required String title,
// //     required List<Widget> children,
// //     bool showDivider = true,
// //   }) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Padding(
// //           padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
// //           child: Text(
// //             title,
// //             style: const TextStyle(
// //               fontSize: 16,
// //               fontWeight: FontWeight.w600,
// //               color: Colors.black87,
// //             ),
// //           ),
// //         ),
// //         ...children,
// //         if (showDivider) const Divider(height: 0, thickness: 1, color: Color(0xFFF0F0F0)),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildListItem({
// //     required IconData icon,
// //     required String title,
// //     required VoidCallback onTap,
// //     Color? iconColor,
// //     bool showTrailing = true,
// //     String? subtitle,
// //   }) {
// //     return ListTile(
// //       onTap: onTap,
// //       leading: Container(
// //         width: 36,
// //         height: 36,
// //         decoration: BoxDecoration(
// //           color: (iconColor ?? primaryColor).withOpacity(0.1),
// //           borderRadius: BorderRadius.circular(8),
// //         ),
// //         child: Icon(
// //           icon,
// //           size: 20,
// //           color: iconColor ?? primaryColor,
// //         ),
// //       ),
// //       title: Text(
// //         title,
// //         style: const TextStyle(
// //           fontSize: 15,
// //           fontWeight: FontWeight.w500,
// //           color: Colors.black87,
// //         ),
// //       ),
// //       subtitle: subtitle != null
// //           ? Text(
// //         subtitle,
// //         style: const TextStyle(
// //           fontSize: 12,
// //           color: Colors.grey,
// //         ),
// //       )
// //           : null,
// //       trailing: showTrailing
// //           ? Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400)
// //           : null,
// //       contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
// //       dense: true,
// //     );
// //   }
// //
// //   Widget _buildDroneListItem({
// //     required String title,
// //     required VoidCallback onTap,
// //     Color? iconColor,
// //     bool showTrailing = true,
// //   }) {
// //     return ListTile(
// //       onTap: onTap,
// //       leading: Container(
// //         width: 36,
// //         height: 36,
// //         padding: const EdgeInsets.all(6),
// //         decoration: BoxDecoration(
// //           color: (iconColor ?? primaryColor).withOpacity(0.1),
// //           borderRadius: BorderRadius.circular(8),
// //         ),
// //         child: SvgPicture.asset(
// //           'assets/categories/drone1.svg',
// //           width: 20,
// //           height: 20,
// //           colorFilter: ColorFilter.mode(
// //             iconColor ?? primaryColor,
// //             BlendMode.srcIn,
// //           ),
// //         ),
// //       ),
// //       title: Text(
// //         title,
// //         style: const TextStyle(
// //           fontSize: 15,
// //           fontWeight: FontWeight.w500,
// //           color: Colors.black87,
// //         ),
// //       ),
// //       trailing: showTrailing
// //           ? Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400)
// //           : null,
// //       contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
// //       dense: true,
// //     );
// //   }
// //
// //   // Social Icon Widget
// //   Widget _buildSocialIcon(String iconPath, {required VoidCallback onTap, String? tooltip}) {
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Tooltip(
// //         message: tooltip ?? '',
// //         child: Container(
// //           width: 40,
// //           height: 40,
// //           padding: const EdgeInsets.all(8),
// //           decoration: BoxDecoration(
// //             color: Colors.white,
// //             borderRadius: BorderRadius.circular(10),
// //             boxShadow: [
// //               BoxShadow(
// //                 color: primaryColor.withOpacity(0.1),
// //                 blurRadius: 5,
// //                 offset: const Offset(0, 2),
// //               ),
// //             ],
// //           ),
// //           child: Image.asset(
// //             iconPath,
// //             fit: BoxFit.contain,
// //             errorBuilder: (context, error, stackTrace) {
// //               return Icon(
// //                 Icons.error_outline,
// //                 color: Colors.red,
// //                 size: 20,
// //               );
// //             },
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // Simplified Earn with Flyhub Section
// //   Widget _buildEarnWithFlyhubSection() {
// //     return Container(
// //       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           // Section Header
// //           Padding(
// //             padding: const EdgeInsets.only(left: 4, bottom: 8),
// //             child: Text(
// //               "Earn with Flyhub",
// //               style: TextStyle(
// //                 fontSize: 16,
// //                 fontWeight: FontWeight.w600,
// //                 color: Colors.black87,
// //               ),
// //             ),
// //           ),
// //
// //           // Sell on Flyhub Card
// //           Material(
// //             color: Colors.transparent,
// //             child: InkWell(
// //               onTap: () => Navigator.push(
// //                 context,
// //                 MaterialPageRoute(builder: (_) => const SellerLoginPage()),
// //               ),
// //               borderRadius: BorderRadius.circular(10),
// //               child: Container(
// //                 padding: const EdgeInsets.all(16),
// //                 decoration: BoxDecoration(
// //                   color: Colors.white,
// //                   borderRadius: BorderRadius.circular(10),
// //                   border: Border.all(
// //                     color: Colors.green.withOpacity(0.3),
// //                     width: 1,
// //                   ),
// //                   boxShadow: [
// //                     BoxShadow(
// //                       color: Colors.black.withOpacity(0.05),
// //                       blurRadius: 6,
// //                       offset: const Offset(0, 2),
// //                     ),
// //                   ],
// //                 ),
// //                 child: Row(
// //                   children: [
// //                     Container(
// //                       width: 44,
// //                       height: 44,
// //                       decoration: BoxDecoration(
// //                         color: Colors.green.withOpacity(0.1),
// //                         borderRadius: BorderRadius.circular(10),
// //                       ),
// //                       child: Icon(
// //                         Icons.storefront_outlined,
// //                         color: Colors.green.shade700,
// //                         size: 22,
// //                       ),
// //                     ),
// //                     const SizedBox(width: 14),
// //                     Expanded(
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           Text(
// //                             "Sell on Flyhub",
// //                             style: TextStyle(
// //                               fontSize: 15,
// //                               fontWeight: FontWeight.w600,
// //                               color: Colors.black87,
// //                             ),
// //                           ),
// //                           const SizedBox(height: 4),
// //                           Text(
// //                             "Start your seller journey and grow your business",
// //                             style: TextStyle(
// //                               fontSize: 12,
// //                               color: Colors.grey.shade600,
// //                             ),
// //                             maxLines: 2,
// //                             overflow: TextOverflow.ellipsis,
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                     Icon(
// //                       Icons.arrow_forward_ios_rounded,
// //                       color: Colors.grey.shade500,
// //                       size: 16,
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   void _showMessage(String msg) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(msg),
// //         backgroundColor: primaryColor,
// //         behavior: SnackBarBehavior.floating,
// //         shape: RoundedRectangleBorder(
// //           borderRadius: BorderRadius.circular(8),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     if (_loading) {
// //       return Scaffold(
// //         backgroundColor: backgroundColor,
// //         body: Center(
// //           child: CircularProgressIndicator(color: primaryColor),
// //         ),
// //       );
// //     }
// //
// //     return Scaffold(
// //       backgroundColor: backgroundColor,
// //       appBar: AppBar(
// //         title: const Text(
// //           "Profile",
// //           style: TextStyle(
// //             fontWeight: FontWeight.w600,
// //             fontSize: 18,
// //           ),
// //         ),
// //         backgroundColor: Colors.white,
// //         elevation: 0.5,
// //         centerTitle: true,
// //         leading: IconButton(
// //           icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
// //           onPressed: () {
// //             Navigator.pushReplacement(
// //               context,
// //               MaterialPageRoute(
// //                 builder: (_) => const Dynamichome(selectedIndex: 0),
// //               ),
// //             );
// //           },
// //         ),
// //       ),
// //       body: Column(
// //         children: [
// //           Expanded(
// //             child: ListView(
// //               children: [
// //                 // Profile Header
// //                 _buildProfileHeader(),
// //
// //                 // Quick Actions
// //                 Container(
// //                   color: Colors.white,
// //                   padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
// //                   child: Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                     children: [
// //                       _buildActionButton(
// //                         icon: Icons.shopping_cart_outlined,
// //                         label: "Cart",
// //                         color: primaryColor,
// //                         onTap: () => Navigator.push(
// //                           context,
// //                           MaterialPageRoute(builder: (_) => const MyCartPage()),
// //                         ),
// //                       ),
// //                       _buildActionButton(
// //                         icon: Icons.favorite_border,
// //                         label: "Wishlist",
// //                         color: Colors.pink,
// //                         onTap: () => Navigator.push(
// //                           context,
// //                           MaterialPageRoute(builder: (_) => const WishlistPage()),
// //                         ),
// //                       ),
// //                       _buildActionButton(
// //                         icon: Icons.receipt_long,
// //                         label: "Orders",
// //                         color: Colors.green,
// //                         onTap: () {
// //                           final buyerId = _buyerData?['buyerId'] ?? '';
// //                           Navigator.push(
// //                             context,
// //                             MaterialPageRoute(
// //                               builder: (_) => MyOrderPage(buyerId: buyerId),
// //                             ),
// //                           );
// //                         },
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //
// //                 // Activities Section
// //                 _buildSection(
// //                   title: "My Activities",
// //                   children: [
// //                     _buildDroneListItem(
// //                       title: "Drone Rentals",
// //                       onTap: () {
// //                         final buyerId = _buyerData?['buyerId'] ?? '';
// //                         Navigator.push(
// //                           context,
// //                           MaterialPageRoute(
// //                             builder: (_) => DroneRentalApprovalPage(buyerId: buyerId),
// //                           ),
// //                         );
// //                       },
// //                     ),
// //                     _buildListItem(
// //                       icon: Icons.work_outline,
// //                       title: "Job Applications",
// //                       onTap: () {
// //                         final buyerId = _buyerData?['buyerId'] ?? '';
// //                         Navigator.push(
// //                           context,
// //                           MaterialPageRoute(
// //                             builder: (_) => BuyerJobApplyStatusPage(buyerId: buyerId),
// //                           ),
// //                         );
// //                       },
// //                     ),
// //                     _buildListItem(
// //                       icon: Icons.person_2_outlined,
// //                       title: "Pilot Booking",
// //                       onTap: () {
// //                         final buyerId = _buyerData?['buyerId'] ?? '';
// //                         Navigator.push(
// //                           context,
// //                           MaterialPageRoute(
// //                             builder: (_) => PilotBookingStatusPage(buyerId: buyerId),
// //                           ),
// //                         );
// //                       },
// //                     ),
// //                     _buildListItem(
// //                       icon: Icons.handyman_outlined,
// //                       title: "Service Bookings",
// //                       onTap: () {
// //                         final buyerId = _buyerData?['buyerId'] ?? '';
// //                         Navigator.push(
// //                           context,
// //                           MaterialPageRoute(
// //                             builder: (_) => BuyerServiceBookingStatusPage(buyerId: buyerId),
// //                           ),
// //                         );
// //                       },
// //                     ),
// //                   ],
// //                 ),
// //
// //                 // Earn with Flyhub Section
// //                 _buildEarnWithFlyhubSection(),
// //
// //                 // Support Section
// //                 _buildSection(
// //                   title: "Support",
// //                   children: [
// //                     _buildListItem(
// //                       icon: Icons.help_outline,
// //                       title: "Help & Support",
// //                       onTap: () => Navigator.push(
// //                         context,
// //                         MaterialPageRoute(builder: (_) => const HelpAndSupportPage()),
// //                       ),
// //                     ),
// //                     _buildListItem(
// //                       icon: Icons.feedback_outlined,
// //                       title: "Send Feedback",
// //                       onTap: () => Navigator.push(
// //                         context,
// //                         MaterialPageRoute(builder: (_) => const FeedbackFormPage()),
// //                       ),
// //                     ),
// //                     _buildListItem(
// //                       icon: Icons.description_outlined,
// //                       title: "Terms & Conditions",
// //                       onTap: () => Navigator.push(
// //                         context,
// //                         MaterialPageRoute(builder: (_) => const TermsAndConditionsPage()),
// //                       ),
// //                     ),
// //                     _buildListItem(
// //                       icon: Icons.privacy_tip_outlined,
// //                       title: "Privacy Policy",
// //                       onTap: () => Navigator.push(
// //                         context,
// //                         MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
// //                       ),
// //                     ),
// //                     _buildListItem(
// //                       icon: Icons.local_shipping_outlined,
// //                       title: "Shipping Policy",
// //                       onTap: () => Navigator.push(
// //                         context,
// //                         MaterialPageRoute(builder: (_) => const BuyerShippingPolicyPage()),
// //                       ),
// //                     ),
// //                     _buildListItem(
// //                       icon: Icons.assignment_return_outlined,
// //                       title: "Return Policy",
// //                       onTap: () => Navigator.push(
// //                         context,
// //                         MaterialPageRoute(builder: (_) => const RRPolicy()),
// //                       ),
// //                     ),
// //                   ],
// //                   showDivider: false,
// //                 ),
// //
// //                 // Account Section
// //                 _buildSection(
// //                   title: "Account",
// //                   children: [
// //                     _buildListItem(
// //                       icon: Icons.settings_outlined,
// //                       title: "Settings",
// //                       onTap: () => Navigator.push(
// //                         context,
// //                         MaterialPageRoute(builder: (_) => const SettingsPage()),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //
// //                 // Logout Button
// //                 Container(
// //                   color: Colors.white,
// //                   margin: const EdgeInsets.only(top: 8),
// //                   child: ListTile(
// //                     onTap: _logout,
// //                     leading: Container(
// //                       width: 36,
// //                       height: 36,
// //                       decoration: BoxDecoration(
// //                         color: Colors.red.withOpacity(0.1),
// //                         borderRadius: BorderRadius.circular(8),
// //                       ),
// //                       child: Icon(
// //                         Icons.logout,
// //                         size: 20,
// //                         color: Colors.red,
// //                       ),
// //                     ),
// //                     title: const Text(
// //                       "Logout",
// //                       style: TextStyle(
// //                         fontSize: 15,
// //                         fontWeight: FontWeight.w500,
// //                         color: Colors.red,
// //                       ),
// //                     ),
// //                     contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
// //                     dense: true,
// //                   ),
// //                 ),
// //
// //                 // Follow Us Footer
// //                 Container(
// //                   width: double.infinity,
// //                   margin: const EdgeInsets.only(top: 16),
// //                   padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
// //                   decoration: BoxDecoration(
// //                     color: primaryColor.withOpacity(0.05),
// //                     borderRadius: const BorderRadius.only(
// //                       topLeft: Radius.circular(20),
// //                       topRight: Radius.circular(20),
// //                     ),
// //                   ),
// //                   child: Column(
// //                     children: [
// //                       Text(
// //                         "Follow us on",
// //                         style: TextStyle(
// //                           color: textSecondary,
// //                           fontSize: 14,
// //                           fontWeight: FontWeight.w500,
// //                         ),
// //                       ),
// //                       const SizedBox(height: 20),
// //
// //                       Row(
// //                         mainAxisAlignment: MainAxisAlignment.center,
// //                         children: [
// //                           _buildSocialIcon(
// //                             'assets/categories/instagram.png',
// //                             onTap: () => _launchSocialMedia('instagram'),
// //                             tooltip: 'Follow us on Instagram',
// //                           ),
// //                           const SizedBox(width: 20),
// //
// //                           _buildSocialIcon(
// //                             'assets/categories/facebook.png',
// //                             onTap: () => _launchSocialMedia('facebook'),
// //                             tooltip: 'Like us on Facebook',
// //                           ),
// //                           const SizedBox(width: 20),
// //
// //                           _buildSocialIcon(
// //                             'assets/categories/linkedin.png',
// //                             onTap: () => _launchSocialMedia('linkedin'),
// //                             tooltip: 'Connect on LinkedIn',
// //                           ),
// //                           const SizedBox(width: 20),
// //
// //                           _buildSocialIcon(
// //                             'assets/categories/whatsapp.png',
// //                             onTap: () => _launchSocialMedia('whatsapp'),
// //                             tooltip: 'Message us on WhatsApp',
// //                           ),
// //                         ],
// //                       ),
// //                       const SizedBox(height: 16),
// //
// //                       GestureDetector(
// //                         onTap: () async {
// //                           final Uri url = Uri.parse("https://www.flyhub.info");
// //                           await launchUrl(url, mode: LaunchMode.externalApplication);
// //                         },
// //                         child: Container(
// //                           padding: const EdgeInsets.all(12),
// //                           decoration: BoxDecoration(
// //                             color: Colors.blue.withOpacity(0.08),
// //                             borderRadius: BorderRadius.circular(10),
// //                             border: Border.all(color: Colors.blue.withOpacity(1)),
// //                           ),
// //                           child: Row(
// //                             mainAxisSize: MainAxisSize.min,
// //                             children: const [
// //                               Icon(Icons.open_in_new, color: Colors.blue),
// //                               SizedBox(width: 8),
// //                               Text(
// //                                 "Explore Our Website",
// //                                 style: TextStyle(
// //                                   color: Colors.blue,
// //                                   fontWeight: FontWeight.w600,
// //                                   fontSize: 16,
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       ),
// //
// //                       const SizedBox(height: 20),
// //
// //                       Text(
// //                         "v1.0.0",
// //                         style: TextStyle(
// //                           fontSize: 12,
// //                           color: textSecondary,
// //                           fontWeight: FontWeight.w500,
// //                         ),
// //                       ),
// //                       const SizedBox(height: 4),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:flyhub/T&C/Help_Support_Page.dart';
// import 'package:flyhub/T&C/PrivacyPolicy.dart';
// import 'package:flyhub/T&C/Terms_Conditions.dart';
// import 'package:flyhub/T&C/feedback_form.dart';
// import 'package:flyhub/T&C/BuyerSettings.dart';
// import '../../BuyerBookingStatuses/Buyer_Shipping_Policy.dart';
// import '../../HomeScreen/Dynamichome.dart';
// import '../../HomeScreen/Bottoms/SellerPage.dart';
// import '../../HomeScreen/Bottoms/GuestProfilePage.dart';
// import '../../BuyerBookingStatuses/Buyer_Return_Refund_Policy.dart';
// import '../../services/role_manager.dart';
// import '../../BuyerDetails/WishlistPage.dart';
// import '../../BuyerDetails/MyCartPage.dart';
// import '../../orders/MyOrderPage.dart';
// import '../../Login/SellerLoginPage.dart';
// import '../../BuyerBookingStatuses/DroneRentalConfirmation.dart';
// import '../../BuyerBookingStatuses/Pilot_Booking_Status.dart';
// import '../../BuyerBookingStatuses/BuyerServiceBookingStatus.dart';
// import '../../BuyerBookingStatuses/BuyerJobApplyStatus.dart';
//
// class BuyerProfilePage extends StatefulWidget {
//   const BuyerProfilePage({super.key});
//
//   @override
//   State<BuyerProfilePage> createState() => _BuyerProfilePageState();
// }
//
// class _BuyerProfilePageState extends State<BuyerProfilePage> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   User? _user;
//   Map<String, dynamic>? _buyerData;
//   bool _loading = true;
//
//   // Pilot registration status variables
//   Map<String, dynamic>? _pilotRegistrationData;
//   bool _checkingPilotStatus = false;
//
//   static const Color primaryColor = Color(0xFF1A0A5B);
//   static const Color backgroundColor = Color(0xFFF8F9FA);
//   static const Color textSecondary = Color(0xFF6B7280);
//
//   // Social Media URLs - Fixed with proper URLs
//   final Map<String, String> socialMediaUrls = {
//     'instagram': 'https://www.instagram.com/flyhub_info',
//     'linkedin': 'https://www.linkedin.com/company/flyhubinfo',
//     'facebook': 'https://www.facebook.com/share/1A8fBiqxmt/',
//     'whatsapp': 'https://wa.me/6379800193',
//   };
//
//   @override
//   void initState() {
//     super.initState();
//     _initBuyerPage();
//     _checkPilotRegistrationStatus();
//   }
//
//   Future<void> _initBuyerPage() async {
//     try {
//       _user = _auth.currentUser;
//       if (_user == null) {
//         await RoleManager.setLocalRole("guest");
//         if (!mounted) return;
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const GuestProfilePage()),
//         );
//         return;
//       }
//       final snap = await _firestore
//           .collection('buyers')
//           .where('firebaseUid', isEqualTo: _user!.uid)
//           .limit(1)
//           .get();
//       if (snap.docs.isEmpty) {
//         await RoleManager.setLocalRole("buyer");
//         setState(() {
//           _buyerData = {
//             'name': _user?.displayName ?? 'User',
//             'email': _user?.email ?? '',
//             'buyerId': '',
//           };
//         });
//         return;
//       }
//
//       final doc = snap.docs.first;
//       final data = doc.data();
//       final buyerDocId = doc.id;
//
//       data['buyerId'] = buyerDocId;
//
//       final role = data['role']?.toString().toLowerCase() ?? "buyer";
//
//       if (role != "buyer") {
//         await RoleManager.setLocalRole("seller");
//         if (!mounted) return;
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const SellerPage()),
//         );
//         return;
//       }
//
//       await RoleManager.setLocalRole("buyer");
//       setState(() => _buyerData = data);
//     } catch (e) {
//       debugPrint("⚠ BuyerPage init error: $e");
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }
//
//   Future<void> _checkPilotRegistrationStatus() async {
//     if (_user == null) return;
//
//     setState(() => _checkingPilotStatus = true);
//
//     try {
//       final pilotSnapshot = await _firestore
//           .collection('pilots')
//           .where('firebaseUid', isEqualTo: _user!.uid)
//           .limit(1)
//           .get();
//
//       if (pilotSnapshot.docs.isNotEmpty) {
//         final pilotData = pilotSnapshot.docs.first.data();
//         setState(() {
//           _pilotRegistrationData = {
//             ...pilotData,
//             'docId': pilotSnapshot.docs.first.id,
//             'hasRegistration': true,
//           };
//         });
//       } else {
//         setState(() {
//           _pilotRegistrationData = {'hasRegistration': false};
//         });
//       }
//     } catch (e) {
//       debugPrint("Error checking pilot status: $e");
//       setState(() {
//         _pilotRegistrationData = {'hasRegistration': false};
//       });
//     } finally {
//       if (mounted) setState(() => _checkingPilotStatus = false);
//     }
//   }
//
//   String _getPilotStatusText(String? status) {
//     switch (status?.toLowerCase()) {
//       case 'approved':
//         return 'Approved ✓';
//       case 'pending':
//         return 'Pending Review';
//       case 'rejected':
//         return 'Rejected';
//       default:
//         return 'Not Submitted';
//     }
//   }
//
//   Color _getPilotStatusColor(String? status) {
//     switch (status?.toLowerCase()) {
//       case 'approved':
//         return Colors.green;
//       case 'pending':
//         return Colors.orange;
//       case 'rejected':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   IconData _getPilotStatusIcon(String? status) {
//     switch (status?.toLowerCase()) {
//       case 'approved':
//         return Icons.check_circle;
//       case 'pending':
//         return Icons.access_time;
//       case 'rejected':
//         return Icons.cancel;
//       default:
//         return Icons.person_add;
//     }
//   }
//
//   String _getStatusMessage(String? status) {
//     switch (status?.toLowerCase()) {
//       case 'approved':
//         return 'Congratulations! Your pilot registration has been approved. You can now start accepting pilot bookings.';
//       case 'pending':
//         return 'Your application is under review by our team. We will notify you once a decision is made.';
//       case 'rejected':
//         return 'Your pilot registration application has been rejected. Please contact support for more details.';
//       default:
//         return 'You have not submitted a pilot registration yet.';
//     }
//   }
//
//   Widget _buildPilotRegistrationCard() {
//     if (_checkingPilotStatus) {
//       return Container(
//         margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//           border: Border.all(color: Colors.grey.shade200),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: primaryColor.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Center(
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   color: primaryColor,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Text(
//                 "Checking pilot status...",
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     final hasRegistration = _pilotRegistrationData?['hasRegistration'] ?? false;
//     final status = _pilotRegistrationData?['status'] as String?;
//     final statusText = _getPilotStatusText(status);
//     final statusColor = _getPilotStatusColor(status);
//     final statusIcon = _getPilotStatusIcon(status);
//
//     return GestureDetector(
//       onTap: () {
//         _showPilotStatusDialog();
//       },
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//           border: Border.all(
//             color: hasRegistration ? statusColor.withOpacity(0.2) : Colors.grey.shade200,
//             width: hasRegistration ? 1.5 : 1,
//           ),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: statusColor.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Center(
//                 child: Icon(
//                   statusIcon,
//                   color: statusColor,
//                   size: 22,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Pilot Registration Status",
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     statusText,
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       color: statusColor,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Icon(
//               Icons.chevron_right,
//               color: Colors.grey.shade400,
//               size: 24,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showPilotStatusDialog() {
//     final hasRegistration = _pilotRegistrationData?['hasRegistration'] ?? false;
//     final status = _pilotRegistrationData?['status'] as String?;
//     final statusText = _getPilotStatusText(status);
//     final statusColor = _getPilotStatusColor(status);
//     final statusIcon = _getPilotStatusIcon(status);
//     final statusMessage = _getStatusMessage(status);
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         title: Row(
//           children: [
//             Icon(
//               statusIcon,
//               color: statusColor,
//               size: 24,
//             ),
//             const SizedBox(width: 12),
//             Text(
//               "Pilot Registration Status",
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//             ),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//               decoration: BoxDecoration(
//                 color: statusColor.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: statusColor.withOpacity(0.3)),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     "Current Status",
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.grey.shade700,
//                     ),
//                   ),
//                   Text(
//                     statusText,
//                     style: TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                       color: statusColor,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               statusMessage,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey.shade700,
//                 height: 1.5,
//               ),
//             ),
//             if (hasRegistration && _pilotRegistrationData?['submittedDate'] != null)
//               Padding(
//                 padding: const EdgeInsets.only(top: 16),
//                 child: Text(
//                   "Submitted on: ${_pilotRegistrationData?['submittedDate']}",
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),
//               ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             style: TextButton.styleFrom(
//               foregroundColor: Colors.grey.shade600,
//             ),
//             child: const Text("Close"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _switchToSeller() async {
//     HapticFeedback.selectionClick();
//     try {
//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const SellerPage()),
//       );
//     } catch (e) {
//       debugPrint("⚠ Switch to seller error: $e");
//     }
//   }
//
//   Future<void> _logout() async {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Logout"),
//         content: const Text("Are you sure you want to logout?"),
//         actions: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("Cancel"),
//               ),
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: TextButton(
//                   onPressed: () async {
//                     Navigator.pop(context);
//                     await _auth.signOut();
//                     await RoleManager.clearRole();
//                     if (!mounted) return;
//                     Navigator.pushAndRemoveUntil(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const Dynamichome(selectedIndex: 0),
//                       ),
//                           (route) => false,
//                     );
//                   },
//                   child: const Text(
//                     "Logout",
//                     style: TextStyle(color: Colors.red),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _launchSocialMedia(String platform) async {
//     final url = socialMediaUrls[platform];
//
//     if (url == null) {
//       _showMessage("Link not available for $platform");
//       return;
//     }
//
//     try {
//       final uri = Uri.parse(url);
//       if (platform == 'whatsapp' && url.contains('wa.me')) {
//         if (await canLaunchUrl(uri)) {
//           await launchUrl(uri);
//         } else {
//           final webUri = Uri.parse('https://web.whatsapp.com/');
//           if (await canLaunchUrl(webUri)) {
//             await launchUrl(webUri);
//           } else {
//             _showMessage("Could not launch WhatsApp");
//           }
//         }
//       }
//       else {
//         if (await canLaunchUrl(uri)) {
//           await launchUrl(
//             uri,
//             mode: LaunchMode.externalApplication,
//           );
//         } else {
//           _showMessage("Could not launch $platform");
//         }
//       }
//     } catch (e) {
//       debugPrint("Error launching $platform: $e");
//       _showMessage("Error opening $platform");
//     }
//   }
//
//   // Add this method for phone call functionality
//   Future<void> _makePhoneCall() async {
//     final phoneNumber = '9003992693';
//     final url = Uri.parse('tel:$phoneNumber');
//
//     try {
//       if (await canLaunchUrl(url)) {
//         await launchUrl(url);
//       } else {
//         _showMessage("Could not make a phone call");
//       }
//     } catch (e) {
//       debugPrint("Error making phone call: $e");
//       _showMessage("Error making phone call");
//     }
//   }
//
//   Widget _buildProfileHeader() {
//     final name = _buyerData?['name'] ??
//         _buyerData?['firstName'] ??
//         _user?.displayName ??
//         "Buyer";
//     final email = _buyerData?['email'] ?? _user?.email ?? "";
//
//     return Container(
//       color: Colors.white,
//       padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 70,
//             height: 70,
//             decoration: BoxDecoration(
//               color: primaryColor.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Center(
//               child: Text(
//                 name.isNotEmpty ? name[0].toUpperCase() : "B",
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.w600,
//                   color: primaryColor,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   name,
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   email,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildActionButton({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 80,
//         padding: const EdgeInsets.symmetric(vertical: 12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             Container(
//               width: 36,
//               height: 36,
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(icon, size: 20, color: color),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 11,
//                 fontWeight: FontWeight.w500,
//                 color: color,
//               ),
//               textAlign: TextAlign.center,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//   Widget _buildSection({
//     required String title,
//     required List<Widget> children,
//     bool showDivider = true,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
//           child: Text(
//             title,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//             ),
//           ),
//         ),
//         ...children,
//         if (showDivider) const Divider(height: 0, thickness: 1, color: Color(0xFFF0F0F0)),
//       ],
//     );
//   }
//
//   Widget _buildListItem({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//     Color? iconColor,
//     bool showTrailing = true,
//     String? subtitle,
//   }) {
//     return ListTile(
//       onTap: onTap,
//       leading: Container(
//         width: 36,
//         height: 36,
//         decoration: BoxDecoration(
//           color: (iconColor ?? primaryColor).withOpacity(0.1),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Icon(
//           icon,
//           size: 20,
//           color: iconColor ?? primaryColor,
//         ),
//       ),
//       title: Text(
//         title,
//         style: const TextStyle(
//           fontSize: 15,
//           fontWeight: FontWeight.w500,
//           color: Colors.black87,
//         ),
//       ),
//       subtitle: subtitle != null
//           ? Text(
//         subtitle,
//         style: const TextStyle(
//           fontSize: 12,
//           color: Colors.grey,
//         ),
//       )
//           : null,
//       trailing: showTrailing
//           ? Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400)
//           : null,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//       dense: true,
//     );
//   }
//
//   Widget _buildDroneListItem({
//     required String title,
//     required VoidCallback onTap,
//     Color? iconColor,
//     bool showTrailing = true,
//   }) {
//     return ListTile(
//       onTap: onTap,
//       leading: Container(
//         width: 36,
//         height: 36,
//         padding: const EdgeInsets.all(6),
//         decoration: BoxDecoration(
//           color: (iconColor ?? primaryColor).withOpacity(0.1),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: SvgPicture.asset(
//           'assets/categories/drone1.svg',
//           width: 20,
//           height: 20,
//           colorFilter: ColorFilter.mode(
//             iconColor ?? primaryColor,
//             BlendMode.srcIn,
//           ),
//         ),
//       ),
//       title: Text(
//         title,
//         style: const TextStyle(
//           fontSize: 15,
//           fontWeight: FontWeight.w500,
//           color: Colors.black87,
//         ),
//       ),
//       trailing: showTrailing
//           ? Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400)
//           : null,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//       dense: true,
//     );
//   }
//
//   // Social Icon Widget
//   Widget _buildSocialIcon(String iconPath, {required VoidCallback onTap, String? tooltip}) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Tooltip(
//         message: tooltip ?? '',
//         child: Container(
//           width: 40,
//           height: 40,
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(10),
//             boxShadow: [
//               BoxShadow(
//                 color: primaryColor.withOpacity(0.1),
//                 blurRadius: 5,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Image.asset(
//             iconPath,
//             fit: BoxFit.contain,
//             errorBuilder: (context, error, stackTrace) {
//               return Icon(
//                 Icons.error_outline,
//                 color: Colors.red,
//                 size: 20,
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Simplified Earn with Flyhub Section
//   Widget _buildEarnWithFlyhubSection() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Section Header
//           Padding(
//             padding: const EdgeInsets.only(left: 4, bottom: 8),
//             child: Text(
//               "Earn with Flyhub",
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//             ),
//           ),
//
//           // Sell on Flyhub Card
//           Material(
//             color: Colors.transparent,
//             child: InkWell(
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const SellerLoginPage()),
//               ),
//               borderRadius: BorderRadius.circular(10),
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(
//                     color: Colors.green.withOpacity(0.3),
//                     width: 1,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.05),
//                       blurRadius: 6,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 44,
//                       height: 44,
//                       decoration: BoxDecoration(
//                         color: Colors.green.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Icon(
//                         Icons.storefront_outlined,
//                         color: Colors.green.shade700,
//                         size: 22,
//                       ),
//                     ),
//                     const SizedBox(width: 14),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "Sell on Flyhub",
//                             style: TextStyle(
//                               fontSize: 15,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.black87,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             "Start your seller journey and grow your business",
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey.shade600,
//                             ),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ],
//                       ),
//                     ),
//                     Icon(
//                       Icons.arrow_forward_ios_rounded,
//                       color: Colors.grey.shade500,
//                       size: 16,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showMessage(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: primaryColor,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return Scaffold(
//         backgroundColor: backgroundColor,
//         body: Center(
//           child: CircularProgressIndicator(color: primaryColor),
//         ),
//       );
//     }
//
//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(
//         title: const Text(
//           "Profile",
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: 18,
//           ),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0.5,
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
//           onPressed: () {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => const Dynamichome(selectedIndex: 0),
//               ),
//             );
//           },
//         ),
//       ),
//
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView(
//               children: [
//                 // Profile Header
//                 _buildProfileHeader(),
//
//                 // Quick Actions
//                 Container(
//                   color: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       _buildActionButton(
//                         icon: Icons.phone,
//                         label: "Bulk order",
//                         color: Colors.green,
//                         onTap: () => _makePhoneCall(),
//                       ),
//                       _buildActionButton(
//                         icon: Icons.shopping_bag_outlined,
//                         label: "Cart",
//                         color: Colors.purple,
//                         onTap: () => Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (_) => const MyCartPage()),
//                         ),
//                       ),
//                       _buildActionButton(
//                         icon: Icons.favorite_border,
//                         label: "Wishlist",
//                         color: Colors.pink,
//                         onTap: () => Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (_) => const WishlistPage()),
//                         ),
//                       ),
//                       _buildActionButton(
//                         icon: Icons.receipt_long,
//                         label: "Orders",
//                         color: Colors.blue,
//                         onTap: () {
//                           final buyerId = _buyerData?['buyerId'] ?? '';
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => MyOrderPage(buyerId: buyerId),
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 // Pilot Registration Status Card - NEW SECTION
//                 _buildPilotRegistrationCard(),
//
//                 // Activities Section
//                 _buildSection(
//                   title: "My Activities",
//                   children: [
//                     _buildDroneListItem(
//                       title: "Drone Rentals",
//                       onTap: () {
//                         final buyerId = _buyerData?['buyerId'] ?? '';
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => DroneRentalApprovalPage(buyerId: buyerId),
//                           ),
//                         );
//                       },
//                     ),
//                     _buildListItem(
//                       icon: Icons.work_outline,
//                       title: "Job Applications",
//                       onTap: () {
//                         final buyerId = _buyerData?['buyerId'] ?? '';
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => BuyerJobApplyStatusPage(buyerId: buyerId),
//                           ),
//                         );
//                       },
//                     ),
//                     _buildListItem(
//                       icon: Icons.person_2_outlined,
//                       title: "Pilot Booking",
//                       onTap: () {
//                         final buyerId = _buyerData?['buyerId'] ?? '';
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => PilotBookingStatusPage(buyerId: buyerId),
//                           ),
//                         );
//                       },
//                     ),
//                     _buildListItem(
//                       icon: Icons.handyman_outlined,
//                       title: "Service Bookings",
//                       onTap: () {
//                         final buyerId = _buyerData?['buyerId'] ?? '';
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => BuyerServiceBookingStatusPage(buyerId: buyerId),
//                           ),
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//
//                 // Earn with Flyhub Section
//                 _buildEarnWithFlyhubSection(),
//
//                 // Support Section
//                 _buildSection(
//                   title: "Support",
//                   children: [
//                     _buildListItem(
//                       icon: Icons.help_outline,
//                       title: "Help & Support",
//                       onTap: () => Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const HelpAndSupportPage()),
//                       ),
//                     ),
//                     _buildListItem(
//                       icon: Icons.feedback_outlined,
//                       title: "Send Feedback",
//                       onTap: () => Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const FeedbackFormPage()),
//                       ),
//                     ),
//                     _buildListItem(
//                       icon: Icons.description_outlined,
//                       title: "Terms & Conditions",
//                       onTap: () => Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const TermsAndConditionsPage()),
//                       ),
//                     ),
//                     _buildListItem(
//                       icon: Icons.privacy_tip_outlined,
//                       title: "Privacy Policy",
//                       onTap: () => Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
//                       ),
//                     ),
//                     _buildListItem(
//                       icon: Icons.local_shipping_outlined,
//                       title: "Shipping Policy",
//                       onTap: () => Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const BuyerShippingPolicyPage()),
//                       ),
//                     ),
//                     _buildListItem(
//                       icon: Icons.assignment_return_outlined,
//                       title: "Return Policy",
//                       onTap: () => Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const RRPolicy()),
//                       ),
//                     ),
//                   ],
//                   showDivider: false,
//                 ),
//
//                 // Account Section
//                 _buildSection(
//                   title: "Account",
//                   children: [
//                     _buildListItem(
//                       icon: Icons.settings_outlined,
//                       title: "Settings",
//                       onTap: () => Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const SettingsPage()),
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 // Logout Button
//                 Container(
//                   color: Colors.white,
//                   margin: const EdgeInsets.only(top: 8),
//                   child: ListTile(
//                     onTap: _logout,
//                     leading: Container(
//                       width: 36,
//                       height: 36,
//                       decoration: BoxDecoration(
//                         color: Colors.red.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Icon(
//                         Icons.logout,
//                         size: 20,
//                         color: Colors.red,
//                       ),
//                     ),
//                     title: const Text(
//                       "Logout",
//                       style: TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.red,
//                       ),
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                     dense: true,
//                   ),
//                 ),
//
//                 // Follow Us Footer
//                 Container(
//                   width: double.infinity,
//                   margin: const EdgeInsets.only(top: 16),
//                   padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
//                   decoration: BoxDecoration(
//                     color: primaryColor.withOpacity(0.05),
//                     borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(20),
//                       topRight: Radius.circular(20),
//                     ),
//                   ),
//                   child: Column(
//                     children: [
//                       Text(
//                         "Follow us on",
//                         style: TextStyle(
//                           color: textSecondary,
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           _buildSocialIcon(
//                             'assets/categories/instagram.png',
//                             onTap: () => _launchSocialMedia('instagram'),
//                             tooltip: 'Follow us on Instagram',
//                           ),
//                           const SizedBox(width: 20),
//
//                           _buildSocialIcon(
//                             'assets/categories/facebook.png',
//                             onTap: () => _launchSocialMedia('facebook'),
//                             tooltip: 'Like us on Facebook',
//                           ),
//                           const SizedBox(width: 20),
//
//                           _buildSocialIcon(
//                             'assets/categories/linkedin.png',
//                             onTap: () => _launchSocialMedia('linkedin'),
//                             tooltip: 'Connect on LinkedIn',
//                           ),
//                           const SizedBox(width: 20),
//
//                           _buildSocialIcon(
//                             'assets/categories/whatsapp.png',
//                             onTap: () => _launchSocialMedia('whatsapp'),
//                             tooltip: 'Message us on WhatsApp',
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 16),
//
//                       GestureDetector(
//                         onTap: () async {
//                           final Uri url = Uri.parse("https://www.flyhub.info");
//                           await launchUrl(url, mode: LaunchMode.externalApplication);
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.blue.withOpacity(0.08),
//                             borderRadius: BorderRadius.circular(10),
//                             border: Border.all(color: Colors.blue.withOpacity(1)),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: const [
//                               Icon(Icons.open_in_new, color: Colors.blue),
//                               SizedBox(width: 8),
//                               Text(
//                                 "Explore Our Website",
//                                 style: TextStyle(
//                                   color: Colors.blue,
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//
//                       const SizedBox(height: 20),
//
//                       Text(
//                         "v1.0.0",
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: textSecondary,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
//


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flyhub/T&C/Help_Support_Page.dart';
import 'package:flyhub/T&C/PrivacyPolicy.dart';
import 'package:flyhub/T&C/Terms_Conditions.dart';
import 'package:flyhub/T&C/feedback_form.dart';
import 'package:flyhub/T&C/BuyerSettings.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../BuyerBookingStatuses/BecomeAPilot_Booking_Status_Page.dart';
import '../../BuyerBookingStatuses/Buyer_Shipping_Policy.dart';
import '../../HomeScreen/Dynamichome.dart';
import '../../HomeScreen/Bottoms/SellerPage.dart';
import '../../HomeScreen/Bottoms/GuestProfilePage.dart';
import '../../BuyerBookingStatuses/Buyer_Return_Refund_Policy.dart';
import '../../services/role_manager.dart';
import '../../BuyerDetails/WishlistPage.dart';
import '../../BuyerDetails/MyCartPage.dart';
import '../../orders/MyOrderPage.dart';
import '../../Login/SellerLoginPage.dart';
import '../../BuyerBookingStatuses/DroneRentalConfirmation.dart';
import '../../BuyerBookingStatuses/Pilot_Booking_Status.dart';
import '../../BuyerBookingStatuses/BuyerServiceBookingStatus.dart';
import '../../BuyerBookingStatuses/BuyerJobApplyStatus.dart';
import '../../BuyerDetails/BecomeAPilotPage.dart';
import '../../config/env.dart';

class BuyerProfilePage extends StatefulWidget {
  const BuyerProfilePage({super.key});

  @override
  State<BuyerProfilePage> createState() => _BuyerProfilePageState();
}

class _BuyerProfilePageState extends State<BuyerProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  Map<String, dynamic>? _buyerData;
  bool _loading = true;

  // Pilot registration status variables
  Map<String, dynamic>? _pilotRegistrationData;
  bool _checkingPilotStatus = false;
  late GraphQLClient _graphqlClient;

  static const Color primaryColor = Color(0xFF1A0A5B);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color textSecondary = Color(0xFF6B7280);

  // Social Media URLs - Fixed with proper URLs
  final Map<String, String> socialMediaUrls = {
    'instagram': 'https://www.instagram.com/flyhub_info',
    'linkedin': 'https://www.linkedin.com/company/flyhubinfo',
    'facebook': 'https://www.facebook.com/share/1A8fBiqxmt/',
    'whatsapp': 'https://wa.me/6379800193',
  };

  @override
  void initState() {
    super.initState();
    _graphqlClient = GraphQLClient(
      link: HttpLink(EnvConfig.baseUrl),
      cache: GraphQLCache(),
    );
    _initBuyerPage();
  }

  Future<void> _initBuyerPage() async {
    try {
      _user = _auth.currentUser;
      if (_user == null) {
        await RoleManager.setLocalRole("guest");
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GuestProfilePage()),
        );
        return;
      }
      final snap = await _firestore
          .collection('buyers')
          .where('firebaseUid', isEqualTo: _user!.uid)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        await RoleManager.setLocalRole("buyer");
        setState(() {
          _buyerData = {
            'name': _user?.displayName ?? 'User',
            'email': _user?.email ?? '',
            'buyerId': '',
          };
        });
        _checkPilotRegistrationStatus();
        return;
      }

      final doc = snap.docs.first;
      final data = doc.data();
      final buyerDocId = doc.id;

      data['buyerId'] = buyerDocId;

      final role = data['role']?.toString().toLowerCase() ?? "buyer";

      if (role != "buyer") {
        await RoleManager.setLocalRole("seller");
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SellerPage()),
        );
        return;
      }

      await RoleManager.setLocalRole("buyer");
      setState(() => _buyerData = data);
      _checkPilotRegistrationStatus();
    } catch (e) {
      debugPrint("⚠ BuyerPage init error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkPilotRegistrationStatus() async {
    if (_user == null || _buyerData?['buyerId'] == null) {
      setState(() {
        _pilotRegistrationData = {'hasRegistration': false};
        _checkingPilotStatus = false;
      });
      return;
    }

    setState(() => _checkingPilotStatus = true);

    try {
      // SIMPLE query that works - only get what we need
      final String query = '''
      query CheckApprovedPilot(\$buyerId: String!) {
        buyerPilotsByBuyer(buyerId: \$buyerId) {
          buyerPilotId
          pilotName
          adminStatus
        }
      }
    ''';

      final result = await _graphqlClient.query(
        QueryOptions(
          document: gql(query),
          variables: {'buyerId': _buyerData?['buyerId'] ?? ''},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      debugPrint("GraphQL Result: ${result.data}");
      debugPrint("GraphQL Errors: ${result.exception}");

      if (result.hasException) {
        debugPrint("GraphQL Error Details: ${result.exception?.graphqlErrors}");
        // Try a simpler fallback query
        await _checkPilotStatusFallback();
        return;
      }

      final List<dynamic> buyerPilots = result.data?['buyerPilotsByBuyer'] ?? [];

      debugPrint("Found ${buyerPilots.length} pilot registrations");

      if (buyerPilots.isNotEmpty) {
        // Check for any approved pilot
        Map<String, dynamic>? approvedPilot;

        for (var pilot in buyerPilots) {
          debugPrint("Pilot: ${pilot['buyerPilotId']} - Status: ${pilot['adminStatus']}");

          if (pilot['adminStatus']?.toString().toLowerCase() == 'approved') {
            approvedPilot = pilot;
            break;
          }
        }

        if (approvedPilot != null) {
          // Buyer has an approved pilot
          debugPrint("✅ Buyer has APPROVED pilot: ${approvedPilot['buyerPilotId']}");
          setState(() {
            _pilotRegistrationData = {
              ...?approvedPilot,
              'hasRegistration': true,
              'status': 'approved',
              'isApproved': true,
            };
          });
        } else {
          // Buyer has pilots but none are approved
          final latestPilot = buyerPilots.first;
          final adminStatus = latestPilot['adminStatus']?.toString().toLowerCase() ?? 'pending';

          debugPrint("ℹ️ Buyer has pilots but status is: $adminStatus");
          setState(() {
            _pilotRegistrationData = {
              ...latestPilot,
              'hasRegistration': true,
              'status': adminStatus,
              'isApproved': adminStatus == 'approved',
            };
          });
        }
      } else {
        // No pilot registrations at all
        debugPrint("📭 No pilot registrations found");
        setState(() {
          _pilotRegistrationData = {'hasRegistration': false};
        });
      }
    } catch (e) {
      debugPrint("Error checking pilot status: $e");
      setState(() {
        _pilotRegistrationData = {'hasRegistration': false};
      });
    } finally {
      if (mounted) setState(() => _checkingPilotStatus = false);
    }
  }

// Fallback method if GraphQL fails
  Future<void> _checkPilotStatusFallback() async {
    try {
      // Alternative: Use a different query that doesn't have the buyer field issue
      final String query = '''
      query {
        buyerPilots {
          buyerPilotId
          pilotName
          adminStatus
          buyerId
        }
      }
    ''';

      final result = await _graphqlClient.query(
        QueryOptions(
          document: gql(query),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      final List<dynamic> allPilots = result.data?['buyerPilots'] ?? [];

      // Filter for this buyer's pilots
      final buyerPilots = allPilots.where((pilot) =>
      pilot['buyerId'] == _buyerData?['buyerId']
      ).toList();

      if (buyerPilots.isNotEmpty) {
        // Check for approved pilot
        for (var pilot in buyerPilots) {
          if (pilot['adminStatus']?.toString().toLowerCase() == 'approved') {
            setState(() {
              _pilotRegistrationData = {
                ...pilot,
                'hasRegistration': true,
                'status': 'approved',
                'isApproved': true,
              };
            });
            return;
          }
        }

        // No approved pilot found
        final latestPilot = buyerPilots.first;
        setState(() {
          _pilotRegistrationData = {
            ...latestPilot,
            'hasRegistration': true,
            'status': latestPilot['adminStatus'] ?? 'pending',
            'isApproved': false,
          };
        });
      } else {
        setState(() {
          _pilotRegistrationData = {'hasRegistration': false};
        });
      }
    } catch (e) {
      debugPrint("Fallback error: $e");
      setState(() {
        _pilotRegistrationData = {'hasRegistration': false};
      });
    }
  }

  Future<void> _checkBuyerPilotStatus() async {
    try {
      // Query to get buyer's own pilot listings
      final String query = '''
      query GetBuyerPilots(\$buyerId: String!) {
        buyerPilotsByBuyer(buyerId: \$buyerId) {
          buyerPilotId
          pilotName
          adminStatus
          buyerStatus
          buyerId
          createdAt
          updatedAt
        }
      }
    ''';

      final result = await _graphqlClient.query(
        QueryOptions(
          document: gql(query),
          variables: {'buyerId': _buyerData?['buyerId'] ?? ''},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        debugPrint("GraphQL Error: ${result.exception}");
        setState(() {
          _pilotRegistrationData = {'hasRegistration': false};
        });
        return;
      }

      final List<dynamic> buyerPilots = result.data?['buyerPilotsByBuyer'] ?? [];

      debugPrint("Total pilot registrations found: ${buyerPilots.length}");

      if (buyerPilots.isNotEmpty) {
        // Sort by updatedAt (most recent first)
        buyerPilots.sort((a, b) {
          final dateA = DateTime.parse(a['updatedAt'] ?? a['createdAt'] ?? '2000-01-01').millisecondsSinceEpoch;
          final dateB = DateTime.parse(b['updatedAt'] ?? b['createdAt'] ?? '2000-01-01').millisecondsSinceEpoch;
          return dateB.compareTo(dateA); // Descending order
        });

        // Find the latest pilot that is approved
        var latestApprovedPilot;
        for (var pilot in buyerPilots) {
          final adminStatus = pilot['adminStatus']?.toString().toLowerCase();
          debugPrint("Checking pilot ${pilot['buyerPilotId']}: adminStatus = $adminStatus");

          if (adminStatus == 'approved') {
            latestApprovedPilot = pilot;
            break;
          }
        }

        if (latestApprovedPilot != null) {
          // We found an approved pilot
          final adminStatus = latestApprovedPilot['adminStatus']?.toString().toLowerCase() ?? 'pending';
          final buyerStatus = latestApprovedPilot['buyerStatus']?.toString().toLowerCase() ?? 'pending';

          debugPrint("Found approved pilot: ${latestApprovedPilot['buyerPilotId']}");
          debugPrint("adminStatus: $adminStatus, buyerStatus: $buyerStatus");

          setState(() {
            _pilotRegistrationData = {
              ...latestApprovedPilot,
              'hasRegistration': true,
              'status': adminStatus, // This should be "approved"
              'isApproved': true, // This should be true since adminStatus is approved
            };
          });

          debugPrint("Updated pilot data: status = ${_pilotRegistrationData?['status']}, isApproved = ${_pilotRegistrationData?['isApproved']}");
        } else {
          // No approved pilots found, show the latest one (even if pending/rejected)
          final latestPilot = buyerPilots.first;
          final adminStatus = latestPilot['adminStatus']?.toString().toLowerCase() ?? 'pending';
          final isApproved = adminStatus == 'approved';

          debugPrint("No approved pilots found. Showing latest: ${latestPilot['buyerPilotId']} with status: $adminStatus");

          setState(() {
            _pilotRegistrationData = {
              ...latestPilot,
              'hasRegistration': true,
              'status': adminStatus,
              'isApproved': isApproved,
            };
          });
        }
      } else {
        debugPrint("No pilot registrations found for buyer: ${_buyerData?['buyerId']}");
        setState(() {
          _pilotRegistrationData = {'hasRegistration': false};
        });
      }
    } catch (e) {
      debugPrint("Error checking pilot status: $e");
      setState(() {
        _pilotRegistrationData = {'hasRegistration': false};
      });
    }
  }

  String _getPilotStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return 'Approved Pilot ✓';
      case 'pending':
        return 'Pending Review';
      case 'rejected':
        return 'Registration Rejected';
      default:
        return 'Not Registered';
    }
  }

  Color _getPilotStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPilotStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Icons.verified;
      case 'pending':
        return Icons.access_time;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.person_add;
    }
  }

  String _getStatusMessage(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return 'Congratulations! Your pilot registration has been approved. You can now accept pilot bookings and manage them from your profile.';
      case 'pending':
        return 'Your pilot application is under review by our team. We will notify you once a decision is made.';
      case 'rejected':
        return 'Your pilot registration application has been rejected. Please contact support for more details or reapply.';
      default:
        return 'You have not submitted a pilot registration yet. Click "Become a Pilot" to start your application.';
    }
  }

  Widget _buildPilotRegistrationSection() {
    if (_checkingPilotStatus) {
      return _buildLoadingCard();
    }

    final hasRegistration = _pilotRegistrationData?['hasRegistration'] ?? false;
    final isApproved = _pilotRegistrationData?['isApproved'] ?? false;
    final status = _pilotRegistrationData?['status'] as String?;
    final statusText = _getPilotStatusText(status);
    final statusColor = _getPilotStatusColor(status);
    final statusIcon = _getPilotStatusIcon(status);

    // If buyer has no pilot registration, show "Become a Pilot" button
    if (!hasRegistration) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // Info card about becoming a pilot
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[700],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Become a certified pilot and start earning by offering your pilot services",
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final buyerId = _buyerData?['buyerId'] ?? '';
                if (buyerId.isEmpty) {
                  _showMessage("Please complete your profile first");
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BecomeAPilotPage(buyerId: buyerId),
                  ),
                ).then((_) {
                  // Refresh pilot status after returning
                  _checkPilotRegistrationStatus();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_alt_1_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "Become a Pilot",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // If buyer has pilot registration, show status card
    return Column(
      children: [
        // Status card
        GestureDetector(
          onTap: () => _showPilotStatusDialog(),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: statusColor.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pilot Registration Status",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                      if (isApproved)
                        const SizedBox(height: 6),
                      if (isApproved)
                        Text(
                          "You can now accept pilot bookings",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),

        // If approved, show pilot booking status link
        if (isApproved)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: TextButton(
              onPressed: () {
                final buyerId = _buyerData?['buyerId'] ?? '';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BuyerPilotBookingStatusPage(buyerId: buyerId),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.airplanemode_active_outlined, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "View Pilot Bookings",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Checking Pilot Status",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Loading...",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPilotStatusDialog() {
    final hasRegistration = _pilotRegistrationData?['hasRegistration'] ?? false;
    final status = _pilotRegistrationData?['status'] as String?;
    final statusText = _getPilotStatusText(status);
    final statusColor = _getPilotStatusColor(status);
    final statusIcon = _getPilotStatusIcon(status);
    final statusMessage = _getStatusMessage(status);
    final isApproved = _pilotRegistrationData?['isApproved'] ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Pilot Registration",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Current Status",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                statusMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              if (isApproved) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "You can now accept pilot bookings and manage them from your profile",
                          style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text("Close"),
          ),
          if (!hasRegistration)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final buyerId = _buyerData?['buyerId'] ?? '';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BecomeAPilotPage(buyerId: buyerId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text("Apply Now"),
            ),
        ],
      ),
    );
  }

  Future<void> _switchToSeller() async {
    HapticFeedback.selectionClick();
    try {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SellerPage()),
      );
    } catch (e) {
      debugPrint("⚠ Switch to seller error: $e");
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _auth.signOut();
                    await RoleManager.clearRole();
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Dynamichome(selectedIndex: 0),
                      ),
                          (route) => false,
                    );
                  },
                  child: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchSocialMedia(String platform) async {
    final url = socialMediaUrls[platform];

    if (url == null) {
      _showMessage("Link not available for $platform");
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (platform == 'whatsapp' && url.contains('wa.me')) {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          final webUri = Uri.parse('https://web.whatsapp.com/');
          if (await canLaunchUrl(webUri)) {
            await launchUrl(webUri);
          } else {
            _showMessage("Could not launch WhatsApp");
          }
        }
      } else {
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          _showMessage("Could not launch $platform");
        }
      }
    } catch (e) {
      debugPrint("Error launching $platform: $e");
      _showMessage("Error opening $platform");
    }
  }

  Future<void> _makePhoneCall() async {
    final phoneNumber = '9003992693';
    final url = Uri.parse('tel:$phoneNumber');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        _showMessage("Could not make a phone call");
      }
    } catch (e) {
      debugPrint("Error making phone call: $e");
      _showMessage("Error making phone call");
    }
  }

  Widget _buildProfileHeader() {
    final name = _buyerData?['name'] ??
        _buyerData?['firstName'] ??
        _user?.displayName ??
        "Buyer";
    final email = _buyerData?['email'] ?? _user?.email ?? "";

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : "B",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    bool showDivider = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        ...children,
        if (showDivider) const Divider(height: 0, thickness: 1, color: Color(0xFFF0F0F0)),
      ],
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    bool showTrailing = true,
    String? subtitle,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (iconColor ?? primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor ?? primaryColor,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      )
          : null,
      trailing: showTrailing
          ? Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      dense: true,
    );
  }

  Widget _buildDroneListItem({
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    bool showTrailing = true,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: (iconColor ?? primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SvgPicture.asset(
          'assets/categories/drone1.svg',
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(
            iconColor ?? primaryColor,
            BlendMode.srcIn,
          ),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: showTrailing
          ? Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      dense: true,
    );
  }

  Widget _buildSocialIcon(String iconPath, {required VoidCallback onTap, String? tooltip}) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? '',
        child: Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Image.asset(
            iconPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 20,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEarnWithFlyhubSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              "Earn with Flyhub",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SellerLoginPage()),
              ),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.storefront_outlined,
                        color: Colors.green.shade700,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Sell on Flyhub",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Start your seller journey and grow your business",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey.shade500,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const Dynamichome(selectedIndex: 0),
              ),
            );
          },
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // Profile Header
                _buildProfileHeader(),

                // Quick Actions
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionButton(
                        icon: Icons.phone,
                        label: "Bulk order",
                        color: Colors.green,
                        onTap: () => _makePhoneCall(),
                      ),
                      _buildActionButton(
                        icon: Icons.shopping_bag_outlined,
                        label: "Cart",
                        color: Colors.purple,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyCartPage()),
                        ),
                      ),
                      _buildActionButton(
                        icon: Icons.favorite_border,
                        label: "Wishlist",
                        color: Colors.pink,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WishlistPage()),
                        ),
                      ),
                      _buildActionButton(
                        icon: Icons.receipt_long,
                        label: "Orders",
                        color: Colors.blue,
                        onTap: () {
                          final buyerId = _buyerData?['buyerId'] ?? '';
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MyOrderPage(buyerId: buyerId),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Pilot Registration Status Section
                _buildPilotRegistrationSection(),

                // Activities Section
                _buildSection(
                  title: "My Activities",
                  children: [
                    _buildDroneListItem(
                      title: "Drone Rentals",
                      onTap: () {
                        final buyerId = _buyerData?['buyerId'] ?? '';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DroneRentalApprovalPage(buyerId: buyerId),
                          ),
                        );
                      },
                    ),
                    _buildListItem(
                      icon: Icons.work_outline,
                      title: "Job Applications",
                      onTap: () {
                        final buyerId = _buyerData?['buyerId'] ?? '';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BuyerJobApplyStatusPage(buyerId: buyerId),
                          ),
                        );
                      },
                    ),
                    _buildListItem(
                      icon: Icons.person_2_outlined,
                      title: "Pilot Bookings",
                      onTap: () {
                        final buyerId = _buyerData?['buyerId'] ?? '';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PilotBookingStatusPage(buyerId: buyerId),
                          ),
                        );
                      },
                    ),
                    _buildListItem(
                      icon: Icons.handyman_outlined,
                      title: "Service Bookings",
                      onTap: () {
                        final buyerId = _buyerData?['buyerId'] ?? '';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BuyerServiceBookingStatusPage(buyerId: buyerId),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // Earn with Flyhub Section
                _buildEarnWithFlyhubSection(),

                // Support Section
                _buildSection(
                  title: "Support",
                  children: [
                    _buildListItem(
                      icon: Icons.help_outline,
                      title: "Help & Support",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpAndSupportPage()),
                      ),
                    ),
                    _buildListItem(
                      icon: Icons.feedback_outlined,
                      title: "Send Feedback",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FeedbackFormPage()),
                      ),
                    ),
                    _buildListItem(
                      icon: Icons.description_outlined,
                      title: "Terms & Conditions",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsAndConditionsPage()),
                      ),
                    ),
                    _buildListItem(
                      icon: Icons.privacy_tip_outlined,
                      title: "Privacy Policy",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                      ),
                    ),
                    _buildListItem(
                      icon: Icons.local_shipping_outlined,
                      title: "Shipping Policy",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BuyerShippingPolicyPage()),
                      ),
                    ),
                    _buildListItem(
                      icon: Icons.assignment_return_outlined,
                      title: "Return Policy",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RRPolicy()),
                      ),
                    ),
                  ],
                  showDivider: false,
                ),

                // Account Section
                _buildSection(
                  title: "Account",
                  children: [
                    _buildListItem(
                      icon: Icons.settings_outlined,
                      title: "Settings",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      ),
                    ),
                  ],
                ),

                // Logout Button
                Container(
                  color: Colors.white,
                  margin: const EdgeInsets.only(top: 8),
                  child: ListTile(
                    onTap: _logout,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.logout,
                        size: 20,
                        color: Colors.red,
                      ),
                    ),
                    title: const Text(
                      "Logout",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    dense: true,
                  ),
                ),

                // Follow Us Footer
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Follow us on",
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialIcon(
                            'assets/categories/instagram.png',
                            onTap: () => _launchSocialMedia('instagram'),
                            tooltip: 'Follow us on Instagram',
                          ),
                          const SizedBox(width: 20),

                          _buildSocialIcon(
                            'assets/categories/facebook.png',
                            onTap: () => _launchSocialMedia('facebook'),
                            tooltip: 'Like us on Facebook',
                          ),
                          const SizedBox(width: 20),

                          _buildSocialIcon(
                            'assets/categories/linkedin.png',
                            onTap: () => _launchSocialMedia('linkedin'),
                            tooltip: 'Connect on LinkedIn',
                          ),
                          const SizedBox(width: 20),

                          _buildSocialIcon(
                            'assets/categories/whatsapp.png',
                            onTap: () => _launchSocialMedia('whatsapp'),
                            tooltip: 'Message us on WhatsApp',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: () async {
                          final Uri url = Uri.parse("https://www.flyhub.info");
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.withOpacity(1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.open_in_new, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                "Explore Our Website",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        "v1.0.0",
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
