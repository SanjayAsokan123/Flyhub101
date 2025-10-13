import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ Local imports
import './SellerPage.dart';
import '../Dynamichome.dart';
import '../../Login/SellerOtpAuthScreen.dart';

class SellerFormDialog {
  static void show(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;

    final loginEmailController = TextEditingController();
    final loginPasswordController = TextEditingController();

    bool loading = false;
    String? errorMessage;

    //Local Commit
    showDialog(
      context: context,
      barrierDismissible: false,

      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> handleLogin() async {
              final email = loginEmailController.text.trim();
              final password = loginPasswordController.text.trim();

              if (email.isEmpty || password.isEmpty) {
                setState(() => errorMessage = "Please enter both email and password.");
                return;
              }

              try {
                setState(() {
                  loading = true;
                  errorMessage = null;
                });

                // 🔹 Firebase Email Login
                UserCredential userCredential =
                await _auth.signInWithEmailAndPassword(
                  email: email,
                  password: password,
                );

                final uid = userCredential.user!.uid;

                // 🔹 Set Firestore role
                await FirebaseFirestore.instance.collection('users').doc(uid).set({
                  'uid': uid,
                  'email': email,
                  'role': 'seller',
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (!context.mounted) return;

                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SellerPage()),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Seller Login Successful!")),
                );
              } on FirebaseAuthException catch (e) {
                setState(() => errorMessage = e.message ?? "Login failed. Try again.");
              } catch (e) {
                setState(() => errorMessage = "Unexpected error: $e");
              } finally {
                setState(() => loading = false);
              }
            }

            // ---------------- LOGIN UI ----------------
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Seller Portal",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A0A5B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Seller Login",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A0A5B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    buildStyledTextField(
                      loginEmailController,
                      "Email",
                      keyboardType: TextInputType.emailAddress,
                    ),
                    buildStyledPasswordField(
                      loginPasswordController,
                      "Password",
                    ),

                    const SizedBox(height: 10),

                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(color: Color(0xFF1A0A5B)),
                      ),

                    const SizedBox(height: 20),

                    // 🔹 Login button
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A0A5B),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: loading ? null : handleLogin,
                        child: const Text(
                          "Login",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 🔹 Register with OTP
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SellerOtpAuthScreen()),
                          );
                        },
                        child: const Text(
                          "New Seller? Register with OTP",
                          style: TextStyle(
                            color: Color(0xFF1A0A5B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    // 🔹 Back to home
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.home_outlined, color: Colors.grey),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                const Dynamichome(selectedIndex: 0)),
                          );
                        },
                        label: const Text(
                          "Back to Home",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- FIELD WIDGETS ----------------
  static Widget buildStyledTextField(
      TextEditingController controller,
      String label, {
        TextInputType? keyboardType,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  static Widget buildStyledPasswordField(
      TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
