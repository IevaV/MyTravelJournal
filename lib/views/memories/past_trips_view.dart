import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mytraveljournal/components/dialog_components/show_error_dialog.dart';
import 'package:mytraveljournal/components/dialog_components/show_on_delete_dialog.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/trip.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:mytraveljournal/services/firebase_storage/firebase_storage_service.dart';
import 'package:mytraveljournal/services/firestore/trip/trip_service.dart';
import 'package:watch_it/watch_it.dart';

class PastTripsView extends StatefulWidget with WatchItStatefulWidgetMixin {
  const PastTripsView({super.key});

  @override
  State<PastTripsView> createState() => _PastTripsViewState();
}

class _PastTripsViewState extends State<PastTripsView> {
  @override
  Widget build(BuildContext context) {
    User user = getIt<User>();
    TripService tripService = getIt<TripService>();
    FirebaseStorageService firebaseStorageService =
        getIt<FirebaseStorageService>();
    List<Trip> userTrips = watchIt<User>().userTrips;
    userTrips.sort(
      (a, b) => b.startDate.year.compareTo(a.startDate.year),
    );
    List<Trip> userPastTrips =
        userTrips.where((trip) => trip.state == "past").toList();
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
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8.0, top: 10.0, bottom: 10.0),
                child: Text(
                  "Memories",
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
              Flexible(
                flex: 7,
                child: ListView.builder(
                  itemCount: userPastTrips.length,
                  itemBuilder: (BuildContext context, int index) {
                    Trip trip = userPastTrips[index];
                    int? previousTripYear = index > 0
                        ? userPastTrips[index - 1].startDate.year
                        : null;
                    return Column(
                      children: [
                        trip.startDate.year != previousTripYear
                            ? Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 8, top: 8, right: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 45,
                                      width: 175,
                                      decoration: const BoxDecoration(
                                          shape: BoxShape.rectangle,
                                          color: Color(0xff46467A),
                                          borderRadius: BorderRadius.only(
                                              topRight: Radius.circular(25.0),
                                              bottomRight:
                                                  Radius.circular(25.0))),
                                      child: Center(
                                        child: Text(
                                          trip.startDate.year.toString(),
                                          style: const TextStyle(
                                              fontSize: 24,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                                color: Colors.white70,
                                borderRadius: BorderRadius.circular(20)),
                            child: Dismissible(
                              key: ValueKey<Trip>(trip),
                              background: Container(
                                color: Colors.redAccent,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(0),
                                  title: Text(
                                    textAlign: TextAlign.center,
                                    trip.title,
                                    style: const TextStyle(
                                        fontSize: 28,
                                        color: Color(0xff46467A),
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          "${DateFormat('dd/MM/yyyy').format(trip.startDate)} - ${DateFormat('dd/MM/yyyy').format(trip.endDate)}",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Color(0xff454579),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  onTap: () {
                                    GoRouter.of(context).push(
                                        '/past-trip-memories',
                                        extra: trip);
                                  },
                                  leading: const SizedBox(),
                                  trailing: IconButton(
                                    onPressed: () {
                                      GoRouter.of(context).push(
                                          '/plan-future-trip',
                                          extra: trip);
                                    },
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDeleteDialog(
                                    context, 'trip "${trip.title}"?');
                              },
                              onDismissed: (direction) async {
                                await firebaseStorageService
                                    .deleteAllFilesInDirectory(
                                        "${user.uid}/${trip.tripId}/files");
                                try {
                                  await tripService.deleteTrip(
                                      user.uid, trip.tripId);
                                  user.userTrips.remove(trip);
                                } catch (e) {
                                  await showErrorDialog(context,
                                      'Something went wrong, please try again later');
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Flexible(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () => GoRouter.of(context).push(
                          '/add-future-trip',
                          extra: {"tripType": "past"}),
                      child: const Text('Add past trip'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
