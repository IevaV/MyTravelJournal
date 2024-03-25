import 'package:get_it/get_it.dart';
import 'package:mytraveljournal/services/firestore/trip/trip_service.dart';
import 'package:mytraveljournal/services/firestore/user/user_service.dart';

GetIt getIt = GetIt.instance;

void initializeLocators() {
  getIt.allowReassignment = true;

  getIt.registerLazySingleton<TripService>(() => TripService());
  getIt.registerLazySingleton<UserService>(() => UserService());
}
