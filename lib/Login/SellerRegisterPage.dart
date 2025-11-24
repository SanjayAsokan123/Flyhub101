import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/env.dart';
import '../../HomeScreen/Dynamichome.dart';
import '../../services/role_manager.dart';

class SellerRegisterPage extends StatefulWidget {
  const SellerRegisterPage({super.key});

  @override
  State<SellerRegisterPage> createState() => _SellerRegisterPageState();
}

class _SellerRegisterPageState extends State<SellerRegisterPage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Registration fields
  final TextEditingController regEmail = TextEditingController();
  final TextEditingController regPassword = TextEditingController();

  // Seller form fields
  final _sellerFormKey = GlobalKey<FormState>();
  final TextEditingController storeName = TextEditingController();
  final TextEditingController gst = TextEditingController();
  final TextEditingController pan = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController bank = TextEditingController();
  final TextEditingController ifsc = TextEditingController();
  final TextEditingController account = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController phone = TextEditingController();

  bool phoneVerified = false;
  String? verificationId;
  bool loading = false;

  // Eye toggles
  bool loginPassVisible = false;
  bool regPassVisible = false;

  static const Color themeColor = Color(0xFF1A0A5B);
  late final String graphqlUrl = "${EnvConfig.baseUrl}/graphql";

  @override
  void initState() {
    tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  // ----------------------------------------------------------------------
  // BUYER → SELLER UPGRADE POPUP
  // ----------------------------------------------------------------------
  void _showUpgradeDialog(String uid, Map<String, dynamic> roles) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Upgrade Account?"),
        content: const Text(
            "This email exists as a BUYER.\n\nDo you want to upgrade and continue Seller Registration?"),
        actions: [
          TextButton(
            child: const Text("NO"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: themeColor),
            child: const Text("YES", style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(context);

              roles["buyer"] = roles["buyer"] ?? true;
              roles["seller"] = true;

              await _firestore
                  .collection("users")
                  .doc(uid)
                  .set({"roles": roles}, SetOptions(merge: true));

              tabController.animateTo(1);

              showMessage("Seller role added — complete your seller form");
            },
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // MULTI-ROLE SAFE REGISTRATION
  // ----------------------------------------------------------------------
  Future<void> createSellerAccount() async {
    final email = regEmail.text.trim();
    final pass = regPassword.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      showMessage("Enter email & password");
      return;
    }

    setState(() => loading = true);

    try {
      // CHECK if user already exists in USERS (not loginIndex)
      final existing = await _firestore
          .collection("users")
          .where("email", isEqualTo: email)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        // Existing user → Upgrade only
        final doc = existing.docs.first;
        final uid = doc.id;

        final data = doc.data();
        final roles = Map<String, dynamic>.from(data["roles"] ?? {});
        roles["seller"] = true;

        await _firestore.collection("users").doc(uid).set({
          "roles": roles
        }, SetOptions(merge: true));

        tabController.animateTo(1);
        showMessage("Seller role added to existing account!");
        return;
      }

      // NEW user
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final user = cred.user!;
      final uid = user.uid;

      // FIRESTORE USER DOC
      await _firestore.collection("users").doc(uid).set({
        "email": email,
        "roles": {
          "buyer": false,
          "seller": true,
        },
        "createdAt": FieldValue.serverTimestamp(),
      });

      // loginIndex: EMAIL
      await _firestore.collection("loginIndex")
          .doc("email_$email")
          .set({"uid": uid});

      tabController.animateTo(1);
      showMessage("Account created. Continue Seller Form");

    } catch (e) {
      showMessage("Error: $e");
    } finally {
      setState(() => loading = false);
    }
  }


  // ----------------------------------------------------------------------
  // OTP SENDING
  // ----------------------------------------------------------------------
  Future<void> sendOTP() async {
    final ph = phone.text.trim();
    if (ph.length != 10) {
      showMessage("Enter valid 10-digit number");
      return;
    }

    FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: "+91$ph",
      verificationCompleted: (cred) async {
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          showMessage("User not logged in");
          return;
        }

        try {
          await user.linkWithCredential(cred);
          setState(() => phoneVerified = true);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'provider-already-linked') {
            setState(() => phoneVerified = true);
          } else if (e.code == 'credential-already-in-use') {
            showMessage("This phone number is already used in another account");
          } else {
            showMessage("Phone verification error: ${e.message}");
          }
        }
      },
      verificationFailed: (e) {
        showMessage("OTP failed: ${e.message}");
      },
      codeSent: (id, _) {
        verificationId = id;
        showOtpDialog();
      },
      codeAutoRetrievalTimeout: (id) => verificationId = id,
    );
  }


  // ----------------------------------------------------------------------
  // OTP POPUP
  // ----------------------------------------------------------------------
  void showOtpDialog() {
    final otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter OTP"),
        content: TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "6-digit OTP"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Verify"),
            onPressed: () async {
              try {
                final cred = PhoneAuthProvider.credential(
                  verificationId: verificationId!,
                  smsCode: otpController.text.trim(),
                );

                final user = FirebaseAuth.instance.currentUser;

                if (user == null) {
                  showMessage("User not logged in");
                  return;
                }

                try {
                  await user.linkWithCredential(cred);
                  setState(() => phoneVerified = true);
                  Navigator.pop(context);
                } on FirebaseAuthException catch (e) {
                  if (e.code == 'provider-already-linked') {
                    setState(() => phoneVerified = true);
                    Navigator.pop(context);
                  } else if (e.code == 'credential-already-in-use') {
                    showMessage("This phone number is already used in another account");
                  } else {
                    showMessage("Verification error: ${e.message}");
                  }
                }
              } catch (e) {
                showMessage("Incorrect OTP");
              }
            },
          ),
        ],
      ),
    );
  }


  // ----------------------------------------------------------------------
  // SUBMIT SELLER FORM (final step)
  // ----------------------------------------------------------------------
  Future<void> submitSellerForm() async {
    if (!_sellerFormKey.currentState!.validate()) return;
    if (!phoneVerified) {
      showMessage("Verify phone first");
      return;
    }

    setState(() => loading = true);

    try {
      final user = _auth.currentUser!;
      final uid = user.uid;

      // Generate sellerId (Example pattern)
      final sellerId = "SELLER_${uid.substring(0, 6).toUpperCase()}";

      // UPDATE Firestore USER DOC
      await _firestore.collection("users").doc(uid).set({
        "sellerId": sellerId,
        "roles": {"seller": true},
        "sellerAccount": {
          "storeName": storeName.text.trim(),
          "gstNumber": gst.text.trim(),
          "panNumber": pan.text.trim(),
          "phone": phone.text.trim(),
          "address": address.text.trim(),
          "description": description.text.trim(),
          "verified": true,
          "createdAt": FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      // loginIndex: PHONE
      await _firestore.collection("loginIndex")
          .doc("phone_${phone.text.trim()}")
          .set({"uid": uid});

      // loginIndex: SELLER-ID
      await _firestore.collection("loginIndex")
          .doc("sellerId_$sellerId")
          .set({"uid": uid});

      // GRAPHQL → save Mongo
      await saveSellerToMongo(user);

      await RoleManager.setLocalRole("seller");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 1)),
            (route) => false,
      );

    } catch (e) {
      showMessage("Error: $e");
    } finally {
      setState(() => loading = false);
    }
  }


  // ----------------------------------------------------------------------
  // SAVE TO MONGO USING GRAPHQL
  // ----------------------------------------------------------------------
  Future<void> saveSellerToMongo(User user) async {
    final token = await user.getIdToken();

    final AuthLink authLink = AuthLink(
      getToken: () async => "Bearer $token",  // AUTO injects token
    );

    final HttpLink httpLink = HttpLink(graphqlUrl);

    final Link link = authLink.concat(httpLink);

    final GraphQLClient client = GraphQLClient(
      cache: GraphQLCache(),
      link: link,
    );

    const String mutation = r'''
    mutation CreateSeller($input: SellerInput!) {
      createSeller(input: $input) {
        customId
        companyName
        email
      }
    }
  ''';


  final variables = {
      "input": {
        "name": user.displayName ?? "Seller",
        "companyName": storeName.text.trim(),
        "PANnumber": pan.text.trim(),
        "gstNumber": gst.text.trim(),
        "address": address.text.trim(),
        "phoneNumber": phone.text.trim(),
        "authorized": storeName.text.trim(),
        "email": user.email,
        "bankName": bank.text.trim(),
        "bankAccountNumber": account.text.trim(),
        "bankIFCnumber": ifsc.text.trim(),
        "companyPan": pan.text.trim(),
        "shippingAddresses": [address.text.trim()],
        "pickupAddresses": [address.text.trim()],
        "firebaseUid": user.uid,
      }
    };

    final result = await client.mutate(
      MutationOptions(document: gql(mutation), variables: variables),
    );

    if (result.hasException) {
      throw Exception("MongoDB Error: ${result.exception}");
    }
  }

  // ----------------------------------------------------------------------
  // MAIN UI (TabBar + Views)
  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seller Registration"),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Register"),
            Tab(text: "Seller Form"),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          registerUI(),
          sellerFormUI(),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // REGISTER UI
  // ----------------------------------------------------------------------
  Widget registerUI() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          input(regEmail, "Email"),

          input(
            regPassword,
            "Password",
            isPass: true,
            isPasswordVisible: regPassVisible,
            onEyeTap: () =>
                setState(() => regPassVisible = !regPassVisible),
          ),

          const SizedBox(height: 20),

          button("Create Account", createSellerAccount),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // SELLER FORM UI
  // ----------------------------------------------------------------------
  Widget sellerFormUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _sellerFormKey,
        child: Column(
          children: [
            input(storeName, "Store Name"),
            input(gst, "GST Number"),
            input(pan, "PAN Number"),
            input(address, "Store Address"),
            input(bank, "Bank Name"),
            input(ifsc, "IFSC Code"),
            input(account, "Account Number"),

            Row(
              children: [
                Expanded(child: input(phone, "Phone Number")),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: phoneVerified ? Colors.green : themeColor,
                  ),
                  onPressed: phoneVerified ? null : sendOTP,
                  child: Text(phoneVerified ? "Verified" : "Verify",
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),

            input(description, "Business Description", maxLines: 3),

            const SizedBox(height: 20),

            button("Submit Seller Form", submitSellerForm),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // INPUT FIELD COMPONENT
  // ----------------------------------------------------------------------
  Widget input(
      TextEditingController controller,
      String label, {
        bool isPass = false,
        bool isPasswordVisible = false,
        VoidCallback? onEyeTap,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: isPass && !isPasswordVisible,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: isPass
              ? IconButton(
            icon: Icon(
              isPasswordVisible
                  ? Icons.visibility
                  : Icons.visibility_off,
            ),
            onPressed: onEyeTap,
          )
              : null,
        ),
        validator: (v) => v!.isEmpty ? "Enter $label" : null,
      ),
    );
  }

  // ----------------------------------------------------------------------
  // BUTTON COMPONENT
  // ----------------------------------------------------------------------
  Widget button(String text, Function() onTap) {
    return ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: themeColor,
      ),
      child: loading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  // ----------------------------------------------------------------------
  // SNACKBAR HELPER
  // ----------------------------------------------------------------------
  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

} // <-- FINAL CLOSING BRACE OF CLASS
