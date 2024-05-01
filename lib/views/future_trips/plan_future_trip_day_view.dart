import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:mytraveljournal/services/firebase_storage/firebase_storage_service.dart';
import 'package:mytraveljournal/services/firestore/trip/trip_service.dart';
import 'package:mytraveljournal/services/google_maps/google_maps_service.dart';
import 'package:mytraveljournal/services/location/location_service.dart';
import 'package:http/http.dart' as http;
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:watch_it/watch_it.dart';
import 'dart:developer' as devtools show log;

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
  List<Map<String, dynamic>> expenses = [];
  List<File> files = [];
  Marker? tempMarker;
  TripService tripService = getIt<TripService>();
  FirebaseStorageService firebaseStorageService =
      getIt<FirebaseStorageService>();
  User user = getIt<User>();
  late final TextEditingController _checkpointTitle;
  late final TextEditingController _departureTime;
  late final TextEditingController _expensesTitle;
  late final TextEditingController _expensesAmount;
  late final TextEditingController _notes;
  PolylinePoints polylinePoints = PolylinePoints();
  String checkpointPositionOption = "Add at end";
  bool selectCheckpointEnabled = false;
  int checkpointPosition = 1;
  final GlobalKey<ScaffoldState> _scaffoldkey = GlobalKey<ScaffoldState>();
  double totalExpenses = 0;
  String? expenseTitleErrorMessage;
  String? expenseAmountErrorMessage;

  @override
  void initState() {
    currentLocation();
    searchController = SearchController();
    _checkpointTitle = TextEditingController();
    _departureTime = TextEditingController();
    _expensesTitle = TextEditingController();
    _expensesAmount = TextEditingController();
    _notes = TextEditingController();
    super.initState();
  }

  @override
  void dispose() async {
    searchController.dispose();
    _checkpointTitle.dispose();
    _departureTime.dispose();
    _expensesTitle.dispose();
    _expensesAmount.dispose();
    _notes.dispose();
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
                            expenses: [],
                            fileNames: [],
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
      expenses: [],
      fileNames: [],
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
    totalExpenses = checkpointToUpdate.expenses
        .map((e) => e.values.first)
        .toList()
        .reduce((a, b) => a + b);
    files = [];
    final appDocDir = await getApplicationDocumentsDirectory();
    devtools.log(checkpointToUpdate.fileNames.length.toString());
    devtools.log(appDocDir.toString());
    for (var filename in checkpointToUpdate.fileNames) {
      String pathToFile = "${appDocDir.path}/${widget.tripId}/$filename";
      devtools.log("File doesn't exist");
      await firebaseStorageService.downloadFile(
          user.uid, widget.tripId, filename);
      // await File(pathToFile).create(recursive: true);
      files.add(File(pathToFile));
    }
    showDialog(
      context: context,
      builder: ((context) {
        return StatefulBuilder(builder: (context, setState) {
          _checkpointTitle.text = checkpointToUpdate.title ?? "";
          _notes.text = checkpointToUpdate.notes;
          expenses = checkpointToUpdate.expenses;
          return Dialog.fullscreen(
            child: Scaffold(
              key: _scaffoldkey,
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
                    // mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            "Checkpoint ${checkpointToUpdate.chekpointNumber}",
                            style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white54,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Flexible(
                                        flex: 1,
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              left: 15, top: 8.0, bottom: 4.0),
                                          child: Icon(
                                            Icons.location_on_outlined,
                                            color:
                                                Color.fromRGBO(69, 69, 121, 1),
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        flex: 5,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 4.0,
                                              top: 8.0,
                                              left: 8.0,
                                              right: 8.0),
                                          child: Text(
                                            checkpointToUpdate.address,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Color(0xff454579),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  checkpointToUpdate.arrivalTime != null ||
                                          checkpointToUpdate.departureTime !=
                                              null
                                      ? Row(
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                  left: 15,
                                                  top: 8.0,
                                                  bottom: 8.0),
                                              child: Icon(
                                                Icons.access_time,
                                                color: Color.fromRGBO(
                                                    69, 69, 121, 1),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8.0,
                                                  top: 4.0,
                                                  left: 8.0,
                                                  right: 8.0),
                                              child: Text(
                                                "Arriving at ${checkpointToUpdate.arrivalTime!.hour.toString().padLeft(2, '0')}:${checkpointToUpdate.arrivalTime!.minute.toString().padLeft(2, '0')} | Leaving at ${checkpointToUpdate.departureTime!.hour.toString().padLeft(2, '0')}:${checkpointToUpdate.departureTime!.minute.toString().padLeft(2, '0')}",
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  color: Color(0xff454579),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : const SizedBox(),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: _checkpointTitle,
                              maxLength: 30,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white54,
                                hintText: 'Checkpoint subtitle',
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(40.0)),
                              ),
                            ),
                          ),
                          // Expenses
                          const Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                    left: 15, top: 8.0, bottom: 4.0),
                                child: Icon(
                                  Icons.sell_outlined,
                                  color: Color.fromRGBO(69, 69, 121, 1),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                    bottom: 4.0,
                                    top: 8.0,
                                    left: 8.0,
                                    right: 8.0),
                                child: Text(
                                  "Expenses",
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: _expensesTitle,
                              maxLength: 30,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white54,
                                hintText: 'Title',
                                errorText: expenseTitleErrorMessage,
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(40.0)),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8.0, right: 8.0, bottom: 8.0),
                                  child: TextField(
                                    controller: _expensesAmount,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d{0,2}')),
                                    ],
                                    maxLength: 10,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white54,
                                      hintText: 'Amount',
                                      counterText: "",
                                      errorText: expenseAmountErrorMessage,
                                      suffix: const Text(
                                        'EUR',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromRGBO(69, 69, 121, 1),
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                          borderSide: BorderSide.none,
                                          borderRadius:
                                              BorderRadius.circular(40.0)),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: IconButton(
                                  onPressed: () async {
                                    if (_expensesAmount.text == "" ||
                                        _expensesTitle.text == "") {
                                      _expensesTitle.text == ""
                                          ? expenseTitleErrorMessage =
                                              "Title can't be empty"
                                          : expenseTitleErrorMessage = null;
                                      _expensesAmount.text == ""
                                          ? expenseAmountErrorMessage =
                                              "Amount can't be empty"
                                          : expenseAmountErrorMessage = null;
                                    } else {
                                      expenseTitleErrorMessage = null;
                                      expenseAmountErrorMessage = null;
                                      try {
                                        List<Map<String, dynamic>> expenseData =
                                            [
                                          {
                                            _expensesTitle.text: double.parse(
                                                _expensesAmount.text),
                                          }
                                        ];
                                        await tripService
                                            .updateCheckpointExpenses(
                                                user.uid,
                                                widget.tripId,
                                                widget.tripDay.dayId,
                                                checkpointToUpdate
                                                    .checkpointId!,
                                                expenseData);
                                        double price =
                                            double.parse(_expensesAmount.text);
                                        checkpointToUpdate.expenses
                                            .add({_expensesTitle.text: price});
                                        totalExpenses = totalExpenses + price;
                                        _expensesTitle.clear();
                                        _expensesAmount.clear();
                                        if (context.mounted) {
                                          FocusScope.of(context).unfocus();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text('New expense added'),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          await showErrorDialog(context,
                                              'Something went wrong, please try again later');
                                        }
                                      }
                                    }
                                    setState(() {});
                                  },
                                  icon: const Icon(
                                    Icons.add_circle,
                                    size: 35,
                                  ),
                                  color: const Color.fromRGBO(69, 69, 121, 1),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white54,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          "Total",
                                          style: TextStyle(
                                            fontSize: 25,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xff454579),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          padding: const EdgeInsets.all(10.0),
                                          decoration: BoxDecoration(
                                              shape: BoxShape.rectangle,
                                              color: const Color(0xbfC94747),
                                              borderRadius:
                                                  BorderRadius.circular(50)),
                                          child: Text(
                                            "${totalExpenses.toStringAsFixed(2)} EUR",
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(20.0),
                                        bottomRight: Radius.circular(20.0)),
                                    child: ExpansionTile(
                                      title: const Text(
                                        'View expenses',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      collapsedTextColor: Colors.white,
                                      collapsedIconColor: Colors.white,
                                      collapsedBackgroundColor:
                                          const Color(0xff454579),
                                      collapsedShape:
                                          const Border(bottom: BorderSide()),
                                      children: expenses
                                          .map(
                                            (expense) => ListTile(
                                              leading: Text(expense.keys.first),
                                              title: Center(
                                                child: Text(expense.values.first
                                                    .toStringAsFixed(2)),
                                              ),
                                              trailing: IconButton(
                                                icon: const Icon(Icons.delete),
                                                onPressed: () async {
                                                  try {
                                                    await tripService
                                                        .deleteCheckpointExpense(
                                                            user.uid,
                                                            widget.tripId,
                                                            widget
                                                                .tripDay.dayId,
                                                            checkpointToUpdate
                                                                .checkpointId!,
                                                            [expense]);
                                                    checkpointToUpdate.expenses
                                                        .remove(expense);
                                                    totalExpenses =
                                                        totalExpenses -
                                                            expense
                                                                .values.first;
                                                    setState(() {});
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      await showErrorDialog(
                                                          context,
                                                          'Something went wrong, please try again later');
                                                    }
                                                  }
                                                },
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // TODO Files
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white54,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(
                                                left: 15,
                                                top: 8.0,
                                                bottom: 4.0),
                                            child: Icon(
                                              Icons.attach_file_outlined,
                                              color: Color.fromRGBO(
                                                  69, 69, 121, 1),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(
                                              "Files",
                                              style: TextStyle(
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xff454579),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                          onPressed: () async {
                                            FilePickerResult? pickedFile =
                                                await FilePicker.platform
                                                    .pickFiles();
                                            if (pickedFile != null) {
                                              File file = File(pickedFile
                                                  .files.single.path!);
                                              try {
                                                String fileName =
                                                    file.path.split('/').last;
                                                await firebaseStorageService
                                                    .uploadFile(user.uid,
                                                        widget.tripId, file);
                                                await tripService
                                                    .updateCheckpointFileNames(
                                                        user.uid,
                                                        widget.tripId,
                                                        widget.tripDay.dayId,
                                                        checkpointToUpdate
                                                            .checkpointId!,
                                                        fileName);
                                                String pathToFile =
                                                    "${(appDocDir).path}/${widget.tripId}/$fileName";
                                                await File(pathToFile)
                                                    .create(recursive: true);
                                                checkpointToUpdate.fileNames
                                                    .add(fileName);
                                                files.add(file);
                                                setState(() {});
                                              } catch (e) {
                                                await showErrorDialog(context,
                                                    'Something went wrong, please try again later');
                                              }
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.add_circle,
                                            size: 35,
                                          ))
                                    ],
                                  ),
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(20.0),
                                        bottomRight: Radius.circular(20.0)),
                                    child: ExpansionTile(
                                      title: const Text(
                                        'View files',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      collapsedTextColor: Colors.white,
                                      collapsedIconColor: Colors.white,
                                      collapsedBackgroundColor:
                                          const Color(0xff454579),
                                      collapsedShape:
                                          const Border(bottom: BorderSide()),
                                      // TODO Show added files (Title) and add delete button at the end of the tile
                                      children: files
                                          .map((file) => ListTile(
                                                title: Text(
                                                    file.path.split('/').last),
                                                onTap: (() async {
                                                  final restult =
                                                      await OpenFile.open(
                                                          file.path.toString());
                                                  devtools.log(restult.message);
                                                }),
                                                trailing: IconButton(
                                                  icon:
                                                      const Icon(Icons.delete),
                                                  onPressed: () async {
                                                    String fileName = file.path
                                                        .split('/')
                                                        .last;
                                                    try {
                                                      await firebaseStorageService
                                                          .deleteFile(
                                                              user.uid,
                                                              widget.tripId,
                                                              fileName);
                                                      await tripService
                                                          .deleteCheckpointFileName(
                                                              user.uid,
                                                              widget.tripId,
                                                              widget.tripDay
                                                                  .dayId,
                                                              checkpointToUpdate
                                                                  .checkpointId!,
                                                              fileName);
                                                      checkpointToUpdate
                                                          .fileNames
                                                          .remove(fileName);
                                                      files.remove(file);
                                                      setState(() {});
                                                    } catch (e) {
                                                      devtools
                                                          .log(e.toString());
                                                      await showErrorDialog(
                                                          context,
                                                          'Something went wrong, please try again later');
                                                    }
                                                  },
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // TODO Notes
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white54,
                              ),
                              child: Column(
                                children: [
                                  const Row(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                            left: 15, top: 8.0, bottom: 4.0),
                                        child: Icon(
                                          Icons.feed_outlined,
                                          color: Color.fromRGBO(69, 69, 121, 1),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          "Notes",
                                          style: TextStyle(
                                            fontSize: 25,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xff454579),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextField(
                                      controller: _notes,
                                      maxLength: 300,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                          hintText: "Notes..."),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
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
                              child: const Text('Finish'),
                              onPressed: () async {
                                try {
                                  Map<String, dynamic> data = {
                                    "title": _checkpointTitle.text,
                                    "notes": _notes.text
                                  };
                                  await tripService.updateCheckpoint(
                                      user.uid,
                                      widget.tripId,
                                      widget.tripDay.dayId,
                                      checkpointToUpdate.checkpointId!,
                                      data);
                                  setState(() {
                                    checkpointToUpdate.title =
                                        _checkpointTitle.text;
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
                ),
              ),
            ),
          );
        });
      }),
    );
  }

  Future<void> _selectDepartureTime(
      BuildContext context, Checkpoint start, Checkpoint destination) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      int timeToDestination = int.parse(
          destination.polylineDuration!.replaceAll(RegExp(r'[^0-9]'), ''));
      TimeOfDay? arrivalTime = TimeOfDay.fromDateTime(
        DateTime(2024, 4, 23, time.hour, time.minute).add(
          Duration(seconds: timeToDestination),
        ),
      );
      try {
        Map<String, dynamic> destinationTimeData = {
          "departureTime": {
            "hour": time.hour,
            "minute": time.minute,
          },
        };
        Map<String, dynamic> arrivalTimeData = {
          "arrivalTime": {
            "hour": arrivalTime.hour,
            "minute": arrivalTime.minute,
          },
        };
        await tripService.updateCheckpoint(user.uid, widget.tripId,
            widget.tripDay.dayId, start.checkpointId!, destinationTimeData);
        await tripService.updateCheckpoint(user.uid, widget.tripId,
            widget.tripDay.dayId, destination.checkpointId!, arrivalTimeData);
        start.departureTime = time;
        destination.arrivalTime = arrivalTime;
        setState(() {});
      } catch (e) {
        await showErrorDialog(
            context, 'Something went wrong, please try again later');
      }
    }
  }

  Future<void> _selectArrivalTime(
      BuildContext context, Checkpoint destination) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      try {
        Map<String, dynamic> arrivalTimeData = {
          "arrivalTime": {
            "hour": time.hour,
            "minute": time.minute,
          },
        };
        await tripService.updateCheckpoint(user.uid, widget.tripId,
            widget.tripDay.dayId, destination.checkpointId!, arrivalTimeData);
        destination.arrivalTime = time;
        setState(() {});
      } catch (e) {
        print(e);
        await showErrorDialog(
            context, 'Something went wrong, please try again later');
      }
    }
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
    end.polylineDuration = routeData["routes"][0]["duration"];
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
        title: Text(
          'Day ${widget.tripDay.dayNumber}',
          style: const TextStyle(color: Colors.white, fontSize: 30),
        ),
        backgroundColor: const Color.fromARGB(255, 119, 102, 203),
        centerTitle: true,
        leading: BackButton(
          onPressed: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            context.pop();
          },
          color: Colors.white,
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
                        myLocationButtonEnabled: false,
                        compassEnabled: false,
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
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: SearchAnchor(
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
                          hintText: 'Search location',
                          controller: searchController,
                          // padding: const MaterialStatePropertyAll<EdgeInsets>(
                          //     EdgeInsets.symmetric(horizontal: 16.0)),
                          onTap: () {
                            searchController.openView();
                          },
                          leading: const Icon(Icons.search),
                          backgroundColor: MaterialStateColor.resolveWith(
                              (states) => const Color(0xe6FFFFFF)),
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
                        )),
                  ),
                  DraggableScrollableSheet(
                    snap: true,
                    maxChildSize: 0.5,
                    initialChildSize: 0.11,
                    minChildSize: 0.11,
                    builder: (BuildContext context,
                        ScrollController scrollController) {
                      return Container(
                        clipBehavior: Clip.hardEdge,
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
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: checkpoints.length + 1,
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
                                              checkpoints[index - 1]
                                                          .departureTime ==
                                                      null
                                                  ? "Select departure time"
                                                  : "Leaving at ${(checkpoints[index - 1].departureTime!.hour).toString().padLeft(2, '0')}:${(checkpoints[index - 1].departureTime!.minute).toString().padLeft(2, '0')}",
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
                                            onPressed: () {
                                              // TODO if departure time != null then:
                                              // arrivalTime button text == "Arriving at $arrivalTime" (Calculated departureTime + googleMapsDuration result) and arrivalTime button set as enabled
                                              _selectDepartureTime(
                                                  context,
                                                  checkpoints[index - 1],
                                                  checkpoints[index]);
                                            },
                                          ),
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
                                              checkpoints[index].arrivalTime ==
                                                      null
                                                  ? "Provide departure time"
                                                  : "Arriving at ${(checkpoints[index].arrivalTime!.hour).toString().padLeft(2, '0')}:${(checkpoints[index].arrivalTime!.minute).toString().padLeft(2, '0')}",
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
                                            onPressed: checkpoints[index]
                                                        .arrivalTime ==
                                                    null
                                                ? null
                                                : () async {
                                                    await _selectArrivalTime(
                                                        context,
                                                        checkpoints[index]);
                                                  },
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
                            Checkpoint checkpoint = checkpoints.firstWhere(
                                (checkpoint) =>
                                    checkpoint.chekpointNumber == index);
                            return Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 6.0),
                              decoration: const BoxDecoration(
                                shape: BoxShape.rectangle,
                                color: Colors.white70,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12.0),
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  "Checkpoint ${checkpoint.chekpointNumber}",
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff454579)),
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
