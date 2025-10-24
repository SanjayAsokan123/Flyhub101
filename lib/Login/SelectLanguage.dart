import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flyhub/CommonClass/ApiClass.dart';
import 'package:flyhub/CommonClass/utils.dart';
import 'package:flyhub/Login/MobileLogin.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Selectlanguage extends StatefulWidget {
  const Selectlanguage({super.key});

  @override
  State<Selectlanguage> createState() => _SelectlanguageState();
}

class _SelectlanguageState extends State<Selectlanguage> {
  final ApiClass _apiClass = ApiClass();
  List<dynamic> languageList = [];
  bool isLoading = false;
  bool isInternet = true;
  int selectedIndex = -1;
  late SharedPreferences pref;

  @override
  void initState() {
    super.initState();
    _fetchLanguages();
  }

  Future<void> _fetchLanguages() async {
    setState(() => isLoading = true);
    final res = await _apiClass.getLanguage();
    setState(() => isLoading = false);

    if (res.status == "success" && res.data is List) {
      setState(() {
        languageList = res.data;
        isInternet = true;
      });
    } else {
      isInternet = false;
      Utils.bottomToast(context, res.message);
    }
  }

  Future<void> _onContinuePressed() async {
    if (selectedIndex < 0) {
      Utils.bottomToast(context, "Choose your language");
      return;
    }

    pref = await SharedPreferences.getInstance();
    pref.setInt("langId", languageList[selectedIndex]['id']);

    setState(() => isLoading = true);
    final res = await _apiClass.getLoginscreen();
    setState(() => isLoading = false);

    if (res.status == "success" && res.data.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Mobilelogin(logindata: res.data)),
      );
    } else {
      Utils.bottomToast(context, res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.07, vertical: h * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Choose Language",
                  style: GoogleFonts.lexend(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text("Select your preferred language",
                  style: GoogleFonts.lexend(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),

              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : !isInternet
                    ? Center(
                  child: ElevatedButton(
                    onPressed: _fetchLanguages,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7049EC)),
                    child: const Text("Retry"),
                  ),
                )
                    : GridView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: languageList.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.2,
                  ),
                  itemBuilder: (context, i) {
                    final lang = languageList[i];
                    final isSel = i == selectedIndex;

                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedIndex = i);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Utils.hexToColor(lang['bgcolor']),
                          borderRadius: BorderRadius.circular(12),
                          border: isSel
                              ? Border.all(color: Colors.green, width: 2)
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.network(lang['img'], width: 40, height: 40),
                                  const SizedBox(height: 8),
                                  Text(lang['name'],
                                      style: GoogleFonts.lexend(fontSize: 15)),
                                ],
                              ),
                            ),
                            if (isSel)
                              const Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.green,
                                  child: Icon(Icons.check,
                                      size: 12, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _onContinuePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7049EC),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("Continue",
                      style: GoogleFonts.lexend(
                          fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
