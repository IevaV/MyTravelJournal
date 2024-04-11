import 'package:google_maps_flutter/google_maps_flutter.dart';

class Checkpoint {
  Checkpoint(
      this.checkpointId, this.chekpointNumber, this.title, this.coordinates,
      [this.marker]);

  String checkpointId;
  int chekpointNumber;
  String title;
  LatLng coordinates;
  late DateTime arrivalTime;
  late DateTime departureTime;
  Marker? marker;

  factory Checkpoint.fromFirestore(Map<String, dynamic> data) {
    LatLng coordinates = LatLng(data["latitude"], data["longitude"]);
    return Checkpoint(
      data["checkpointId"],
      data["checkpointNumber"],
      data["title"],
      coordinates,
    );
  }
}
