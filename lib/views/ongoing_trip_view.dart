import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:listenable_collections/listenable_collections.dart';
import 'package:location/location.dart';
import 'package:mytraveljournal/components/dialog_components/show_error_dialog.dart';
import 'package:mytraveljournal/components/dialog_components/show_on_delete_dialog.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/checkpoint.dart';
import 'package:mytraveljournal/models/trip.dart';
import 'package:mytraveljournal/models/trip_day.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:mytraveljournal/services/firebase_storage/firebase_storage_service.dart';
import 'package:mytraveljournal/services/firestore/trip/trip_service.dart';
import 'package:mytraveljournal/services/location/location_service.dart';
import 'package:mytraveljournal/utilities/date_time_apis.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
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
  FirebaseStorageService firebaseStorageService =
      getIt<FirebaseStorageService>();
  TripService tripService = getIt<TripService>();
  User user = getIt<User>();
  late GoogleMapController mapController;
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemScrollController photoVideoController = ItemScrollController();
  late LocationData currentPosition;
  LatLng initialCameraPosition =
      const LatLng(37.42796133580664, -122.085749655962);
  late TripDay todaysTripDay;
  late TripDay selectedTripDay;
  late Checkpoint? nextCheckpoint;
  List<Marker> markers = [];
  List<Polyline> polylines = [];

  // Checkpoint info
  double totalExpenses = 0;
  List<File> files = [];
  List<Map<String, dynamic>> expenses = [];
  String? expenseTitleErrorMessage;
  String? expenseAmountErrorMessage;
  late final TextEditingController _expensesTitle;
  late final TextEditingController _expensesAmount;

  // Add Checkpoint Memories
  int checkpointRating = 1;
  late final TextEditingController _memoryNotes;

  // Add Day Memories
  String daySentimentScore = "";
  String weatherScore = "";
  int favoriteCheckpoint = 1;
  late final TextEditingController _otherDayNotes;

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

  Future<void> checkpointInfo(Checkpoint checkpoint) async {
    if (checkpoint.expenses.isNotEmpty) {
      totalExpenses = checkpoint.expenses
          .map((e) => e.values.first)
          .toList()
          .reduce((a, b) => a + b);
    }

    files = [];
    final appDocDir = await getApplicationDocumentsDirectory();
    for (var filename in checkpoint.fileNames) {
      String pathToFile =
          "${appDocDir.path}/${user.uid}/${widget.trip.tripId}/files/$filename";
      // if (!(await File(pathToFile).exists())) {
      await firebaseStorageService.downloadFile(
          "${user.uid}/${widget.trip.tripId}/files", filename);
      // }
      files.add(File(pathToFile));
    }
    showDialog(
      context: context,
      builder: ((context) {
        return StatefulBuilder(builder: (context, setState) {
          expenses = checkpoint.expenses;
          return Dialog.fullscreen(
            child: Scaffold(
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
                            "Checkpoint ${checkpoint.chekpointNumber}",
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
                                            checkpoint.address,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Color(0xff454579),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  checkpoint.arrivalTime != null ||
                                          checkpoint.departureTime != null
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
                                                "Arriving at ${checkpoint.arrivalTime!.hour.toString().padLeft(2, '0')}:${checkpoint.arrivalTime!.minute.toString().padLeft(2, '0')} | Leaving at ${checkpoint.departureTime!.hour.toString().padLeft(2, '0')}:${checkpoint.departureTime!.minute.toString().padLeft(2, '0')}",
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
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white54,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        flex: 5,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 4.0,
                                              top: 8.0,
                                              left: 8.0,
                                              right: 8.0),
                                          child: Text(
                                            checkpoint.title ?? "",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Color(0xff454579),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
                                                widget.trip.tripId,
                                                selectedTripDay.dayId,
                                                checkpoint.checkpointId!,
                                                expenseData);
                                        double price =
                                            double.parse(_expensesAmount.text);
                                        checkpoint.expenses
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
                                                            widget.trip.tripId,
                                                            selectedTripDay
                                                                .dayId,
                                                            checkpoint
                                                                .checkpointId!,
                                                            [expense]);
                                                    checkpoint.expenses
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
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
                                      children: files
                                          .map((file) => ListTile(
                                                title: Text(
                                                    file.path.split('/').last),
                                                onTap: (() async {
                                                  await OpenFile.open(
                                                      file.path.toString());
                                                }),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                                      child: Text(checkpoint.notes)),
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
                              child: const Text('Back'),
                              onPressed: () {
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

  Future<void> addCheckpointMemories(Checkpoint checkpoint) async {
    checkpointRating = checkpoint.rating ?? 1;
    _memoryNotes.text = checkpoint.memoryNotes ?? "";
    var photosVideosList = ListNotifier();
    final appDocDir = await getApplicationDocumentsDirectory();
    for (var mediaFilename in checkpoint.mediaFilesNames) {
      String pathToFile =
          "${appDocDir.path}/${user.uid}/${widget.trip.tripId}/memories/$mediaFilename";
      // if (!(await File(pathToFile).exists())) {
      await firebaseStorageService.downloadFile(
          "${user.uid}/${widget.trip.tripId}/memories", mediaFilename);
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
                                top: 15.0,
                                left: 10.0,
                                right: 10.0,
                                bottom: 8.0),
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
                                  controller: _memoryNotes,
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
                                                    bool showBannerOptions =
                                                        true;
                                                    return StatefulBuilder(
                                                        builder: (context,
                                                            setState) {
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
                                                                          index:
                                                                              index + 1);
                                                                } else {
                                                                  if (index -
                                                                          1 >=
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
                                                                          color:
                                                                              Colors.white70,
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
                                                                                      await firebaseStorageService.deleteFile("${user.uid}/${widget.trip.tripId}/memories", photosVideosList[index].path.split('/').last);
                                                                                      await tripService.updateCheckpoint(user.uid, widget.trip.tripId, selectedTripDay.dayId, checkpoint.checkpointId!, <String, dynamic>{
                                                                                        "rating": checkpointRating,
                                                                                        "memoryNotes": _memoryNotes.text,
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
                                        photosVideosList.addAll(pickedFiles
                                            .paths
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
                                          final mediaFileNames =
                                              photosVideosList
                                                  .map((file) =>
                                                      file.path.split('/').last)
                                                  .toList();
                                          await Future.wait(photosVideosList.map(
                                              (file) => firebaseStorageService
                                                  .uploadFile(
                                                      "${user.uid}/${widget.trip.tripId}/memories",
                                                      file)));
                                          await tripService.updateCheckpoint(
                                              user.uid,
                                              widget.trip.tripId,
                                              selectedTripDay.dayId,
                                              checkpoint.checkpointId!,
                                              <String, dynamic>{
                                                "rating": checkpointRating,
                                                "memoryNotes":
                                                    _memoryNotes.text,
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

  Future<void> addDayMemories(TripDay day) async {
    int currentStepIndex = 0;
    daySentimentScore =
        day.sentimentScore == "" ? "dissatisfied" : day.sentimentScore;
    weatherScore = day.weatherScore == "" ? "snowy" : day.weatherScore;
    favoriteCheckpoint = day.favoriteCheckpoint ?? 1;
    _otherDayNotes.text = day.otherDayNotes;
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
                                  widget.trip.tripId,
                                  day.dayId,
                                  {
                                    "daySentimentScore": daySentimentScore,
                                    "weatherScore": weatherScore,
                                    "favoriteCheckpoint": favoriteCheckpoint,
                                    "otherDayNotes": _otherDayNotes.text,
                                    "dayFinished": true
                                  },
                                );
                                day.sentimentScore = daySentimentScore;
                                day.weatherScore = weatherScore;
                                day.favoriteCheckpoint = favoriteCheckpoint;
                                day.otherDayNotes = _otherDayNotes.text;
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
                                      ? const Color.fromRGBO(
                                          255, 232, 173, 0.984)
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
                                      ? const Color.fromRGBO(
                                          255, 232, 173, 0.984)
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
                      content: DropdownMenu(
                        initialSelection: favoriteCheckpoint,
                        onSelected: (value) {
                          favoriteCheckpoint = value!;
                          setState(() {});
                        },
                        dropdownMenuEntries: day.checkpoints
                            .map(
                              (checkpoint) => DropdownMenuEntry(
                                  value: checkpoint.chekpointNumber,
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
                                              day.checkpoints[index]);
                                        },
                                        child:
                                            (day.checkpoints[index].rating !=
                                                        null ||
                                                    day.checkpoints[index]
                                                            .memoryNotes !=
                                                        null ||
                                                    day
                                                        .checkpoints[index]
                                                        .mediaFilesNames
                                                        .isNotEmpty)
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
                                              widget.trip.tripId,
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
                        controller: _otherDayNotes,
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

  @override
  void initState() {
    todaysTripDay = widget.trip.days
        .firstWhere((day) => day.date.isSameDate(DateTime.now()));
    selectedTripDay = todaysTripDay;
    nextCheckpoint = todaysTripDay.checkpoints
        .firstWhereOrNull((checkpoint) => checkpoint.isVisited == false);
    currentLocation();
    _expensesTitle = TextEditingController();
    _expensesAmount = TextEditingController();
    _memoryNotes = TextEditingController();
    _otherDayNotes = TextEditingController();
    super.initState();
  }

  @override
  void dispose() async {
    _expensesTitle.dispose();
    _expensesAmount.dispose();
    _memoryNotes.dispose();
    _otherDayNotes.dispose();
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
    if (selectedTripDay.date
            .isBefore(DateTime.now().subtract(const Duration(days: 1))) &&
        selectedTripDay.dayFinished == false) {
      tripService.updateTripDay(
        user.uid,
        widget.trip.tripId,
        selectedTripDay.dayId,
        {"dayFinished": true},
      ).then((_) {});
      selectedTripDay.dayFinished = true;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.trip.title,
          style: const TextStyle(color: Colors.white, fontSize: 30),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 119, 102, 203),
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
                                  ? const Color(0xbf7766CB)
                                  : Colors.white70,
                              border: todaysTripDay.dayId ==
                                      widget.trip.days[index].dayId
                                  ? Border.all(
                                      color: const Color(0xffFFC212),
                                      width: 3.0)
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
                                              color: Colors.white70,
                                              fontWeight: FontWeight.bold)
                                          : const TextStyle(
                                              color: Color(0xff454579),
                                              fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                        widget.trip.days[index].dayNumber
                                            .toString(),
                                        style: selectedTripDay.dayId ==
                                                widget.trip.days[index].dayId
                                            ? const TextStyle(
                                                color: Colors.white70,
                                                fontWeight: FontWeight.bold)
                                            : const TextStyle(
                                                color: Color(0xff454579),
                                                fontWeight: FontWeight.bold)),
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
                        child: Column(
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                              ),
                              height: 50,
                              child: ListView(
                                controller: scrollController,
                                children: [
                                  Stack(
                                    children: [
                                      selectedTripDay.dayFinished == true
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0),
                                              child: IconButton(
                                                icon: const Icon(
                                                    Icons.auto_stories),
                                                onPressed: () async {
                                                  await addDayMemories(
                                                      selectedTripDay);
                                                },
                                              ),
                                            )
                                          : const SizedBox(),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Center(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  Theme.of(context).hintColor,
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(10)),
                                            ),
                                            height: 4,
                                            width: 40,
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            Flexible(
                              flex: 1,
                              child: ListView.separated(
                                padding: const EdgeInsets.only(top: 12),
                                itemCount: selectedTripDay.checkpoints.length,
                                separatorBuilder: (context, index) {
                                  if (index ==
                                      selectedTripDay.checkpoints.length) {
                                    return const Divider();
                                  }
                                  return SizedBox(
                                    height: 120,
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  right: 10.0, top: 10.0),
                                              height: 38,
                                              child: ElevatedButton.icon(
                                                label: Text(
                                                  selectedTripDay
                                                              .checkpoints[
                                                                  index]
                                                              .departureTime ==
                                                          null
                                                      ? "Select departure time"
                                                      : "Leaving at ${(selectedTripDay.checkpoints[index].departureTime!.hour).toString().padLeft(2, '0')}:${(selectedTripDay.checkpoints[index].departureTime!.minute).toString().padLeft(2, '0')}",
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
                                                onPressed: () {},
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
                                                  margin: const EdgeInsets.only(
                                                      left: 10.0),
                                                  height: 38,
                                                  child: ElevatedButton.icon(
                                                    label: Text(
                                                      selectedTripDay
                                                                  .checkpoints[
                                                                      index]
                                                                  .arrivalTime ==
                                                              null
                                                          ? "Provide departure time"
                                                          : "Arriving at ${(selectedTripDay.checkpoints[index + 1].arrivalTime!.hour).toString().padLeft(2, '0')}:${(selectedTripDay.checkpoints[index + 1].arrivalTime!.minute).toString().padLeft(2, '0')}",
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                    icon: const Icon(
                                                      Icons.access_time,
                                                      color: Colors.white,
                                                    ),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                              0xff7D77FF),
                                                    ),
                                                    onPressed: () {},
                                                  ))
                                            ]),
                                      ],
                                    ),
                                  );
                                },
                                itemBuilder: (BuildContext context, int index) {
                                  Checkpoint checkpoint = selectedTripDay
                                      .checkpoints
                                      .firstWhere((checkpoint) =>
                                          checkpoint.chekpointNumber ==
                                          index + 1);
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6.0,
                                    ),
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
                                        await mapController
                                            .showMarkerInfoWindow(
                                                checkpoint.marker.markerId);
                                      }),
                                      leading: (nextCheckpoint != null &&
                                              nextCheckpoint!.checkpointId ==
                                                  checkpoint.checkpointId)
                                          ? ElevatedButton(
                                              onPressed: () async {
                                                try {
                                                  await tripService
                                                      .updateCheckpoint(
                                                    user.uid,
                                                    widget.trip.tripId,
                                                    todaysTripDay.dayId,
                                                    checkpoint.checkpointId!,
                                                    {"isVisited": true},
                                                  );
                                                  nextCheckpoint = todaysTripDay
                                                      .checkpoints
                                                      .firstWhereOrNull(
                                                          (checkpoint) =>
                                                              checkpoint
                                                                  .isVisited ==
                                                              false);
                                                  if (nextCheckpoint == null) {
                                                    await tripService
                                                        .updateTripDay(
                                                      user.uid,
                                                      widget.trip.tripId,
                                                      todaysTripDay.dayId,
                                                      {"dayFinished": true},
                                                    );
                                                    todaysTripDay.dayFinished =
                                                        true;
                                                  }
                                                  checkpoint.isVisited = true;
                                                  setState(() {});
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    await showErrorDialog(
                                                        context,
                                                        'Something went wrong, please try again later');
                                                  }
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                  minimumSize:
                                                      const Size(50, 50),
                                                  backgroundColor:
                                                      const Color.fromRGBO(
                                                          201, 71, 71, 0.749),
                                                  shape: const CircleBorder()),
                                              child: const Text(
                                                "visited",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            )
                                          : null,
                                      trailing: PopupMenuButton(
                                        itemBuilder: (context) {
                                          return [
                                            PopupMenuItem(
                                              onTap: (() async {
                                                await checkpointInfo(
                                                    checkpoint);
                                              }),
                                              child: const Row(
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.all(8),
                                                    child: Icon(
                                                        Icons.info_outline),
                                                  ),
                                                  Text('View info')
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              enabled: (checkpoint.isVisited ||
                                                  selectedTripDay.dayFinished),
                                              onTap: (() async {
                                                await addCheckpointMemories(
                                                    checkpoint);
                                              }),
                                              child: const Row(
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.all(8),
                                                    child: Icon(
                                                        Icons.auto_stories),
                                                  ),
                                                  Text('Add memories')
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
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 90,
                    child: Container(
                      height: 40,
                      decoration: const BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: Color(0xffFFC212),
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(12.0),
                              bottomRight: Radius.circular(12.0))),
                      child: TextButton(
                        onPressed: () async {
                          if (nextCheckpoint != null) {
                            await animateGoogleMapsCamera(
                                nextCheckpoint!.coordinates.latitude,
                                nextCheckpoint!.coordinates.longitude);
                            await mapController.showMarkerInfoWindow(
                                nextCheckpoint!.marker.markerId);
                          }
                        },
                        child: Text(
                          nextCheckpoint != null
                              ? "Next: Checkpoint ${nextCheckpoint!.chekpointNumber}"
                              : "All checkpoints visited today!",
                          style: const TextStyle(
                              color: Color(0xff46467A),
                              fontWeight: FontWeight.bold),
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
