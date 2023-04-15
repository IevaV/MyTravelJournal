import 'package:flutter/material.dart';
import '../../constants/color_constants.dart';

@immutable
class AuthInputField extends StatelessWidget {
  const AuthInputField({super.key, required this.textController, required this.hintText, required this.obscureText});
  final TextEditingController textController;
  final String hintText;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 10),
      child: PhysicalModel(
        borderRadius: BorderRadius.circular(50),
        color: ColorConstants.primaryYellow,
        elevation: 5.0,
        shadowColor: ColorConstants.assetColorBlack,
        child: TextField(
          controller: textController,
          obscureText: obscureText,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            hintStyle: const TextStyle(
              color: ColorConstants.turquoisePlaceholderText,
            ),
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: ColorConstants.yellowPlaceholderBackground,
          ),
        ),
      ),
    );
  }
}
