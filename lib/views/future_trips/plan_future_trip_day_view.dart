import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:mytraveljournal/components/dialog_components/show_error_dialog.dart';
import 'package:mytraveljournal/components/dialog_components/show_on_delete_dialog.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/checkpoint.dart';
import 'package:mytraveljournal/models/trip_day.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:mytraveljournal/services/firestore/trip/trip_service.dart';
import 'package:mytraveljournal/services/google_maps/google_maps_service.dart';
import 'package:mytraveljournal/services/location/location_service.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:watch_it/watch_it.dart';

class PlanFutureTripDayView extends StatefulWidget
    with WatchItStatefulWidgetMixin {
  const PlanFutureTripDayView(
      {super.key, required this.tripId, required this.tripDay});

  final String tripId;
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
  List<Polyline> polylines = [];
  Marker? tempMarker;
  TripService tripService = getIt<TripService>();
  User user = getIt<User>();
  late final TextEditingController _checkpointTitle;
  PolylinePoints polylinePoints = PolylinePoints();
  String checkpointPositionOption = "Add at end";
  bool selectCheckpointEnabled = false;
  int checkpointPosition = 1;

  @override
  void initState() {
    currentLocation();
    searchController = SearchController();
    _checkpointTitle = TextEditingController();
    super.initState();
  }

  @override
  void dispose() async {
    searchController.dispose();
    _checkpointTitle.dispose();
    super.dispose();
  }

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

  void currentLocation() async {
    await locationService.getServiceEnabled();
    await locationService.getPermissionStatus();

    currentPosition = await locationService.getCurrentLocation();
    await animateGoogleMapsCamera(
        currentPosition.latitude!, currentPosition.longitude!);
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
        tempMarker = selectedLocationMarker;
        markers.add(selectedLocationMarker);
      } else {
        markers.removeLast();
        tempMarker = selectedLocationMarker;
        markers.add(selectedLocationMarker);
      }
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
                    onPressed: () async {
                      bool addCheckpoint = await createCheckpointDialog();
                      if (addCheckpoint) {
                        http.Response response = await googleMapsService
                            .fetchAddressFromLocation(latLng);
                        final addressData =
                            jsonDecode(response.body) as Map<String, dynamic>;
                        Marker marker;
                        Checkpoint checkpoint;
                        if (checkpointPositionOption == "Add at end") {
                          marker = Marker(
                            markerId: markerId,
                            position: latLng,
                            infoWindow: InfoWindow(
                                title: markerId.value,
                                snippet: addressData["results"][0]
                                    ["formatted_address"]),
                          );
                          checkpoint = Checkpoint(
                            chekpointNumber: checkpointNumber,
                            address: addressData["results"][0]
                                ["formatted_address"],
                            coordinates: latLng,
                            marker: marker,
                          );

                          try {
                            if (widget.tripDay.checkpoints.isNotEmpty) {
                              Checkpoint lastCheckpoint = widget
                                  .tripDay.checkpoints
                                  .firstWhere((checkpoint) =>
                                      checkpoint.chekpointNumber ==
                                      widget.tripDay.checkpoints.length);
                              Polyline createdPolyline =
                                  await addPolyline(lastCheckpoint, checkpoint);
                              setState(() {
                                polylines.add(createdPolyline);
                              });
                            }
                            final addedCheckpoint =
                                await tripService.addCheckpointToTripDay(
                                    user.uid,
                                    widget.tripId,
                                    widget.tripDay.dayId,
                                    checkpoint);
                            ScaffoldMessenger.of(context).clearSnackBars();
                            checkpoint.checkpointId = addedCheckpoint.id;
                            widget.tripDay.addCheckpoint(checkpoint);
                            markers.removeLast();
                            markers.add(marker);
                            tempMarker = null;
                          } catch (e) {
                            await showErrorDialog(context,
                                'Something went wrong, please try again later');
                          }
                        } else {
                          await insertCheckpointBefore(latLng, addressData);
                        }
                      }
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

  Future<bool> createCheckpointDialog() async {
    checkpointPositionOption = "Add at end";
    checkpointPosition = 1;
    List<Checkpoint> checkpointsToModify = widget.tripDay.checkpoints.toList();
    checkpointsToModify
        .sort(((a, b) => a.chekpointNumber.compareTo(b.chekpointNumber)));
    return await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                          'Add as Checkpoint ${widget.tripDay.checkpoints.length + 1}'),
                      leading: Radio<String>(
                        value: "Add at end",
                        groupValue: checkpointPositionOption,
                        onChanged: (value) {
                          setState(() {
                            checkpointPositionOption = value!;
                            selectCheckpointEnabled = false;
                          });
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('Before'),
                      leading: Radio<String>(
                        value: "Add before",
                        groupValue: checkpointPositionOption,
                        onChanged: checkpointsToModify.isNotEmpty
                            ? (value) {
                                setState(() {
                                  checkpointPositionOption = value!;
                                  selectCheckpointEnabled = true;
                                });
                              }
                            : null,
                      ),
                      trailing: DropdownMenu(
                          enabled: selectCheckpointEnabled,
                          initialSelection: 1,
                          onSelected: (value) {
                            setState(() {
                              checkpointPosition = value!;
                            });
                          },
                          dropdownMenuEntries: checkpointsToModify
                              .map((checkpoint) => DropdownMenuEntry(
                                  value: checkpoint.chekpointNumber,
                                  label:
                                      "Checkpoint ${checkpoint.chekpointNumber}"))
                              .toList()),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: const Text('Close'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              );
            },
          );
        });
  }

  Future<void> insertCheckpointBefore(
      LatLng latLng, Map<String, dynamic> addressData) async {
    markers.removeLast();
    tempMarker = null;
    List<Checkpoint> checkpointsToUpdate = [];
    List<Checkpoint> tripDaysCheckpointsModified =
        widget.tripDay.checkpoints.toList();
    List<Marker> tripDayMarkersModified = markers.toList();
    List<Polyline> polylinesModified = polylines.toList();
    Checkpoint checkpointAfter = tripDaysCheckpointsModified.firstWhere(
        (checkpoint) => checkpoint.chekpointNumber == checkpointPosition);
    if (checkpointPosition != 1) {
      polylinesModified.remove(checkpointAfter.polyline);
    }
    MarkerId markerId = MarkerId("Checkpoint $checkpointPosition");
    Marker marker = Marker(
      markerId: markerId,
      position: latLng,
      infoWindow: InfoWindow(
          title: markerId.value,
          snippet: addressData["results"][0]["formatted_address"]),
    );
    Checkpoint checkpoint = Checkpoint(
      chekpointNumber: checkpointPosition,
      address: addressData["results"][0]["formatted_address"],
      coordinates: latLng,
      marker: marker,
    );
    for (var i = tripDaysCheckpointsModified.length;
        i > checkpointPosition - 1;
        i--) {
      Checkpoint checkpointToUpdate = tripDaysCheckpointsModified
          .firstWhere((checkpoint) => checkpoint.chekpointNumber == i);
      checkpointToUpdate.chekpointNumber =
          checkpointToUpdate.chekpointNumber + 1;
      Marker newMarker = Marker(
        markerId: MarkerId("Checkpoint ${checkpointToUpdate.chekpointNumber}"),
        position: checkpointToUpdate.coordinates,
        infoWindow: InfoWindow(
          title: "Checkpoint ${checkpointToUpdate.chekpointNumber}",
          snippet: checkpointToUpdate.address,
        ),
      );
      tripDayMarkersModified.remove(checkpointToUpdate.marker);
      checkpointToUpdate.marker = newMarker;
      tripDayMarkersModified.add(newMarker);
      checkpointsToUpdate.add(checkpointToUpdate);
    }
    tripDayMarkersModified.add(marker);
    if (checkpointPosition != 1) {
      Checkpoint checkpointBefore = tripDaysCheckpointsModified.firstWhere(
          (checkpoint) => checkpoint.chekpointNumber == checkpointPosition - 1);
      Polyline polylineBefore = await addPolyline(checkpointBefore, checkpoint);
      Polyline polylineAfter = await addPolyline(checkpoint, checkpointAfter);
      polylinesModified.addAll([polylineBefore, polylineAfter]);
      checkpoint.polyline = polylineBefore;
      checkpointAfter.polyline = polylineAfter;
    } else {
      Polyline polylineAfter = await addPolyline(checkpoint, checkpointAfter);
      polylinesModified.add(polylineAfter);
      checkpointAfter.polyline = polylineAfter;
    }

    try {
      String addedCheckpointId =
          await tripService.batchUpdateAfterTripDayCheckpointAddition(
              user.uid,
              widget.tripId,
              widget.tripDay.dayId,
              checkpoint,
              checkpointsToUpdate);
      checkpoint.checkpointId = addedCheckpointId;
      tripDaysCheckpointsModified.add(checkpoint);
      setState(() {
        markers = tripDayMarkersModified;
        polylines = polylinesModified;
        widget.tripDay.checkpoints = tripDaysCheckpointsModified;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New checkpoint added'),
          ),
        );
      });
    } catch (e) {
      await showErrorDialog(
          context, 'Something went wrong, please try again later');
    }
  }

  Future<void> deleteCheckpoint(
      Checkpoint checkpointToDelete, List<Checkpoint> checkpoints) async {
    List<Checkpoint> tripDaysCheckpointsModified =
        widget.tripDay.checkpoints.toList();
    List<Marker> tripDayMarkersModified = markers.toList();
    List<Polyline> polylinesModified = polylines.toList();
    tripDaysCheckpointsModified.remove(checkpointToDelete);
    tripDayMarkersModified.remove(checkpointToDelete.marker);
    if (tripDaysCheckpointsModified.isNotEmpty) {
      if (checkpointToDelete.chekpointNumber == 1) {
        Checkpoint secondCheckpoint = tripDaysCheckpointsModified
            .firstWhere((checkpoint) => checkpoint.chekpointNumber == 2);
        polylinesModified.remove(secondCheckpoint.polyline!);
        secondCheckpoint.polyline = null;
      } else if (checkpointToDelete.chekpointNumber ==
          widget.tripDay.checkpoints.length) {
        polylinesModified.remove(checkpointToDelete.polyline!);
      } else {
        Checkpoint nextCheckpoint = tripDaysCheckpointsModified.firstWhere(
            (checkpoint) =>
                checkpoint.chekpointNumber ==
                checkpointToDelete.chekpointNumber + 1);
        Checkpoint previousCheckpoint = tripDaysCheckpointsModified.firstWhere(
            (checkpoint) =>
                checkpoint.chekpointNumber ==
                checkpointToDelete.chekpointNumber - 1);
        polylinesModified.remove(nextCheckpoint.polyline!);
        polylinesModified.remove(checkpointToDelete.polyline!);
        Polyline createdPolyline =
            await addPolyline(previousCheckpoint, nextCheckpoint);
        polylinesModified.add(createdPolyline);
      }
      for (var i = checkpointToDelete.chekpointNumber;
          i <= tripDaysCheckpointsModified.length;
          i++) {
        Checkpoint checkpointToUpdate = tripDaysCheckpointsModified
            .firstWhere((checkpoint) => checkpoint.chekpointNumber == i + 1);
        checkpointToUpdate.chekpointNumber = i;
        Marker newMarker = Marker(
          markerId: MarkerId("Checkpoint $i"),
          position: checkpointToUpdate.coordinates,
          infoWindow: InfoWindow(
            title: "Checkpoint ${checkpointToUpdate.chekpointNumber}",
            snippet: checkpointToUpdate.address,
          ),
        );
        tripDayMarkersModified.remove(checkpointToUpdate.marker);
        checkpointToUpdate.marker = newMarker;
        tripDayMarkersModified.add(newMarker);
      }
    }

    try {
      await tripService.batchUpdateAfterTripDayCheckpointDeletion(
          user.uid,
          widget.tripId,
          widget.tripDay.dayId,
          checkpointToDelete.checkpointId!,
          tripDaysCheckpointsModified);
      setState(() {
        markers = tripDayMarkersModified;
        polylines = polylinesModified;
        widget.tripDay.checkpoints = tripDaysCheckpointsModified;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Checkpoint ${checkpointToDelete.chekpointNumber} deleted'),
          ),
        );
      });
    } catch (e) {
      await showErrorDialog(
          context, 'Something went wrong, please try again later');
    }
  }

  Future<void> updateCheckpoint(
      Checkpoint checkpointToUpdate, List<Checkpoint> checkpoints) async {
    _checkpointTitle.text = checkpointToUpdate.title ?? "";
    showDialog(
      context: context,
      builder: ((context) {
        return Dialog.fullscreen(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                flex: 3,
                child: Column(
                  children: [
                    Text("Checkpoint ${checkpointToUpdate.chekpointNumber}"),
                    TextField(
                      controller: _checkpointTitle,
                      decoration: const InputDecoration(
                        labelText: "Checkpoint title",
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilledButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    FilledButton(
                      child: const Text('Save'),
                      onPressed: () async {
                        try {
                          Map<String, dynamic> data = {
                            "title": _checkpointTitle.text
                          };
                          await tripService.updateCheckpoint(
                              user.uid,
                              widget.tripId,
                              widget.tripDay.dayId,
                              checkpointToUpdate.checkpointId!,
                              data);
                          setState(() {
                            checkpointToUpdate.title = _checkpointTitle.text;
                          });
                        } catch (e) {
                          await showErrorDialog(context,
                              'Something went wrong, please try again later');
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<Polyline> addPolyline(Checkpoint start, Checkpoint end) async {
    http.Response response =
        await googleMapsService.fetchRoute(start.coordinates, end.coordinates);
    final routeData = jsonDecode(response.body) as Map<String, dynamic>;
    List<PointLatLng> result = polylinePoints
        .decodePolyline(routeData["routes"][0]["polyline"]["encodedPolyline"]);
    List<LatLng> coords =
        result.map((coord) => LatLng(coord.latitude, coord.longitude)).toList();
    Polyline polyline = Polyline(
        polylineId: PolylineId(const Uuid().v4()),
        points: coords,
        color: Colors.blue.withOpacity(0.75));
    end.polyline = polyline;
    return polyline;
  }

  @override
  Widget build(BuildContext context) {
    List<Checkpoint> checkpoints = watch(widget.tripDay).checkpoints;
    callOnce(
      (context) {
        markers = checkpoints.map((checkpoint) {
          return checkpoint.marker;
        }).toList();
        polylines = checkpoints.skip(1).map((checkpoint) {
          return checkpoint.polyline!;
        }).toList();
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
                        polylines: Set<Polyline>.of(polylines),
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
                              setState(() async {
                                controller.closeView(item);
                                FocusScope.of(context).unfocus();
                                await animateGoogleMapsCamera(
                                    locationData["location"]["latitude"],
                                    locationData["location"]["longitude"]);
                              });
                            },
                          );
                        },
                      );
                    },
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
                            Checkpoint checkpoint = checkpoints.firstWhere(
                                (checkpoint) =>
                                    checkpoint.chekpointNumber == index);
                            return ListTile(
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
                              trailing: PopupMenuButton(
                                itemBuilder: (context) {
                                  return [
                                    PopupMenuItem(
                                      onTap: (() async {
                                        await updateCheckpoint(
                                            checkpoint, checkpoints);
                                      }),
                                      child: const Row(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(Icons.edit),
                                          ),
                                          Text('Edit')
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      onTap: (() async {
                                        bool? confirmDelete =
                                            await showDeleteDialog(context,
                                                'Checkpoint ${checkpoint.chekpointNumber}?');
                                        if (confirmDelete == true) {
                                          await deleteCheckpoint(
                                              checkpoint, checkpoints);
                                        }
                                      }),
                                      child: const Row(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(Icons.delete),
                                          ),
                                          Text('Delete')
                                        ],
                                      ),
                                    )
                                  ];
                                },
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
