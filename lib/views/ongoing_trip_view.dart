import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:mytraveljournal/components/dialog_components/add_checkpoint_memories_dialog.dart';
import 'package:mytraveljournal/components/dialog_components/add_day_memories_dialog.dart';
import 'package:mytraveljournal/components/dialog_components/show_error_dialog.dart';
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
  String favoriteCheckpoint = "";
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
                                                    context,
                                                    selectedTripDay,
                                                    widget.trip.tripId,
                                                    daySentimentScore,
                                                    weatherScore,
                                                    favoriteCheckpoint,
                                                    _otherDayNotes,
                                                    _memoryNotes,
                                                    user,
                                                    tripService,
                                                    firebaseStorageService,
                                                    checkpointRating,
                                                    photoVideoController,
                                                  );
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
                                                  if (todaysTripDay.checkpoints
                                                      .every((checkpoint) =>
                                                          checkpoint
                                                              .isVisited ==
                                                          true)) {
                                                    // TODO redirect user to memory page!
                                                  }
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
                                                // await addCheckpointMemories(
                                                //     checkpoint);
                                                await addCheckpointMemories(
                                                    context,
                                                    checkpoint,
                                                    checkpointRating,
                                                    widget.trip.tripId,
                                                    selectedTripDay.dayId,
                                                    photoVideoController,
                                                    _memoryNotes,
                                                    user,
                                                    tripService,
                                                    firebaseStorageService);
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
