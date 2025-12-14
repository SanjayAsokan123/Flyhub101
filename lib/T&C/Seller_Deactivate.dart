import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

const String deactivateSellerMutation = r'''
mutation DeactivateSeller($customId: ID!, $reason: String!) {
  deactivateSeller(customId: $customId, reason: $reason) {
    customId
    status
    message
  }
}
''';

// ===============================
// WIDGET CLASS
// ===============================
class DeactivateAccountPage extends StatefulWidget {
  final String? sellerId;
  final Map<String, dynamic>? sellerData;

  const DeactivateAccountPage({
    super.key,
    required this.sellerId,
    required this.sellerData,
  });

  @override
  State<DeactivateAccountPage> createState() => _DeactivateAccountPageState();
}

// ===============================
// STATE CLASS
// ===============================
class _DeactivateAccountPageState extends State<DeactivateAccountPage> {
  bool isLoading = false;
  bool isOnline = true;
  late StreamSubscription<ConnectivityResult> connectivitySubscription;

  // ===============================
  // INIT & DISPOSE
  // ===============================
  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _startConnectivityListener();
  }

  @override
  void dispose() {
    connectivitySubscription.cancel();
    super.dispose();
  }

  // ===============================
  // CONNECTIVITY METHODS
  // ===============================
  Future<void> _initConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  void _startConnectivityListener() {
    connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          (ConnectivityResult result) {
            setState(() {
              isOnline = result != ConnectivityResult.none;
            });

            if (!isOnline) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("No internet connection"),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } as void Function(List<ConnectivityResult> event)?,
        ) as StreamSubscription<ConnectivityResult>;
  }

  // ===============================
  // DEACTIVATE API CALL
  // ===============================
  Future<void> _deactivateAccount(String reason) async {
    // ✅ Validate seller ID
    if (widget.sellerId == null || widget.sellerId!.isEmpty) {
      _showErrorSnackbar("Invalid seller ID");
      return;
    }

    // ✅ Check internet connection
    if (!isOnline) {
      _showErrorSnackbar("No internet connection. Please check your network.");
      return;
    }

    setState(() => isLoading = true);

    final client = GraphQLProvider.of(context).value;

    try {
      final result = await client
          .mutate(
            MutationOptions(
              document: gql(deactivateSellerMutation),
              variables: {
                "customId": widget.sellerId,
                "reason":
                    reason.trim().isEmpty ? "Not specified" : reason.trim(),
              },
              fetchPolicy: FetchPolicy.networkOnly, // Ensure fresh data
              onCompleted: (data) {
                debugPrint("Mutation completed: $data");
              },
            ),
          )
          .timeout(
              const Duration(seconds: 30)); // ✅ Increased timeout for safety

      if (result.hasException) {
        await _handleGraphQLError(result.exception!);
        return;
      }

      // ✅ Validate response
      final responseData = result.data?['deactivateSeller'];
      if (responseData == null) {
        throw Exception("Invalid response format");
      }

      // ✅ Check operation success
      final status = responseData['status']?.toString().toLowerCase();
      if (status == 'success' || status == 'deactivated') {
        await _handleSuccess();
      } else {
        final message = responseData['message'] ?? "Deactivation failed";
        throw Exception(message);
      }
    } on TimeoutException catch (e) {
      _showErrorSnackbar("Request timeout. Please try again.");
      debugPrint("Timeout error: $e");
    } catch (e) {
      _showErrorSnackbar("Deactivation failed. Please try again.");
      debugPrint("Deactivation error: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ===============================
  // ERROR HANDLING METHODS
  // ===============================
  Future<void> _handleGraphQLError(OperationException exception) async {
    debugPrint("GraphQL Error: ${exception.toString()}");

    String errorMessage = "Deactivation failed";

    if (exception.graphqlErrors.isNotEmpty) {
      final graphQLError = exception.graphqlErrors.first;
      errorMessage = graphQLError.message;

      // Handle specific GraphQL errors
      if (graphQLError.extensions?['code'] == 'UNAUTHENTICATED') {
        errorMessage = "Session expired. Please login again.";
        await _navigateToLogin();
        return;
      }
    } else if (exception.linkException != null) {
      errorMessage = "Network error. Please check your connection.";
    }

    _showErrorSnackbar(errorMessage);
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ===============================
  // SUCCESS HANDLING
  // ===============================
  Future<void> _handleSuccess() async {
    _showSuccessSnackbar("Account deactivated successfully");

    // ✅ Clear GraphQL cache (optional)
    // final client = GraphQLProvider.of(context).value;
    // await client.cache.store?.reset();

    // ✅ Add a small delay before navigation
    await Future.delayed(const Duration(milliseconds: 1500));

    await _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/FlyHubSelectionPage',
      (route) => false,
    );
  }

  // ===============================
  // CONFIRMATION DIALOG
  // ===============================
  void _showDeactivateDialog() {
    if (!isOnline) {
      _showErrorSnackbar(
          "No internet connection. Please connect to the internet.");
      return;
    }

    final TextEditingController reasonController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          "Confirm Deactivation",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.red,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Please provide a reason for deactivation (optional but recommended):",
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Enter reason...",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please provide a reason for deactivation";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              if (!isOnline)
                const Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.orange, size: 16),
                    SizedBox(width: 4),
                    Text(
                      "No internet connection",
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              disabledBackgroundColor: Colors.red.withOpacity(0.5),
            ),
            onPressed: isLoading || !isOnline
                ? null
                : () {
                    if (formKey.currentState?.validate() ?? true) {
                      Navigator.pop(context);
                      _deactivateAccount(reasonController.text.trim());
                    }
                  },
            child: const Text("Deactivate"),
          ),
        ],
      ),
    );
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    const Color textPrimary = Color(0xFF1F2937);
    const Color textSecondary = Color(0xFF6B7280);
    const Color borderColor = Color(0xFFE5E7EB);
    const Color errorColor = Color(0xFFEF4444);
    const Color warningColor = Color(0xFFF59E0B);
    const Color cardColor = Colors.white;
    const Color backgroundColor = Color(0xFFF8FAFC);
    const Color successColor = Color(0xFF10B981);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Deactivate Account",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: errorColor,
          ),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  isOnline ? Icons.wifi : Icons.wifi_off,
                  color: isOnline ? successColor : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  isOnline ? "Online" : "Offline",
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnline ? successColor : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status Banner
            if (!isOnline)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "No internet connection. Connect to proceed.",
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Warning
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: errorColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: errorColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Please read carefully before deactivating your account.",
                      style: TextStyle(
                        color: textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Account Details",
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _infoRow(Icons.business,
                      widget.sellerData?['companyName'] ?? "Seller"),
                  _infoRow(
                      Icons.email, widget.sellerData?['email'] ?? "No email"),
                  if (widget.sellerId != null)
                    _infoRow(Icons.numbers, "Seller ID: ${widget.sellerId}"),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Consequences
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: warningColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: warningColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "What happens when you deactivate:",
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _consequenceRow(
                      Icons.visibility_off, "Account hidden from buyers"),
                  _consequenceRow(Icons.store, "Products not visible"),
                  _consequenceRow(Icons.block, "No new orders"),
                  _consequenceRow(Icons.lock_clock, "Data preserved",
                      color: successColor),
                  _consequenceRow(Icons.restore, "Reactivate anytime",
                      color: successColor),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Acknowledgment
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: errorColor.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: errorColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "By proceeding, you acknowledge all consequences mentioned above.",
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Deactivate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (!isLoading && isOnline) ? _showDeactivateDialog : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorColor,
                  disabledBackgroundColor: errorColor.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.power_settings_new, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            "Deactivate Account",
                            style: TextStyle(fontSize: 16),
                          ),
                          if (!isOnline) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.wifi_off, size: 16),
                          ],
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: borderColor),
                ),
                child: const Text("Cancel"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _consequenceRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color ?? const Color(0xFFF59E0B),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: const Color(0xFF1F2937),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
