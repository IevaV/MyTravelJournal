import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as devtools show log;

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
}
