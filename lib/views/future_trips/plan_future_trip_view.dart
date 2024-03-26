import 'package:flutter/material.dart';
import 'package:mytraveljournal/models/trip.dart';

class PlanFutureTripView extends StatelessWidget {
  const PlanFutureTripView({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Plan Your Trip'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                child: Text(trip.title),
              ),
              Container(
                padding: const EdgeInsets.all(10.0),
                child: Text(trip.description),
              ),
              Container(
                padding: const EdgeInsets.all(10.0),
                child: Text(trip.startDate),
              ),
              Container(
                padding: const EdgeInsets.all(10.0),
                child: Text(trip.endDate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
