import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// ===================== API RESPONSE MODEL ======================
class ApiResponse {
  final String status;
  final String message;
  final dynamic data;

  ApiResponse({
    required this.status,
    required this.message,
    this.data,
  });
}

// ===================== API CLASS ======================
class ApiClass {
  static const String graphQLUrl = 'http://192.168.1.169:5001/graphql';

  static final HttpLink httpLink = HttpLink(graphQLUrl);

  static final ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(store: InMemoryStore()),
    ),
  );

  Future<ApiResponse> bookDroneService(Map<String, dynamic> body) async {
    const String mutation = r'''
      mutation CreateContact($input: CreateContactInput!) {
        createContact(input: $input) {
          success
          message
          data {
            id
            name
            email
            location
            information
            phone
            date
            serviceId
            sellerId
            serviceBookingId
          }
        }
      }
    ''';

    final result = await client.value.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: body,
      ),
    );

    if (result.hasException) {
      return ApiResponse(
        status: "error",
        message: result.exception.toString(),
      );
    }

    return ApiResponse(
      status: result.data!["createContact"]["success"] ? "success" : "error",
      message: result.data!["createContact"]["message"],
      data: result.data!["createContact"]["data"],
    );
  }
}

// ========================= UI PAGE ==========================
class ServiceBookNowPage extends StatefulWidget {
  final Map<String, dynamic> service;

  const ServiceBookNowPage({super.key, required this.service});

  @override
  State<ServiceBookNowPage> createState() => _ServiceBookNowPageState();
}

class _ServiceBookNowPageState extends State<ServiceBookNowPage> {
  final ApiClass _apiClass = ApiClass();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController locationCtrl = TextEditingController();
  final TextEditingController noteCtrl = TextEditingController();
  DateTime? selectedDate;
  bool _isLoading = false;

  Future<void> chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDate == null) {
      showToast("Please choose a date");
      return;
    }

    setState(() => _isLoading = true);

    final body = {
      "input": {
        "name": nameCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "location": locationCtrl.text.trim(),
        "information": noteCtrl.text.trim(),
        "phone": "",
        "date": selectedDate.toString().split(" ")[0],
        "serviceId": widget.service['serviceId'], // ✅ inside input
        "sellerId": widget.service['sellerId'],   // ✅ inside input
        "serviceBookingId": DateTime.now().millisecondsSinceEpoch.toString(),
      }
    };

    log("📤 BODY SENT → $body");

    ApiResponse response = await _apiClass.bookDroneService(body);

    setState(() => _isLoading = false);

    if (response.status == "success") {
      showToast("Service booked successfully!");
      Navigator.pop(context);
    } else {
      showToast("Error: ${response.message}");
    }
  }

  void showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;

    return Scaffold(
      appBar: AppBar(
        title: Text(service["name"] ?? "Service"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Service Info
            Column(
              children: [
                safeNetworkImage(service["image"]),
                const SizedBox(height: 10),
                Text(
                  service["name"] ?? "",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  "Price: ₹ ${service["price"]}",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 25),
            const Text(
              "Fill Booking Details",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 15),

            // Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: inputDecoration("Full Name"),
                    validator: (v) => v!.isEmpty ? "Enter your name" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: inputDecoration("Email"),
                    validator: (v) => v!.isEmpty ? "Enter your email" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: locationCtrl,
                    decoration: inputDecoration("Location"),
                    validator: (v) => v!.isEmpty ? "Enter location" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: noteCtrl,
                    maxLines: 5,
                    decoration: inputDecoration("Tell us more about your requirement"),
                    validator: (v) => v!.length < 10 ? "Minimum 10 characters required" : null,
                  ),
                  const SizedBox(height: 15),

                  // Date Picker
                  InkWell(
                    onTap: chooseDate,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate == null ? "Choose Date" : selectedDate.toString().split(" ")[0],
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.calendar_month),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    width: 220,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : submitBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        "Book Service",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Safe Network Image
Widget safeNetworkImage(String? url) {
  if (url == null || url.isEmpty || !url.startsWith("http")) {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey.shade300,
      child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
    );
  }
  return Image.network(
    url,
    height: 200,
    width: double.infinity,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stack) => Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey.shade300,
      child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
    ),
  );
}

// Input Decoration
InputDecoration inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}