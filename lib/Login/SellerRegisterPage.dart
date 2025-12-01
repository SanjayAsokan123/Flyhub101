import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../HomeScreen/Dynamichome.dart';
import '../../config/env.dart';
import '../../services/role_manager.dart';
import '../auth/auth_service.dart';

class SellerRegisterPage extends StatefulWidget {
  const SellerRegisterPage({super.key});

  @override
  State<SellerRegisterPage> createState() => _SellerRegisterPageState();
}

class _SellerRegisterPageState extends State<SellerRegisterPage> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form key
  final _formKey = GlobalKey<FormState>();

  // All form fields
  final TextEditingController regEmail = TextEditingController();
  final TextEditingController regPassword = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController otpCode = TextEditingController();
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController storeName = TextEditingController();
  final TextEditingController gst = TextEditingController();
  final TextEditingController pan = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController bank = TextEditingController();
  final TextEditingController ifsc = TextEditingController();
  final TextEditingController account = TextEditingController();
  final TextEditingController description = TextEditingController();

  // ✅ NEW: Shipping and Pickup Address Controllers
  final TextEditingController shippingAddress = TextEditingController();
  final TextEditingController pickupAddress = TextEditingController();

  // State
  bool otpSent = false;
  bool phoneVerified = false;
  bool accountCreated = false;
  bool loading = false;
  bool regPassVisible = false;

  // ✅ NEW: Checkbox states
  bool sameAsBusinessAddress = false;
  bool pickupSameAsShipping = false;

  static const Color themeColor = Color(0xFF1A0A5B);
  late final String graphqlUrl = "${EnvConfig.baseUrl}/graphql";

  String? verificationId;

  // ═════════════════════════════════════════════════════════════
  // STEP 1: SEND OTP (FIREBASE PHONE AUTH)
  // ═════════════════════════════════════════════════════════════

  Future<void> sendOTP() async {
    final ph = phone.text.trim();

    if (ph.isEmpty || ph.length < 10) {
      showMessage("Enter valid phone number");
      return;
    }

    String phoneWithCode = ph.startsWith('+') ? ph : '+91$ph';

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneWithCode,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android)
          setState(() {
            otpSent = true;
            phoneVerified = true;
          });
          showMessage("✅ Phone verified automatically");
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => loading = false);
          showMessage("❌ Verification failed: ${e.message}");
        },
        codeSent: (String verId, int? resendToken) {
          setState(() {
            verificationId = verId;
            otpSent = true;
            loading = false;
          });
          showMessage("📲 OTP sent to $phoneWithCode");
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId = verId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() => loading = false);
      showMessage("❌ ${e.toString().replaceAll('Exception: ', '')}");
    }
  }


  // ═════════════════════════════════════════════════════════════
  // STEP 2: VERIFY OTP AND CREATE ACCOUNT (FIREBASE)
  // ═════════════════════════════════════════════════════════════

  Future<void> createAccountWithOTP() async {
    if (!_formKey.currentState!.validate()) return;

    final email = regEmail.text.trim();
    final pass = regPassword.text.trim();
    final ph = phone.text.trim();
    final code = otpCode.text.trim();

    if (code.isEmpty || code.length != 6) {
      showMessage("Enter 6-digit OTP");
      return;
    }

    if (verificationId == null) {
      showMessage("Please send OTP first");
      return;
    }


    String phoneWithCode = ph.startsWith('+') ? ph : '+91$ph';
    setState(() => loading = true);

    try {
      // 1️⃣ VERIFY OTP
      final PhoneAuthCredential credential  = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: code,
      );

      final userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );




      final user = userCredential.user;
      if (user == null) throw Exception("User creation failed");

      // ⿣ Link phone credential to the account
      try {
        await user.linkWithCredential(credential);
        print("✅ Phone linked to account");
      } on FirebaseAuthException catch (e) {
        if (e.code == 'provider-already-linked') {
          print("⚠ Phone already linked");
        } else if (e.code == 'credential-already-in-use') {
          throw Exception("This phone number is already in use");
        } else {
          throw Exception("Phone linking failed: ${e.message}");
        }
      }

      // 3️⃣ UPDATE SELLER OTP DOCUMENT
      await _firestore.collection("SellerOtp").doc(phoneWithCode).set({
        "uid": user.uid,
        "phoneVerified": true,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        phoneVerified = true;
        accountCreated = true;
      });


      showMessage("✅ Account created! Complete your business profile.");
    } catch (e) {
      // If account creation fails, delete the user
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await currentUser.delete();
        }
      } catch (_) {}

      showMessage("❌ ${e.toString().replaceAll('Exception: ', '')}");
    }finally {
      setState(() => loading = false);
    }
  }


  // ═════════════════════════════════════════════════════════════
  // STEP 3: SUBMIT SELLER FORM (FIREBASE)
  // ═════════════════════════════════════════════════════════════
  Future<void> submitSellerForm() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage("User not logged in");
      return;
    }

    setState(() => loading = true);

    try {
      final phoneNumber = phone.text.startsWith("+")
          ? phone.text.trim()
          : "+91${phone.text.trim()}";

      // 👉 First: Send all data to MongoDB and get customId
      final String? customId =
      await saveSellerToMongoAndMirror(user, phoneNumber);

      if (customId == null) {
        throw Exception("Failed to get customId from MongoDB");
      }

      await RoleManager.setLocalRole("seller");

      // 👉 Success Dialog
      await _showSubmissionConfirmationDialog();

    } catch (e) {
      showMessage("Error: ${e.toString()}");
    } finally {
      setState(() => loading = false);
    }
  }



  /// Show confirmation dialog after submission
  Future<void> _showSubmissionConfirmationDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Application Submitted!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Thank you for registering as a seller!",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 15),
              const Text(
                "Your details will be verified by FlyHub Private Company. You will receive a notification and email once your account is approved.",
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "You can explore the app while we review your application.",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to home
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const Dynamichome(selectedIndex: 0)),
                      (route) => false,
                );
              },
              child: const Text(
                "Explore App",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String?> saveSellerToMongoAndMirror(
      User user,
      String phoneNumber,
      ) async {
    final token = await user.getIdToken();

    final client = GraphQLClient(
      cache: GraphQLCache(),
      link: AuthLink(getToken: () async => "Bearer $token")
          .concat(HttpLink(graphqlUrl)),
    );

    const String mutation = r'''
    mutation CreateSeller($input: SellerInput!) {
      createSeller(input: $input) {
        customId
        status
        companyName
      }
    }
  ''';

    // -------------------- Address Logic --------------------
    String finalShippingAddress = shippingAddress.text.trim();
    String finalPickupAddress = pickupAddress.text.trim();

    if (sameAsBusinessAddress && finalShippingAddress.isEmpty) {
      finalShippingAddress = address.text.trim();
    }

    if (pickupSameAsShipping && finalPickupAddress.isEmpty) {
      finalPickupAddress = finalShippingAddress;
    }

    // -------------------- SEND TO MONGO --------------------
    final variables = {
      "input": {
        "name": "${firstName.text.trim()} ${lastName.text.trim()}",
        "companyName": storeName.text.trim(),
        "PANnumber": pan.text.trim(),
        "gstNumber": gst.text.trim(),
        "address": address.text.trim(),
        "phoneNumber": phoneNumber,
        "authorized": storeName.text.trim(),
        "email": user.email,
        "bankName": bank.text.trim(),
        "bankAccountNumber": account.text.trim(),
        "bankIFCnumber": ifsc.text.trim(),
        "companyPan": pan.text.trim(),
        "shippingAddresses": [finalShippingAddress],
        "pickupAddresses": [finalPickupAddress],
        "firebaseUid": user.uid,
        "status": "pending",
      }
    };

    final result = await client.mutate(
      MutationOptions(document: gql(mutation), variables: variables),
    );

    if (result.hasException) {
      throw Exception("MongoDB Error: ${result.exception.toString()}");
    }

    final created = result.data?['createSeller'];
    final customId = created?['customId'];
    final status = created?['status'] ?? "pending";

    if (customId == null) throw Exception("No customId returned from server");

    // -------------------- SAVE TO sellers COLLECTION --------------------
    await _firestore.collection("sellers").doc(customId).set({
      "customId": customId,
      "firebaseUid": user.uid,
      "companyName": storeName.text.trim(),
      "gstNumber": gst.text.trim(),
      "panNumber": pan.text.trim(),
      "address": address.text.trim(),
      "shippingAddresses": [finalShippingAddress],
      "pickupAddresses": [finalPickupAddress],
      "bankName": bank.text.trim(),
      "accountNumber": account.text.trim(),
      "ifsc": ifsc.text.trim(),
      "phoneNumber": phoneNumber,
      "email": user.email,
      "status": status,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    // -------------------- UPDATE SellerOtp --------------------
    await _firestore.collection("SellerOtp").doc(phoneNumber).set({
      "phone": phoneNumber,
      "uid": user.uid,
      "phoneVerified": true,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return customId;
  }


  // ═════════════════════════════════════════════════════════════
  // UI - SINGLE PAGE WITH PROGRESSIVE SECTIONS
  // ═════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seller Registration"),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Indicator
              _buildProgressIndicator(),

              const SizedBox(height: 30),

              // Step 1: Phone Verification
              _buildPhoneVerificationSection(),

              if (otpSent && !accountCreated) ...[
                const SizedBox(height: 20),
                _buildOTPSection(),
              ],

              // Step 2: Account Creation
              if (!accountCreated) ...[
                const SizedBox(height: 20),
                _buildAccountSection(),
              ],

              // Step 3: Business Information
              if (accountCreated) ...[
                const SizedBox(height: 30),
                _buildBusinessInfoSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Progress Indicator
  Widget _buildProgressIndicator() {
    int currentStep = 1;
    if (otpSent && !accountCreated) currentStep = 2;
    if (accountCreated) currentStep = 3;

    return Column(
      children: [
        Row(
          children: [
            _buildStepIndicator(1, "Phone", currentStep >= 1),
            _buildStepLine(currentStep >= 2),
            _buildStepIndicator(2, "Account", currentStep >= 2),
            _buildStepLine(currentStep >= 3),
            _buildStepIndicator(3, "Profile", currentStep >= 3),
          ],
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? themeColor : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "$step",
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? themeColor : Colors.grey.shade600,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? themeColor : Colors.grey.shade300,
        margin: const EdgeInsets.only(bottom: 30),
      ),
    );
  }

  // Section 1: Phone Verification
  Widget _buildPhoneVerificationSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  phoneVerified ? Icons.check_circle : Icons.phone_android,
                  color: phoneVerified ? Colors.green : themeColor,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  "Step 1: Phone Verification",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: phoneVerified ? Colors.green : themeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: input(
                    phone,
                    "Phone Number",
                    keyboardType: TextInputType.phone,
                    enabled: !phoneVerified,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: phoneVerified ? Colors.green : themeColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                  ),
                  onPressed: phoneVerified ? null : (loading ? null : sendOTP),
                  child: Text(
                    phoneVerified ? "✓ Sent" : "Send OTP",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Section 2: OTP Input
  Widget _buildOTPSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter OTP",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            input(otpCode, "6-digit OTP", keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextButton(
              onPressed: loading ? null : sendOTP,
              child: const Text("Resend OTP"),
            ),
          ],
        ),
      ),
    );
  }

  // Section 3: Account Details
  Widget _buildAccountSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  accountCreated ? Icons.check_circle : Icons.person_add,
                  color: accountCreated ? Colors.green : themeColor,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  "Step 2: Create Account",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accountCreated ? Colors.green : themeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            input(firstName, "First Name", enabled: !accountCreated),
            input(lastName, "Last Name", enabled: !accountCreated),
            input(regEmail, "Email",
                keyboardType: TextInputType.emailAddress,
                enabled: !accountCreated),
            input(
              regPassword,
              "Password",
              isPass: true,
              isPasswordVisible: regPassVisible,
              onEyeTap: () => setState(() => regPassVisible = !regPassVisible),
              enabled: !accountCreated,
            ),
            const SizedBox(height: 20),
            button("Create Account", createAccountWithOTP),
          ],
        ),
      ),
    );
  }

  // Section 4: Business Information
  Widget _buildBusinessInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: themeColor, size: 28),
                const SizedBox(width: 10),
                const Text(
                  "Step 3: Business Information",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Business Details Section
            const Text("Business Details",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            input(storeName, "Company/Store Name"),
            input(gst, "GST Number"),
            input(pan, "PAN Number"),
            input(address, "Business Address", maxLines: 2),
            input(description, "Business Description", maxLines: 3),

            const SizedBox(height: 20),

            // ✅ NEW: Shipping Address Section
            const Text("Shipping Address",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Checkbox for same as business address
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "Same as Business Address",
                style: TextStyle(fontSize: 14),
              ),
              value: sameAsBusinessAddress,
              activeColor: themeColor,
              onChanged: (bool? value) {
                setState(() {
                  sameAsBusinessAddress = value ?? false;
                  if (sameAsBusinessAddress) {
                    shippingAddress.text = address.text.trim();
                  } else {
                    shippingAddress.clear();
                  }
                });
              },
            ),

            input(
              shippingAddress,
              "Shipping Address",
              maxLines: 2,
              enabled: !sameAsBusinessAddress,
            ),

            const SizedBox(height: 20),

            // ✅ NEW: Pickup Address Section
            const Text("Pickup Address",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Checkbox for same as shipping address
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "Same as Shipping Address",
                style: TextStyle(fontSize: 14),
              ),
              value: pickupSameAsShipping,
              activeColor: themeColor,
              onChanged: (bool? value) {
                setState(() {
                  pickupSameAsShipping = value ?? false;
                  if (pickupSameAsShipping) {
                    pickupAddress.text = sameAsBusinessAddress
                        ? address.text.trim()
                        : shippingAddress.text.trim();
                  } else {
                    pickupAddress.clear();
                  }
                });
              },
            ),

            input(
              pickupAddress,
              "Pickup Address",
              maxLines: 2,
              enabled: !pickupSameAsShipping,
            ),

            const SizedBox(height: 20),

            // Banking Information Section
            const Text("Banking Information",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            input(bank, "Bank Name"),
            input(ifsc, "IFSC Code"),
            input(account, "Account Number"),

            const SizedBox(height: 30),
            button("Submit Application", submitSellerForm),
            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Your application will be reviewed by our team within 24-48 hours.",
                      style: TextStyle(fontSize: 12),
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

  Widget input(
      TextEditingController controller,
      String label, {
        bool isPass = false,
        bool isPasswordVisible = false,
        VoidCallback? onEyeTap,
        int maxLines = 1,
        TextInputType? keyboardType,
        bool enabled = true,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: isPass && !isPasswordVisible,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: !enabled,
          fillColor: !enabled ? Colors.grey.shade100 : null,
          suffixIcon: isPass
              ? IconButton(
            icon: Icon(
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: onEyeTap,
          )
              : null,
        ),
        validator: (v) => v!.isEmpty ? "Enter $label" : null,
      ),
    );
  }

  Widget button(String text, Function() onTap) {
    return ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: themeColor,
      ),
      child: loading
          ? const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  void showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    regEmail.dispose();
    regPassword.dispose();
    phone.dispose();
    otpCode.dispose();
    firstName.dispose();
    lastName.dispose();
    storeName.dispose();
    gst.dispose();
    pan.dispose();
    address.dispose();
    bank.dispose();
    ifsc.dispose();
    account.dispose();
    description.dispose();
    shippingAddress.dispose(); // ✅ NEW
    pickupAddress.dispose(); // ✅ NEW
    super.dispose();
  }
}