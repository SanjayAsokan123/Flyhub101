import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../RegisterPage.dart';
import '../../CommonClass/utils.dart';

class Template2 extends StatefulWidget {
  final String title;
  final String appBarTitle;
  final String formTitle;
  final String rightImg;
  final String leftImg;
  final List items;

  const Template2({
    super.key,
    required this.title,
    required this.appBarTitle,
    required this.formTitle,
    required this.rightImg,
    required this.leftImg,
    required this.items,
  });

  @override
  State<Template2> createState() => _Template2State();
}

class _Template2State extends State<Template2> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final leftImgUrl = Utils.safeString(widget.leftImg);
    final rightImgUrl = Utils.safeString(widget.rightImg);
    final title = Utils.safeString(widget.title);

    return Padding(
      padding: const EdgeInsets.only(left: 18.0, right: 18, bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact(); // ✅ better UX
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegisterPage(
                registerList: widget.items,
                appBarTitle: widget.appBarTitle,
                formTitle: widget.formTitle,
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF7057FF),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Utils.safeNetworkImage(
                leftImgUrl,
                width: 35,
                height: 35,
              ),
              SizedBox(
                width: width * 0.6,
                child: Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    textStyle:
                    const TextStyle(overflow: TextOverflow.ellipsis),
                  ),
                  maxLines: 2,
                ),
              ),
              Utils.safeNetworkImage(
                rightImgUrl,
                width: 25,
                height: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}