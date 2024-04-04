import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/trip_day.dart';
import 'package:mytraveljournal/services/location/location_service.dart';

class PlanFutureTripDayView extends StatefulWidget {
  const PlanFutureTripDayView({super.key, required this.tripDay});

  final TripDay tripDay;

  @override
  State<PlanFutureTripDayView> createState() => _PlanFutureTripDayViewState();
}

class _PlanFutureTripDayViewState extends State<PlanFutureTripDayView> {
  late GoogleMapController mapController;
  late LocationData data;
  late StreamSubscription stream;
  LocationService locationService = getIt<LocationService>();
  late LocationData currentPosition;
  LatLng initialCameraPosition =
      const LatLng(37.42796133580664, -122.085749655962);

  @override
  void initState() {
    currentLocation();
    super.initState();
  }

  @override
  void dispose() async {
    stream.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void currentLocation() async {
    await locationService.getServiceEnabled();
    await locationService.getPermissionStatus();

    currentPosition = await locationService.getCurrentLocation();
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(currentPosition.latitude!, currentPosition.longitude!),
          zoom: 15,
        ),
      ),
    );
    // Useful when in routes or ongoing trip, that should listen and snap to the current user location
    // stream = locationService.location.onLocationChanged.listen((data) {
    //   print("${currentPosition.longitude} : ${currentPosition.longitude}");
    //   setState(() {
    //     currentPosition = data;
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Day ${widget.tripDay.dayNumber}'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              flex: 1,
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
              ),
            ),
            Flexible(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: () => print('hello'),
                    child: const Text('Add start point'),
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
