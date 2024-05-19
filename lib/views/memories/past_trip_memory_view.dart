import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:listenable_collections/listenable_collections.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/trip.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:mytraveljournal/services/firebase_storage/firebase_storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:watch_it/watch_it.dart';

class PastTripMemoryView extends StatelessWidget with WatchItMixin {
  PastTripMemoryView({super.key, required this.trip});
  final Trip trip;
  late final GoogleMapController mapController;
  final ItemScrollController photoVideoController = ItemScrollController();
  final User user = getIt<User>();
  final FirebaseStorageService firebaseStorageService =
      getIt<FirebaseStorageService>();

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Icon sentimentIcon(String sentimentScore) {
    Icon icon;
    switch (sentimentScore) {
      case 'dissatisfied':
        icon = const Icon(
          Icons.sentiment_dissatisfied_outlined,
          size: 33,
          color: Color(0xff454579),
        );
        break;
      case 'neutral':
        icon = const Icon(
          Icons.sentiment_neutral_outlined,
          size: 33,
          color: Color(0xff454579),
        );
        break;
      case 'satisfied':
        icon = const Icon(
          Icons.sentiment_satisfied_alt_outlined,
          size: 33,
          color: Color(0xff454579),
        );
        break;
      case 'very_satisfied':
        icon = const Icon(
          Icons.sentiment_very_satisfied_outlined,
          size: 33,
          color: Color(0xff454579),
        );
        break;
      default:
        icon = const Icon(Icons.sentiment_dissatisfied_outlined);
    }
    return icon;
  }

  Icon weatherIcon(String weatherIcon) {
    Icon icon;
    switch (weatherIcon) {
      case 'snowy':
        icon = const Icon(
          Icons.ac_unit_outlined,
          size: 33,
          color: Color(0xff454579),
        );
        break;
      case 'rainy':
        icon = const Icon(
          Icons.water_drop_outlined,
          size: 33,
          color: Color(0xff454579),
        );
        break;
      case 'cloudy':
        icon = const Icon(
          Icons.wb_cloudy_outlined,
          size: 33,
          color: Color(0xff454579),
        );
        break;
      case 'sunny':
        icon = const Icon(
          Icons.wb_sunny_outlined,
          size: 33,
          color: Color(0xff454579),
        );
        break;
      default:
        icon = const Icon(Icons.ac_unit_outlined);
    }
    return icon;
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> markers = [];
    final LatLng initialCameraPosition = LatLng(
        trip.days.first.checkpoints.first.coordinates.latitude,
        trip.days.first.checkpoints.first.coordinates.longitude);
    callOnce(
      (context) {
        for (var day in trip.days) {
          markers.addAll(day.checkpoints.map((checkpoint) {
            return checkpoint.marker;
          }).toList());
        }
      },
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          trip.title,
          style: const TextStyle(
              color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
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
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 10, right: 10),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(
                        Icons.calendar_month,
                        color: Color(0xff454579),
                      ),
                    ),
                    Text(
                      "${DateFormat('dd/MM/yyyy').format(trip.startDate)} - ${DateFormat('dd/MM/yyyy').format(trip.endDate)}",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(15),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  trip.description,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xff454579),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(right: 20, bottom: 5),
                          child: Text(
                            'Total distance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff454579),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                              top: 10, bottom: 10, left: 60, right: 20),
                          alignment: Alignment.centerLeft,
                          decoration: const BoxDecoration(
                            color: Color(0xff7766CB),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          // TODO total kilometers
                          child: const Text(
                            '2500 km',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(right: 15, bottom: 5),
                          child: Text(
                            'Total cost',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff454579),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                              top: 10, bottom: 10, left: 20, right: 60),
                          alignment: Alignment.centerRight,
                          decoration: const BoxDecoration(
                            color: Color(0xff454579),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                          ),
                          // TODO total expenses
                          child: const Text(
                            '3000 eur',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8.0),
                width: double.infinity,
                height: 250,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: GoogleMap(
                  myLocationButtonEnabled: false,
                  compassEnabled: false,
                  mapType: MapType.hybrid,
                  onMapCreated: (GoogleMapController controller) {
                    _onMapCreated(controller);
                  },
                  initialCameraPosition: CameraPosition(
                    target: initialCameraPosition,
                    zoom: 7.4746,
                  ),
                  myLocationEnabled: true,
                  markers: Set<Marker>.of(markers),
                ),
              ),
              Flexible(
                flex: 1,
                child: ListView.builder(
                  itemCount: trip.days.length,
                  itemBuilder: (context, dayIndex) {
                    return Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Day ${trip.days[dayIndex].dayNumber}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff454579),
                                  ),
                                ),
                                Row(
                                  children: [
                                    trip.days[dayIndex].sentimentScore != ""
                                        ? Container(
                                            margin: const EdgeInsets.only(
                                                right: 8.0),
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xffF4D874),
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                            ),
                                            child: sentimentIcon(trip
                                                .days[dayIndex].sentimentScore),
                                          )
                                        : Container(),
                                    trip.days[dayIndex].weatherScore != ""
                                        ? Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xffF4D874),
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                            ),
                                            child: weatherIcon(trip
                                                .days[dayIndex].weatherScore),
                                          )
                                        : Container(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(15),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0x807D77FF),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Text(
                              trip.days[dayIndex].otherDayNotes,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xff454579),
                              ),
                            ),
                          ),
                          Column(
                            children: List.generate(
                              trip.days[dayIndex].checkpoints.length,
                              ((checkpointIndex) {
                                var photosVideosList = ListNotifier();

                                getApplicationDocumentsDirectory()
                                    .then((appDocDir) => {
                                          for (var mediaFilename in trip
                                              .days[dayIndex]
                                              .checkpoints[checkpointIndex]
                                              .mediaFilesNames)
                                            {
                                              firebaseStorageService
                                                  .downloadFile(
                                                      "${user.uid}/${trip.tripId}/memories",
                                                      mediaFilename)
                                                  .then((_) => {
                                                        photosVideosList.add(File(
                                                            "${appDocDir.path}/${user.uid}/${trip.tripId}/memories/$mediaFilename"))
                                                      })
                                            }
                                        });
                                return Column(
                                  children: [
                                    TimelineTile(
                                      alignment: TimelineAlign.manual,
                                      lineXY: 0.075,
                                      isFirst:
                                          checkpointIndex == 0 ? true : false,
                                      indicatorStyle: IndicatorStyle(
                                        height: 30,
                                        width: 30,
                                        color: const Color(0xff454579),
                                        iconStyle: trip.days[dayIndex]
                                                    .favoriteCheckpoint ==
                                                trip
                                                    .days[dayIndex]
                                                    .checkpoints[
                                                        checkpointIndex]
                                                    .checkpointId!
                                            ? IconStyle(
                                                color: const Color(0xffF4D874),
                                                iconData: Icons.star,
                                              )
                                            : null,
                                      ),
                                      afterLineStyle: const LineStyle(
                                          color: Color(0xff454579)),
                                      beforeLineStyle: const LineStyle(
                                          color: Color(0xff454579)),
                                      endChild: Container(
                                        constraints: const BoxConstraints(
                                          minHeight: 25,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                "Checkpoint ${trip.days[dayIndex].checkpoints[checkpointIndex].chekpointNumber}",
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xff454579),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      startChild: Container(),
                                    ),
                                    TimelineTile(
                                      alignment: TimelineAlign.manual,
                                      lineXY: 0.075,
                                      hasIndicator: false,
                                      indicatorStyle: const IndicatorStyle(
                                          color: Color(0xff454579)),
                                      afterLineStyle: const LineStyle(
                                          color: Color(0xff454579)),
                                      beforeLineStyle: const LineStyle(
                                          color: Color(0xff454579)),
                                      endChild: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          trip
                                                      .days[dayIndex]
                                                      .checkpoints[
                                                          checkpointIndex]
                                                      .title !=
                                                  null
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 8.0,
                                                          right: 8.0,
                                                          bottom: 8.0),
                                                  child: Text(
                                                    trip
                                                        .days[dayIndex]
                                                        .checkpoints[
                                                            checkpointIndex]
                                                        .title!,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      color: Color(0xff454579),
                                                    ),
                                                  ),
                                                )
                                              : Container(),
                                          Container(
                                            width: 150,
                                            padding: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(
                                              color: Color(0xffF4D874),
                                              borderRadius: BorderRadius.only(
                                                  topRight: Radius.circular(40),
                                                  bottomRight:
                                                      Radius.circular(40)),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: List.generate(
                                                5,
                                                (starCountIndex) {
                                                  if ((trip
                                                                  .days[
                                                                      dayIndex]
                                                                  .checkpoints[
                                                                      checkpointIndex]
                                                                  .rating ==
                                                              null
                                                          ? 1
                                                          : trip
                                                              .days[dayIndex]
                                                              .checkpoints[
                                                                  checkpointIndex]
                                                              .rating!) >
                                                      starCountIndex) {
                                                    return const Icon(
                                                      Icons.star,
                                                      size: 26,
                                                      color: Color(0xff454579),
                                                    );
                                                  } else {
                                                    return const Icon(
                                                      Icons
                                                          .star_border_outlined,
                                                      size: 26,
                                                      color: Color(0xff454579),
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                          trip
                                                      .days[dayIndex]
                                                      .checkpoints[
                                                          checkpointIndex]
                                                      .memoryNotes ==
                                                  null
                                              ? Container()
                                              : Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(trip
                                                      .days[dayIndex]
                                                      .checkpoints[
                                                          checkpointIndex]
                                                      .memoryNotes!),
                                                ),
                                          trip
                                                  .days[dayIndex]
                                                  .checkpoints[checkpointIndex]
                                                  .mediaFilesNames
                                                  .isNotEmpty
                                              ? Container(
                                                  height: trip
                                                              .days[dayIndex]
                                                              .checkpoints[
                                                                  checkpointIndex]
                                                              .mediaFilesNames
                                                              .length <=
                                                          3
                                                      ? 120
                                                      : (120 *
                                                              ((trip.days[dayIndex].checkpoints[checkpointIndex].mediaFilesNames
                                                                              .length /
                                                                          3)
                                                                      .truncate() +
                                                                  1))
                                                          .toDouble(),
                                                  margin: const EdgeInsets.only(
                                                      top: 31.0,
                                                      bottom: 8.0,
                                                      left: 8.0,
                                                      right: 8.0),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    color: Colors.white54,
                                                  ),
                                                  child: ValueListenableBuilder(
                                                    valueListenable:
                                                        photosVideosList,
                                                    builder: (context, value,
                                                            child) =>
                                                        GridView.count(
                                                      physics:
                                                          const NeverScrollableScrollPhysics(),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              9),
                                                      mainAxisSpacing: 8,
                                                      crossAxisSpacing: 8,
                                                      crossAxisCount: 3,
                                                      children: List.generate(
                                                        photosVideosList.length,
                                                        (index) {
                                                          return GestureDetector(
                                                            onTap: () async {
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  bool
                                                                      showBannerOptions =
                                                                      true;
                                                                  return StatefulBuilder(
                                                                    builder:
                                                                        (context,
                                                                            setState) {
                                                                      return Dialog
                                                                          .fullscreen(
                                                                        child: ScrollablePositionedList
                                                                            .builder(
                                                                          initialScrollIndex:
                                                                              index,
                                                                          scrollDirection:
                                                                              Axis.horizontal,
                                                                          itemScrollController:
                                                                              photoVideoController,
                                                                          itemCount:
                                                                              photosVideosList.length,
                                                                          itemBuilder:
                                                                              (context, index) {
                                                                            return GestureDetector(
                                                                              onHorizontalDragEnd: (dragDetail) {
                                                                                if (dragDetail.velocity.pixelsPerSecond.dx < 1) {
                                                                                  photoVideoController.jumpTo(index: index + 1);
                                                                                } else {
                                                                                  if (index - 1 >= 0) {
                                                                                    photoVideoController.jumpTo(index: index - 1);
                                                                                  }
                                                                                }
                                                                              },
                                                                              child: Stack(
                                                                                children: [
                                                                                  GestureDetector(
                                                                                    onTap: () {
                                                                                      showBannerOptions = !showBannerOptions;
                                                                                      setState(() {});
                                                                                    },
                                                                                    child: SizedBox(
                                                                                      height: MediaQuery.of(context).size.height,
                                                                                      width: MediaQuery.of(context).size.width,
                                                                                      child: Image.file(
                                                                                        photosVideosList[index],
                                                                                        fit: BoxFit.contain,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      );
                                                                    },
                                                                  );
                                                                },
                                                              );
                                                            },
                                                            child: Image.file(
                                                              photosVideosList[
                                                                  index],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : Container(),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
