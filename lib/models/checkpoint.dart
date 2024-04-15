import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

class Checkpoint {
  Checkpoint(
      {required this.chekpointNumber,
      required this.address,
      required this.coordinates,
      required this.marker,
      this.checkpointId,
      this.title,
      this.polyline});

  int chekpointNumber;
  String? checkpointId;
  String? title;
  String address;
  LatLng coordinates;
  late DateTime arrivalTime;
  late DateTime departureTime;
  Marker marker;
  Polyline? polyline;
  // List<LatLng>? polylineCoordinates;

  factory Checkpoint.fromFirestore(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    LatLng coordinates =
        LatLng(data["coordinates"].latitude, data["coordinates"].longitude);
    Polyline? polyline;
    List<LatLng> polylineCoordinates = [];
    Marker marker = Marker(
      markerId: MarkerId("Checkpoint ${data["checkpointNumber"]}"),
      position: coordinates,
      infoWindow: InfoWindow(
        title: "Checkpoint ${data["checkpointNumber"]}",
        snippet: data["address"],
      ),
    );
    if (data["polylineCoordinates"] != null) {
      List<dynamic> geopoints = data["polylineCoordinates"] as List;
      for (var geopoint in geopoints) {
        polylineCoordinates.add(LatLng(geopoint.latitude, geopoint.longitude));
      }
      polyline = Polyline(
          polylineId: PolylineId(const Uuid().v4()),
          points: polylineCoordinates,
          color: Colors.blue.withOpacity(0.75));
    }

    return Checkpoint(
      chekpointNumber: data["checkpointNumber"],
      address: data["address"],
      coordinates: coordinates,
      title: data["title"] ?? '',
      checkpointId: doc.id,
      polyline: polyline,
      marker: marker,
    );
  }
}
