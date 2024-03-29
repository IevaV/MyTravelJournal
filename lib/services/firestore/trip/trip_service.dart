import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mytraveljournal/models/trip.dart';
import 'package:mytraveljournal/models/trip_day.dart';
import 'package:mytraveljournal/utilities/date_helper.dart';

class TripService {
  TripService();

  final _db = FirebaseFirestore.instance;

  Future<DocumentReference<Object?>> addNewTrip(String uid, String title,
      String description, DateTime startDate, DateTime endDate) async {
    final data = <String, dynamic>{
      "title": title,
      "description": description,
      "startDate": Timestamp.fromDate(startDate),
      "endDate": Timestamp.fromDate(endDate),
    };
    return await _db.collection("users").doc(uid).collection("trips").add(data);
  }

  List<Trip> getUserTrips(String uid) {
    List<Trip> userTrips = [];
    _db
        .collection("users")
        .doc(uid)
        .collection("trips")
        .get()
        .then((querySnapshot) {
      for (var trip in querySnapshot.docs) {
        userTrips.add(Trip.fromFirestore(trip));
      }
    });
    return userTrips;
  }

  List<TripDay> getTripDays(String uid, String tripId) {
    List<TripDay> tripDays = [];
    _db
        .collection("users")
        .doc(uid)
        .collection("trips")
        .doc(tripId)
        .collection("days")
        .orderBy('dayNumber')
        .snapshots()
        .forEach((querySnapshot) {
      for (var tripDay in querySnapshot.docs) {
        tripDays.add(TripDay.fromFirestore(tripDay));
      }
    });
    return tripDays;
  }

  addNewTripDay(String uid, String tripId, int dayNumber, DateTime date) async {
    final data = <String, dynamic>{
      "dayNumber": dayNumber,
      "date": Timestamp.fromDate(date),
    };
    await _db
        .collection("users")
        .doc(uid)
        .collection("trips")
        .doc(tripId)
        .collection("days")
        .add(data);
  }

  void generateDaysForTrip(
      DateTime startDate, DateTime endDate, String uid, String tripId) async {
    List<DateTime> dates = datesBetween(startDate, endDate);
    for (var i = 0; i < dates.length; i++) {
      await addNewTripDay(uid, tripId, i + 1, dates[i]);
    }
  }

  void updateTripDay(
      String uid, String tripId, String dayId, Map<String, dynamic> data) {
    _db
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(tripId)
        .collection("days")
        .doc(dayId)
        .update(data);
  }
}
