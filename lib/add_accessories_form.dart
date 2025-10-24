import 'dart:io';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';

class AddAccessoryForm extends StatefulWidget {
  const AddAccessoryForm({super.key});

  @override
  _AddAccessoryFormState createState() => _AddAccessoryFormState();
}

class _AddAccessoryFormState extends State<AddAccessoryForm> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String brand = '';
  String description = '';
  double? price;
  int quantity = 1;
  File? imageFile;

  bool _isSubmitting = false;
  final picker = ImagePicker();
  // final String graphqlUrl = "http://192.168.1.45:5001/graphql";
  final String graphqlUrl = 'http://192.168.0.103:5001/graphql';
  final Color themeColor = const Color(0xFF1A0A5B);

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    final client = GraphQLClient(
      link: HttpLink(graphqlUrl),
      cache: GraphQLCache(store: InMemoryStore()),
    );

    final String imageUrl =
        "https://via.placeholder.com/300x200.png?text=${Uri.encodeComponent(name)}";

    final mutation = gql("""
      mutation CreateAccessory(\$input: AccessoryInput!) {
        createAccessory(input: \$input) {
          id
          name
          brand
          price
          description
          image
          quantity
          status
        }
      }
    """);

    final options = MutationOptions(
      document: mutation,
      variables: {
        'input': {
          'name': name,
          'brand': brand,
          'price': price,
          'description': description,
          'image': imageUrl,
          'quantity': quantity,
        },
      },
    );

    try {
      final result = await client.mutate(options);

      if (result.hasException) {
        final errorMsg = result.exception!.graphqlErrors.isNotEmpty
            ? result.exception!.graphqlErrors.first.message
            : "Network error or invalid mutation";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $errorMsg"), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Accessory submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unexpected Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Accessory", style: TextStyle(color: themeColor)),
        backgroundColor: Colors.white,
        foregroundColor: themeColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 📸 Image picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: imageFile == null
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 50, color: themeColor),
                        SizedBox(height: 8),
                        Text("Tap to upload image"),
                      ],
                    ),
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(imageFile!, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                "Accessory Name",
                icon: Icons.build,
                onSaved: (v) => name = v!,
              ),
              _buildTextField(
                "Brand",
                icon: Icons.business,
                onSaved: (v) => brand = v!,
              ),
              _buildTextField(
                "Price (₹)",
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                onSaved: (v) => price = double.tryParse(v!),
              ),

              // 🆕 Quantity Field
              _buildTextField(
                "Quantity",
                icon: Icons.add_shopping_cart,
                keyboardType: TextInputType.number,
                onSaved: (v) => quantity = int.tryParse(v!) ?? 1,
              ),

              _buildTextField(
                "Description",
                icon: Icons.description,
                onSaved: (v) => description = v!,
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Submit",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, {
        required IconData icon,
        FormFieldSetter<String>? onSaved,
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: themeColor),
          labelText: label,
          labelStyle: TextStyle(color: themeColor),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: themeColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: themeColor.withOpacity(0.5)),
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Please enter $label' : null,
        onSaved: onSaved,
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }
}