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

class FutureTripsView extends StatelessWidget with WatchItMixin {
  const FutureTripsView({super.key});

  @override
  Widget build(BuildContext context) {
    User user = getIt<User>();
    TripService tripService = getIt<TripService>();
    FirebaseStorageService firebaseStorageService =
        getIt<FirebaseStorageService>();
    List<Trip> userFutureTrips = watchIt<User>()
        .userTrips
        .where((trip) => trip.state == "planning")
        .toList();
    for (var trip in userFutureTrips) {
      watch(trip);
    }
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
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Continue planning",
                    style: TextStyle(
                      fontSize: 26,
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
              ),
              Flexible(
                flex: 3,
                child: ListView.separated(
                    separatorBuilder: (context, index) {
                      return const SizedBox(
                        height: 25.0,
                      );
                    },
                    padding: const EdgeInsets.all(8),
                    itemCount: userFutureTrips.length,
                    itemBuilder: (BuildContext context, int index) {
                      Trip trip = userFutureTrips[index];
                      return Container(
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
                            padding: EdgeInsets.all(8.0),
                            child: ListTile(
                              title: Text(
                                textAlign: TextAlign.center,
                                trip.title,
                                style: const TextStyle(
                                    fontSize: 30,
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
                              // TODO Create subtitle that shows how many days are in "planned" state for trip
                              // subtitle: Text(
                              //     '${userFutureTrips[index].days.where((day) => day.planned == true).length}/${userFutureTrips[index].days.length} days planned'),
                              onTap: () => GoRouter.of(context)
                                  .push('/plan-future-trip', extra: trip),
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
                      );
                    }),
              ),
              Flexible(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () => GoRouter.of(context).push(
                          '/add-future-trip',
                          extra: {"tripType": "planning"}),
                      child: const Text('Plan new trip'),
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
