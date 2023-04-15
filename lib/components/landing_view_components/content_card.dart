import 'package:flutter/material.dart';
import 'package:mytraveljournal/constants/color_constants.dart';

class ContentCard extends StatefulWidget {
  const ContentCard({super.key});

  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard> {
  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 15,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusDirectional.circular(20),
          ),
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            splashColor: ColorConstants.primaryTurquoise,
            onTap: () {
              debugPrint('Card tapped.');
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: ColorConstants.primaryTurquoise,
                  width: 5,
                ),
                borderRadius: const BorderRadius.all(
                  Radius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
