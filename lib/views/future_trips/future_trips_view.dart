import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mytraveljournal/models/trip.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:watch_it/watch_it.dart';

class FutureTripsView extends StatelessWidget with WatchItMixin {
  const FutureTripsView({super.key});

  @override
  Widget build(BuildContext context) {
    List<Trip> userFutureTrips =
        watchPropertyValue((User user) => user.userTrips);
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
                      return ListTile(
                        title: Text('Trip ${userFutureTrips[index].title}'),
                        onTap: () => GoRouter.of(context).push(
                            '/plan-future-trip',
                            extra: userFutureTrips[index]),
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
