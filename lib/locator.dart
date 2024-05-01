import 'package:get_it/get_it.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:mytraveljournal/services/firebase_storage/firebase_storage_service.dart';
import 'package:mytraveljournal/services/firestore/trip/trip_service.dart';
import 'package:mytraveljournal/services/firestore/user/user_service.dart';
import 'package:mytraveljournal/services/google_maps/google_maps_service.dart';
import 'package:mytraveljournal/services/location/location_service.dart';

GetIt getIt = GetIt.instance;

void initializeLocators() {
  getIt.allowReassignment = true;

  // Models
  getIt.registerLazySingleton<User>(() => User());

  // Services
  getIt.registerLazySingleton<TripService>(() => TripService());
  getIt.registerLazySingleton<FirebaseStorageService>(
      () => FirebaseStorageService());
  getIt.registerLazySingleton<UserService>(() => UserService());
  getIt.registerLazySingleton<LocationService>(() => LocationService());
  getIt.registerLazySingleton<GoogleMapsService>(() => GoogleMapsService());
}
