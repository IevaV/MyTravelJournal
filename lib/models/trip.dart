import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/trip_day.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:mytraveljournal/services/firestore/trip/trip_service.dart';

class Trip {
  Trip(
      {required this.tripId,
      required this.title,
      required this.description,
      required this.startDate,
      required this.endDate,
      this.days = const []});

  String tripId;
  String title;
  String description;
  DateTime startDate;
  DateTime endDate;
  List<TripDay> days;

  factory Trip.fromFirestore(QueryDocumentSnapshot doc) {
    final tripService = getIt<TripService>();
    final user = getIt<User>();
    final data = doc.data() as Map<String, dynamic>;
    List<TripDay> tripDays = tripService.getTripDays(user.uid, doc.id);
    return Trip(
      tripId: doc.id,
      title: data["title"] ?? "",
      description: data["description"] ?? "",
      startDate: data["startDate"].toDate() ?? DateTime.now(),
      endDate: data["endDate"].toDate() ?? DateTime.now(),
      days: tripDays,
    );
  }
}
