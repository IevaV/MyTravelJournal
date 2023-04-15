import 'package:flutter/material.dart';

import '../../constants/color_constants.dart';

class SectionBanner extends StatelessWidget {
  const SectionBanner({super.key, required this.bannerText});
  final String bannerText;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.expand(),
      color: ColorConstants.primaryRed,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            bannerText,
            style: const TextStyle(
              fontSize: 28,
              color: ColorConstants.assetColorWhite,
            ),
          ),
        ),
      ),
    );
  }
}
