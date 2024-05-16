import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mytraveljournal/components/dialog_components/add_checkpoint_memories_dialog.dart';
import 'package:mytraveljournal/components/dialog_components/show_error_dialog.dart';
import 'package:mytraveljournal/models/checkpoint.dart';
import 'package:mytraveljournal/models/trip_day.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:mytraveljournal/services/firebase_storage/firebase_storage_service.dart';
import 'package:mytraveljournal/services/firestore/trip/trip_service.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

Future<void> addDayMemories(
  BuildContext context,
  TripDay day,
  String tripId,
  String daySentimentScore,
  String weatherScore,
  String favoriteCheckpoint,
  TextEditingController otherDayNotes,
  TextEditingController memoryNotes,
  User user,
  TripService tripService,
  FirebaseStorageService firebaseStorageService,
  int checkpointRating,
  ItemScrollController photoVideoController,
) async {
  int currentStepIndex = 0;
  daySentimentScore =
      day.sentimentScore == "" ? "dissatisfied" : day.sentimentScore;
  weatherScore = day.weatherScore == "" ? "snowy" : day.weatherScore;
  favoriteCheckpoint = day.favoriteCheckpoint;
  otherDayNotes.text = day.otherDayNotes;
  showDialog(
    context: context,
    builder: ((context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog.fullscreen(
            child: Scaffold(
              body: Stepper(
                controlsBuilder: (context, details) {
                  if (details.currentStep == 0) {
                    return Row(
                      children: <Widget>[
                        TextButton(
                          onPressed: () {
                            details.onStepCancel!();
                          },
                          child: const Text('Exit'),
                        ),
                        TextButton(
                          onPressed: () {
                            details.onStepContinue!();
                          },
                          child: const Text('Next'),
                        ),
                      ],
                    );
                  } else if (details.currentStep == 4) {
                    return Row(
                      children: <Widget>[
                        TextButton(
                          onPressed: () {
                            details.onStepCancel!();
                          },
                          child: const Text('Back'),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              await tripService.updateTripDay(
                                user.uid,
                                tripId,
                                day.dayId,
                                {
                                  "daySentimentScore": daySentimentScore,
                                  "weatherScore": weatherScore,
                                  "favoriteCheckpoint": favoriteCheckpoint,
                                  "otherDayNotes": otherDayNotes.text,
                                  "dayFinished": true
                                },
                              );
                              day.sentimentScore = daySentimentScore;
                              day.weatherScore = weatherScore;
                              day.favoriteCheckpoint = favoriteCheckpoint;
                              day.otherDayNotes = otherDayNotes.text;
                              day.dayFinished = true;
                              if (context.mounted) {
                                context.pop();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                await showErrorDialog(context,
                                    'Something went wrong, please try again later');
                              }
                            }
                          },
                          child: const Text('Finish'),
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      children: <Widget>[
                        TextButton(
                          onPressed: () {
                            details.onStepCancel!();
                          },
                          child: const Text('Back'),
                        ),
                        TextButton(
                          onPressed: () {
                            details.onStepContinue!();
                          },
                          child: const Text('Next'),
                        ),
                      ],
                    );
                  }
                },
                currentStep: currentStepIndex,
                onStepCancel: () {
                  if (currentStepIndex > 0) {
                    currentStepIndex -= 1;
                    setState(() {});
                  } else {
                    context.pop();
                  }
                },
                onStepContinue: () {
                  if (currentStepIndex <= 3) {
                    currentStepIndex += 1;
                    setState(() {});
                  }
                },
                onStepTapped: (index) {
                  currentStepIndex = index;
                  setState(() {});
                },
                steps: <Step>[
                  Step(
                    title: const Text('Today I felt'),
                    content: Container(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        color: Colors.pink.shade300,
                        height: 60,
                        width: double.infinity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: () {
                                daySentimentScore = "dissatisfied";
                                setState(() {});
                              },
                              icon: Icon(
                                Icons.sentiment_dissatisfied_outlined,
                                color: daySentimentScore == "dissatisfied"
                                    ? const Color.fromRGBO(255, 232, 173, 0.984)
                                    : Colors.white70,
                              ),
                            ),
                            IconButton(
                                onPressed: () {
                                  daySentimentScore = "neutral";
                                  setState(() {});
                                },
                                icon: Icon(
                                  Icons.sentiment_neutral_outlined,
                                  color: daySentimentScore == "neutral"
                                      ? const Color.fromRGBO(
                                          255, 232, 173, 0.984)
                                      : Colors.white70,
                                )),
                            IconButton(
                                onPressed: () {
                                  daySentimentScore = "satisfied";
                                  setState(() {});
                                },
                                icon: Icon(
                                  Icons.sentiment_satisfied_alt_outlined,
                                  color: daySentimentScore == "satisfied"
                                      ? const Color.fromRGBO(
                                          255, 232, 173, 0.984)
                                      : Colors.white70,
                                )),
                            IconButton(
                                onPressed: () {
                                  daySentimentScore = "very_satisfied";
                                  setState(() {});
                                },
                                icon: Icon(
                                  Icons.sentiment_very_satisfied_outlined,
                                  color: daySentimentScore == "very_satisfied"
                                      ? const Color.fromRGBO(
                                          255, 232, 173, 0.984)
                                      : Colors.white70,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Step(
                    title: const Text('Weather was'),
                    content: Container(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        color: Colors.blue.shade300,
                        height: 60,
                        width: double.infinity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: () {
                                weatherScore = "snowy";
                                setState(() {});
                              },
                              icon: Icon(
                                Icons.ac_unit_outlined,
                                color: weatherScore == "snowy"
                                    ? const Color.fromRGBO(255, 232, 173, 0.984)
                                    : Colors.white70,
                              ),
                            ),
                            IconButton(
                                onPressed: () {
                                  weatherScore = "rainy";
                                  setState(() {});
                                },
                                icon: Icon(
                                  Icons.water_drop_outlined,
                                  color: weatherScore == "rainy"
                                      ? const Color.fromRGBO(
                                          255, 232, 173, 0.984)
                                      : Colors.white70,
                                )),
                            IconButton(
                                onPressed: () {
                                  weatherScore = "cloudy";
                                  setState(() {});
                                },
                                icon: Icon(
                                  Icons.wb_cloudy_outlined,
                                  color: weatherScore == "cloudy"
                                      ? const Color.fromRGBO(
                                          255, 232, 173, 0.984)
                                      : Colors.white70,
                                )),
                            IconButton(
                                onPressed: () {
                                  weatherScore = "sunny";
                                  setState(() {});
                                },
                                icon: Icon(
                                  Icons.wb_sunny_outlined,
                                  color: weatherScore == "sunny"
                                      ? const Color.fromRGBO(
                                          255, 232, 173, 0.984)
                                      : Colors.white70,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Step(
                    title: const Text('My favorite checkpoint'),
                    content: DropdownMenu<Checkpoint>(
                      initialSelection: favoriteCheckpoint != ""
                          ? day.checkpoints.firstWhere((checkpoint) =>
                              checkpoint.checkpointId! == favoriteCheckpoint)
                          : day.checkpoints.first,
                      onSelected: (Checkpoint? checkpoint) {
                        favoriteCheckpoint = checkpoint!.checkpointId!;
                        setState(() {});
                      },
                      dropdownMenuEntries: day.checkpoints
                          .map(
                            (checkpoint) => DropdownMenuEntry(
                                value: checkpoint,
                                label:
                                    "Checkpoint ${checkpoint.chekpointNumber}"),
                          )
                          .toList(),
                    ),
                  ),
                  Step(
                    title: const Text('Overview checkpoint memories'),
                    content: SizedBox(
                      width: double.infinity,
                      height: 300,
                      child: Scrollbar(
                        child: ListView(
                          children: [
                            Table(
                              children: List.generate(
                                day.checkpoints.length,
                                (index) => TableRow(
                                  children: [
                                    Text(
                                        "Checkpoint ${day.checkpoints[index].chekpointNumber}"),
                                    TextButton(
                                      onPressed: () async {
                                        await addCheckpointMemories(
                                            context,
                                            day.checkpoints[index],
                                            checkpointRating,
                                            tripId,
                                            day.dayId,
                                            photoVideoController,
                                            memoryNotes,
                                            user,
                                            tripService,
                                            firebaseStorageService);
                                      },
                                      child: (day.checkpoints[index].rating !=
                                                  null ||
                                              day.checkpoints[index]
                                                      .memoryNotes !=
                                                  null ||
                                              day.checkpoints[index]
                                                  .mediaFilesNames.isNotEmpty)
                                          ? const Text("Review")
                                          : const Text("Add memories"),
                                    ),
                                    Checkbox(
                                      checkColor: Colors.white,
                                      value: day.checkpoints[index]
                                          .checkpointOverviewCompleted,
                                      onChanged: (bool? value) {
                                        tripService.updateCheckpoint(
                                            user.uid,
                                            tripId,
                                            day.dayId,
                                            day.checkpoints[index]
                                                .checkpointId!,
                                            {
                                              "checkpointOverviewCompleted": !day
                                                  .checkpoints[index]
                                                  .checkpointOverviewCompleted!
                                            });
                                        day.checkpoints[index]
                                                .checkpointOverviewCompleted =
                                            value!;
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Step(
                    title: const Text('Other memories'),
                    content: TextField(
                      controller: otherDayNotes,
                      maxLength: 1000,
                      maxLines: null,
                      decoration: const InputDecoration(
                          hintText: "Anything else you want to remember?"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }),
  );
}
