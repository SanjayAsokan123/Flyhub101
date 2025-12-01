import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool loading = false;
  bool emailSent = false;
  String? _message;

  static const Color themeColor = Color(0xFF1A0A5B);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Colors.white;
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color textSecondary = Color(0xFF6B7280);

  // -------------------------------------------------------------------
  // 🔥 SEND PASSWORD RESET EMAIL (FIXED - No Deprecated Method)
  // -------------------------------------------------------------------
  Future<void> sendPasswordResetEmail() async {
    final email = emailController.text.trim();

    // --- Email Validation ---
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _message = "⚠ Please enter a valid email address";
      });
      return;
    }

    setState(() {
      loading = true;
      _message = null;
    });

    try {
      // ✅ Send password reset email directly
      // Firebase will throw 'user-not-found' if email doesn't exist
      await _auth.sendPasswordResetEmail(email: email);

      // If we reach here, email was sent successfully
      setState(() {
        emailSent = true;
        loading = false;
        _message = "✅ Password reset email sent successfully!";
      });
    } on FirebaseAuthException catch (e) {
      setState(() => loading = false);

      String errorMessage;

      switch (e.code) {
        case 'invalid-email':
          errorMessage = "⚠ Invalid email format.";
          break;

        case 'user-not-found':
        // ✅ Email doesn't exist in Firebase
          errorMessage = "⚠ No account found with this email address.";
          break;

        case 'too-many-requests':
          errorMessage = "⚠ Too many requests. Please try again later.";
          break;

        case 'network-request-failed':
          errorMessage = "⚠ Network error. Check your internet connection.";
          break;

        default:
          errorMessage = "⚠ Error: ${e.message}";
      }

      setState(() => _message = errorMessage);
    } catch (e) {
      setState(() {
        loading = false;
        _message = "❌ Failed to send reset email.";
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------
  // SIMPLE & PROFESSIONAL UI
  // -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Forgot Password",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Text(
                  emailSent ? "Reset Password" : "Reset Your Password",
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: themeColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  emailSent
                      ? "Check your email for password reset instructions"
                      : "Enter your registered email address and we'll send you a link to reset your password.",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Main Content
                if (!emailSent) ...[
                  // Email Input Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Email Field
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: const Color(0xFF111827),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: "you@example.com",
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF9CA3AF),
                            ),
                            labelText: "Email Address",
                            labelStyle: GoogleFonts.inter(
                              color: const Color(0xFF374151),
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Color(0xFF6B7280),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: themeColor,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Reset Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: loading
                              ? Center(
                            child: CircularProgressIndicator(
                              valueColor:
                              AlwaysStoppedAnimation<Color>(themeColor),
                            ),
                          )
                              : ElevatedButton(
                            onPressed: sendPasswordResetEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                              padding:
                              const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              "Send Reset Link",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Message Display (from first version)
                  if (_message != null && !emailSent)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _message!.startsWith("✅")
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _message!.startsWith("✅")
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _message!.startsWith("✅")
                                ? Icons.check_circle_outline_rounded
                                : Icons.error_outline_rounded,
                            color: _message!.startsWith("✅")
                                ? const Color(0xFF10B981)
                                : const Color(0xFFD97706),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _message!.replaceAll("✅ ", "").replaceAll("⚠ ", "").replaceAll("❌ ", ""),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: _message!.startsWith("✅")
                                    ? const Color(0xFF065F46)
                                    : const Color(0xFF92400E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Help Text (from first version)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0F2FE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: const Color(0xFF0369A1),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Important",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0369A1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "• Check your spam folder if you don't see the email\n"
                              "• The link expires in 24 hours\n"
                              "• Contact support if you need further assistance",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Success State (from second version)
                if (emailSent) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF10B981)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Success Icon
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Color(0xFF10B981),
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Success Message
                        Text(
                          "Email Sent Successfully!",
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF065F46),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        Text(
                          "We've sent a password reset link to:",
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        Text(
                          emailController.text,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: themeColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Help Info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0F2FE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: const Color(0xFF0369A1),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Next Steps",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0369A1),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "1. Check your email inbox\n"
                                    "2. Click the reset link in the email\n"
                                    "3. Enter your new password\n"
                                    "4. Return to the app and login",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF4B5563),
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  "Back to Login",
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  emailSent = false;
                                  emailController.clear();
                                  _message = null;
                                });
                              },
                              child: Text(
                                "Try Different Email",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: themeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.inter(),
        ),
        backgroundColor: msg.contains("sent") || msg.startsWith("✅")
            ? const Color(0xFF10B981)
            : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}