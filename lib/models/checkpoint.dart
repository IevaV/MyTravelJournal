import 'package:google_maps_flutter/google_maps_flutter.dart';

class Checkpoint {
  Checkpoint(this.title, this.coordinates, this.marker);

  String title;
  LatLng coordinates;
  late DateTime arrivalTime;
  late DateTime departureTime;
  Marker marker;
}
