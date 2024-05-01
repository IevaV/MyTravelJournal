import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

class Checkpoint {
  Checkpoint({
    required this.chekpointNumber,
    required this.address,
    required this.coordinates,
    required this.marker,
    required this.expenses,
    required this.fileNames,
    this.checkpointId,
    this.title,
    this.polyline,
    this.isVisited = false,
    this.departureTime,
    this.arrivalTime,
    this.polylineDuration,
    this.notes = "",
  });

  int chekpointNumber;
  String? checkpointId;
  String? title;
  String address;
  String? polylineDuration;
  String notes;
  LatLng coordinates;
  TimeOfDay? arrivalTime;
  TimeOfDay? departureTime;
  Marker marker;
  Polyline? polyline;
  bool isVisited;
  List<Map<String, dynamic>> expenses;
  List<String> fileNames;

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
    print(
        "${data["expenses"]} and this is Checkpoint ${data["checkpointNumber"]} ");
    return Checkpoint(
      chekpointNumber: data["checkpointNumber"],
      address: data["address"],
      coordinates: coordinates,
      title: data["title"] ?? '',
      checkpointId: doc.id,
      polyline: polyline,
      marker: marker,
      isVisited: data["isVisited"] ?? false,
      departureTime: data["departureTime"] != null
          ? TimeOfDay(
              hour: data["departureTime"]["hour"],
              minute: data["departureTime"]["minute"])
          : null,
      arrivalTime: data["arrivalTime"] != null
          ? TimeOfDay(
              hour: data["arrivalTime"]["hour"],
              minute: data["arrivalTime"]["minute"])
          : null,
      polylineDuration: data["polylineDuration"],
      expenses: data["expenses"] == null
          ? []
          : (data["expenses"] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList(),
      fileNames: data["fileNames"] == null
          ? []
          : List<String>.from(data["fileNames"] as List),
      notes: data["notes"] ?? "",
    );
  }
}
