import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../Login/FlyHubSelectionPage.dart';
import '../config/env.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Delete Account',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Icon
            Center(
              child: Icon(
                Icons.warning,
                size: 80,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 20),

            // Warning Title
            const Center(
              child: Text(
                'Warning: Account Deletion',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: Container(
                width: double.infinity, // keeps full width
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'This action is PERMANENT and cannot be undone.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'The following data will be permanently removed:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text('• Your profile and account information'),
                    Text('• Order history and invoices'),
                    Text('• Saved addresses'),
                    Text('• Payment preferences'),
                    Text('• Wishlist and cart items'),
                    Text('• Notifications and alerts'),
                    Text('• App activity and preferences'),
                    SizedBox(height: 8),
                    Text(
                      'This action cannot be reversed!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Confirmation Field
            TextFormField(
              controller: _confirmController,
              decoration: InputDecoration(
                labelText: 'Type "DELETE" to confirm',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.warning_amber, color: Colors.red),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please type DELETE to confirm';
                }
                if (value != 'DELETE') {
                  return 'You must type exactly "DELETE"';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'Enter your current password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock, color: Colors.red),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 30),

            // Delete Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  'Delete Account Permanently',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    // Validate inputs
    if (FirebaseAuth.instance.currentUser == null) {
      _showSuccessAndNavigate();
      return;
    }

    if (_confirmController.text != 'DELETE') {
      _showErrorDialog('Please type "DELETE" exactly as shown to confirm account deletion.');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showErrorDialog('Please enter your password to confirm deletion.');
      return;
    }

    // Show final confirmation dialog
    final bool confirmed = await _showFinalConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Get current user
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final String uid = user.uid;
      final String? email = user.email;

      if (email == null) {
        throw Exception('Email not found');
      }

      // Step 2: Reauthenticate with Firebase
      await _reauthenticateUser(user, email);

      // Step 3: Delete Firestore data FIRST (before auth deletion)
      await _deleteFirestoreData(uid, email);

      // Step 4: Delete MongoDB data
      await _deleteMongoDBData(uid, email);

      // Step 5: Delete Firebase Authentication account LAST
      await _deleteFirebaseAuthAccount(user);

      await FirebaseAuth.instance.signOut();

      // Step 6: Show success and navigate
      _showSuccessAndNavigate();

    } catch (error) {
      final message = error.toString();

      // 🔥 IMPORTANT FIX
      if (message.contains('user-not-found')) {
        debugPrint('ℹ️ User already deleted, treating as success');
        _showSuccessAndNavigate();
        return;
      }

      debugPrint('❌ Delete account error: $error');
      _showErrorDialog(
        message.replaceAll('Exception: ', ''),
      );
    }
    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reauthenticateUser(User user, String email) async {
    try {
      debugPrint('🔐 Reauthenticating user...');
      final AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: _passwordController.text,
      );
      await user.reauthenticateWithCredential(credential);
      debugPrint('✅ Firebase reauthentication successful');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Incorrect password. Please enter your current password.');
      } else if (e.code == 'user-not-found') {
        throw Exception('User not found');
      } else if (e.code == 'invalid-credential') {
        throw Exception('Invalid credentials. Please check your email and password.');
      } else if (e.code == 'too-many-requests') {
        throw Exception('Too many attempts. Please try again later.');
      } else {
        throw Exception('Authentication failed: ${e.message}');
      }
    }
  }

  Future<void> _deleteFirestoreData(String uid, String email) async {
    try {
      debugPrint('🗑 Deleting Firestore data for UID: $uid');

      // List of collections where user data might be stored
      final collectionsToClean = [
        'users',
        'buyers',
        'customers',
        'Orders',
        'addresses',
        'payments',
        'notifications',
        'wishlist',
        'cart',
        'profiles',
        'settings'
      ];

      int deletedCount = 0;

      for (final collection in collectionsToClean) {
        try {
          // Delete documents where userId/uid matches
          final querySnapshot = await _firestore
              .collection(collection)
              .where('userId', isEqualTo: uid)
              .get();

          for (final doc in querySnapshot.docs) {
            await doc.reference.delete();
            deletedCount++;
          }

          // Also try with buyerId field
          final querySnapshot2 = await _firestore
              .collection(collection)
              .where('buyerId', isEqualTo: uid)
              .get();

          for (final doc in querySnapshot2.docs) {
            await doc.reference.delete();
            deletedCount++;
          }

          // Also try with email field
          final querySnapshot3 = await _firestore
              .collection(collection)
              .where('email', isEqualTo: email)
              .get();

          for (final doc in querySnapshot3.docs) {
            await doc.reference.delete();
            deletedCount++;
          }

        } catch (e) {
          debugPrint('⚠ Error deleting from $collection: $e');
          // Continue with other collections
        }
      }

      debugPrint('✅ Deleted $deletedCount Firestore documents');

      // Also delete the main user document if it exists
      try {
        final userDoc = _firestore.collection('users').doc(uid);
        if ((await userDoc.get()).exists) {
          await userDoc.delete();
          debugPrint('✅ Deleted main user document');
        }
      } catch (e) {
        debugPrint('⚠ Error deleting main user document: $e');
      }

    } catch (e) {
      debugPrint('❌ Error deleting Firestore data: $e');
      throw Exception('Failed to delete Firestore data: ${e.toString()}');
    }
  }

  Future<void> _deleteMongoDBData(String uid, String email) async {
    try {
      debugPrint('🗄 Deleting MongoDB data for email: $email, UID: $uid');

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };

      final Map<String, dynamic> requestBody = {
        'query': '''
          mutation DeleteBuyerAccountCompletely(\$email: String!, \$firebaseUid: String!) {
            deleteBuyerAccountCompletely(email: \$email, firebaseUid: \$firebaseUid) {
              success
              message
              buyerId
              email
              deletedAt
              deletedCounts {
                buyers
                notifications
                Orders
                addresses
                wishlist
              }
            }
          }
        ''',
        'variables': {
          'email': email,
          'firebaseUid': uid,
        }
      };

      final response = await http.post(
        Uri.parse(EnvConfig.baseUrl),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      debugPrint('📥 MongoDB Response status: ${response.statusCode}');
      debugPrint('📥 MongoDB Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['errors'] != null && responseData['errors'].isNotEmpty) {
          final error = responseData['errors'][0];
          throw Exception(error['message'] ?? 'GraphQL error');
        }

        final Map<String, dynamic>? data = responseData['data']?['deleteBuyerAccountCompletely'];

        if (data != null && data['success'] == true) {
          debugPrint('✅ MongoDB data deleted successfully');
          debugPrint('📊 Deleted counts: ${data['deletedCounts']}');
        } else {
          final String errorMessage = data?['message'] ?? 'Failed to delete MongoDB data';
          throw Exception(errorMessage);
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error deleting MongoDB data: $e');
      throw Exception('Failed to delete database data: ${e.toString()}');
    }
  }

  Future<void> _deleteFirebaseAuthAccount(User user) async {
    try {
      debugPrint('🔥 Deleting Firebase Authentication account...');
      await user.delete();
      debugPrint('✅ Firebase Authentication account deleted successfully');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // ✅ Already deleted → OK
        debugPrint('ℹ️ User already deleted');
        return;
      }
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'Session expired. Please log in again and try deleting your account.',
        );
      }
      rethrow;
    }
  }


  Future<bool> _showFinalConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.red, size: 40),
        title: const Text(
          'Final Confirmation',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you absolutely sure you want to delete your account?',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'This will permanently remove all your data, including:',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Your profile and account information'),
            Text('• Order history and invoices'),
            Text('• Saved addresses and preferences'),
            Text('• Wishlist, cart, and app activity'),
            Text('• Notifications and alerts'),
            SizedBox(height: 12),
            Text(
              'This action cannot be undone and your data cannot be recovered.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Yes, Delete My Account',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ) ?? false;
  }


  void _showSuccessAndNavigate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 48,
        ),
        title: const Text(
          'Account Deleted Successfully',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            Text(
              'Your account has been permanently deleted and cannot be recovered.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              'All your data has been removed from our system.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            Text(
              'We hope to see you again someday.\n\nThank you for choosing Flyhub (Aviatricks).',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const FlyHubSelectionPage(),
                ),
                    (route) => false,
              );
            },
            child: const Text(
              'Continue',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }



  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        icon: const Icon(Icons.error, color: Colors.red, size: 40),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _confirmController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}