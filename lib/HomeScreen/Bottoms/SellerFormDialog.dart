import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/role_manager.dart';
import '../Dynamichome.dart';

class SellerFormDialog extends StatefulWidget {
  const SellerFormDialog({super.key});

  @override
  State<SellerFormDialog> createState() => _SellerFormDialogState();
}

class _SellerFormDialogState extends State<SellerFormDialog> {
  // Toggle between login and registration sections
  bool _showLogin = true;

  // -----------------------
  // Shared / Registration
  // -----------------------
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Seller form controllers
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();

  // New registration email/password controllers
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();

  // Login controllers
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
  TextEditingController();

  bool _isLoading = false;
  bool _phoneVerified = false;
  String? _verificationId;

  static const Color themeColor = Color(0xFF1A0A5B);

  // GraphQL endpoint (edit if needed)
  final String graphqlUrl = "http://192.168.0.149:5001/graphql";

  // -------------------------------------------------------
  // ---------------- Auth / Login Methods -----------------
  // -------------------------------------------------------
  Future<void> _loginWithEmail() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter email and password")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Optionally fetch role from Firestore & set local role
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()!.containsKey('role')) {
          final role = doc.data()!['role'] as String;
          await RoleManager.setLocalRole(role);
        }
      }

      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const Dynamichome(selectedIndex: 3)));

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("✅ Logged in")));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Login failed: ${e.message}")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Login failed: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _loginEmailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter email to receive reset link")));
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reset link sent to email")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sending reset link: $e")));
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'role': 'seller', // adjust if you want to ask role
          'signInMethod': 'google',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await RoleManager.setLocalRole('seller');

        if (!mounted) return;
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const Dynamichome(selectedIndex: 3)));

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Logged in with Google")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Google sign-in failed: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -------------------------------------------------------
  // ------------- Registration (create auth) --------------
  // -------------------------------------------------------
  Future<void> _createAuthAccountIfNeeded() async {
    // If already authenticated, nothing to do
    if (_auth.currentUser != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Already signed in")));
      return;
    }

    final email = _regEmailController.text.trim();
    final password = _regPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Enter email and password to create account")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // Update display name to store name if provided
      final user = cred.user;
      if (user != null && _storeNameController.text.trim().isNotEmpty) {
        await user.updateDisplayName(_storeNameController.text.trim());
      }

      // Create Firestore user doc skeleton (useful for login lookups)
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email ?? email,
          'role': 'seller',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Account created — continue seller setup")));

      // now user remains signed in and can submit seller form
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration failed: ${e.message}")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Registration failed: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -------------------------------------------------------
  // ------------- Seller form submission -----------------
  // -------------------------------------------------------
  Future<void> _submitSellerFormFull() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_phoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please verify phone before submitting")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception(
            "Please login/register first (email & password) to continue");
      }

      // Save Firestore user doc with sellerAccount
      await _firestore.collection('users').doc(user.uid).set({
        'role': 'seller',
        'email': user.email ?? _regEmailController.text.trim(),
        'sellerAccount': {
          'storeName': _storeNameController.text.trim(),
          'gstNumber': _gstController.text.trim(),
          'description': _descriptionController.text.trim(),
          'phone': _phoneController.text.trim(),
          'verified': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      // Create in Mongo via GraphQL (your existing mutation)
      final createdSeller = await _createSellerInMongo(user);

      await RoleManager.setLocalRole('seller');

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => const Dynamichome(selectedIndex: 3)),
              (route) => false);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Seller Registered Successfully (ID: ${createdSeller['customId']})"),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error registering seller: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _createSellerInMongo(User user) async {
    final HttpLink link = HttpLink(graphqlUrl);
    final GraphQLClient client =
    GraphQLClient(cache: GraphQLCache(), link: link);

    const String mutation = r'''
      mutation CreateSeller($input: SellerInput!) {
        createSeller(input: $input) {
          customId
          companyName
          email
          status
        }
      }
    ''';

    final variables = {
      "input": {
        "name": user.displayName ?? "Seller User",
        "companyName": _storeNameController.text.trim(),
        "PANnumber": _panController.text.trim().isEmpty
            ? "NOT_PROVIDED"
            : _panController.text.trim(),
        "gstNumber": _gstController.text.trim(),
        "address": _addressController.text.trim(),
        "bankIFCnumber": _ifscController.text.trim(),
        "bankAccountNumber": _accountController.text.trim(),
        "authorized": user.displayName ?? "Authorized Seller",
        "email": (user.email == null || user.email!.isEmpty)
            ? "${_phoneController.text.trim()}@seller.flyhub"
            : user.email,
        "phoneNumber": _phoneController.text.trim(),
        "shippingAddresses": [_addressController.text.trim()],
        "pickupAddresses": [_addressController.text.trim()],
        "companyPan": _panController.text.trim().isEmpty
            ? "NOT_PROVIDED"
            : _panController.text.trim(),
        "bankName": _bankNameController.text.trim().isEmpty
            ? "Unknown Bank"
            : _bankNameController.text.trim(),
      }
    };

    final result = await client
        .mutate(MutationOptions(document: gql(mutation), variables: variables));

    if (result.hasException) {
      debugPrint("GraphQL Exception: ${result.exception}");
      throw Exception("MongoDB Seller Creation Failed");
    }

    return result.data!['createSeller'] as Map<String, dynamic>;
  }

  // -------------------------------------------------------
  // --------------- Phone OTP verification ----------------
  // -------------------------------------------------------
  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter a valid 10-digit phone number")));
      return;
    }

    final fullPhone = phone.startsWith("+") ? phone : "+91$phone";

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: fullPhone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto verification (rare on Android)
        await _auth.signInWithCredential(credential);
        if (mounted) setState(() => _phoneVerified = true);
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("OTP failed: ${e.message}")));
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _showOtpDialog();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  void _showOtpDialog() {
    final otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Enter OTP"),
        content: TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "6-digit OTP"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final code = otpController.text.trim();
              if (code.length != 6) return;

              try {
                final credential = PhoneAuthProvider.credential(
                    verificationId: _verificationId!, smsCode: code);
                await _auth.signInWithCredential(credential);
                if (mounted) setState(() => _phoneVerified = true);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Phone verified")));
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text("Invalid OTP: $e")));
              }
            },
            child: const Text("Verify"),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // -------------------- UI Builders ----------------------
  // -------------------------------------------------------
  Widget _loginSection() {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Seller Login"),
        backgroundColor: Colors.white,
        foregroundColor: themeColor,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          EdgeInsets.symmetric(horizontal: w * 0.08, vertical: h * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Welcome back",
                  style: GoogleFonts.lexend(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: themeColor)),
              const SizedBox(height: 8),
              Text("Login with email/password or continue with Google",
                  style: GoogleFonts.lexend(
                      fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(height: 20),
              TextField(
                controller: _loginEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _loginPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text("Forgot Password?")),
              ),
              const SizedBox(height: 8),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _loginWithEmail,
                style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text("Login",
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata),
                label: const Text("Continue with Google"),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => setState(() => _showLogin = false),
                child:
                const Text("Don't have an account? Create Seller Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _registrationSection() {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Seller Registration"),
        backgroundColor: Colors.white,
        foregroundColor: themeColor,
        elevation: 1,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _showLogin = true)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          EdgeInsets.symmetric(horizontal: w * 0.08, vertical: h * 0.02),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text("Setup Your Seller Profile",
                    style: GoogleFonts.lexend(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: themeColor)),
                const SizedBox(height: 18),

                // Email & Password for registration (added)
                TextFormField(
                  controller: _regEmailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final s = v ?? '';
                    if (s.trim().isEmpty) return "Please enter email";
                    if (!s.contains('@')) return "Enter a valid email";
                    return null;
                  },
                  decoration: const InputDecoration(
                      labelText: "Email (for login)",
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _regPasswordController,
                  obscureText: true,
                  validator: (v) {
                    if ((v ?? '').length < 6)
                      return "Password must be at least 6 characters";
                    return null;
                  },
                  decoration: const InputDecoration(
                      labelText: "Password (for login)",
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 18),

                // Seller fields (same as your original)
                _buildTextField(
                    _storeNameController, "Store Name", Icons.storefront),
                _buildTextField(
                    _gstController, "GST Number", Icons.receipt_long),
                _buildTextField(
                    _panController, "PAN Number", Icons.credit_card),
                _buildTextField(
                    _addressController, "Address", Icons.location_pin),
                _buildTextField(
                    _bankNameController, "Bank Name", Icons.account_balance),
                _buildTextField(_ifscController, "IFSC Code", Icons.qr_code),
                _buildTextField(
                    _accountController, "Account Number", Icons.numbers),

                // Phone + OTP
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                          _phoneController, "Phone Number", Icons.phone_android,
                          keyboardType: TextInputType.phone),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _phoneVerified ? null : _sendOTP,
                      style:
                      ElevatedButton.styleFrom(backgroundColor: themeColor),
                      child: Text(_phoneVerified ? "Verified" : "Verify",
                          style: const TextStyle(color: Colors.white)),
                    )
                  ],
                ),

                _buildTextField(_descriptionController, "Business Description",
                    Icons.description,
                    maxLines: 3),

                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                        _isLoading ? null : _createAuthAccountIfNeeded,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text("Create Account",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitSellerFormFull,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor),
                        child: _isLoading
                            ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                            : const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text("Submit & Continue",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                // Note: Approval flow on backend should set seller status; only approved sellers allowed to login as sellers
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable text field builder (keeps your UI style)
  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (v) =>
        v == null || v.trim().isEmpty ? "Please enter $label" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: themeColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: themeColor)),
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // --------------------- lifecycle -----------------------
  // -------------------------------------------------------
  @override
  void dispose() {
    // login
    _loginEmailController.dispose();
    _loginPasswordController.dispose();

    // registration email/password
    _regEmailController.dispose();
    _regPasswordController.dispose();

    // seller form
    _storeNameController.dispose();
    _gstController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _panController.dispose();
    _addressController.dispose();
    _bankNameController.dispose();
    _ifscController.dispose();
    _accountController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _showLogin ? _loginSection() : _registrationSection();
  }
}