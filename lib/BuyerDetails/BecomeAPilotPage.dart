// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:graphql_flutter/graphql_flutter.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:intl/intl.dart';
//
// import '../config/env.dart';
//
// class BecomeAPilotPage extends StatefulWidget {
//   final String buyerId;
//   const BecomeAPilotPage({super.key, required this.buyerId});
//
//   @override
//   State<BecomeAPilotPage> createState() => _BecomeAPilotPageState();
// }
//
// class _BecomeAPilotPageState extends State<BecomeAPilotPage> {
//   // Professional Color Scheme
//   static const Color primaryColor = Color(0xFF1A0A5B);
//   static const Color secondaryColor = Color(0xFF4C1D95);
//   static const Color accentColor = Color(0xFF00D9A3);
//   static const Color backgroundColor = Colors.white;
//   static const Color surfaceColor = Colors.white;
//   static const Color textPrimary = Color(0xFF111827);
//   static const Color textSecondary = Color(0xFF6B7280);
//   static const Color borderColor = Color(0xFFE5E7EB);
//   static const Color successColor = Color(0xFF10B981);
//   static const Color errorColor = Color(0xFFEF4444);
//   static const Color warningColor = Color(0xFFF59E0B);
//   static const Color infoColor = Color(0xFF3B82F6);
//   static const Color cardColor = Color(0xFFF9FAFB);
//
//   // Form controllers
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _companyController = TextEditingController();
//   final TextEditingController _locationController = TextEditingController();
//   final TextEditingController _specificationController = TextEditingController();
//   final TextEditingController _perHourController = TextEditingController();
//   final TextEditingController _perDayController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//
//   // Form state
//   final _formKey = GlobalKey<FormState>();
//   bool _isSubmitting = false;
//   bool _isLoading = true;
//   String? _errorMessage;
//
//   // File pickers
//   final ImagePicker _picker = ImagePicker();
//   File? _profileImage;
//   File? _rpcCertificateImage;
//   bool _isUploadingCertificate = false;
//   double _certificateUploadProgress = 0.0;
//
//   // RPC Status
//   bool _hasRPCCertificate = false;
//
//   // Pilot availability
//   bool _availability = true;
//
//   // Firebase
//   final String graphqlUrl = EnvConfig.baseUrl;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadInitialData();
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _companyController.dispose();
//     _locationController.dispose();
//     _specificationController.dispose();
//     _perHourController.dispose();
//     _perDayController.dispose();
//     _descriptionController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadInitialData() async {
//     try {
//       // Load buyer data if needed
//       await Future.delayed(const Duration(milliseconds: 300));
//       setState(() => _isLoading = false);
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = "Failed to load data: ${e.toString()}";
//       });
//     }
//   }
//
//   Future<void> _ensureFirebaseAuth() async {
//     try {
//       if (_auth.currentUser == null) {
//         await _auth.signInAnonymously();
//       }
//     } catch (e) {
//       debugPrint("❌ Firebase auth error: $e");
//       throw Exception('Failed to authenticate with Firebase');
//     }
//   }
//
//   Future<String> _uploadFileToFirebase(File file, String type) async {
//     await _ensureFirebaseAuth();
//     try {
//       final uid = _auth.currentUser?.uid ?? "unknown";
//       final timestamp = DateTime.now().millisecondsSinceEpoch;
//       final extension = file.path.split('.').last.toLowerCase();
//       final fileName = "pilots/${widget.buyerId}/$type/${timestamp}_$uid.$extension";
//       final ref = _storage.ref().child(fileName);
//
//       debugPrint("🚀 Uploading $type: $fileName");
//
//       final metadata = SettableMetadata(
//         contentType: 'image/jpeg',
//         customMetadata: {
//           'uploadedBy': widget.buyerId,
//           'timestamp': DateTime.now().toIso8601String(),
//           'type': type,
//         },
//       );
//
//       final uploadTask = ref.putFile(file, metadata);
//
//       // Track upload progress
//       uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
//         final progress = snapshot.bytesTransferred / snapshot.totalBytes.toDouble();
//         setState(() {
//           if (type == 'certificate') {
//             _certificateUploadProgress = progress;
//           }
//         });
//       });
//
//       await uploadTask;
//       final url = await ref.getDownloadURL();
//       debugPrint("✅ Uploaded $type: $url");
//       return url;
//     } catch (e) {
//       debugPrint("❌ Firebase Upload Error for $type: $e");
//       throw Exception("$type upload failed: $e");
//     }
//   }
//
//   Future<void> _pickProfileImage() async {
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 85,
//       );
//
//       if (image != null) {
//         setState(() {
//           _profileImage = File(image.path);
//         });
//         _showSnackBar('Profile photo added successfully', color: successColor);
//       }
//     } catch (e) {
//       _showSnackBar('Error picking image: ${e.toString()}', isError: true);
//     }
//   }
//
//   Future<void> _pickRPCCertificate() async {
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 90,
//       );
//
//       if (image != null) {
//         final file = File(image.path);
//         final fileSize = await file.length();
//
//         // Validate file size (10MB limit)
//         if (fileSize > 10 * 1024 * 1024) {
//           _showSnackBar('Certificate size must be less than 10MB', isError: true);
//           return;
//         }
//
//         setState(() {
//           _isUploadingCertificate = true;
//           _certificateUploadProgress = 0.0;
//         });
//
//         try {
//           await _uploadFileToFirebase(file, 'certificate');
//           setState(() {
//             _rpcCertificateImage = file;
//           });
//           _showSnackBar('RPC certificate uploaded successfully', color: successColor);
//         } catch (e) {
//           _showSnackBar('Failed to upload certificate: ${e.toString()}', isError: true);
//         } finally {
//           setState(() {
//             _isUploadingCertificate = false;
//           });
//         }
//       }
//     } catch (e) {
//       _showSnackBar('Error picking certificate: ${e.toString()}', isError: true);
//     }
//   }
//
//   void _removeRPCCertificate() {
//     setState(() {
//       _rpcCertificateImage = null;
//     });
//     _showSnackBar('RPC certificate removed', color: infoColor);
//   }
//
//   Widget _buildProfileImagePicker() {
//     return GestureDetector(
//       onTap: _pickProfileImage,
//       child: Container(
//         width: MediaQuery.of(context).size.width * 0.25,
//         height: MediaQuery.of(context).size.width * 0.25,
//         decoration: BoxDecoration(
//           color: borderColor.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: borderColor,
//             width: 1.5,
//           ),
//         ),
//         child: _profileImage != null
//             ? ClipRRect(
//           borderRadius: BorderRadius.circular(12),
//           child: Stack(
//             children: [
//               Image.file(
//                 _profileImage!,
//                 fit: BoxFit.cover,
//                 width: double.infinity,
//                 height: double.infinity,
//               ),
//               Positioned(
//                 top: 4,
//                 right: 4,
//                 child: Container(
//                   padding: const EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.6),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.edit,
//                     size: 14,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         )
//             : Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.add_a_photo_outlined,
//               size: MediaQuery.of(context).size.width * 0.07,
//               color: textSecondary,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'Add Photo',
//               style: GoogleFonts.inter(
//                 color: textSecondary,
//                 fontSize: MediaQuery.of(context).size.width * 0.03,
//                 fontWeight: FontWeight.w500,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildRPCCertificateSection() {
//     final screenWidth = MediaQuery.of(context).size.width;
//
//     return Container(
//       decoration: BoxDecoration(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: borderColor),
//       ),
//       padding: EdgeInsets.all(screenWidth * 0.04),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "RPC Certificate Status",
//             style: GoogleFonts.inter(
//               fontWeight: FontWeight.w600,
//               color: textPrimary,
//               fontSize: screenWidth * 0.04,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Select your current RPC certification status",
//             style: GoogleFonts.inter(
//               color: textSecondary,
//               fontSize: screenWidth * 0.035,
//             ),
//           ),
//           const SizedBox(height: 16),
//
//           // RPC Options
//           Column(
//             children: [
//               // Have RPC Option
//               GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     _hasRPCCertificate = true;
//                   });
//                 },
//                 child: Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.symmetric(
//                     vertical: MediaQuery.of(context).size.height * 0.016,
//                     horizontal: screenWidth * 0.04,
//                   ),
//                   margin: const EdgeInsets.only(bottom: 12),
//                   decoration: BoxDecoration(
//                     color: _hasRPCCertificate
//                         ? successColor.withOpacity(0.1)
//                         : Colors.white,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: _hasRPCCertificate ? successColor : borderColor,
//                       width: _hasRPCCertificate ? 1.5 : 1,
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 32,
//                         height: 32,
//                         decoration: BoxDecoration(
//                           color: _hasRPCCertificate
//                               ? successColor.withOpacity(0.2)
//                               : borderColor.withOpacity(0.3),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           Icons.verified_outlined,
//                           color: _hasRPCCertificate ? successColor : textSecondary,
//                           size: 18,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'I have RPC Certificate',
//                               style: GoogleFonts.inter(
//                                 color: _hasRPCCertificate ? successColor : textPrimary,
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: screenWidth * 0.038,
//                               ),
//                             ),
//                             Text(
//                               'Already certified pilot',
//                               style: GoogleFonts.inter(
//                                 color: textSecondary,
//                                 fontSize: screenWidth * 0.032,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       if (_hasRPCCertificate)
//                         Icon(
//                           Icons.check_circle,
//                           color: successColor,
//                           size: 20,
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//               // Need RPC Option
//               GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     _hasRPCCertificate = false;
//                     _rpcCertificateImage = null;
//                   });
//                   _openRPCTrainingWebsite();
//                 },
//                 child: Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.symmetric(
//                     vertical: MediaQuery.of(context).size.height * 0.016,
//                     horizontal: screenWidth * 0.04,
//                   ),
//                   decoration: BoxDecoration(
//                     color: !_hasRPCCertificate
//                         ? primaryColor.withOpacity(0.05)
//                         : Colors.white,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: !_hasRPCCertificate ? primaryColor : borderColor,
//                       width: !_hasRPCCertificate ? 1.5 : 1,
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 32,
//                         height: 32,
//                         decoration: BoxDecoration(
//                           color: !_hasRPCCertificate
//                               ? primaryColor.withOpacity(0.1)
//                               : borderColor.withOpacity(0.3),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           Icons.school_outlined,
//                           color: !_hasRPCCertificate ? primaryColor : textSecondary,
//                           size: 18,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Need RPC Certificate',
//                               style: GoogleFonts.inter(
//                                 color: !_hasRPCCertificate ? primaryColor : textPrimary,
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: screenWidth * 0.038,
//                               ),
//                             ),
//                             Text(
//                               'Get certified through Flytutor.in',
//                               style: GoogleFonts.inter(
//                                 color: textSecondary,
//                                 fontSize: screenWidth * 0.032,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       if (!_hasRPCCertificate)
//                         Icon(
//                           Icons.arrow_forward_ios_rounded,
//                           color: primaryColor,
//                           size: 16,
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//
//           // RPC Certificate Upload (only if they have one)
//           if (_hasRPCCertificate) ...[
//             const SizedBox(height: 20),
//             Text(
//               "Upload RPC Certificate",
//               style: GoogleFonts.inter(
//                 fontWeight: FontWeight.w600,
//                 color: textPrimary,
//                 fontSize: screenWidth * 0.04,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               "Upload a clear photo or scan of your valid RPC certificate",
//               style: GoogleFonts.inter(
//                 color: textSecondary,
//                 fontSize: screenWidth * 0.035,
//               ),
//             ),
//             const SizedBox(height: 16),
//
//             if (_isUploadingCertificate)
//               Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.symmetric(
//                   vertical: MediaQuery.of(context).size.height * 0.04,
//                 ),
//                 decoration: BoxDecoration(
//                   color: borderColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: borderColor, width: 1.5),
//                 ),
//                 child: Column(
//                   children: [
//                     SizedBox(
//                       width: 40,
//                       height: 40,
//                       child: CircularProgressIndicator(
//                         value: _certificateUploadProgress,
//                         valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
//                         strokeWidth: 3,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       'Uploading Certificate... ${(_certificateUploadProgress * 100).toStringAsFixed(0)}%',
//                       style: GoogleFonts.inter(
//                         color: textPrimary,
//                         fontSize: screenWidth * 0.038,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               )
//             else if (_rpcCertificateImage == null)
//               GestureDetector(
//                 onTap: _pickRPCCertificate,
//                 child: Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.symmetric(
//                     vertical: MediaQuery.of(context).size.height * 0.04,
//                   ),
//                   decoration: BoxDecoration(
//                     color: accentColor.withOpacity(0.05),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: accentColor.withOpacity(0.3),
//                       width: 1.5,
//                     ),
//                   ),
//                   child: Column(
//                     children: [
//                       Icon(
//                         Icons.cloud_upload_outlined,
//                         size: screenWidth * 0.1,
//                         color: accentColor,
//                       ),
//                       const SizedBox(height: 12),
//                       Text(
//                         'Upload RPC Certificate',
//                         style: GoogleFonts.inter(
//                           color: accentColor,
//                           fontSize: screenWidth * 0.04,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Click to upload certificate image (Max 10MB)',
//                         style: GoogleFonts.inter(
//                           color: textSecondary,
//                           fontSize: screenWidth * 0.035,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               )
//             else
//               Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: borderColor),
//                 ),
//                 child: Column(
//                   children: [
//                     Stack(
//                       children: [
//                         ClipRRect(
//                           borderRadius: const BorderRadius.only(
//                             topLeft: Radius.circular(8),
//                             topRight: Radius.circular(8),
//                           ),
//                           child: Image.file(
//                             _rpcCertificateImage!,
//                             fit: BoxFit.cover,
//                             width: double.infinity,
//                             height: MediaQuery.of(context).size.height * 0.2,
//                           ),
//                         ),
//                         Positioned(
//                           top: 8,
//                           right: 8,
//                           child: Container(
//                             padding: const EdgeInsets.all(4),
//                             decoration: const BoxDecoration(
//                               color: Colors.white,
//                               shape: BoxShape.circle,
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black12,
//                                   blurRadius: 4,
//                                   offset: Offset(0, 2),
//                                 ),
//                               ],
//                             ),
//                             child: Icon(
//                               Icons.verified,
//                               color: successColor,
//                               size: 20,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: const BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.only(
//                           bottomLeft: Radius.circular(8),
//                           bottomRight: Radius.circular(8),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'RPC Certificate',
//                                   style: GoogleFonts.inter(
//                                     fontWeight: FontWeight.w600,
//                                     color: textPrimary,
//                                     fontSize: screenWidth * 0.038,
//                                   ),
//                                 ),
//                                 Text(
//                                   'Uploaded successfully',
//                                   style: GoogleFonts.inter(
//                                     color: successColor,
//                                     fontSize: screenWidth * 0.032,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           IconButton(
//                             onPressed: _removeRPCCertificate,
//                             icon: Icon(
//                               Icons.delete_outline_rounded,
//                               color: errorColor,
//                               size: 22,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//           ] else ...[
//             // Training Information for those needing RPC
//             const SizedBox(height: 20),
//             Container(
//               padding: EdgeInsets.all(screenWidth * 0.04),
//               decoration: BoxDecoration(
//                 color: infoColor.withOpacity(0.05),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: infoColor.withOpacity(0.2)),
//               ),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Icon(
//                     Icons.info_outline_rounded,
//                     color: infoColor,
//                     size: 20,
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "RPC Training Required",
//                           style: GoogleFonts.inter(
//                             fontWeight: FontWeight.w600,
//                             color: infoColor,
//                             fontSize: screenWidth * 0.038,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           "Click 'Need RPC Certificate' to visit FlyTutor.in for DGCA approved RPC training courses.",
//                           style: GoogleFonts.inter(
//                             color: textSecondary,
//                             fontSize: screenWidth * 0.034,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFormField({
//     required String label,
//     required TextEditingController controller,
//     required IconData icon,
//     TextInputType keyboardType = TextInputType.text,
//     int maxLines = 1,
//     bool isRequired = true,
//     String? hintText,
//     String? Function(String?)? validator,
//   }) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Text(
//               label,
//               style: GoogleFonts.inter(
//                 fontWeight: FontWeight.w500,
//                 color: textPrimary,
//                 fontSize: screenWidth * 0.04,
//               ),
//             ),
//             if (isRequired)
//               Text(
//                 ' *',
//                 style: GoogleFonts.inter(
//                   fontWeight: FontWeight.w500,
//                   color: errorColor,
//                   fontSize: screenWidth * 0.04,
//                 ),
//               ),
//           ],
//         ),
//         const SizedBox(height: 6),
//         TextFormField(
//           controller: controller,
//           keyboardType: keyboardType,
//           maxLines: maxLines,
//           validator: validator ??
//                   (value) {
//                 if (isRequired && (value == null || value.isEmpty)) {
//                   return 'This field is required';
//                 }
//                 return null;
//               },
//           style: GoogleFonts.inter(
//             color: textPrimary,
//             fontSize: screenWidth * 0.04,
//           ),
//           decoration: InputDecoration(
//             hintText: hintText ?? 'Enter $label',
//             hintStyle: GoogleFonts.inter(
//               color: textSecondary,
//               fontSize: screenWidth * 0.04,
//             ),
//             prefixIcon: Icon(
//               icon,
//               color: textSecondary,
//               size: 20,
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: const BorderSide(color: borderColor),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: const BorderSide(color: borderColor),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: const BorderSide(color: primaryColor, width: 1.5),
//             ),
//             errorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: const BorderSide(color: errorColor),
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             contentPadding: EdgeInsets.symmetric(
//               horizontal: screenWidth * 0.04,
//               vertical: screenHeight * 0.016,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildAvailabilityToggle() {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//
//     return Container(
//       padding: EdgeInsets.all(screenWidth * 0.04),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: borderColor),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.calendar_today_outlined,
//                       color: textPrimary,
//                       size: 20,
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         'Available for Hire',
//                         style: GoogleFonts.inter(
//                           color: textPrimary,
//                           fontSize: screenWidth * 0.04,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.only(left: 32),
//                   child: Text(
//                     _availability
//                         ? 'Currently accepting projects'
//                         : 'Not available for hire',
//                     style: GoogleFonts.inter(
//                       color: textSecondary,
//                       fontSize: screenWidth * 0.035,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Switch(
//             value: _availability,
//             onChanged: (value) {
//               setState(() {
//                 _availability = value;
//               });
//             },
//             activeColor: successColor,
//             materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPricingSection() {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//
//     return Container(
//       decoration: BoxDecoration(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: borderColor),
//       ),
//       padding: EdgeInsets.all(screenWidth * 0.04),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Service Pricing',
//             style: GoogleFonts.inter(
//               fontWeight: FontWeight.w600,
//               color: textPrimary,
//               fontSize: screenWidth * 0.04,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Hourly Rate (₹)',
//                       style: GoogleFonts.inter(
//                         fontWeight: FontWeight.w500,
//                         color: textPrimary,
//                         fontSize: screenWidth * 0.038,
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     TextFormField(
//                       controller: _perHourController,
//                       keyboardType: TextInputType.number,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Required';
//                         }
//                         final price = double.tryParse(value);
//                         if (price == null || price <= 0) {
//                           return 'Invalid amount';
//                         }
//                         return null;
//                       },
//                       style: GoogleFonts.inter(
//                         color: textPrimary,
//                         fontSize: screenWidth * 0.04,
//                       ),
//                       decoration: InputDecoration(
//                         hintText: '1500',
//                         hintStyle: GoogleFonts.inter(
//                           color: textSecondary,
//                           fontSize: screenWidth * 0.04,
//                         ),
//                         prefixIcon: const Icon(
//                           Icons.currency_rupee_rounded,
//                           size: 20,
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(color: borderColor),
//                         ),
//                         filled: true,
//                         fillColor: Colors.white,
//                         contentPadding: EdgeInsets.symmetric(
//                           horizontal: screenWidth * 0.04,
//                           vertical: screenHeight * 0.014,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(width: screenWidth * 0.04),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Daily Rate (₹)',
//                       style: GoogleFonts.inter(
//                         fontWeight: FontWeight.w500,
//                         color: textPrimary,
//                         fontSize: screenWidth * 0.038,
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     TextFormField(
//                       controller: _perDayController,
//                       keyboardType: TextInputType.number,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Required';
//                         }
//                         final price = double.tryParse(value);
//                         if (price == null || price <= 0) {
//                           return 'Invalid amount';
//                         }
//                         return null;
//                       },
//                       style: GoogleFonts.inter(
//                         color: textPrimary,
//                         fontSize: screenWidth * 0.04,
//                       ),
//                       decoration: InputDecoration(
//                         hintText: '12000',
//                         hintStyle: GoogleFonts.inter(
//                           color: textSecondary,
//                           fontSize: screenWidth * 0.04,
//                         ),
//                         prefixIcon: const Icon(
//                           Icons.currency_rupee_rounded,
//                           size: 20,
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(color: borderColor),
//                         ),
//                         filled: true,
//                         fillColor: Colors.white,
//                         contentPadding: EdgeInsets.symmetric(
//                           horizontal: screenWidth * 0.04,
//                           vertical: screenHeight * 0.014,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _openRPCTrainingWebsite() async {
//     const url = 'https://flytutor.in';
//     try {
//       if (await canLaunchUrl(Uri.parse(url))) {
//         await launchUrl(Uri.parse(url));
//       } else {
//         _showSnackBar('Could not open the website', isError: true);
//       }
//     } catch (e) {
//       _showSnackBar('Error: ${e.toString()}', isError: true);
//     }
//   }
//
//   void _showSnackBar(String message, {bool isError = false, Color? color}) {
//     ScaffoldMessenger.of(context).hideCurrentSnackBar();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         backgroundColor: color ?? (isError ? errorColor : successColor),
//         content: Text(
//           message,
//           style: GoogleFonts.inter(
//             color: Colors.white,
//             fontSize: MediaQuery.of(context).size.width * 0.038,
//           ),
//         ),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _submitBuyerPilot() async {
//     if (!_formKey.currentState!.validate()) {
//       _showSnackBar('Please fill all required fields correctly', isError: true);
//       return;
//     }
//
//     // Validate RPC certificate if they said they have one
//     if (_hasRPCCertificate && _rpcCertificateImage == null) {
//       _showSnackBar('Please upload your RPC certificate', isError: true);
//       return;
//     }
//
//     // Validate pricing
//     final perHour = double.tryParse(_perHourController.text);
//     final perDay = double.tryParse(_perDayController.text);
//
//     if (perHour == null || perHour <= 0) {
//       _showSnackBar('Please enter a valid per hour price', isError: true);
//       return;
//     }
//
//     if (perDay == null || perDay <= 0) {
//       _showSnackBar('Please enter a valid per day price', isError: true);
//       return;
//     }
//
//     // Validate email
//     final email = _emailController.text.trim();
//     if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
//       _showSnackBar('Please enter a valid email address', isError: true);
//       return;
//     }
//
//     // Validate phone
//     final phone = _phoneController.text.trim();
//     if (!RegExp(r'^[0-9]{10,}$').hasMatch(phone)) {
//       _showSnackBar('Please enter a valid phone number (minimum 10 digits)', isError: true);
//       return;
//     }
//
//     setState(() {
//       _isSubmitting = true;
//       _errorMessage = null;
//     });
//
//     try {
//       // Upload RPC certificate if exists
//       String? rpcUrl;
//       if (_hasRPCCertificate && _rpcCertificateImage != null) {
//         rpcUrl = await _uploadFileToFirebase(_rpcCertificateImage!, 'certificate');
//       }
//
//       // 2. Create GraphQL client
//       final client = GraphQLClient(
//         link: HttpLink(graphqlUrl),
//         cache: GraphQLCache(store: InMemoryStore()),
//       );
//
//       // 3. Prepare GraphQL mutation
//       final mutation = gql("""
//         mutation AddBuyerPilot(\$input: BuyerPilotInput!) {
//           addBuyerPilot(input: \$input) {
//             buyerPilotId
//             pilotName
//             pilotCompany
//             location
//             availability
//             specification
//             price {
//               perHour
//               perDay
//             }
//             certifications {
//               url
//             }
//             description
//             newemail
//             newphoneNumber
//             adminStatus
//             buyerStatus
//             buyerId
//             buyer {
//               buyerId
//               name
//               email
//               phoneNumber
//             }
//           }
//         }
//       """);
//
//       // 4. Prepare certifications array (only RPC certificate)
//       List<Map<String, dynamic>> certifications = [];
//       if (rpcUrl != null) {
//         certifications.add({'url': rpcUrl});
//       }
//
//       // 5. Execute mutation
//       final result = await client.mutate(
//         MutationOptions(
//           document: mutation,
//           variables: {
//             'input': {
//               'pilotName': _nameController.text.trim(),
//               'pilotCompany': _companyController.text.trim(),
//               'location': _locationController.text.trim(),
//               'availability': _availability,
//               'specification': _specificationController.text.trim(),
//               'price': {
//                 'perHour': perHour,
//                 'perDay': perDay,
//               },
//               'certifications': certifications,
//               'description': _descriptionController.text.trim(),
//               'newemail': email,
//               'newphoneNumber': phone,
//               'buyerId': widget.buyerId,
//             },
//           },
//           fetchPolicy: FetchPolicy.noCache,
//         ),
//       );
//
//       if (result.hasException) {
//         debugPrint("❌ GraphQL Error: ${result.exception.toString()}");
//         String errorMessage = "Submission failed";
//         if (result.exception!.graphqlErrors.isNotEmpty) {
//           errorMessage = result.exception!.graphqlErrors.first.message;
//         } else if (result.exception!.linkException != null) {
//           errorMessage = "Network error: ${result.exception!.linkException}";
//         }
//         throw Exception(errorMessage);
//       } else {
//         debugPrint("✅ BuyerPilot Created Successfully!");
//         _showSnackBar(
//           '✅ Pilot application submitted successfully! Your profile is under review.',
//           color: successColor,
//         );
//
//         // Navigate back after success
//         await Future.delayed(const Duration(seconds: 1));
//         if (mounted) {
//           Navigator.pop(context, true);
//         }
//       }
//     } catch (e) {
//       debugPrint("⚠ Error submitting pilot application: $e");
//       setState(() {
//         _errorMessage = e.toString();
//       });
//       _showSnackBar('Error: ${e.toString()}', isError: true);
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSubmitting = false;
//           _certificateUploadProgress = 0.0;
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Scaffold(
//         backgroundColor: backgroundColor,
//         body: Center(
//           child: CircularProgressIndicator(color: primaryColor),
//         ),
//       );
//     }
//
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final isSmallScreen = screenWidth < 600;
//
//     return Scaffold(
//       backgroundColor: backgroundColor,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Header
//             Container(
//               padding: EdgeInsets.symmetric(
//                 horizontal: screenWidth * 0.05,
//                 vertical: screenHeight * 0.02,
//               ),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 border: Border(
//                   bottom: BorderSide(color: borderColor, width: 1),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(
//                       Icons.arrow_back_ios_new_rounded,
//                       color: primaryColor,
//                       size: 20,
//                     ),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                   SizedBox(width: screenWidth * 0.02),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Pilot Registration',
//                           style: GoogleFonts.inter(
//                             fontWeight: FontWeight.w700,
//                             fontSize: isSmallScreen ? 18 : 20,
//                             color: primaryColor,
//                           ),
//                         ),
//                         Text(
//                           'Join our professional pilot network',
//                           style: GoogleFonts.inter(
//                             color: textSecondary,
//                             fontSize: isSmallScreen ? 12 : 13,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   if (_isSubmitting)
//                     Padding(
//                       padding: const EdgeInsets.only(right: 8),
//                       child: SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: primaryColor,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//
//             Expanded(
//               child: SingleChildScrollView(
//                 physics: const BouncingScrollPhysics(),
//                 padding: EdgeInsets.all(screenWidth * 0.05),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Profile Image
//                     Center(
//                       child: Column(
//                         children: [
//                           _buildProfileImagePicker(),
//                           SizedBox(height: screenHeight * 0.01),
//                           Text(
//                             'Add professional photo (Optional)',
//                             style: GoogleFonts.inter(
//                               color: textSecondary,
//                               fontSize: screenWidth * 0.035,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     SizedBox(height: screenHeight * 0.03),
//
//                     Form(
//                       key: _formKey,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // RPC Certificate Section
//                           _buildRPCCertificateSection(),
//
//                           SizedBox(height: screenHeight * 0.03),
//
//                           // Professional Information
//                           Text(
//                             'Professional Information',
//                             style: GoogleFonts.inter(
//                               fontWeight: FontWeight.w600,
//                               fontSize: screenWidth * 0.045,
//                               color: textPrimary,
//                             ),
//                           ),
//                           SizedBox(height: screenHeight * 0.01),
//                           Text(
//                             'Enter your professional details',
//                             style: GoogleFonts.inter(
//                               color: textSecondary,
//                               fontSize: screenWidth * 0.038,
//                             ),
//                           ),
//
//                           SizedBox(height: screenHeight * 0.02),
//
//                           _buildFormField(
//                             label: 'Full Name',
//                             controller: _nameController,
//                             icon: Icons.person_outline_rounded,
//                             hintText: 'Enter your full name',
//                           ),
//
//                           SizedBox(height: screenHeight * 0.02),
//
//                           _buildFormField(
//                             label: 'Company/Organization',
//                             controller: _companyController,
//                             icon: Icons.business_outlined,
//                             hintText: 'Your company or organization',
//                           ),
//
//                           SizedBox(height: screenHeight * 0.02),
//
//                           _buildFormField(
//                             label: 'Location',
//                             controller: _locationController,
//                             icon: Icons.location_on_outlined,
//                             hintText: 'City, State or operating area',
//                           ),
//
//                           SizedBox(height: screenHeight * 0.02),
//
//                           _buildFormField(
//                             label: 'Specialization',
//                             controller: _specificationController,
//                             icon: Icons.engineering_outlined,
//                             maxLines: 2,
//                             hintText: 'Aerial photography, surveying, inspection, etc.',
//                           ),
//
//                           SizedBox(height: screenHeight * 0.02),
//
//                           // Availability
//                           Text(
//                             'Availability Status',
//                             style: GoogleFonts.inter(
//                               fontWeight: FontWeight.w500,
//                               color: textPrimary,
//                               fontSize: screenWidth * 0.04,
//                             ),
//                           ),
//                           SizedBox(height: screenHeight * 0.01),
//                           _buildAvailabilityToggle(),
//
//                           SizedBox(height: screenHeight * 0.03),
//
//                           // Pricing Section
//                           _buildPricingSection(),
//
//                           SizedBox(height: screenHeight * 0.03),
//
//                           // Professional Summary
//                           _buildFormField(
//                             label: 'Professional Summary',
//                             controller: _descriptionController,
//                             icon: Icons.description_outlined,
//                             maxLines: 3,
//                             hintText: 'Describe your experience and expertise',
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return 'Summary is required';
//                               }
//                               if (value.split(' ').length < 10) {
//                                 return 'Please provide at least 10 words';
//                               }
//                               return null;
//                             },
//                           ),
//
//                           SizedBox(height: screenHeight * 0.03),
//
//                           // Contact Information
//                           Text(
//                             'Contact Information',
//                             style: GoogleFonts.inter(
//                               fontWeight: FontWeight.w600,
//                               fontSize: screenWidth * 0.045,
//                               color: textPrimary,
//                             ),
//                           ),
//                           SizedBox(height: screenHeight * 0.01),
//                           Text(
//                             'We will contact you for opportunities',
//                             style: GoogleFonts.inter(
//                               color: textSecondary,
//                               fontSize: screenWidth * 0.038,
//                             ),
//                           ),
//
//                           SizedBox(height: screenHeight * 0.02),
//
//                           _buildFormField(
//                             label: 'Email Address',
//                             controller: _emailController,
//                             icon: Icons.email_outlined,
//                             keyboardType: TextInputType.emailAddress,
//                             hintText: 'Enter your email address',
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return 'Email is required';
//                               }
//                               if (!RegExp(
//                                   r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
//                                   .hasMatch(value)) {
//                                 return 'Please enter a valid email address';
//                               }
//                               return null;
//                             },
//                           ),
//
//                           SizedBox(height: screenHeight * 0.02),
//
//                           _buildFormField(
//                             label: 'Phone Number',
//                             controller: _phoneController,
//                             icon: Icons.phone_outlined,
//                             keyboardType: TextInputType.phone,
//                             hintText: 'Enter your phone number',
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return 'Phone number is required';
//                               }
//                               if (!RegExp(r'^[0-9]{10,}$').hasMatch(value)) {
//                                 return 'Please enter a valid phone number';
//                               }
//                               return null;
//                             },
//                           ),
//
//                           SizedBox(height: screenHeight * 0.03),
//
//                           // Error Message
//                           if (_errorMessage != null)
//                             Container(
//                               padding: EdgeInsets.all(screenWidth * 0.04),
//                               margin: EdgeInsets.only(bottom: screenHeight * 0.02),
//                               decoration: BoxDecoration(
//                                 color: errorColor.withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(color: errorColor.withOpacity(0.3)),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Icon(
//                                     Icons.error_outline_rounded,
//                                     color: errorColor,
//                                     size: 20,
//                                   ),
//                                   SizedBox(width: screenWidth * 0.03),
//                                   Expanded(
//                                     child: Text(
//                                       _errorMessage!,
//                                       style: GoogleFonts.inter(
//                                         color: errorColor,
//                                         fontSize: screenWidth * 0.035,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//
//                           SizedBox(height: screenHeight * 0.04),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             // Submit Button
//             Container(
//               padding: EdgeInsets.symmetric(
//                 horizontal: screenWidth * 0.05,
//                 vertical: screenHeight * 0.02,
//               ),
//               decoration: BoxDecoration(
//                 color: surfaceColor,
//                 border: Border(
//                   top: BorderSide(
//                     color: borderColor,
//                     width: 1,
//                   ),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 10,
//                     offset: const Offset(0, -3),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: _isSubmitting ? null : _submitBuyerPilot,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primaryColor,
//                         foregroundColor: Colors.white,
//                         elevation: 0,
//                         padding: EdgeInsets.symmetric(
//                           vertical: screenHeight * 0.02,
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: _isSubmitting
//                           ? SizedBox(
//                         width: screenWidth * 0.06,
//                         height: screenWidth * 0.06,
//                         child: const CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2,
//                         ),
//                       )
//                           : Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             _hasRPCCertificate
//                                 ? Icons.check_circle_outline_rounded
//                                 : Icons.send_outlined,
//                             size: screenWidth * 0.05,
//                           ),
//                           SizedBox(width: screenWidth * 0.03),
//                           Text(
//                             _hasRPCCertificate
//                                 ? 'Submit Application'
//                                 : 'Submit',
//                             style: GoogleFonts.inter(
//                               fontWeight: FontWeight.w600,
//                               fontSize: screenWidth * 0.04,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//





import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../config/env.dart';

class BecomeAPilotPage extends StatefulWidget {
  final String buyerId;
  const BecomeAPilotPage({super.key, required this.buyerId});

  @override
  State<BecomeAPilotPage> createState() => _BecomeAPilotPageState();
}

class _BecomeAPilotPageState extends State<BecomeAPilotPage> {
  // Professional Color Scheme
  static const Color primaryColor = Color(0xFF1A0A5B);
  static const Color secondaryColor = Color(0xFF4C1D95);
  static const Color accentColor = Color(0xFF00D9A3);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color infoColor = Color(0xFF3B82F6);
  static const Color cardColor = Color(0xFFF9FAFB);
  static const Color disabledColor = Color(0xFFF3F4F6);

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _specificationController = TextEditingController();
  final TextEditingController _perHourController = TextEditingController();
  final TextEditingController _perDayController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Form state
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isLoading = true;
  String? _errorMessage;

  // File pickers
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  File? _rpcCertificateImage;
  bool _isUploadingCertificate = false;
  double _certificateUploadProgress = 0.0;

  // RPC Status
  bool _hasRPCCertificate = false;
  bool _rpcCertificateUploaded = false;

  // Pilot availability
  bool _availability = true;

  // Firebase
  final String graphqlUrl = EnvConfig.baseUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _specificationController.dispose();
    _perHourController.dispose();
    _perDayController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load data: ${e.toString()}";
      });
    }
  }

  Future<void> _ensureFirebaseAuth() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
    } catch (e) {
      debugPrint("❌ Firebase auth error: $e");
      throw Exception('Failed to authenticate with Firebase');
    }
  }

  Future<String> _uploadFileToFirebase(File file, String type) async {
    await _ensureFirebaseAuth();
    try {
      final uid = _auth.currentUser?.uid ?? "unknown";
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last.toLowerCase();
      final fileName = "pilots/${widget.buyerId}/$type/${timestamp}_$uid.$extension";
      final ref = _storage.ref().child(fileName);

      debugPrint("🚀 Uploading $type: $fileName");

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': widget.buyerId,
          'timestamp': DateTime.now().toIso8601String(),
          'type': type,
        },
      );

      final uploadTask = ref.putFile(file, metadata);

      // Track upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes.toDouble();
        setState(() {
          if (type == 'certificate') {
            _certificateUploadProgress = progress;
          }
        });
      });

      await uploadTask;
      final url = await ref.getDownloadURL();
      debugPrint("✅ Uploaded $type: $url");
      return url;
    } catch (e) {
      debugPrint("❌ Firebase Upload Error for $type: $e");
      throw Exception("$type upload failed: $e");
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
        _showSnackBar('Profile photo added successfully', color: successColor);
      }
    } catch (e) {
      _showSnackBar('Error picking image: ${e.toString()}', isError: true);
    }
  }

  Future<void> _pickRPCCertificate() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();

        // Validate file size (10MB limit)
        if (fileSize > 10 * 1024 * 1024) {
          _showSnackBar('Certificate size must be less than 10MB', isError: true);
          return;
        }

        setState(() {
          _isUploadingCertificate = true;
          _certificateUploadProgress = 0.0;
        });

        try {
          await _uploadFileToFirebase(file, 'certificate');
          setState(() {
            _rpcCertificateImage = file;
            _rpcCertificateUploaded = true;
          });
          _showSnackBar('RPC certificate uploaded successfully', color: successColor);
        } catch (e) {
          _showSnackBar('Failed to upload certificate: ${e.toString()}', isError: true);
        } finally {
          setState(() {
            _isUploadingCertificate = false;
          });
        }
      }
    } catch (e) {
      _showSnackBar('Error picking certificate: ${e.toString()}', isError: true);
    }
  }

  void _removeRPCCertificate() {
    setState(() {
      _rpcCertificateImage = null;
      _rpcCertificateUploaded = false;
    });
    _showSnackBar('RPC certificate removed', color: infoColor);
  }

  Widget _buildProfileImagePicker() {
    return GestureDetector(
      onTap: _hasRPCCertificate ? _pickProfileImage : null,
      child: Opacity(
        opacity: _hasRPCCertificate ? 1.0 : 0.5,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.25,
          height: MediaQuery.of(context).size.width * 0.25,
          decoration: BoxDecoration(
            color: _hasRPCCertificate ? borderColor.withOpacity(0.1) : disabledColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hasRPCCertificate ? borderColor : disabledColor,
              width: 1.5,
            ),
          ),
          child: _profileImage != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.file(
                  _profileImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                if (_hasRPCCertificate)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: MediaQuery.of(context).size.width * 0.07,
                color: _hasRPCCertificate ? textSecondary : borderColor,
              ),
              const SizedBox(height: 4),
              Text(
                _hasRPCCertificate ? 'Add Photo' : 'RPC Required',
                style: GoogleFonts.inter(
                  color: _hasRPCCertificate ? textSecondary : borderColor,
                  fontSize: MediaQuery.of(context).size.width * 0.03,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRPCCertificateSection() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "RPC Certificate Status",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: textPrimary,
              fontSize: screenWidth * 0.04,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Select your current RPC certification status",
            style: GoogleFonts.inter(
              color: textSecondary,
              fontSize: screenWidth * 0.035,
            ),
          ),
          const SizedBox(height: 16),

          // RPC Options
          Column(
            children: [
              // Have RPC Option
              GestureDetector(
                onTap: () {
                  setState(() {
                    _hasRPCCertificate = true;
                    _rpcCertificateUploaded = false;
                    _rpcCertificateImage = null;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: MediaQuery.of(context).size.height * 0.016,
                    horizontal: screenWidth * 0.04,
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _hasRPCCertificate
                        ? successColor.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _hasRPCCertificate ? successColor : borderColor,
                      width: _hasRPCCertificate ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _hasRPCCertificate
                              ? successColor.withOpacity(0.2)
                              : borderColor.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified_outlined,
                          color: _hasRPCCertificate ? successColor : textSecondary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'I have RPC Certificate',
                              style: GoogleFonts.inter(
                                color: _hasRPCCertificate ? successColor : textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: screenWidth * 0.038,
                              ),
                            ),
                            Text(
                              'Already certified pilot',
                              style: GoogleFonts.inter(
                                color: textSecondary,
                                fontSize: screenWidth * 0.032,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_hasRPCCertificate)
                        Icon(
                          Icons.check_circle,
                          color: successColor,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
              // Need RPC Option
              GestureDetector(
                onTap: () {
                  setState(() {
                    _hasRPCCertificate = false;
                    _rpcCertificateImage = null;
                    _rpcCertificateUploaded = false;
                    // Clear all form fields when switching to "Need RPC"
                    _nameController.clear();
                    _companyController.clear();
                    _locationController.clear();
                    _specificationController.clear();
                    _perHourController.clear();
                    _perDayController.clear();
                    _descriptionController.clear();
                    _emailController.clear();
                    _phoneController.clear();
                    _profileImage = null;
                  });
                  _openRPCTrainingWebsite();
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: MediaQuery.of(context).size.height * 0.016,
                    horizontal: screenWidth * 0.04,
                  ),
                  decoration: BoxDecoration(
                    color: !_hasRPCCertificate
                        ? primaryColor.withOpacity(0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: !_hasRPCCertificate ? primaryColor : borderColor,
                      width: !_hasRPCCertificate ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: !_hasRPCCertificate
                              ? primaryColor.withOpacity(0.1)
                              : borderColor.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.school_outlined,
                          color: !_hasRPCCertificate ? primaryColor : textSecondary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Need RPC Certificate',
                              style: GoogleFonts.inter(
                                color: !_hasRPCCertificate ? primaryColor : textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: screenWidth * 0.038,
                              ),
                            ),
                            Text(
                              'Get certified through Flytutor.in',
                              style: GoogleFonts.inter(
                                color: textSecondary,
                                fontSize: screenWidth * 0.032,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_hasRPCCertificate)
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: primaryColor,
                          size: 16,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // RPC Certificate Upload (only if they have one)
          if (_hasRPCCertificate) ...[
            const SizedBox(height: 20),
            Text(
              "Upload RPC Certificate",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: textPrimary,
                fontSize: screenWidth * 0.04,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Upload a clear photo or scan of your valid RPC certificate",
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: screenWidth * 0.035,
              ),
            ),
            const SizedBox(height: 16),

            if (_isUploadingCertificate)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: MediaQuery.of(context).size.height * 0.04,
                ),
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        value: _certificateUploadProgress,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Uploading Certificate... ${(_certificateUploadProgress * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        color: textPrimary,
                        fontSize: screenWidth * 0.038,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else if (_rpcCertificateImage == null)
              GestureDetector(
                onTap: _pickRPCCertificate,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: MediaQuery.of(context).size.height * 0.04,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accentColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: screenWidth * 0.1,
                        color: accentColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Upload RPC Certificate',
                        style: GoogleFonts.inter(
                          color: accentColor,
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click to upload certificate image (Max 10MB)',
                        style: GoogleFonts.inter(
                          color: textSecondary,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          child: Image.file(
                            _rpcCertificateImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.2,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.verified,
                              color: successColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RPC Certificate',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                    fontSize: screenWidth * 0.038,
                                  ),
                                ),
                                Text(
                                  'Uploaded successfully',
                                  style: GoogleFonts.inter(
                                    color: successColor,
                                    fontSize: screenWidth * 0.032,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _removeRPCCertificate,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: errorColor,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ] else ...[
            // Training Information for those needing RPC
            const SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: infoColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: infoColor.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: infoColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "RPC Training Required",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: infoColor,
                            fontSize: screenWidth * 0.038,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "You need an RPC certificate to register as a pilot. Click 'Need RPC Certificate' to visit FlyTutor.in for DGCA approved RPC training courses.",
                          style: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: screenWidth * 0.034,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "After obtaining your RPC certificate, come back to complete your pilot registration.",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                            fontSize: screenWidth * 0.034,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = true,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: _hasRPCCertificate ? textPrimary : textSecondary,
                fontSize: screenWidth * 0.04,
              ),
            ),
            if (isRequired && _hasRPCCertificate)
              Text(
                ' *',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: errorColor,
                  fontSize: screenWidth * 0.04,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: _hasRPCCertificate,
          validator: _hasRPCCertificate
              ? (validator ??
                  (value) {
                if (isRequired && (value == null || value.isEmpty)) {
                  return 'This field is required';
                }
                return null;
              })
              : null,
          style: GoogleFonts.inter(
            color: _hasRPCCertificate ? textPrimary : textSecondary,
            fontSize: screenWidth * 0.04,
          ),
          decoration: InputDecoration(
            hintText: hintText ?? 'Enter $label',
            hintStyle: GoogleFonts.inter(
              color: _hasRPCCertificate ? textSecondary : borderColor,
              fontSize: screenWidth * 0.04,
            ),
            prefixIcon: Icon(
              icon,
              color: _hasRPCCertificate ? textSecondary : borderColor,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _hasRPCCertificate ? borderColor : disabledColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _hasRPCCertificate ? borderColor : disabledColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _hasRPCCertificate ? primaryColor : disabledColor,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: errorColor),
            ),
            filled: true,
            fillColor: _hasRPCCertificate ? Colors.white : disabledColor,
            contentPadding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.016,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityToggle() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Opacity(
      opacity: _hasRPCCertificate ? 1.0 : 0.5,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: _hasRPCCertificate ? Colors.white : disabledColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _hasRPCCertificate ? borderColor : disabledColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: _hasRPCCertificate ? textPrimary : borderColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Available for Hire',
                          style: GoogleFonts.inter(
                            color: _hasRPCCertificate ? textPrimary : borderColor,
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Text(
                      _availability
                          ? 'Currently accepting projects'
                          : 'Not available for hire',
                      style: GoogleFonts.inter(
                        color: _hasRPCCertificate ? textSecondary : borderColor,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _availability,
              onChanged: _hasRPCCertificate
                  ? (value) {
                setState(() {
                  _availability = value;
                });
              }
                  : null,
              activeColor: successColor,
              inactiveThumbColor: borderColor,
              inactiveTrackColor: disabledColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Opacity(
      opacity: _hasRPCCertificate ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: _hasRPCCertificate ? cardColor : disabledColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hasRPCCertificate ? borderColor : disabledColor,
          ),
        ),
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Pricing',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: _hasRPCCertificate ? textPrimary : borderColor,
                fontSize: screenWidth * 0.04,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hourly Rate (₹)',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: _hasRPCCertificate ? textPrimary : borderColor,
                          fontSize: screenWidth * 0.038,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _perHourController,
                        keyboardType: TextInputType.number,
                        enabled: _hasRPCCertificate,
                        validator: _hasRPCCertificate
                            ? (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Invalid amount';
                          }
                          return null;
                        }
                            : null,
                        style: GoogleFonts.inter(
                          color: _hasRPCCertificate ? textPrimary : borderColor,
                          fontSize: screenWidth * 0.04,
                        ),
                        decoration: InputDecoration(
                          hintText: '1500',
                          hintStyle: GoogleFonts.inter(
                            color: _hasRPCCertificate ? textSecondary : borderColor,
                            fontSize: screenWidth * 0.04,
                          ),
                          prefixIcon: Icon(
                            Icons.currency_rupee_rounded,
                            color: _hasRPCCertificate ? textSecondary : borderColor,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _hasRPCCertificate ? borderColor : disabledColor,
                            ),
                          ),
                          filled: true,
                          fillColor: _hasRPCCertificate ? Colors.white : disabledColor,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.014,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Rate (₹)',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: _hasRPCCertificate ? textPrimary : borderColor,
                          fontSize: screenWidth * 0.038,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _perDayController,
                        keyboardType: TextInputType.number,
                        enabled: _hasRPCCertificate,
                        validator: _hasRPCCertificate
                            ? (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Invalid amount';
                          }
                          return null;
                        }
                            : null,
                        style: GoogleFonts.inter(
                          color: _hasRPCCertificate ? textPrimary : borderColor,
                          fontSize: screenWidth * 0.04,
                        ),
                        decoration: InputDecoration(
                          hintText: '12000',
                          hintStyle: GoogleFonts.inter(
                            color: _hasRPCCertificate ? textSecondary : borderColor,
                            fontSize: screenWidth * 0.04,
                          ),
                          prefixIcon: Icon(
                            Icons.currency_rupee_rounded,
                            color: _hasRPCCertificate ? textSecondary : borderColor,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _hasRPCCertificate ? borderColor : disabledColor,
                            ),
                          ),
                          filled: true,
                          fillColor: _hasRPCCertificate ? Colors.white : disabledColor,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.014,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _openRPCTrainingWebsite() async {
    const url = 'https://flytutor.in';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        _showSnackBar('Could not open the website', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false, Color? color}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color ?? (isError ? errorColor : successColor),
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.038,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _submitBuyerPilot() async {
    if (!_hasRPCCertificate) {
      _showSnackBar('You need an RPC certificate to register as a pilot', isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields correctly', isError: true);
      return;
    }

    // Validate RPC certificate
    if (_rpcCertificateImage == null) {
      _showSnackBar('Please upload your RPC certificate', isError: true);
      return;
    }

    // Validate pricing
    final perHour = double.tryParse(_perHourController.text);
    final perDay = double.tryParse(_perDayController.text);

    if (perHour == null || perHour <= 0) {
      _showSnackBar('Please enter a valid per hour price', isError: true);
      return;
    }

    if (perDay == null || perDay <= 0) {
      _showSnackBar('Please enter a valid per day price', isError: true);
      return;
    }

    // Validate email
    final email = _emailController.text.trim();
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      _showSnackBar('Please enter a valid email address', isError: true);
      return;
    }

    // Validate phone
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^[0-9]{10,}$').hasMatch(phone)) {
      _showSnackBar('Please enter a valid phone number (minimum 10 digits)', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Upload RPC certificate
      String rpcUrl = await _uploadFileToFirebase(_rpcCertificateImage!, 'certificate');

      // Create GraphQL client
      final client = GraphQLClient(
        link: HttpLink(graphqlUrl),
        cache: GraphQLCache(store: InMemoryStore()),
      );

      // Prepare GraphQL mutation
      final mutation = gql("""
        mutation AddBuyerPilot(\$input: BuyerPilotInput!) {
          addBuyerPilot(input: \$input) {
            buyerPilotId
            pilotName
            pilotCompany
            location
            availability
            specification
            price {
              perHour
              perDay
            }
            certifications {
              url
            }
            description
            newemail
            newphoneNumber
            adminStatus
            buyerStatus
            buyerId
            buyer {
              buyerId
              name
              email
              phoneNumber
            }
          }
        }
      """);

      // Prepare certifications array
      List<Map<String, dynamic>> certifications = [
        {'url': rpcUrl}
      ];

      // Execute mutation
      final result = await client.mutate(
        MutationOptions(
          document: mutation,
          variables: {
            'input': {
              'pilotName': _nameController.text.trim(),
              'pilotCompany': _companyController.text.trim(),
              'location': _locationController.text.trim(),
              'availability': _availability,
              'specification': _specificationController.text.trim(),
              'price': {
                'perHour': perHour,
                'perDay': perDay,
              },
              'certifications': certifications,
              'description': _descriptionController.text.trim(),
              'newemail': email,
              'newphoneNumber': phone,
              'buyerId': widget.buyerId,
            },
          },
          fetchPolicy: FetchPolicy.noCache,
        ),
      );

      if (result.hasException) {
        debugPrint("❌ GraphQL Error: ${result.exception.toString()}");
        String errorMessage = "Submission failed";
        if (result.exception!.graphqlErrors.isNotEmpty) {
          errorMessage = result.exception!.graphqlErrors.first.message;
        } else if (result.exception!.linkException != null) {
          errorMessage = "Network error: ${result.exception!.linkException}";
        }
        throw Exception(errorMessage);
      } else {
        debugPrint("✅ BuyerPilot Created Successfully!");
        _showSnackBar(
          '✅ Pilot application submitted successfully! Your profile is under review.',
          color: successColor,
        );

        // Navigate back after success
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint("⚠ Error submitting pilot application: $e");
      setState(() {
        _errorMessage = e.toString();
      });
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _certificateUploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.02,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasRPCCertificate
                              ? 'Pilot Registration'
                              : 'RPC Certificate Required',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: isSmallScreen ? 18 : 20,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          _hasRPCCertificate
                              ? 'Join our professional pilot network'
                              : 'Get RPC certified to register as a pilot',
                          style: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: isSmallScreen ? 12 : 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isSubmitting)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image
                    Center(
                      child: Column(
                        children: [
                          _buildProfileImagePicker(),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            _hasRPCCertificate
                                ? 'Add professional photo (Optional)'
                                : 'Profile photo requires RPC certificate',
                            style: GoogleFonts.inter(
                              color: _hasRPCCertificate ? textSecondary : borderColor,
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // RPC Certificate Section
                          _buildRPCCertificateSection(),

                          if (_hasRPCCertificate) ...[
                            SizedBox(height: screenHeight * 0.03),

                            // Professional Information
                            Text(
                              'Professional Information',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: screenWidth * 0.045,
                                color: textPrimary,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              'Enter your professional details',
                              style: GoogleFonts.inter(
                                color: textSecondary,
                                fontSize: screenWidth * 0.038,
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.02),

                            _buildFormField(
                              label: 'Full Name',
                              controller: _nameController,
                              icon: Icons.person_outline_rounded,
                              hintText: 'Enter your full name',
                            ),

                            SizedBox(height: screenHeight * 0.02),

                            _buildFormField(
                              label: 'Company/Organization',
                              controller: _companyController,
                              icon: Icons.business_outlined,
                              hintText: 'Your company or organization',
                            ),

                            SizedBox(height: screenHeight * 0.02),

                            _buildFormField(
                              label: 'Location',
                              controller: _locationController,
                              icon: Icons.location_on_outlined,
                              hintText: 'City, State or operating area',
                            ),

                            SizedBox(height: screenHeight * 0.02),

                            _buildFormField(
                              label: 'Specialization',
                              controller: _specificationController,
                              icon: Icons.engineering_outlined,
                              maxLines: 2,
                              hintText: 'Aerial photography, surveying, inspection, etc.',
                            ),

                            SizedBox(height: screenHeight * 0.02),

                            // Availability
                            Text(
                              'Availability Status',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                                fontSize: screenWidth * 0.04,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            _buildAvailabilityToggle(),

                            SizedBox(height: screenHeight * 0.03),

                            // Pricing Section
                            _buildPricingSection(),

                            SizedBox(height: screenHeight * 0.03),

                            // Professional Summary
                            _buildFormField(
                              label: 'Professional Summary',
                              controller: _descriptionController,
                              icon: Icons.description_outlined,
                              maxLines: 3,
                              hintText: 'Describe your experience and expertise',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Summary is required';
                                }
                                if (value.split(' ').length < 10) {
                                  return 'Please provide at least 10 words';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: screenHeight * 0.03),

                            // Contact Information
                            Text(
                              'Contact Information',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: screenWidth * 0.045,
                                color: textPrimary,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              'We will contact you for opportunities',
                              style: GoogleFonts.inter(
                                color: textSecondary,
                                fontSize: screenWidth * 0.038,
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.02),

                            _buildFormField(
                              label: 'Email Address',
                              controller: _emailController,
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              hintText: 'Enter your email address',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email is required';
                                }
                                if (!RegExp(
                                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                    .hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: screenHeight * 0.02),

                            _buildFormField(
                              label: 'Phone Number',
                              controller: _phoneController,
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              hintText: 'Enter your phone number',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Phone number is required';
                                }
                                if (!RegExp(r'^[0-9]{10,}$').hasMatch(value)) {
                                  return 'Please enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                          ],

                          SizedBox(height: screenHeight * 0.03),

                          // Error Message
                          if (_errorMessage != null)
                            Container(
                              padding: EdgeInsets.all(screenWidth * 0.04),
                              margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                              decoration: BoxDecoration(
                                color: errorColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: errorColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: errorColor,
                                    size: 20,
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.inter(
                                        color: errorColor,
                                        fontSize: screenWidth * 0.035,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          SizedBox(height: screenHeight * 0.04),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Submit Button
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.02,
              ),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(
                  top: BorderSide(
                    color: borderColor,
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _hasRPCCertificate && !_isSubmitting ? _submitBuyerPilot : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasRPCCertificate ? primaryColor : disabledColor,
                        foregroundColor: _hasRPCCertificate ? Colors.white : borderColor,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                        width: screenWidth * 0.06,
                        height: screenWidth * 0.06,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _hasRPCCertificate
                                ? Icons.check_circle_outline_rounded
                                : Icons.lock_outline_rounded,
                            size: screenWidth * 0.05,
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Text(
                            _hasRPCCertificate
                                ? 'Submit Application'
                                : 'RPC Certificate Required',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.04,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
