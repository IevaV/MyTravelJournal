import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mytraveljournal/models/trip.dart';

class TripService {
  TripService();

  final _db = FirebaseFirestore.instance;

  addNewTrip(String uid, String title, String description, String startDate,
      String endDate) {
    final data = <String, dynamic>{
      "title": title,
      "description": description,
      "startDate": startDate,
      "endDate": endDate,
    };
    _db.collection("users").doc(uid).collection("trips").add(data);
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
}
