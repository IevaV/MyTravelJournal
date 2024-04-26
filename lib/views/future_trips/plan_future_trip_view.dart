import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mytraveljournal/components/dialog_components/show_error_dialog.dart';
import 'package:mytraveljournal/components/dialog_components/show_on_delete_dialog.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/checkpoint.dart';
import 'package:mytraveljournal/models/trip.dart';
import 'package:mytraveljournal/models/trip_day.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:mytraveljournal/services/firestore/trip/trip_service.dart';
import 'package:mytraveljournal/utilities/date_helper.dart';
import 'package:watch_it/watch_it.dart';
import 'package:intl/intl.dart';

class PlanFutureTripView extends StatefulWidget
    with WatchItStatefulWidgetMixin {
  const PlanFutureTripView({super.key, required this.trip});

  final Trip trip;

  @override
  State<PlanFutureTripView> createState() => _PlanFutureTripViewState();
}

class _PlanFutureTripViewState extends State<PlanFutureTripView> {
  TripService tripService = getIt<TripService>();
  User user = getIt<User>();
  late final TextEditingController _description;
  late final TextEditingController _tripTitle;
  bool descriptionEdited = false;

  Future<void> updateDayPlannedState(TripDay day) async {
    bool setAsPlanned = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(day.planned == false
              ? "Set Day ${day.dayNumber} as planned"
              : "Set Day ${day.dayNumber} to in progress"),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('Cancel')),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('Confirm')),
          ],
        );
      },
    );
    if (setAsPlanned) {
      try {
        await tripService.updateTripDay(user.uid, widget.trip.tripId, day.dayId,
            <String, dynamic>{"planned": !day.planned});
        setState(() {
          day.updateDayStatus(!day.planned);
        });
        if (widget.trip.days.where((day) => day.planned == true).length ==
            widget.trip.days.length) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(
                    "All days are planned! Trip will start on ${widget.trip.startDate}"),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Ok')),
                ],
              );
            },
          );
        }
      } catch (e) {
        await showErrorDialog(
            context, 'Something went wrong, please try again later');
      }
    }
  }

  Future<DateTimeRange?> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      keyboardType: TextInputType.text,
      initialDateRange:
          DateTimeRange(start: widget.trip.startDate, end: widget.trip.endDate),
      firstDate: DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) {
      return picked;
    }
    return null;
  }

  Future<void> editTripDates() async {
    DateTimeRange? selectedDates = await _selectDateRange(context);
    Trip? trip;
    if (selectedDates != null) {
      trip = user.userTrips.firstWhereOrNull(
        (userTrip) {
          List<DateTime> datesBetweenSelected =
              datesBetween(selectedDates.start, selectedDates.end);
          List<DateTime> datesBetweenExisting =
              datesBetween(selectedDates.start, selectedDates.end);
          return (datesBetweenSelected.contains(userTrip.startDate) ||
                  datesBetweenSelected.contains(userTrip.endDate) ||
                  datesBetweenExisting.contains(selectedDates.start) ||
                  datesBetweenExisting.contains(selectedDates.end)) &&
              userTrip.tripId != widget.trip.tripId;
        },
      );
    }
    if (selectedDates != null &&
        (selectedDates.start != widget.trip.startDate ||
            selectedDates.end != widget.trip.endDate) &&
        trip == null) {
      if (widget.trip.days.length > selectedDates.duration.inDays + 1) {
        List<TripDay> tripDaysModified = widget.trip.days.toList();
        int daysToDelete =
            tripDaysModified.length - (selectedDates.duration.inDays + 1);
        Map<String, dynamic> checkboxValues = {};
        for (var day in tripDaysModified) {
          checkboxValues["Day ${day.dayNumber}"] = {
            "day": day,
            "checked": false
          };
        }
        int totalChecked = checkboxValues.entries
            .where((e) => e.value == true)
            .toList()
            .length;
        bool? confirmDeleteDays = await selectDaysToDelete(
            tripDaysModified, checkboxValues, daysToDelete, totalChecked);
        if (confirmDeleteDays == true) {
          List<MapEntry<String, dynamic>> selectedDays = checkboxValues.entries
              .where((e) => e.value["checked"] == true)
              .toList();
          List<TripDay> selectedDaysToDelete =
              selectedDays.map((data) => data.value["day"] as TripDay).toList();
          for (var day in selectedDaysToDelete) {
            tripDaysModified.remove(day);
          }
          List<DateTime> dateRange =
              datesBetween(selectedDates.start, selectedDates.end);
          for (var i = 0; i < tripDaysModified.length; i++) {
            tripDaysModified[i].dayNumber = i + 1;
            tripDaysModified[i].date = dateRange[i];
          }
          try {
            await tripService.batchUpdateAfterEditedTripDates(
                user.uid,
                widget.trip.tripId,
                tripDaysModified,
                selectedDates.start,
                selectedDates.end,
                null,
                selectedDaysToDelete,
                widget.trip.days.length);
            widget.trip.days = tripDaysModified;
            widget.trip.startDate = selectedDates.start;
            widget.trip.endDate = selectedDates.end;
            setState(() {});
          } catch (e) {
            await showErrorDialog(
                context, 'Something went wrong, please try again later');
          }
        }
      } else if (widget.trip.days.length < selectedDates.duration.inDays + 1) {
        List<TripDay> tripDaysModified = widget.trip.days.toList();
        if (selectedDates.start.isAtSameMomentAs(widget.trip.startDate)) {
          List<DateTime> dates = datesBetween(
              widget.trip.endDate.add(const Duration(days: 1)),
              selectedDates.end);
          try {
            await tripService.batchUpdateAfterEditedTripDates(
                user.uid,
                widget.trip.tripId,
                [],
                null,
                selectedDates.end,
                dates,
                null,
                widget.trip.days.length);
            List<TripDay> allTripDays =
                await tripService.getTripDays(user.uid, widget.trip.tripId);
            widget.trip.days = allTripDays;
            widget.trip.endDate = selectedDates.end;
            setState(() {});
          } catch (e) {
            await showErrorDialog(
                context, 'Something went wrong, please try again later');
          }
        } else {
          List<DateTime> dateRange =
              datesBetween(selectedDates.start, selectedDates.end);
          for (var i = 0; i < tripDaysModified.length; i++) {
            tripDaysModified[i].date = dateRange[i];
          }
          List<DateTime> dates = dateRange.sublist(tripDaysModified.length);
          DateTime? endDateModified =
              selectedDates.end.isAtSameMomentAs(widget.trip.endDate)
                  ? null
                  : selectedDates.end;
          try {
            await tripService.batchUpdateAfterEditedTripDates(
                user.uid,
                widget.trip.tripId,
                tripDaysModified,
                selectedDates.start,
                endDateModified,
                dates,
                null,
                widget.trip.days.length);
            List<TripDay> allTripDays =
                await tripService.getTripDays(user.uid, widget.trip.tripId);
            widget.trip.days = allTripDays;
            widget.trip.startDate = selectedDates.start;
            widget.trip.endDate = selectedDates.end;
            setState(() {});
          } catch (e) {
            await showErrorDialog(
                context, 'Something went wrong, please try again later');
          }
        }
      } else if (widget.trip.days.length == selectedDates.duration.inDays + 1) {
        List<TripDay> tripDaysModified = widget.trip.days.toList();
        List<DateTime> dates =
            datesBetween(selectedDates.start, selectedDates.end);
        for (var i = 0; i < dates.length; i++) {
          tripDaysModified[i].date = dates[i];
        }
        try {
          await tripService.batchUpdateAfterEditedTripDates(
              user.uid,
              widget.trip.tripId,
              tripDaysModified,
              selectedDates.start,
              selectedDates.end,
              null,
              null,
              widget.trip.days.length);
          widget.trip.days = tripDaysModified;
          widget.trip.startDate = selectedDates.start;
          widget.trip.endDate = selectedDates.end;
          setState(() {});
        } catch (e) {
          await showErrorDialog(
              context, 'Something went wrong, please try again later');
        }
      }
    } else if (trip != null) {
      showErrorDialog(context,
          "Selected dates are overlapping with existing Trip: ${trip.title}");
    }
  }

  Future<bool?> selectDaysToDelete(
      tripDaysModified, checkboxValues, daysToDelete, totalChecked) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Column(
                children: [
                  Text(
                      "Your selected Date range is shorter than the original Trip length. Please select $daysToDelete days to delete!"),
                  Flexible(
                    flex: 3,
                    child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: tripDaysModified.length,
                        itemBuilder: (BuildContext context, int index) {
                          TripDay tripDay = tripDaysModified[index];
                          return CheckboxListTile(
                            value: checkboxValues["Day ${tripDay.dayNumber}"]
                                ["checked"],
                            title: Text("Day ${tripDay.dayNumber}"),
                            enabled: (daysToDelete == totalChecked &&
                                    checkboxValues["Day ${tripDay.dayNumber}"]
                                            ["checked"] ==
                                        false)
                                ? false
                                : true,
                            onChanged: (bool? value) {
                              checkboxValues["Day ${tripDay.dayNumber}"]
                                  ["checked"] = value!;
                              totalChecked = checkboxValues.entries
                                  .where((e) => e.value["checked"] == true)
                                  .toList()
                                  .length;
                              setState(() {});
                            },
                          );
                        }),
                  ),
                  const Divider(height: 0),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: daysToDelete == totalChecked
                            ? () async {
                                Navigator.of(context).pop(true);
                              }
                            : null,
                        child: const Text('Confirm'),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    _description = TextEditingController();
    _tripTitle = TextEditingController();
    _description.text = widget.trip.description;
    _tripTitle.text = widget.trip.title;
    super.initState();
  }

  @override
  void dispose() {
    _description.dispose();
    _tripTitle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    callOnce((context) async {
      for (var i = 0; i < widget.trip.days.length; i++) {
        List<Checkpoint> checkpoints = await tripService.getTripDayCheckpoints(
            user.uid, widget.trip.tripId, widget.trip.days[i].dayId);
        widget.trip.days[i].checkpoints = checkpoints;
      }
      setState(() {});
    });
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 119, 102, 203),
        title: Text(
          widget.trip.title,
          style: const TextStyle(color: Colors.white, fontSize: 30),
        ),
        centerTitle: true,
        leading: BackButton(
          color: Colors.white,
          onPressed: () async {
            while (context.canPop()) {
              context.pop();
            }
          },
        ),
        actions: [
          IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Edit trip Title"),
                            TextField(
                              controller: _tripTitle,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      await tripService.updateTrip(user.uid,
                                          widget.trip.tripId, <String, dynamic>{
                                        "title": _tripTitle.text,
                                      });
                                      widget.trip.updateTitle(_tripTitle.text);
                                      setState(() {});
                                      Navigator.of(context).pop();
                                    } catch (e) {
                                      await showErrorDialog(context,
                                          'Something went wrong, please try again later');
                                    }
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    });
              },
              icon: const Icon(
                Icons.edit,
                color: Colors.white,
              ))
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
              flex: 2,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Description',
                      style: TextStyle(
                          color: Color(0xff454579),
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    child: TextField(
                      controller: _description,
                      enableSuggestions: false,
                      autocorrect: false,
                      maxLength: 100,
                      maxLines: 3,
                      onChanged: (descriptionInputText) {
                        if (descriptionInputText == widget.trip.description) {
                          descriptionEdited = false;
                        } else {
                          descriptionEdited = true;
                        }
                        _description.value = TextEditingValue(
                          text: descriptionInputText,
                        );
                        setState(() {});
                      },
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color.fromARGB(128, 125, 119, 255),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          suffixIcon: descriptionEdited
                              ? IconButton(
                                  onPressed: () async {
                                    try {
                                      await tripService.updateTrip(user.uid,
                                          widget.trip.tripId, <String, dynamic>{
                                        "description": _description.text,
                                      });
                                      widget.trip.description =
                                          _description.text;
                                      descriptionEdited = false;
                                      FocusScope.of(context).unfocus();
                                      setState(() {});
                                    } catch (e) {
                                      await showErrorDialog(context,
                                          'Something went wrong, please try again later');
                                    }
                                  },
                                  icon: const Icon(Icons.check_rounded))
                              : null),
                    ),
                  ),
                  const Text(
                    'Start date - End date',
                    style: TextStyle(
                        color: Color(0xff454579),
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color.fromRGBO(125, 119, 255, 0.502),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(15.0),
                            child: Text(
                              "${DateFormat('dd/MM/yyyy').format(widget.trip.startDate)} - ${DateFormat('dd/MM/yyyy').format(widget.trip.endDate)}",
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xff454579),
                              ),
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: () async {
                              await editTripDates();
                            },
                            icon: const Icon(Icons.calendar_month),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Days',
                style: TextStyle(
                    color: Color(0xff454579),
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ),
            Flexible(
              flex: 2,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(125, 119, 255, 0.984),
                      Color.fromRGBO(255, 232, 173, 0.984),
                    ],
                  ),
                ),
                child: ReorderableListView(
                  children: [
                    for (final day in widget.trip.days)
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        key: ValueKey<TripDay>(day),
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white70,
                              borderRadius: BorderRadius.circular(20)),
                          child: Dismissible(
                            background: Container(
                              color: Colors.redAccent,
                            ),
                            key: ValueKey<TripDay>(day),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              if (widget.trip.days.length == 1) {
                                await showErrorDialog(context,
                                    'Failed to delete Day 1, trip must be at least 1 day long');
                                return null;
                              } else {
                                return await showDeleteDialog(context,
                                    'Day ${day.dayNumber.toString()}?');
                              }
                            },
                            onDismissed: (DismissDirection direction) async {
                              List<TripDay> tripDaysModified =
                                  widget.trip.days.toList();
                              DateTime updatedEndDate = widget.trip.endDate
                                  .subtract(const Duration(days: 1));
                              tripDaysModified.removeAt(day.dayNumber - 1);
                              for (var i = day.dayNumber - 1;
                                  i < tripDaysModified.length;
                                  i++) {
                                tripDaysModified[i].dayNumber = i + 1;
                                tripDaysModified[i].date = tripDaysModified[i]
                                    .date
                                    .subtract(const Duration(days: 1));
                              }
                              try {
                                await tripService
                                    .batchUpdateAfterTripDayDeletion(
                                        user.uid,
                                        widget.trip.tripId,
                                        day.dayId,
                                        tripDaysModified,
                                        updatedEndDate);
                                setState(() {
                                  widget.trip.endDate = updatedEndDate;
                                  widget.trip.days = tripDaysModified;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Day ${day.dayNumber} deleted'),
                                    ),
                                  );
                                });
                              } catch (e) {
                                await showErrorDialog(context,
                                    'Something went wrong, please try again later');
                              }
                            },
                            child: ListTile(
                              key: ValueKey(day),
                              leading: ElevatedButton(
                                onPressed: () async {
                                  await updateDayPlannedState(day);
                                },
                                style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(50, 50),
                                    backgroundColor: day.planned == false
                                        ? const Color.fromRGBO(
                                            201, 71, 71, 0.749)
                                        : const Color.fromRGBO(
                                            125, 119, 255, 1),
                                    shape: const CircleBorder()),
                                child: Text(
                                  day.dayNumber.toString(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text("Day ${day.dayNumber}"),
                              subtitle: Text(
                                  DateFormat('dd/MM/yyyy').format(day.date)),
                              onTap: () {
                                GoRouter.of(context).push(
                                    '/plan-future-trip-day?tripId=${widget.trip.tripId}',
                                    extra: day);
                              },
                              trailing: Container(
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                    shape: BoxShape.rectangle,
                                    color: day.checkpoints.isEmpty
                                        ? const Color.fromRGBO(
                                            201, 71, 71, 0.749)
                                        : const Color.fromRGBO(
                                            125, 119, 255, 1),
                                    borderRadius: BorderRadius.circular(50)),
                                child: Text(
                                  "Checkpoints: ${day.checkpoints.length}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                  ],
                  onReorder: (oldIndex, newIndex) async {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    if (oldIndex != newIndex) {
                      List<TripDay> tripDaysModified =
                          widget.trip.days.toList();
                      List<DateTime> allTripDates = datesBetween(
                          widget.trip.startDate, widget.trip.endDate);
                      final TripDay item = tripDaysModified.removeAt(oldIndex);
                      tripDaysModified.insert(newIndex, item);
                      for (var i = min(oldIndex, newIndex);
                          i <= max(oldIndex, newIndex);
                          i++) {
                        tripDaysModified[i].dayNumber = i + 1;
                        tripDaysModified[i].date = allTripDates[i];
                      }
                      try {
                        await tripService.batchUpdateAfterTripDayReorder(
                            user.uid, widget.trip.tripId, tripDaysModified);
                        setState(() {
                          widget.trip.days = tripDaysModified;
                        });
                      } catch (e) {
                        await showErrorDialog(context,
                            'Something went wrong, please try again later');
                      }
                    }
                  },
                ),
              ),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  int dayNumber = widget.trip.days.length + 1;
                  DateTime newDate =
                      widget.trip.days.last.date.add(const Duration(days: 1));
                  await tripService.batchUpdateAfterAddingNewTripDay(
                      user.uid, widget.trip.tripId, dayNumber, newDate);
                  List<TripDay> updatedDaysList = await tripService.getTripDays(
                      user.uid, widget.trip.tripId);
                  setState(() {
                    widget.trip.endDate = newDate;
                    widget.trip.days = updatedDaysList.toList();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Day $dayNumber has been added!'),
                      ),
                    );
                  });
                } catch (e) {
                  if (context.mounted) {
                    await showErrorDialog(context,
                        'Something went wrong, please try again later');
                  }
                }
              },
              child: const Text('Add new day'),
            ),
          ],
        ),
      ),
    );
  }
}
