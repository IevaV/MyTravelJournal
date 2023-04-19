import 'package:flutter/material.dart';
import 'package:mytraveljournal/constants/routes.dart';

import '../constants/color_constants.dart';

class TripMemoryView extends StatelessWidget {
  const TripMemoryView({super.key, required this.callback()});
  final Function callback;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Flexible(
        flex: 4,
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Card(
            color: ColorConstants.primaryRed,
            elevation: 15,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusDirectional.circular(20),
            ),
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              splashColor: ColorConstants.primaryRed,
              onTap: () {
                // Navigator.of(context).pushNamed(addNewTripRoute);
                callback();
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: ColorConstants.orangeCardOutline,
                    width: 5,
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'PLAN NEW TRIP',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.assetColorWhite,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Flexible(
        flex: 4,
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Card(
            elevation: 15,
            color: ColorConstants.primaryRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusDirectional.circular(20),
            ),
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              splashColor: ColorConstants.primaryRed,
              onTap: () {
                debugPrint('Card tapped.');
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: ColorConstants.orangeCardOutline,
                    width: 5,
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'ADD MEMORY',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.assetColorWhite,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}
