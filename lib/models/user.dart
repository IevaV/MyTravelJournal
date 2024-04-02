import 'package:flutter/material.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/trip.dart';
import 'package:mytraveljournal/services/firestore/trip/trip_service.dart';

class User extends ChangeNotifier {
  User();

  late String uid;
  final List<Trip> userTrips = [];

  void addTrip(Trip trip) {
    userTrips.insert(0, trip);
    notifyListeners();
  }

  Future<void> assignUserData(String uid) async {
    this.uid = uid;
    getIt<TripService>().listenToUserTrips();
  }
}
