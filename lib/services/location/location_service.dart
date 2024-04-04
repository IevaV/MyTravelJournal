import 'package:location/location.dart';

class LocationService {
  final Location location = Location();

  Future<LocationData> getCurrentLocation() async {
    return await location.getLocation();
  }

  getServiceEnabled() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }
  }

  getPermissionStatus() async {
    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
  }
}
