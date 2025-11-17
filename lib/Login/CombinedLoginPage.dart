import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../HomeScreen/Dynamichome.dart';
import '../HomeScreen/Bottoms/SellerFormDialog.dart';
import '../services/role_manager.dart';
import 'BuyerRegisterPage.dart';

class CombinedLoginPage extends StatefulWidget {
  const CombinedLoginPage({super.key});

  @override
  State<CombinedLoginPage> createState() => _CombinedLoginPageState();
}

class _CombinedLoginPageState extends State<CombinedLoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  static const Color themeColor = Color(0xFF1A0A5B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // --------------------------------------------------------------------------
  // 🔍 LOOKUP FIRESTORE loginIndex
  // --------------------------------------------------------------------------
  Future<String?> _resolveEmailFromLoginIndex(String input) async {
    DocumentSnapshot? doc;

    // 1. Phone
    doc = await _firestore.collection("loginIndex").doc("phone_$input").get();
    if (doc.exists) return doc["uid"];

    // 2. Email
    doc = await _firestore.collection("loginIndex").doc("email_$input").get();
    if (doc.exists) return doc["uid"];

    // 3. SellerID
    doc = await _firestore.collection("loginIndex").doc("sellerId_$input").get();
    if (doc.exists) return doc["uid"];

    return null;
  }

  // --------------------------------------------------------------------------
  // 🔐 LOGIN HANDLER (Buyer or Seller)
  // --------------------------------------------------------------------------
  Future<void> _login({required bool isSeller}) async {
    final input = _inputController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      setState(() => _error = "Please enter login details");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Step 1: Resolve UID from loginIndex
      final uid = await _resolveEmailFromLoginIndex(input);
      if (uid == null) throw Exception("No user found for this login.");

      // Step 2: Fetch user document
      final userDoc = await _firestore.collection("users").doc(uid).get();
      if (!userDoc.exists) throw Exception("User record missing.");

      final email = userDoc["email"];
      final role = userDoc["role"];

      if (isSeller && role != "seller") {
        throw Exception("This account is not a seller account.");
      }
      if (!isSeller && role != "buyer") {
        throw Exception("This account is not a buyer account.");
      }

      // Step 3: Firebase login
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Step 4: Save role locally
      await RoleManager.setLocalRole(role);

      // Step 5: Navigate
      if (!mounted) return;

      if (isSeller) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 3)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
        );
      }

      _showSnack("Welcome back!");
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // --------------------------------------------------------------------------
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: themeColor,
        centerTitle: true,
        title: Text(
          "FlyHub Login",
          style: GoogleFonts.lexend(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Buyer"),
            Tab(text: "Seller"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLoginForm(isSeller: false),
          _buildLoginForm(isSeller: true),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  Widget _buildLoginForm({required bool isSeller}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isSeller
                ? "Login to manage your Drone Store"
                : "Login to explore FlyHub Marketplace",
            style: GoogleFonts.lexend(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 30),

          // Input
          TextField(
            controller: _inputController,
            decoration: InputDecoration(
              hintText: "Email / Phone / ${isSeller ? 'Seller ID' : 'Buyer ID'}",
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 15),

          // Password
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: "Password",
              prefixIcon: const Icon(Icons.lock),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
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
            onPressed: () => _login(isSeller: isSeller),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isSeller ? "Login as Seller" : "Login as Buyer",
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),

          if (!isSeller)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BuyerRegisterPage()),
                );
              },
              child: const Text("New Buyer? Register here"),
            ),

          if (isSeller)
            Text(
              "Seller accounts are created through Seller Form",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            )
        ],
      ),
    );
  }
}
