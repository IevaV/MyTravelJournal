import 'package:flutter/material.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/trip.dart';
import 'package:mytraveljournal/services/firestore/trip/trip_service.dart';

class User extends ChangeNotifier {
  User();

  late String uid;
  late List<Trip> userTrips;

  void addTrip(Trip trip) {
    userTrips.add(trip);
    notifyListeners();
  }

  void assignUserData(String uid) {
    this.uid = uid;
    userTrips = getIt<TripService>().getUserTrips(uid);
  }
}
