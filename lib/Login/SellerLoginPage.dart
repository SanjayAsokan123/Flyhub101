import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../HomeScreen/Dynamichome.dart';
import '../../services/role_manager.dart';
import './SellerRegisterPage.dart';

class SellerLoginPage extends StatefulWidget {
  const SellerLoginPage({super.key});

  @override
  State<SellerLoginPage> createState() => _SellerLoginPageState();
}

class _SellerLoginPageState extends State<SellerLoginPage> {
  final TextEditingController input = TextEditingController();
  final TextEditingController password = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool loading = false;
  bool showPassword = false;
  String? error;

  static const Color themeColor = Color(0xFF1A0A5B);

  // -------------------------------------------------------------------
  // 🔥 SELLER LOGIN METHOD
  // Supports: email / phone / sellerId
  // -------------------------------------------------------------------
  Future<void> sellerLogin() async {
    final inputVal = input.text.trim();
    final pass = password.text.trim();

    if (inputVal.isEmpty || pass.isEmpty) {
      showMessage("Enter credentials");
      return;
    }

    setState(() => loading = true);

    try {
      DocumentSnapshot? indexDoc;

      // 1) Email login
      indexDoc = await _firestore.collection("loginIndex")
          .doc("email_$inputVal")
          .get();

      // 2) Phone login
      if (!indexDoc.exists) {
        indexDoc = await _firestore.collection("loginIndex")
            .doc("phone_$inputVal")
            .get();
      }

      // 3) Seller ID login
      if (!indexDoc.exists) {
        indexDoc = await _firestore.collection("loginIndex")
            .doc("sellerId_$inputVal")
            .get();
      }

      if (!indexDoc.exists) {
        showMessage("User not found");
        return;
      }

      final uid = indexDoc["uid"];

      // Fetch users/{uid}
      final userDoc = await _firestore.collection("users").doc(uid).get();
      if (!userDoc.exists) {
        showMessage("User record missing");
        return;
      }

      final data = userDoc.data()!;
      final email = data["email"];

      Map<String, dynamic> roles =
      Map<String, dynamic>.from(data["roles"] ?? {});

      if (roles["seller"] != true) {
        showMessage("Not a seller account");
        return;
      }

      // Firebase login
      await _auth.signInWithEmailAndPassword(email: email, password: pass);

      // Save role locally
      await RoleManager.setLocalRole("seller");

      showMessage("Login successful");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 3)),
      );

    } catch (e) {
      showMessage("Login failed: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  // -------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: w * 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Seller Login",
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: input,
                decoration: InputDecoration(
                  labelText: "Email / Phone / Seller ID",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: password,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                        showPassword ? Icons.visibility : Icons.visibility_off,
                        color: themeColor),
                    onPressed: () {
                      setState(() => showPassword = !showPassword);
                    },
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),

              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(error!,
                      style: const TextStyle(color: Colors.red, fontSize: 14)),
                ),

              const SizedBox(height: 20),

              loading
                  ? const Center(
                child: CircularProgressIndicator(color: themeColor),
              )
                  : ElevatedButton(
                onPressed: sellerLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Login",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),

              const SizedBox(height: 15),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SellerRegisterPage()),
                  );
                },
                child: Text(
                  "Don't have a seller account? Register",
                  style: TextStyle(
                    color: themeColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  void showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
