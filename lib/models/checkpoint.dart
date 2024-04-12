import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Checkpoint {
  Checkpoint({ required this.chekpointNumber, required this.address, required this.coordinates,
      this.marker, this.checkpointId, this.title});

  int chekpointNumber;
  String? checkpointId;
  String? title;
  String address;
  LatLng coordinates;
  late DateTime arrivalTime;
  late DateTime departureTime;
  Marker? marker;

  factory Checkpoint.fromFirestore(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    LatLng coordinates = LatLng(data["latitude"], data["longitude"]);
    return Checkpoint(
      chekpointNumber: data["checkpointNumber"],
      address: data["address"],
      coordinates: coordinates,
      title: data["title"] ?? '',
      checkpointId: doc.id,
    );
  }
}
