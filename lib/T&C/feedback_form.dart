import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../config/env.dart';

class FeedbackFormPage extends StatefulWidget {
  const FeedbackFormPage({Key? key}) : super(key: key);

  @override
  State<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends State<FeedbackFormPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final feedbackController = TextEditingController();

  int _selectedStars = 0;
  bool _isSubmitting = false;
  Timer? _loadingTimer;

  // Optimized email sending
  Completer<bool> _emailCompleter = Completer<bool>();

  // ✉ FAST email sending function with timeout
  Future<bool> _sendEmailFast() async {
    try {
      final String username = Mail_User.EMAIL_USER;
      final String appPassword = Mail_Pass.EMAIL_PASS;

      final smtpServer = gmail(username, appPassword);

      final message = Message()
        ..from = Address(username, 'Feedback Bot')
        ..recipients.add(username)
        ..subject = 'New Feedback Received ⭐'
        ..text = '''
Name: ${nameController.text}
Email: ${emailController.text}
Rating: $_selectedStars
Feedback: ${feedbackController.text}
Time: ${DateTime.now()}
        ''';

      // Send email with timeout
      final sendFuture = send(message, smtpServer);
      final result = await sendFuture.timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Email sending timed out');
        },
      );

      return result != null;
    } catch (e) {
      print('Email error: $e');
      return false;
    }
  }

  // Success Dialog - Faster animation
  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 60,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Thank You!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A0A5B),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Your feedback has been submitted successfully.",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1A0A5B),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Done",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Optimized submit function
  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Start timer for minimum loading display
    _loadingTimer = Timer(Duration(milliseconds: 800), () {});

    try {
      // Send email in background
      final emailSent = await _sendEmailFast();

      // Wait for minimum loading time
      await _loadingTimer?.timeout(Duration(seconds: 1), onTimeout: () {});

      if (emailSent) {
        await _showSuccessDialog();
      } else {
        _showError("Failed to send feedback. Please try again.");
      }
    } on TimeoutException {
      _showError("Request timed out. Please check your connection.");
    } catch (e) {
      _showError("An error occurred: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
      _loadingTimer?.cancel();
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedStars = _selectedStars == starNumber ? 0 : starNumber;
          }),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            margin: EdgeInsets.all(4),
            child: Icon(
              Icons.star,
              size: 36,
              color: starNumber <= _selectedStars
                  ? Color(0xFF1A0A5B)
                  : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: _isSubmitting ? 220 : null,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF1A0A5B),
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 3,
          shadowColor: Color(0xFF1A0A5B).withOpacity(0.3),
        ),
        child: _isSubmitting
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text(
              "Sending...",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.send_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text(
              "Submit Feedback",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    feedbackController.dispose();
    _loadingTimer?.cancel();
    _emailCompleter.complete(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Send Feedback",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A0A5B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A0A5B)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF1A0A5B).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.feedback_rounded,
                          size: 40,
                          color: Color(0xFF1A0A5B),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Share Your Thoughts",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A0A5B),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Help us improve your experience",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),

                // Name Field
                Text(
                  "Your Name",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A0A5B),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: nameController,
                  style: TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: "Enter your name",
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF1A0A5B), width: 1.5),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? "Please enter your name" : null,
                ),
                SizedBox(height: 20),

                // Email Field
                Text(
                  "Email Address",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A0A5B),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: emailController,
                  style: TextStyle(fontSize: 15),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Enter your email",
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF1A0A5B), width: 1.5),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? "Please enter your email" : null,
                ),
                SizedBox(height: 20),

                // Feedback Field
                Text(
                  "Your Feedback",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A0A5B),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: feedbackController,
                  style: TextStyle(fontSize: 15),
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Tell us what you think...",
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF1A0A5B), width: 1.5),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? "Please share your feedback" : null,
                ),
                SizedBox(height: 25),

                // Star Rating
                Column(
                  children: [
                    Text(
                      "Rate Your Experience",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A0A5B),
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildStarRating(),
                    SizedBox(height: 8),
                    Text(
                      _selectedStars == 0
                          ? "Tap stars to rate"
                          : "You rated: $_selectedStars/5",
                      style: TextStyle(
                        fontSize: 13,
                        color: _selectedStars > 0
                            ? Color(0xFF1A0A5B)
                            : Colors.grey,
                        fontStyle:
                        _selectedStars == 0 ? FontStyle.italic : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),

                // Submit Button
                Center(child: _buildSubmitButton()),

                // Loading Indicator
                if (_isSubmitting) SizedBox(height: 20),
                if (_isSubmitting)
                  Center(
                    child: Column(
                      children: [
                        SizedBox(height: 10),
                        Text(
                          "Sending your feedback...",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Info Note
                SizedBox(height: 30),
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A0A5B).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF1A0A5B).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF1A0A5B),
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Your feedback is valuable to us. We'll review it and work on improvements.",
                          style: TextStyle(
                            color: Color(0xFF1A0A5B).withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on Timer? {
  Future<void> timeout(Duration duration, {required Null Function() onTimeout}) async {}
}