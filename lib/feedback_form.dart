import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

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
  double rating = 0;

  // ✉ Function to send feedback mail
  Future<void> sendMail() async {
    const String username = 'preethis19102004@gmail.com'; // your email
    const String appPassword = 'jcqm eubr vcdx nlvl'; // 🔒 app password

    final smtpServer = gmail(username, appPassword);

    final message = Message()
      ..from = Address(username, 'Feedback Bot')
      ..recipients.add(username) // you will receive mail here
      ..subject = 'New Feedback Received ⭐'
      ..text = '''
New feedback received from your Flutter app:

👤 Name: ${nameController.text}
📧 Email: ${emailController.text}
⭐ Rating: $rating
💬 Feedback: ${feedbackController.text}

Time: ${DateTime.now()}
      ''';

    try {
      await send(message, smtpServer);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Feedback submitted successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Wait 2 seconds and go back
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠ Error sending feedback: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void submitFeedback() {
    if (_formKey.currentState!.validate()) {
      sendMail();
    }
  }

  Widget buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
            (index) => IconButton(
          onPressed: () {
            setState(() {
              if (rating == index + 1) {
                rating = 0;
              } else {
                rating = index + 1;
              }
            });
          },
          icon: Icon(
            Icons.star,
            color: index < rating
                ? const Color(0xFF1A0A5B)
                : Colors.grey.shade400,
            size: 30,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Feedback"),
        backgroundColor: const Color(0xFFFFFFFF),
        foregroundColor: const Color(0xFF1A0A5B),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "We’d love to hear from you!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A0A5B),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your feedback helps us improve our app experience.",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 25),

              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Your Name",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                value!.isEmpty ? "Please enter your name" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                value!.isEmpty ? "Please enter your email" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: feedbackController,
                decoration: InputDecoration(
                  labelText: "Your Feedback",
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 5,
                validator: (value) =>
                value!.isEmpty ? "Please share your feedback" : null,
              ),
              const SizedBox(height: 25),

              Center(
                child: Column(
                  children: [
                    const Text(
                      "Rate your experience",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    buildStarRating(),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Center(
                child: ElevatedButton(
                  onPressed: submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A0A5B),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Submit Feedback",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}