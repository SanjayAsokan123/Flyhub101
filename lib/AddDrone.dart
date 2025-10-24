import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flyhub/CommonClass/utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'CommonClass/ApiClass.dart';
import 'HomeScreen/Dynamichome.dart';

class Adddrone extends StatefulWidget {
  final String clickUrl;
  final String type;

  const Adddrone({super.key, required this.clickUrl, required this.type});

  @override
  State<Adddrone> createState() => _AdddroneState();
}

class _AdddroneState extends State<Adddrone> {
  final ApiClass _apiClass = ApiClass();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  String dgcaApproval = '';
  List<dynamic> dronePurposeList = [];
  String selectedPurposeName = '';
  int? selectedPurposeId;

  final picker = ImagePicker();
  final Map<String, File?> images = {
    'top': null,
    'right': null,
    'left': null,
    'full': null,
  };

  String selectedUnit = 'Kgs';
  final List<String> units = ['Kgs', 'Grams'];

  final TextEditingController uinController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController batteryController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController fHoursController = TextEditingController();
  final TextEditingController fMinsController = TextEditingController();
  final TextEditingController cHoursController = TextEditingController();
  final TextEditingController cMinsController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDronePurposes();
  }

  Future<void> _fetchDronePurposes() async {
    setState(() => isLoading = true);

    final result = await _apiClass.getPurpose();

    if (result.status == "success" && result.data != null) {
      dronePurposeList = result.data!;
    } else {
      Utils.bottomToast(context, result.message ?? "Failed to fetch purposes");
    }

    setState(() => isLoading = false);
  }

  Future<void> _submitDrone() async {
    if (!_validateInputs()) return;

    setState(() => isLoading = true);

    try {
      final Map<String, File?> fileImages = {
        for (var key in images.keys)
          key: images[key] != null ? File(images[key]!.path) : null,
      };

      final result = await _apiClass.addDrone(
        dgcaApproval,
        selectedPurposeId.toString(),
        priceController.text,
        batteryController.text,
        weightController.text,
        modelController.text,
        fHoursController.text,
        fMinsController.text,
        cHoursController.text,
        cMinsController.text,
        descriptionController.text,
        widget.type,
        fileImages,
      );

      if (result.status == "success") {
        Utils.bottomToast(context, "Drone added successfully!");
        _navigateAfterSuccess();
      } else {
        Utils.bottomToast(context, result.message ?? "Something went wrong!");
      }
    } catch (e) {
      Utils.bottomToast(context, "Error: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  bool _validateInputs() {
    if (dgcaApproval.isEmpty ||
        selectedPurposeId == null ||
        uinController.text.isEmpty ||
        priceController.text.isEmpty ||
        batteryController.text.isEmpty ||
        weightController.text.isEmpty ||
        modelController.text.isEmpty ||
        images['top'] == null) {
      Utils.bottomToast(context, "Please fill all required fields.");
      return false;
    }
    return true;
  }

  void _navigateAfterSuccess() {
    final targetIndex = widget.type == "1" ? 1 : 3;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => Dynamichome(selectedIndex: targetIndex),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Add My Drone',
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: isLoading ? null : _submitDrone,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff7057FF),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
            "Continue",
            style: GoogleFonts.lexend(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildFormContent(),
    );
  }

  Widget _buildFormContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDGCASection(),
          const SizedBox(height: 10),
          _buildTextField("Drone UIN Number *", uinController,
              hint: "eg. ABCDEFGH1234IJKLMNOP", maxLength: 20),
          const SizedBox(height: 15),
          _buildPurposeSelector(),
          const SizedBox(height: 15),
          _buildTextField("Price *", priceController,
              hint: "eg. 900000 ₹", suffix: "₹"),
          const SizedBox(height: 15),
          _buildTextField("Battery Capacity *", batteryController,
              hint: "eg. 22000 mAh", suffix: "mAh"),
          const SizedBox(height: 15),
          _buildWeightInput(),
          const SizedBox(height: 15),
          _buildTextField("Drone Model Name *", modelController,
              hint: "eg. DJI Mini 4 Pro"),
          const SizedBox(height: 20),
          _buildTimeInput("Flying Time *", fHoursController, fMinsController),
          const SizedBox(height: 20),
          _buildTimeInput("Charging Time *", cHoursController, cMinsController),
          const SizedBox(height: 20),
          _buildTextField("Description", descriptionController,
              hint: "Write about your drone...", maxLines: 4, maxLength: 250),
          const SizedBox(height: 15),
          _buildImageSection(),
        ],
      ),
    );
  }

  Widget _buildDGCASection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Do you have DGCA Approval *",
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Radio<String>(
              value: '1',
              groupValue: dgcaApproval,
              onChanged: (String? val) {
                setState(() => dgcaApproval = val ?? '');
              },
            ),
            const Text("Yes"),
            Radio<String>(
              value: '0',
              groupValue: dgcaApproval,
              onChanged: (String? val) {
                setState(() => dgcaApproval = val ?? '');
              },
            ),
            const Text("No"),
          ],
        ),
      ],
    );
  }

  Widget _buildPurposeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Drone Purpose *",
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        ...dronePurposeList.map((item) {
          final int id = int.tryParse(item['id'].toString()) ?? 0;
          final String name = item['cname'] ?? '';

          return Row(
            children: [
              Radio<int>(
                value: id,
                groupValue: selectedPurposeId,
                onChanged: (int? val) {
                  setState(() {
                    selectedPurposeId = val;
                    selectedPurposeName = name;
                  });
                },
              ),
              Text(
                name,
                style: GoogleFonts.lexend(
                  fontWeight: selectedPurposeId == id
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {String? hint, String? suffix, int maxLines = 1, int? maxLength}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType:
      label.contains("Price") || label.contains("Battery") || label.contains("Weight")
          ? TextInputType.number
          : TextInputType.text,
      inputFormatters: label.contains("Price") || label.contains("Battery")
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        labelStyle: GoogleFonts.lexend(color: Colors.black),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        counterText: "",
      ),
    );
  }

  Widget _buildWeightInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFBBBBBB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Drone Weight *',
                border: InputBorder.none,
              ),
            ),
          ),
          DropdownButton<String>(
            value: selectedUnit,
            underline: const SizedBox(),
            items: units.map((unit) {
              return DropdownMenuItem(value: unit, child: Text(unit));
            }).toList(),
            onChanged: (value) => setState(() => selectedUnit = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInput(String title, TextEditingController hourCtrl,
      TextEditingController minCtrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 50,
              child: TextField(
                controller: hourCtrl,
                keyboardType: TextInputType.number,
                maxLength: 2,
                decoration: const InputDecoration(
                  hintText: "00",
                  counterText: "",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text("hrs"),
            const SizedBox(width: 20),
            SizedBox(
              width: 50,
              child: TextField(
                controller: minCtrl,
                keyboardType: TextInputType.number,
                maxLength: 2,
                decoration: const InputDecoration(
                  hintText: "00",
                  counterText: "",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text("mins"),
          ],
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Add Drone Photo *",
            style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
        Text("Upload Drone Photos from all sides",
            style: GoogleFonts.lexend(fontSize: 12)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildImageBox('top', 'Full Image'),
            _buildImageBox('right', 'Top Angle'),
            _buildImageBox('left', 'Right Angle'),
            _buildImageBox('full', 'Left Angle'),
          ],
        ),
      ],
    );
  }

  Widget _buildImageBox(String key, String label) {
    return InkWell(
      onTap: () => _selectImageSource(key),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: images[key] != null
            ? Image.file(images[key]!, fit: BoxFit.cover)
            : Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_upload_outlined,
                  size: 34, color: Color(0xffBBBBBB)),
              const SizedBox(height: 8),
              Text(label,
                  style: GoogleFonts.lexend(
                      fontSize: 13, color: Color(0xffBBBBBB))),
            ],
          ),
        ),
      ),
    );
  }

  void _selectImageSource(String key) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildIconOption(Icons.camera_alt, "Camera", () {
                Navigator.pop(context);
                _pickImage(key, ImageSource.camera);
              }),
              _buildIconOption(Icons.photo_library, "Gallery", () {
                Navigator.pop(context);
                _pickImage(key, ImageSource.gallery);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(icon, size: 45),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _pickImage(String key, ImageSource source) async {
    final XFile? pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    File? cropped = await _cropImage(pickedFile.path);
    if (cropped != null) {
      File? compressed = await _compressImage(cropped);
      if (compressed != null) {
        setState(() => images[key] = compressed);
      }
    }
  }

  Future<File?> _cropImage(String path) async {
    CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: path,
      maxWidth: 1080,
      maxHeight: 1080,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.deepPurple,
          toolbarWidgetColor: Colors.white,
        ),
        IOSUiSettings(title: 'Crop Image'),
      ],
    );
    return cropped != null ? File(cropped.path) : null;
  }

  Future<File?> _compressImage(File file) async {
    final outPath = '${file.path}_compressed.jpg';
    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      outPath,
      quality: 60,
    );
    return result != null ? File(result.path) : null;
  }
}
