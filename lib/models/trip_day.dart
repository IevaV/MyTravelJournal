import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mytraveljournal/models/checkpoint.dart';

class TripDay {
  TripDay(
      {required this.dayId,
      required this.dayNumber,
      required this.date,
      this.checkpoints = const []});

  String dayId;
  int dayNumber;
  DateTime date;
  List<Checkpoint> checkpoints;

  factory TripDay.fromFirestore(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TripDay(
      dayId: doc.id,
      dayNumber: data["dayNumber"] ?? 0,
      date: data["date"].toDate() ?? DateTime.now(),
    );
  }
}
