import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:listenable_collections/listenable_collections.dart';
import 'package:mytraveljournal/components/dialog_components/show_error_dialog.dart';
import 'package:mytraveljournal/components/dialog_components/show_on_delete_dialog.dart';
import 'package:mytraveljournal/models/checkpoint.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:mytraveljournal/services/firebase_storage/firebase_storage_service.dart';
import 'package:mytraveljournal/services/firestore/trip/trip_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

Future<void> addCheckpointMemories(
  BuildContext context,
  Checkpoint checkpoint,
  int checkpointRating,
  String tripId,
  String dayId,
  ItemScrollController photoVideoController,
  TextEditingController memoryNotes,
  User user,
  TripService tripService,
  FirebaseStorageService firebaseStorageService,
) async {
  checkpointRating = checkpoint.rating ?? 1;
  memoryNotes.text = checkpoint.memoryNotes ?? "";
  var photosVideosList = ListNotifier();
  final appDocDir = await getApplicationDocumentsDirectory();
  for (var mediaFilename in checkpoint.mediaFilesNames) {
    String pathToFile =
        "${appDocDir.path}/${user.uid}/$tripId/memories/$mediaFilename";
    // if (!(await File(pathToFile).exists())) {
    await firebaseStorageService.downloadFile(
        "${user.uid}/$tripId/memories", mediaFilename);
    // }
    photosVideosList.add(File(pathToFile));
  }
  showDialog(
    context: context,
    builder: ((context) {
      return StatefulBuilder(builder: (context, setState) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                'Checkpoint ${checkpoint.chekpointNumber}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xff454579).withAlpha(245),
              centerTitle: true,
              leading: BackButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  context.pop();
                },
                color: Colors.white,
              ),
            ),
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
              child: SingleChildScrollView(
                child: ListBody(
                  children: [
                    Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(
                              top: 15.0, left: 10.0, right: 10.0, bottom: 8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10.0,
                                offset: Offset(0.0, 3.0),
                              ),
                            ],
                            color: const Color.fromRGBO(69, 69, 121, 0.702),
                          ),
                          child: Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(
                                    left: 8.0, right: 8.0, top: 8.0),
                                child: Text(
                                  'Rate your experience',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    right: 8.0, left: 8.0, bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    5,
                                    (index) {
                                      if (checkpointRating >= index + 1) {
                                        return IconButton(
                                          onPressed: () {
                                            checkpointRating = index + 1;
                                            setState(() {});
                                          },
                                          icon: const Icon(
                                            Icons.star,
                                            size: 40,
                                            color: Color(0xffF4D874),
                                          ),
                                        );
                                      } else {
                                        return IconButton(
                                          onPressed: () {
                                            checkpointRating = index + 1;
                                            setState(() {});
                                          },
                                          icon: const Icon(
                                            Icons.star_border_outlined,
                                            size: 40,
                                            color: Color(0xffF4D874),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                              right: 80, top: 10, bottom: 8),
                          alignment: Alignment.centerLeft,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                            color: Colors.white54,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(15.0),
                            child: Text(
                              'Write down your memories!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff454579),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white54,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: TextField(
                                controller: memoryNotes,
                                maxLength: 1000,
                                maxLines: null,
                                decoration: const InputDecoration(
                                    hintText: "Write your experience here!"),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                            left: 80,
                            top: 10,
                          ),
                          alignment: Alignment.centerRight,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              bottomLeft: Radius.circular(30),
                            ),
                            color: Color(0xb3454579),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.only(
                                right: 60, left: 15, top: 15, bottom: 15),
                            child: Text(
                              'Add images and videos!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Stack(
                          children: [
                            Container(
                              height: 400,
                              margin: const EdgeInsets.only(
                                  top: 31.0,
                                  bottom: 8.0,
                                  left: 8.0,
                                  right: 8.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white54,
                              ),
                              child: ValueListenableBuilder(
                                valueListenable: photosVideosList,
                                builder: (context, value, child) =>
                                    GridView.count(
                                        padding: const EdgeInsets.all(9),
                                        mainAxisSpacing: 8,
                                        crossAxisSpacing: 8,
                                        crossAxisCount: 3,
                                        children: List.generate(
                                            photosVideosList.length, (index) {
                                          return GestureDetector(
                                            onTap: () async {
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  bool showBannerOptions = true;
                                                  return StatefulBuilder(
                                                      builder:
                                                          (context, setState) {
                                                    return Dialog.fullscreen(
                                                      child:
                                                          ScrollablePositionedList
                                                              .builder(
                                                        initialScrollIndex:
                                                            index,
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        itemScrollController:
                                                            photoVideoController,
                                                        itemCount:
                                                            photosVideosList
                                                                .length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          return GestureDetector(
                                                            onHorizontalDragEnd:
                                                                (dragDetail) {
                                                              if (dragDetail
                                                                      .velocity
                                                                      .pixelsPerSecond
                                                                      .dx <
                                                                  1) {
                                                                photoVideoController
                                                                    .jumpTo(
                                                                        index: index +
                                                                            1);
                                                              } else {
                                                                if (index - 1 >=
                                                                    0) {
                                                                  photoVideoController
                                                                      .jumpTo(
                                                                          index:
                                                                              index - 1);
                                                                }
                                                              }
                                                            },
                                                            child: Stack(
                                                              children: [
                                                                GestureDetector(
                                                                  onTap: () {
                                                                    showBannerOptions =
                                                                        !showBannerOptions;
                                                                    setState(
                                                                        () {});
                                                                  },
                                                                  child:
                                                                      SizedBox(
                                                                    height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .height,
                                                                    width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width,
                                                                    child: Image
                                                                        .file(
                                                                      photosVideosList[
                                                                          index],
                                                                      fit: BoxFit
                                                                          .contain,
                                                                    ),
                                                                  ),
                                                                ),
                                                                showBannerOptions ==
                                                                        true
                                                                    ? Container(
                                                                        width: MediaQuery.of(context)
                                                                            .size
                                                                            .width,
                                                                        color: Colors
                                                                            .white70,
                                                                        child:
                                                                            Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            IconButton(
                                                                              icon: const Icon(Icons.arrow_back),
                                                                              onPressed: () {
                                                                                Navigator.of(context).pop();
                                                                                setState(() {});
                                                                              },
                                                                            ),
                                                                            IconButton(
                                                                              icon: const Icon(Icons.delete),
                                                                              onPressed: () async {
                                                                                String fileNameToDelete = photosVideosList[index].path.split('/').last;
                                                                                bool? confirmDelete = await showDeleteDialog(context, '$fileNameToDelete?');
                                                                                if (confirmDelete == true) {
                                                                                  try {
                                                                                    await firebaseStorageService.deleteFile("${user.uid}/$tripId/memories", photosVideosList[index].path.split('/').last);
                                                                                    await tripService.updateCheckpoint(user.uid, tripId, dayId, checkpoint.checkpointId!, <String, dynamic>{
                                                                                      "rating": checkpointRating,
                                                                                      "memoryNotes": memoryNotes.text,
                                                                                      "mediaFilesNames": FieldValue.arrayRemove([
                                                                                        fileNameToDelete
                                                                                      ]),
                                                                                    });
                                                                                    checkpoint.mediaFilesNames.remove(fileNameToDelete);
                                                                                    photosVideosList.remove(photosVideosList[index]);
                                                                                    setState(() {});
                                                                                  } catch (e) {
                                                                                    await showErrorDialog(context, 'Something went wrong, please try again later');
                                                                                  }
                                                                                }
                                                                              },
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      )
                                                                    : const SizedBox(),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  });
                                                },
                                              );
                                            },
                                            child: Image.file(
                                              photosVideosList[index],
                                            ),
                                          );
                                        })),
                              ),
                            ),
                            Positioned(
                              top: -9,
                              child: Container(
                                margin: const EdgeInsets.all(9.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  color: Colors.white54,
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    FilePickerResult? pickedFiles =
                                        await FilePicker.platform
                                            .pickFiles(allowMultiple: true);
                                    if (pickedFiles != null) {
                                      photosVideosList.addAll(pickedFiles.paths
                                          .map((path) => File(path!))
                                          .toList());
                                      setState(() {});
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.add_circle_rounded,
                                    size: 50,
                                    color: Color.fromRGBO(69, 69, 121, 1),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          color: const Color(0xff454579).withAlpha(245),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        final mediaFileNames = photosVideosList
                                            .map((file) =>
                                                file.path.split('/').last)
                                            .toList();
                                        await Future.wait(photosVideosList.map(
                                            (file) => firebaseStorageService
                                                .uploadFile(
                                                    "${user.uid}/$tripId/memories",
                                                    file)));
                                        await tripService.updateCheckpoint(
                                            user.uid,
                                            tripId,
                                            dayId,
                                            checkpoint.checkpointId!,
                                            <String, dynamic>{
                                              "rating": checkpointRating,
                                              "memoryNotes": memoryNotes.text,
                                              "mediaFilesNames":
                                                  FieldValue.arrayUnion(
                                                mediaFileNames,
                                              ),
                                            });
                                        checkpoint.rating = checkpointRating;

                                        Navigator.of(context).pop();
                                      } catch (e) {
                                        if (context.mounted) {
                                          await showErrorDialog(context,
                                              'Something went wrong, please try again later');
                                        }
                                      }
                                    },
                                    child: const Text('Save'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      });
    }),
  );
}
