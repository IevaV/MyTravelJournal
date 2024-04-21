import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/checkpoint.dart';
import 'package:mytraveljournal/models/trip.dart';
import 'package:mytraveljournal/models/trip_day.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:mytraveljournal/services/firestore/trip/trip_service.dart';
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
                      // height: constraints.maxHeight / 1.12,
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
                              style: TextStyle(color: Colors.pink),
                            )),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
