import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/checkpoint.dart';
import 'package:mytraveljournal/models/trip.dart';
import 'package:mytraveljournal/models/trip_day.dart';
import 'package:mytraveljournal/services/location/location_service.dart';
import 'package:mytraveljournal/utilities/date_time_apis.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:watch_it/watch_it.dart';

class OngoingTripView extends StatefulWidget with WatchItStatefulWidgetMixin {
  const OngoingTripView({super.key, required this.trip});
  final Trip trip;

  @override
  State<OngoingTripView> createState() => _OngoingTripViewState();
}

class _OngoingTripViewState extends State<OngoingTripView> {
  LocationService locationService = getIt<LocationService>();
  late GoogleMapController mapController;
  final ItemScrollController itemScrollController = ItemScrollController();
  late LocationData currentPosition;
  LatLng initialCameraPosition =
      const LatLng(37.42796133580664, -122.085749655962);
  late TripDay todaysTripDay;
  late TripDay selectedTripDay;
  late Checkpoint? nextCheckpoint;
  List<Marker> markers = [];
  List<Polyline> polylines = [];

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> animateGoogleMapsCamera(latitude, longitude) async {
    await mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 15,
        ),
      ),
    );
  }

  Future<void> currentLocation() async {
    await locationService.getServiceEnabled();
    await locationService.getPermissionStatus();

    currentPosition = await locationService.getCurrentLocation();
    await animateGoogleMapsCamera(
        currentPosition.latitude!, currentPosition.longitude!);
    await animateListView();
    // return LatLng(currentPosition.latitude!, currentPosition.longitude!);
  }

  Future<void> animateListView() async {
    // Scroll current tripDay into view only if there are more than 5 days in days list
    if (widget.trip.days.length > 5) {
      await itemScrollController.scrollTo(
          index: todaysTripDay.dayNumber - 1,
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOutCubic);
    }
  }

  @override
  void initState() {
    todaysTripDay = widget.trip.days
        .firstWhere((day) => day.date.isSameDate(DateTime.now()));
    selectedTripDay = todaysTripDay;
    nextCheckpoint = todaysTripDay.checkpoints
        .firstWhereOrNull((checkpoint) => checkpoint.isVisited == false);
    currentLocation();
    super.initState();
  }

  @override
  void dispose() async {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    markers = selectedTripDay.checkpoints.map((checkpoint) {
      return checkpoint.marker;
    }).toList();
    polylines = selectedTripDay.checkpoints.skip(1).map((checkpoint) {
      return checkpoint.polyline!;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.trip.title),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              flex: 1,
              child: Stack(
                children: [
                  LayoutBuilder(builder:
                      (BuildContext context, BoxConstraints constraints) {
                    return SizedBox(
                      height: constraints.maxHeight / 1.12,
                      child: GoogleMap(
                        mapType: MapType.hybrid,
                        onMapCreated: (GoogleMapController controller) {
                          _onMapCreated(controller);
                        },
                        initialCameraPosition: CameraPosition(
                          target: initialCameraPosition,
                          zoom: 14.4746,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        markers: Set<Marker>.of(markers),
                        polylines: Set<Polyline>.of(polylines),
                      ),
                    );
                  }),
                  SizedBox(
                    height: 80,
                    child: ScrollablePositionedList.builder(
                      scrollDirection: Axis.horizontal,
                      itemScrollController: itemScrollController,
                      itemCount: widget.trip.days.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selectedTripDay.dayId ==
                                      widget.trip.days[index].dayId
                                  ? Colors.deepPurple.withAlpha(200)
                                  : Colors.white70,
                              border: todaysTripDay.dayId ==
                                      widget.trip.days[index].dayId
                                  ? Border.all(
                                      color: Colors.purpleAccent, width: 2.0)
                                  : null,
                            ),
                            child: Center(
                              child: TextButton(
                                onPressed: () {
                                  selectedTripDay = widget.trip.days[index];
                                  setState(() {});
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Day",
                                      style: selectedTripDay.dayId ==
                                              widget.trip.days[index].dayId
                                          ? const TextStyle(
                                              color: Colors.white70)
                                          : null,
                                    ),
                                    Text(
                                        widget.trip.days[index].dayNumber
                                            .toString(),
                                        style: selectedTripDay.dayId ==
                                                widget.trip.days[index].dayId
                                            ? const TextStyle(
                                                color: Colors.white70)
                                            : null),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.lerp(
                          Alignment.centerRight, Alignment.bottomRight, 0.5)!,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FloatingActionButton(
                          onPressed: (() async {
                            await animateGoogleMapsCamera(
                                currentPosition.latitude,
                                currentPosition.longitude);
                          }),
                          child: const Icon(Icons.location_searching),
                        ),
                      ),
                    ),
                  ),
                  DraggableScrollableSheet(
                    snap: true,
                    maxChildSize: 0.5,
                    initialChildSize: 0.10,
                    minChildSize: 0.10,
                    builder: (BuildContext context,
                        ScrollController scrollController) {
                      return Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: Theme.of(context).canvasColor,
                        ),
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: selectedTripDay.checkpoints.length + 1,
                          separatorBuilder: (context, index) {
                            if (index > 0) {
                              return SizedBox(
                                height: 120,
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(
                                              right: 10.0, top: 10.0),
                                          height: 38,
                                          child: ElevatedButton.icon(
                                              label: Text(
                                                selectedTripDay
                                                            .checkpoints[
                                                                index - 1]
                                                            .departureTime ==
                                                        null
                                                    ? "Select departure time"
                                                    : "Leaving at ${(selectedTripDay.checkpoints[index - 1].departureTime!.hour).toString().padLeft(2, '0')}:${(selectedTripDay.checkpoints[index - 1].departureTime!.minute).toString().padLeft(2, '0')}",
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                              icon: const Icon(
                                                Icons.access_time,
                                                color: Colors.white,
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xff7D77FF),
                                              ),
                                              onPressed: () {}),
                                        )
                                      ],
                                    ),
                                    const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.arrow_downward,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin:
                                              const EdgeInsets.only(left: 10.0),
                                          height: 38,
                                          child: ElevatedButton.icon(
                                            label: Text(
                                              selectedTripDay.checkpoints[index]
                                                          .arrivalTime ==
                                                      null
                                                  ? "Provide departure time"
                                                  : "Arriving at ${(selectedTripDay.checkpoints[index].arrivalTime!.hour).toString().padLeft(2, '0')}:${(selectedTripDay.checkpoints[index].arrivalTime!.minute).toString().padLeft(2, '0')}",
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                            icon: const Icon(
                                              Icons.access_time,
                                              color: Colors.white,
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xff7D77FF),
                                            ),
                                            onPressed: selectedTripDay
                                                        .checkpoints[index]
                                                        .arrivalTime ==
                                                    null
                                                ? null
                                                : () async {},
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return const Divider();
                            }
                          },
                          itemBuilder: (BuildContext context, int index) {
                            if (index == 0) {
                              return Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).hintColor,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10)),
                                  ),
                                  height: 4,
                                  width: 40,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                              );
                            }
                            Checkpoint checkpoint = selectedTripDay.checkpoints
                                .firstWhere((checkpoint) =>
                                    checkpoint.chekpointNumber == index);
                            return Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 6.0),
                              decoration: const BoxDecoration(
                                shape: BoxShape.rectangle,
                                color: Colors.amber,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12.0),
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  "Checkpoint ${checkpoint.chekpointNumber}",
                                ),
                                subtitle: Text(checkpoint.title != null
                                    ? checkpoint.title!
                                    : ""),
                                onTap: (() async {
                                  await animateGoogleMapsCamera(
                                      checkpoint.coordinates.latitude,
                                      checkpoint.coordinates.longitude);
                                  await mapController.showMarkerInfoWindow(
                                      checkpoint.marker.markerId);
                                }),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 90,
                    child: Container(
                      height: 35,
                      decoration: const BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: Colors.amber,
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(12.0),
                              bottomRight: Radius.circular(12.0))),
                      child: TextButton(
                        onPressed: () async {
                          await animateGoogleMapsCamera(
                              nextCheckpoint!.coordinates.latitude,
                              nextCheckpoint!.coordinates.longitude);
                          await mapController.showMarkerInfoWindow(
                              nextCheckpoint!.marker.markerId);
                        },
                        child: Text(
                          "Next: Checkpoint ${nextCheckpoint!.chekpointNumber}",
                          style: const TextStyle(color: Colors.pink),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
