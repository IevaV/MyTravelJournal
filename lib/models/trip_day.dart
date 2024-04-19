import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mytraveljournal/models/checkpoint.dart';

class TripDay extends ChangeNotifier {
  TripDay(
      {required this.dayId,
      required this.dayNumber,
      required this.date,
      this.checkpoints = const [],
      this.planned = false});

  String dayId;
  int dayNumber;
  DateTime date;
  List<Checkpoint> checkpoints;
  bool planned;

  factory TripDay.fromFirestore(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TripDay(
      dayId: doc.id,
      dayNumber: data["dayNumber"] ?? 0,
      date: data["date"].toDate() ?? DateTime.now(),
      checkpoints: [],
      planned: data["planned"] ?? false,
    );
  }

  void updateDayStatus(bool planned) {
    this.planned = planned;
    notifyListeners();
  }

  void addCheckpoint(Checkpoint checkpoint) {
    checkpoints.add(checkpoint);
    notifyListeners();
  }
}
