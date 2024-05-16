import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mytraveljournal/components/dialog_components/show_error_dialog.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/checkpoint.dart';
import 'package:mytraveljournal/models/trip.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:mytraveljournal/services/firestore/trip/trip_service.dart';
import 'package:mytraveljournal/utilities/date_helper.dart';
import 'package:mytraveljournal/utilities/date_time_apis.dart';
import 'package:watch_it/watch_it.dart';

class HomeView extends StatelessWidget with WatchItMixin {
  HomeView({super.key});
  final User user = getIt<User>();
  final TripService tripService = getIt<TripService>();

  Column homeViewState(BuildContext context) {
    Trip? closestTrip;
    if (user.ongoingTrip != null &&
        DateTime.now().isAfter(user.ongoingTrip!.endDate)) {
      callOnce((context) async {
        try {
          await tripService.updateTrip(
              user.uid, user.ongoingTrip!.tripId, {"state": "past"});
          user.ongoingTrip = null;
        } catch (e) {
          await showErrorDialog(
              context, 'Something went wrong, please try again later');
        }
      });
    }
    user.ongoingTrip ??= user.userTrips
        .firstWhereOrNull((trip) => trip.startDate.isSameDate(DateTime.now()));
    if (user.ongoingTrip == null) {
      for (var trip in user.userTrips) {
        if (closestTrip == null && trip.startDate.isAfter(DateTime.now())) {
          closestTrip ??= trip;
        } else if (trip.startDate.isAfter(DateTime.now()) &&
            daysBetween(trip.startDate, DateTime.now()) <
                daysBetween(closestTrip!.startDate, DateTime.now())) {
          closestTrip = trip;
        }
      }
    }
    if (user.ongoingTrip != null) {
      callOnce((context) async {
        for (var i = 0; i < user.ongoingTrip!.days.length; i++) {
          List<Checkpoint> tripCheckpoints =
              await tripService.getTripDayCheckpoints(user.uid,
                  user.ongoingTrip!.tripId, user.ongoingTrip!.days[i].dayId);
          user.ongoingTrip!.days[i].checkpoints = tripCheckpoints;
        }
        try {
          await tripService.updateTrip(
              user.uid, user.ongoingTrip!.tripId, {"state": "ongoing"});
        } catch (e) {
          user.ongoingTrip = null;
          await showErrorDialog(
              context, 'Something went wrong, please try again later');
        }
      });
      return Column(
        children: [
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, top: 8.0),
                  child: Text(
                    "Ongoing trip",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: Offset(0.0, 3.0),
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  elevation: 0,
                  color: Colors.white70,
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    splashColor: Colors.blue.withAlpha(50),
                    onTap: () => GoRouter.of(context)
                        .push('/ongoing-trip', extra: user.ongoingTrip!),
                    child: Column(
                      children: [
                        ListTile(
                          title: Center(
                            child: Text(
                              user.ongoingTrip!.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 25,
                                color: Color(0xff454579),
                              ),
                            ),
                          ),
                          subtitle: Center(
                            child: Text(
                              "${DateFormat('dd/MM/yyyy').format(user.ongoingTrip!.startDate)} - ${DateFormat('dd/MM/yyyy').format(user.ongoingTrip!.endDate)}",
                              style: const TextStyle(
                                color: Color(0xff454579),
                              ),
                            ),
                          ),
                          enableFeedback: false,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 8.0, right: 10.0),
                              child: Container(
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.rectangle,
                                  color: const Color.fromRGBO(125, 119, 255, 1),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(
                                  "Day: ${daysBetween(DateTime.now(), user.ongoingTrip!.startDate) + 1}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      );
    } else if (user.ongoingTrip == null && closestTrip != null) {
      return Column(
        children: [
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, top: 10.0, bottom: 10.0),
                  child: Text(
                    "Closest trip",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: Offset(0.0, 3.0),
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  elevation: 0,
                  color: Colors.white70,
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    splashColor: Colors.blue.withAlpha(50),
                    onTap: () => GoRouter.of(context)
                        .push('/plan-future-trip', extra: closestTrip),
                    child: Column(
                      children: [
                        ListTile(
                          title: Center(
                            child: Text(
                              closestTrip.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 25,
                                color: Color(0xff454579),
                              ),
                            ),
                          ),
                          subtitle: Center(
                            child: Text(
                              "${DateFormat('dd/MM/yyyy').format(closestTrip.startDate)} - ${DateFormat('dd/MM/yyyy').format(closestTrip.endDate)}",
                              style: const TextStyle(
                                color: Color(0xff454579),
                              ),
                            ),
                          ),
                          enableFeedback: false,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 10.0, right: 10.0),
                              child: Container(
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                    shape: BoxShape.rectangle,
                                    color:
                                        const Color.fromRGBO(125, 119, 255, 1),
                                    borderRadius: BorderRadius.circular(50)),
                                child: Text(
                                  "Days left: ${daysBetween(closestTrip.startDate, DateTime.now())}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      );
    } else {
      return Column(
        children: [
          const Text("You don't have any planned trips yet!"),
          FilledButton(
              onPressed: () => {GoRouter.of(context).push('/add-future-trip')},
              child: const Text('Plan your first trip!'))
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: homeViewState(context),
          ),
        ),
      ),
    );
  }
}
