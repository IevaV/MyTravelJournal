import 'package:flutter/material.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/trip_day.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:mytraveljournal/services/firestore/trip/trip_service.dart';

class Trip extends ChangeNotifier {
  Trip({
    required this.tripId,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.days = const [],
    this.state = "planning",
  });

  String tripId;
  String title;
  String description;
  DateTime startDate;
  DateTime endDate;
  List<TripDay> days;
  DateTime createdAt;
  String state;

  static Future<Trip> createTrip(String id, Map<String, dynamic>? data) async {
    final tripService = getIt<TripService>();
    final user = getIt<User>();
    List<TripDay> tripDays = await tripService.getTripDays(user.uid, id);
    return Trip(
      tripId: id,
      title: data?["title"] ?? "",
      description: data?["description"] ?? "",
      startDate: data?["startDate"].toDate() ?? DateTime.now(),
      endDate: data?["endDate"].toDate() ?? DateTime.now(),
      createdAt: data?["createdAt"] != null
          ? data!["createdAt"].toDate()
          : DateTime.now(),
      days: tripDays,
      state: data?["state"] != null ? data!["state"] : "planning",
    );
  }

  void updateTitle(String title) {
    this.title = title;
    notifyListeners();
  }
}
