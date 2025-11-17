import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../HomeScreen/Dynamichome.dart';
import '../../services/role_manager.dart';

class SellerLoginPage extends StatefulWidget {
  const SellerLoginPage({super.key});

  @override
  State<SellerLoginPage> createState() => _SellerLoginPageState();
}

class _SellerLoginPageState extends State<SellerLoginPage> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = false;
  String? _error;
  static const Color themeColor = Color(0xFF1A0A5B);

  Future<void> _sellerLogin() async {
    final input = _inputController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      setState(() => _error = "Enter email/phone/Seller ID and password.");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      String? email;

      // 🔍 1. LOOKUP INPUT IN loginIndex
      final indexDoc = await _firestore
          .collection("loginIndex")
          .doc("phone_$input")
          .get();

      DocumentSnapshot? loginIndex;

      if (indexDoc.exists) {
        loginIndex = indexDoc;
      } else {
        final emailDoc = await _firestore.collection("loginIndex").doc("email_$input").get();
        if (emailDoc.exists) {
          loginIndex = emailDoc;
        } else {
          final idDoc = await _firestore.collection("loginIndex").doc("sellerId_$input").get();
          if (idDoc.exists) loginIndex = idDoc;
        }
      }

      if (loginIndex == null || !loginIndex.exists) {
        throw Exception("No seller found for this ID/phone/email.");
      }

      final uid = loginIndex['uid'];

      // 🔄 2. FETCH EMAIL FROM USERS/{uid}
      final userDoc = await _firestore.collection("users").doc(uid).get();
      email = userDoc['email'];

      if (email == null) {
        throw Exception("Email not found for this seller.");
      }

      // 🔐 3. Firebase Auth login using email
      await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // 🏷 Save role locally
      await RoleManager.setLocalRole("seller");

      // 🚀 Navigate to seller dashboard
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const Dynamichome(selectedIndex: 3),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Logged in successfully!")),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Seller Login",
                style: GoogleFonts.lexend(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                )),

            const SizedBox(height: 20),

            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: "Email / Phone / Seller ID",
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Password",
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            const SizedBox(height: 20),

            _loading
                ? const CircularProgressIndicator(color: themeColor)
                : ElevatedButton(
              onPressed: _sellerLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Login",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
