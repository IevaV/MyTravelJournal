import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mytraveljournal/components/dialog_components/show_error_dialog.dart';
import 'package:mytraveljournal/components/dialog_components/show_on_delete_dialog.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/trip.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:mytraveljournal/services/firestore/trip/trip_service.dart';
import 'package:watch_it/watch_it.dart';

class FutureTripsView extends StatelessWidget with WatchItMixin {
  const FutureTripsView({super.key});

  @override
  Widget build(BuildContext context) {
    User user = getIt<User>();
    TripService tripService = getIt<TripService>();
    List<Trip> userFutureTrips = watchIt<User>().userTrips;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Planned Trips'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Flexible(
                flex: 3,
                child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: userFutureTrips.length,
                    itemBuilder: (BuildContext context, int index) {
                      Trip trip = userFutureTrips[index];
                      return Dismissible(
                        key: ValueKey<Trip>(trip),
                        background: Container(
                          color: Colors.redAccent,
                        ),
                        child: ListTile(
                          title: Text(trip.title),
                          // TODO Create subtitle that shows how many days are in "planned" state for trip
                          // subtitle: Text(
                          //     '${userFutureTrips[index].days.where((day) => day.planned == true).length}/${userFutureTrips[index].days.length} days planned'),
                          onTap: () => GoRouter.of(context)
                              .push('/plan-future-trip', extra: trip),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDeleteDialog(
                              context, 'trip "${trip.title}"?');
                        },
                        onDismissed: (direction) async {
                          try {
                            await tripService.deleteTrip(user.uid, trip.tripId);
                            user.userTrips.remove(trip);
                          } catch (e) {
                            await showErrorDialog(context,
                                'Something went wrong, please try again later');
                          }
                        },
                      );
                    }),
              ),
              Flexible(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () =>
                          GoRouter.of(context).push('/add-future-trip'),
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
