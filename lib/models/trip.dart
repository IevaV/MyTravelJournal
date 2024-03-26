import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  Trip({
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
  });

  String title;
  String description;
  String startDate;
  String endDate;

  factory Trip.fromFirestore(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trip(
      title: data["title"] ?? "",
      description: data["description"] ?? "",
      startDate: data["startDate"] ?? "",
      endDate: data["endDate"] ?? "",
    );
  }
}
