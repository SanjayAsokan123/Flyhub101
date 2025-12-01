import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../HomeScreen/Dynamichome.dart';
import '../../services/role_manager.dart';
import '../config/env.dart';
import './ForgotPasswordPage.dart'; // ✅ NEW
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

  bool loading = false;
  bool showPassword = false;

  static const Color themeColor = Color(0xFF1A0A5B);

  // -------------------------------------------------------------
  // 🔥 GRAPHQL → Check seller status ONLY from MongoDB
  // -------------------------------------------------------------
  Future<Map<String, dynamic>?> fetchSellerFromAPI(String value) async {
    final String url = EnvConfig.baseUrl;

    final query = """
      query SellerByEmail(\$email: String, \$username: String, \$phone: String, \$customId: String) {
        sellerByEmail(email: \$email, username: \$username, phone: \$phone, customId: \$customId) {
          customId
          email
          phoneNumber
          status
        }
      }
    """;

    final variables = {
      "email": value.contains("@") ? value : null,
      "phone": value.length >= 8 ? value : null,
      "username": null,
      "customId": value,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"query": query, "variables": variables}),
    );

    final body = jsonDecode(response.body);
    return body["data"]?["sellerByEmail"];
  }

  // -------------------------------------------------------------
  // 🔐 SELLER LOGIN
  // -------------------------------------------------------------
  Future<void> sellerLogin() async {
    final enteredInput = input.text.trim();
    final enteredPass = password.text.trim();

    if (enteredInput.isEmpty || enteredPass.isEmpty) {
      showMessage("Please enter login details");
      return;
    }

    setState(() => loading = true);

    try {
      // 1️⃣ CHECK SELLER IN MONGODB (GraphQL)
      final seller = await fetchSellerFromAPI(enteredInput);

      if (seller == null) {
        showMessage("No seller found");
        setState(() => loading = false);
        return;
      }

      final String customId = seller["customId"] ?? "";
      final String email = seller["email"] ?? "";
      final String status = seller["status"] ?? "pending";

      // 2️⃣ STATUS CHECK
      if (status == "pending") {
        showMessage("Seller account is pending approval");
        setState(() => loading = false);
        return;
      }

      if (status == "rejected") {
        showMessage("Seller account is rejected");
        setState(() => loading = false);
        return;
      }

      if (status != "approved") {
        showMessage("Invalid status: $status");
        setState(() => loading = false);
        return;
      }

      if (email.isEmpty) {
        showMessage("Account has no email. Contact support.");
        setState(() => loading = false);
        return;
      }

      // 3️⃣ LOGIN USING FIREBASE EMAIL/PASSWORD
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: enteredPass,
      );

      // 4️⃣ SAVE ROLE
      await RoleManager.setLocalRole("seller");

      showMessage("Login Successful!");

      // 5️⃣ NAVIGATE
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
      );
    } catch (e) {
      debugPrint("Login error: $e");
      showMessage("Login failed: ${_friendlyError(e)}");
    } finally {
      setState(() => loading = false);
    }
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains("wrong-password")) return "Incorrect password";
    if (s.contains("user-not-found")) return "User not found";
    if (s.contains("invalid-credential")) return "Invalid credentials";
    return s;
  }

  @override
  void dispose() {
    input.dispose();
    password.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------
  // UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: themeColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
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

              // INPUT
              TextField(
                controller: input,
                decoration: InputDecoration(
                  labelText: "Email / Phone / Seller ID",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: themeColor, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // PASSWORD
              TextField(
                controller: password,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                      color: themeColor,
                    ),
                    onPressed: () {
                      setState(() => showPassword = !showPassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: themeColor, width: 2),
                  ),
                ),
              ),

              // ✅ Forgot Password Link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              loading
                  ? const Center(
                  child: CircularProgressIndicator(color: themeColor))
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
                      builder: (_) => const SellerRegisterPage(),
                    ),
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

  void showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: msg.contains("Successful") ? Colors.green : null,
      ),
    );
  }
}