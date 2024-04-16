import 'dart:math';
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

  @override
  void initState() {
    _description = TextEditingController();
    _description.text = widget.trip.description;
    super.initState();
  }

  @override
  void dispose() {
    _description.dispose();
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
    });
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.trip.title),
        centerTitle: true,
        leading: BackButton(
          onPressed: () async {
            while (context.canPop()) {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            //mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                flex: 2,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
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
                            labelText: 'Description',
                            filled: true,
                            border: InputBorder.none,
                            suffixIcon: descriptionEdited
                                ? IconButton(
                                    onPressed: () async {
                                      try {
                                        await tripService.updateTrip(
                                            user.uid,
                                            widget.trip.tripId,
                                            <String, dynamic>{
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
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(widget.trip.startDate.toString()),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(widget.trip.endDate.toString()),
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 3,
                child: ReorderableListView(
                  children: [
                    for (final day in widget.trip.days)
                      Dismissible(
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
                            return await showDeleteDialog(
                                context, 'Day ${day.dayNumber.toString()}?');
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
                            await tripService.batchUpdateAfterTripDayDeletion(
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
                                  content: Text('Day ${day.dayNumber} deleted'),
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
                                backgroundColor: day.planned == false
                                    ? Colors.grey
                                    : Colors.green,
                                shape: const CircleBorder()),
                            child: Text(day.dayNumber.toString()),
                          ),
                          title: Text("Day ${day.dayNumber}"),
                          subtitle:
                              Text("${day.dayId} and ${day.date.toString()}"),
                          onTap: () {
                            GoRouter.of(context).push(
                                '/plan-future-trip-day?tripId=${widget.trip.tripId}',
                                extra: day);
                          },
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
              Flexible(
                flex: 1,
                child: FilledButton(
                  onPressed: () async {
                    try {
                      int dayNumber = widget.trip.days.length + 1;
                      DateTime newDate = widget.trip.days.last.date
                          .add(const Duration(days: 1));
                      await tripService.batchUpdateAfterAddingNewTripDay(
                          user.uid, widget.trip.tripId, dayNumber, newDate);
                      List<TripDay> updatedDaysList = await tripService
                          .getTripDays(user.uid, widget.trip.tripId);
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
