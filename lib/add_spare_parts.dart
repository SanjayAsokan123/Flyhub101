import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class AddSparePartForm extends StatefulWidget {
  const AddSparePartForm({super.key});

  @override
  State<AddSparePartForm> createState() => _AddSparePartFormState();
}

class _AddSparePartFormState extends State<AddSparePartForm> {
  final _formKey = GlobalKey<FormState>();
  final Color themeColor = const Color(0xFF1A0A5B);

  final picker = ImagePicker();
  File? imageFile;
  bool _isSubmitting = false;

  String name = '';
  String brand = '';
  String description = '';
  double? price;

  final String graphqlUrl = "http://192.168.1.45:5001/graphql";

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
      mutation CreatePart(\$input: PartInput!) {
        createPart(input: \$input) {
          id
          name
          brand
          price
          description
          image
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
        },
      },
    );

    try {
      final result = await client.mutate(options);

      if (result.hasException) {
        final errorMsg = result.exception!.graphqlErrors.isNotEmpty
            ? result.exception!.graphqlErrors.first.message
            : "Network error";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $errorMsg"), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Spare part submitted successfully!"),
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
        title: Text("Add Spare Part", style: TextStyle(color: themeColor)),
        backgroundColor: Colors.white,
        foregroundColor: themeColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Image Picker
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
              SizedBox(height: 16),

              _buildTextField("Spare Part Name", icon: Icons.category, onSaved: (v) => name = v!),
              _buildTextField("Brand", icon: Icons.business, onSaved: (v) => brand = v!),
              _buildTextField("Price (₹)", icon: Icons.attach_money, keyboardType: TextInputType.number, onSaved: (v) => price = double.tryParse(v!)),
              _buildTextField("Description", icon: Icons.description, onSaved: (v) => description = v!, maxLines: 3),
              SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
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