import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/checkpoint.dart';
import 'package:mytraveljournal/models/trip_day.dart';
import 'package:mytraveljournal/services/google_maps/google_maps_service.dart';
import 'package:mytraveljournal/services/location/location_service.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as devtools show log;
import 'package:watch_it/watch_it.dart';

class PlanFutureTripDayView extends StatefulWidget
    with WatchItStatefulWidgetMixin {
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
  Marker? tempMarker;

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

  void addMarker(LatLng latLng) {
    setState(() {
      int checkpointNumber =
          tempMarker == null ? markers.length + 1 : markers.length;
      MarkerId markerId = MarkerId('Checkpoint $checkpointNumber');
      Marker selectedLocationMarker = Marker(
        markerId: markerId,
        position: latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      );
      if (tempMarker == null) {
        devtools.log(markers.length.toString());
        tempMarker = selectedLocationMarker;
        markers.add(selectedLocationMarker);
      } else {
        markers.removeLast();
        tempMarker = selectedLocationMarker;
        markers.add(selectedLocationMarker);
      }
      markers.forEach((element) {
        devtools.log(element.markerId.toString());
      });
      devtools.log(markers.length.toString());
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(days: 365),
          content: Column(
            children: [
              Text('Do you want to add Checkpoint ${markers.length}?'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      setState(() {
                        markers.removeLast();
                        tempMarker = null;
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      Marker marker = Marker(
                        markerId: markerId,
                        position: latLng,
                        onTap: () => addedMarkerModal(checkpointNumber),
                      );
                      Checkpoint checkpoint = Checkpoint(
                          selectedLocationMarker.markerId.value,
                          latLng,
                          marker);
                      // TODO add to db checkpoint
                      widget.tripDay.addCheckpoint(checkpoint);
                      markers.removeLast();
                      markers.add(marker);
                      tempMarker = null;
                    },
                    child: const Text('Add'),
                  )
                ],
              )
            ],
          ),
        ),
      );
    });
  }

  void addedMarkerModal(int checkpointNumber) {
    showModalBottomSheet(
      context: context,
      // isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Center(
          child: Column(
            children: [
              Text(widget.tripDay.checkpoints[checkpointNumber - 1].title),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Checkpoint> checkpoints = watch(widget.tripDay).checkpoints;
    callOnce(
      (context) {
        markers = checkpoints.map((checkpoint) => checkpoint.marker).toList();
      },
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Day ${widget.tripDay.dayNumber}'),
        centerTitle: true,
        leading: BackButton(
          onPressed: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            context.pop();
          },
        ),
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
                        markers: Set<Marker>.of(markers),
                        onLongPress: (latLang) => addMarker(latLang),
                      ),
                    );
                  }),
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
                              addMarker(LatLng(
                                  locationData["location"]["latitude"],
                                  locationData["location"]["longitude"]));
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
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                  DraggableScrollableSheet(
                    snap: true,
                    initialChildSize: 0.10,
                    minChildSize: 0.10,
                    builder: (BuildContext context,
                        ScrollController scrollController) {
                      return Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: Theme.of(context).canvasColor,
                        ),
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: checkpoints.length + 1,
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
                            return ListTile(
                              title: Text(
                                checkpoints[index - 1].title,
                              ),
                            );
                          },
                        ),
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
