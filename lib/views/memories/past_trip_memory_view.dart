import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mytraveljournal/models/trip.dart';
import 'package:timelines/timelines.dart';

class PastTripMemoryView extends StatelessWidget {
  const PastTripMemoryView({super.key, required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(125, 119, 255, 0.984),
              Color.fromRGBO(255, 232, 173, 0.984),
            ],
          ),
        ),
        child: SafeArea(
          child: Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white70,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Timeline.tileBuilder(
                    builder: TimelineTileBuilder.fromStyle(
                      contentsAlign: ContentsAlign.basic,
                      contentsBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text('Checkpoint ${index + 1}'),
                      ),
                      itemCount: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
