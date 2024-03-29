import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mytraveljournal/components/dialog_components/show_error_dialog.dart';
import 'package:mytraveljournal/components/dialog_components/show_on_delete_dialog.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/trip.dart';
import 'package:mytraveljournal/models/trip_day.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:mytraveljournal/services/firestore/trip/trip_service.dart';
import 'package:mytraveljournal/utilities/date_helper.dart';

class PlanFutureTripView extends StatefulWidget {
  const PlanFutureTripView({super.key, required this.trip});

  final Trip trip;

  @override
  State<PlanFutureTripView> createState() => _PlanFutureTripViewState();
}

class _PlanFutureTripViewState extends State<PlanFutureTripView> {
  @override
  Widget build(BuildContext context) {
    TripService tripService = getIt<TripService>();
    User user = getIt<User>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Plan Your Trip'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            //mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                flex: 1,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(widget.trip.title),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(widget.trip.description),
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
                flex: 1,
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
                          List<TripDay> tripDaysModified = widget.trip.days;
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
                            tripService.batchUpdateAfterTripDayDeletion(
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
                          title: Text("Day ${day.dayNumber}"),
                          subtitle:
                              Text("${day.dayId} and ${day.date.toString()}"),
                        ),
                      )
                  ],
                  onReorder: (oldIndex, newIndex) async {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    if (oldIndex != newIndex) {
                      List<TripDay> tripDaysModified = widget.trip.days;
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
                        tripService.batchUpdateAfterTripDayReorder(
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
            ],
          ),
        ),
      ),
    );
  }
}
