import 'dart:math';

import 'package:flutter/material.dart';
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
                          color: Colors.green,
                        ),
                        key: ValueKey<TripDay>(day),
                        onDismissed: (DismissDirection direction) {
                          setState(() {
                            print('DELETES day');
                            // items.removeAt(index);
                          });
                        },
                        child: ListTile(
                          key: ValueKey(day),
                          title: Text("Day ${day.dayNumber}"),
                          subtitle:
                              Text("${day.dayId} and ${day.date.toString()}"),
                        ),
                      )
                  ],
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    if (oldIndex != newIndex) {
                      setState(() {
                        List<DateTime> allTripDates = datesBetween(
                            widget.trip.startDate, widget.trip.endDate);
                        print("oldIndex: $oldIndex");
                        print("newIndex: $newIndex");

                        final TripDay item =
                            widget.trip.days.removeAt(oldIndex);
                        widget.trip.days.insert(newIndex, item);
                        for (var i = min(oldIndex, newIndex);
                            i <= max(oldIndex, newIndex);
                            i++) {
                          widget.trip.days[i].dayNumber = i + 1;
                          widget.trip.days[i].date = allTripDates[i];
                          Map<String, dynamic> dataToUpdate = { "dayNumber": widget.trip.days[i].dayNumber, "date": widget.trip.days[i].date };
                          tripService.updateTripDay(user.uid, widget.trip.tripId, widget.trip.days[i].dayId, dataToUpdate);
                        }
                      });
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
