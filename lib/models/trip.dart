import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/trip_day.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:mytraveljournal/services/firestore/trip/trip_service.dart';

class Trip {
  Trip({
    required this.tripId,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.days = const [],
  });

  String tripId;
  String title;
  String description;
  DateTime startDate;
  DateTime endDate;
  List<TripDay> days;
  DateTime createdAt;

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
      createdAt: data?["createdAt"] != null ? data!["createdAt"].toDate() : DateTime.now(),
      days: tripDays,
    );
  }
}
