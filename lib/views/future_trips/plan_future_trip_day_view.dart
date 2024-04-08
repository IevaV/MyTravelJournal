import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/trip_day.dart';
import 'package:mytraveljournal/services/google_maps/google_maps_service.dart';
import 'package:mytraveljournal/services/location/location_service.dart';
import 'package:http/http.dart' as http;

class PlanFutureTripDayView extends StatefulWidget {
  const PlanFutureTripDayView({super.key, required this.tripDay});

  final TripDay tripDay;

  @override
  State<PlanFutureTripDayView> createState() => _PlanFutureTripDayViewState();
}

class _PlanFutureTripDayViewState extends State<PlanFutureTripDayView> {
  late GoogleMapController mapController;
  late LocationData data;
  LocationService locationService = getIt<LocationService>();
  GoogleMapsService googleMapsService = getIt<GoogleMapsService>();
  late LocationData currentPosition;
  LatLng initialCameraPosition =
      const LatLng(37.42796133580664, -122.085749655962);
  late final SearchController searchController;
  List<dynamic> autoCompleteSuggestions = [];
  List<Marker> markers = [];

  @override
  void initState() {
    currentLocation();
    searchController = SearchController();
    super.initState();
  }

  @override
  void dispose() async {
    searchController.dispose();
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
              child: Stack(
                children: [
                  GoogleMap(
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
                  ),
                  SearchAnchor(
                    viewOnChanged: (value) async {
                      http.Response response = await googleMapsService
                          .fetchPlacesAutocompleteResults(value);
                      final autoCompleteData =
                          jsonDecode(response.body) as Map<String, dynamic>;
                      setState(() {
                        autoCompleteSuggestions =
                            autoCompleteData["suggestions"];
                      });
                    },
                    viewLeading: BackButton(
                      onPressed: () {
                        context.pop();
                        FocusScope.of(context).requestFocus(FocusNode());
                      },
                    ),
                    builder: (BuildContext context, searchController) {
                      return SearchBar(
                        controller: searchController,
                        // padding: const MaterialStatePropertyAll<EdgeInsets>(
                        //     EdgeInsets.symmetric(horizontal: 16.0)),
                        onTap: () {
                          searchController.openView();
                        },
                        leading: const Icon(Icons.search),
                      );
                    },
                    suggestionsBuilder: (BuildContext context,
                        SearchController controller) async {
                      return List<ListTile>.generate(
                        autoCompleteSuggestions.length,
                        (int index) {
                          final String item =
                              '${autoCompleteSuggestions[index]["placePrediction"]["text"]["text"]}';
                          return ListTile(
                            title: Text(item),
                            onTap: () async {
                              http.Response response = await googleMapsService
                                  .fetchPlaceLocationData(
                                      autoCompleteSuggestions[index]
                                          ["placePrediction"]["placeId"]);
                              final locationData = jsonDecode(response.body)
                                  as Map<String, dynamic>;
                              MarkerId markerId = const MarkerId('Test');
                              Marker selectedLocationMarker = Marker(
                                markerId: markerId,
                                position: LatLng(
                                    locationData["location"]["latitude"],
                                    locationData["location"]["longitude"]),
                                infoWindow: InfoWindow(
                                  title: "Sydney",
                                  snippet: "Capital of New South Wales",
                                  onTap: () {},
                                ),
                              );
                              setState(() {
                                controller.closeView(item);
                                FocusScope.of(context).unfocus();
                                mapController.animateCamera(
                                  CameraUpdate.newCameraPosition(
                                    CameraPosition(
                                      target: LatLng(
                                          locationData["location"]["latitude"],
                                          locationData["location"]
                                              ["longitude"]),
                                      zoom: 15,
                                    ),
                                  ),
                                );
                                markers.add(selectedLocationMarker);
                              });
                            },
                          );
                        },
                      );
                    },
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
