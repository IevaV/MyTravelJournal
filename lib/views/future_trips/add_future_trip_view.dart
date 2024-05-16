import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mytraveljournal/components/dialog_components/show_error_dialog.dart';
import 'package:mytraveljournal/components/ui_components/date_picker.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/trip.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:mytraveljournal/services/firestore/trip/trip_service.dart';
import 'package:mytraveljournal/utilities/date_helper.dart';
import 'package:collection/collection.dart';

class AddFutureTripView extends StatefulWidget {
  const AddFutureTripView({super.key, required this.params});

  final Map<String, String> params;

  @override
  State<AddFutureTripView> createState() => _AddFutureTripViewState();
}

class _AddFutureTripViewState extends State<AddFutureTripView> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _date;
  final Map<String, DateTimeRange?> selectedDates = {};
  bool _validateTitleInput = false;
  bool _validateDescriptionInput = false;
  bool _validateDateInput = false;
  String tripDateErrorMessage = "Please select Trip start and end dates";

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _description = TextEditingController();
    _date = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _title.dispose();
    _description.dispose();
    _date.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TripService tripService = getIt<TripService>();
    User user = getIt<User>();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(119, 102, 203, 1),
        title: Text(
          widget.params["tripType"] == "planning"
              ? 'Create New Trip'
              : "Create Past Trip",
          style: const TextStyle(color: Colors.white, fontSize: 30),
        ),
        centerTitle: true,
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  flex: 4,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          widget.params["tripType"] == "planning"
                              ? 'Where you will be traveling to?'
                              : "Where did you travel to?",
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff454579)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        child: TextField(
                          controller: _title,
                          maxLength: 30,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white54,
                            hintText: 'Trip title',
                            border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(40.0)),
                            errorText: _validateTitleInput
                                ? "Title can't be empty"
                                : null,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          widget.params["tripType"] == "planning"
                              ? 'Write short description about your upcoming adventures!'
                              : "Write short description about your past adventure!",
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        child: TextField(
                          controller: _description,
                          maxLength: 100,
                          maxLines: 3,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white54,
                            hintText: 'Description',
                            border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(20.0)),
                            errorText: _validateDescriptionInput
                                ? "Description can't be empty"
                                : null,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          widget.params["tripType"] == "planning"
                              ? 'When your adventure will start?'
                              : "When did your adventure happen?",
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff454579)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        child: DatePicker(
                          textController: _date,
                          pickedDates: selectedDates,
                          validateSelectedDates: _validateDateInput,
                          textFieldErrorMessage: tripDateErrorMessage,
                          firstDate: widget.params["tripType"] == "past"
                              ? DateTime(DateTime.now().year - 50)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FilledButton(
                          onPressed: () {
                            GoRouter.of(context).pop();
                          },
                          child: const Text('Cancel')),
                      FilledButton(
                        child: const Text('Next'),
                        onPressed: () async {
                          Trip? trip;
                          if (widget.params["tripType"] == "planning" &&
                              selectedDates['dates'] != null) {
                            trip = user.userTrips.firstWhereOrNull(
                              (userTrip) {
                                List<DateTime> datesBetweenSelect =
                                    datesBetween(selectedDates['dates']!.start,
                                        selectedDates['dates']!.end);
                                List<DateTime> datesBetweenExisting =
                                    datesBetween(
                                        userTrip.startDate, userTrip.endDate);
                                return (datesBetweenSelect
                                            .contains(userTrip.startDate) ||
                                        datesBetweenSelect
                                            .contains(userTrip.endDate)) ||
                                    (datesBetweenExisting.contains(
                                            selectedDates['dates']!.start) ||
                                        datesBetweenExisting.contains(
                                            selectedDates['dates']!.end));
                              },
                            );
                          }

                          setState(() {
                            _validateTitleInput = _title.text.isEmpty;
                            _validateDescriptionInput =
                                _description.text.isEmpty;
                            if (selectedDates['dates'] == null) {
                              tripDateErrorMessage =
                                  "Please select Trip start and end dates";
                            } else if (trip != null) {
                              tripDateErrorMessage =
                                  "Selected dates are overlapping with existing Trip: ${trip.title}";
                            }
                            _validateDateInput =
                                selectedDates['dates'] == null || trip != null;
                          });

                          if (!_validateTitleInput &&
                              !_validateDescriptionInput &&
                              !_validateDateInput) {
                            try {
                              await tripService.batchUpdateAfterAddingNewTrip(
                                user.uid,
                                _title.text,
                                _description.text,
                                selectedDates['dates']!.start,
                                DateTime(
                                  selectedDates['dates']!.end.year,
                                  selectedDates['dates']!.end.month,
                                  selectedDates['dates']!.end.day,
                                  23,
                                  59,
                                  59,
                                ),
                                widget.params["tripType"]!,
                              );
                              Trip trip =
                                  await tripService.getLatestUserTrip(user.uid);
                              user.addTrip(trip);
                              context.push('/plan-future-trip', extra: trip);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('New trip added'),
                                ),
                              );
                            } catch (e) {
                              print(e);
                              await showErrorDialog(context,
                                  'Something went wrong, please try again later');
                            }
                          }
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
  }
}
