import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mytraveljournal/config.dart';

class GoogleMapsService {
  Future<http.Response> fetchPlacesAutocompleteResults(String searchInput) {
    Map<String, String> data = {"input": searchInput};
    return http.post(
        Uri.parse('https://places.googleapis.com/v1/places:autocomplete'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': googleMapsAPIKey
        },
        body: jsonEncode(data));
  }

  Future<http.Response> fetchPlaceLocationData(String placeId) {
    return http.get(
      Uri.parse('https://places.googleapis.com/v1/places/$placeId'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': googleMapsAPIKey,
        'X-Goog-FieldMask': 'location'
      },
    );
  }

  Future<http.Response> fetchAddressFromLocation(LatLng latLng) {
    return http.get(Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$googleMapsAPIKey'));
  }
}
