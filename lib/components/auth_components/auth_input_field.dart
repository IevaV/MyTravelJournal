import 'package:flutter/material.dart';
import '../../constants/color_constants.dart';

@immutable
class AuthInputField extends StatelessWidget {
  const AuthInputField(
      {super.key,
      required this.textController,
      required this.hintText,
      required this.obscureText,
      required this.labelText});
  final TextEditingController textController;
  final String hintText;
  final bool obscureText;
  final String labelText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 10),
      child: PhysicalModel(
        borderRadius: BorderRadius.circular(50),
        color: Colors.white70,
        elevation: 5.0,
        shadowColor: ColorConstants.assetColorBlack,
        child: TextField(
          controller: textController,
          obscureText: obscureText,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.only(
                left: 25.0, right: 25.0, top: 15.0, bottom: 15.0),
            hintStyle: const TextStyle(
              color: Color.fromRGBO(119, 102, 203, 0.8),
            ),
            hintText: hintText,
            labelText: labelText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
          ),
        ),
      ),
    );
  }
}
