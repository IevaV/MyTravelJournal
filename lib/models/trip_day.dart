import 'package:cloud_firestore/cloud_firestore.dart';

class TripDay {
  TripDay({required this.dayId, required this.dayNumber, required this.date});

  String dayId;
  int dayNumber;
  DateTime date;

  factory TripDay.fromFirestore(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    print(data.toString());
    return TripDay(
      dayId: doc.id,
      dayNumber: data["dayNumber"] ?? 0,
      date: data["date"].toDate() ?? DateTime.now(),
    );
  }
}
