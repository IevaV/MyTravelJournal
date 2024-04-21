import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mytraveljournal/models/checkpoint.dart';
import 'package:mytraveljournal/models/trip.dart';
import 'package:mytraveljournal/models/trip_day.dart';
import 'package:mytraveljournal/utilities/date_helper.dart';

class TripService {
  TripService();

  final _db = FirebaseFirestore.instance;
  late final StreamSubscription<QuerySnapshot> userTripListener;

  // Trip

  Future<List<Trip>> getAllUserTrips(String uid) async {
    List<Trip> trips = [];
    await _db
        .collection("users")
        .doc(uid)
        .collection("trips")
        .orderBy("createdAt", descending: true)
        .get()
        .then((querySnapshot) async {
      for (var tripDay in querySnapshot.docs) {
        trips.add(await Trip.createTrip(tripDay.id, tripDay.data()));
      }
    });
    return trips;
  }

  Future<void> updateTrip(
      String uid, String tripId, Map<String, dynamic> data) async {
    await _db
        .collection("users")
        .doc(uid)
        .collection("trips")
        .doc(tripId)
        .update(data);
  }

  Future<void> deleteTrip(String uid, String tripId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(tripId)
        .delete();
  }

  Future<Trip> getLatestUserTrip(String uid) {
    return _db
        .collection("users")
        .doc(uid)
        .collection("trips")
        .orderBy("createdAt", descending: true)
        .limit(1)
        .get()
        .then((querySnapshot) async {
      return await Trip.createTrip(
          querySnapshot.docs.first.id, querySnapshot.docs.first.data());
    });
  }

  Future<void> batchUpdateAfterAddingNewTrip(String uid, String title,
      String description, DateTime startDate, DateTime endDate) async {
    final batch = _db.batch();

    // Add new trip
    var tripRef = _db.collection('users').doc(uid).collection('trips').doc();
    final tripData = <String, dynamic>{
      "title": title,
      "description": description,
      "startDate": Timestamp.fromDate(startDate),
      "endDate": Timestamp.fromDate(endDate),
      "createdAt": Timestamp.fromDate(DateTime.now()),
    };
    batch.set(tripRef, tripData);

    // Add trip days to trip
    List<DateTime> dates = datesBetween(startDate, endDate);
    for (var i = 0; i < dates.length; i++) {
      var tripDaysRef = _db
          .collection('users')
          .doc(uid)
          .collection('trips')
          .doc(tripRef.id)
          .collection('days')
          .doc();
      final daysData = <String, dynamic>{
        "dayNumber": i + 1,
        "date": Timestamp.fromDate(dates[i]),
      };
      batch.set(tripDaysRef, daysData);
    }

    await batch.commit();
  }

  // Trip Days

  Future<List<TripDay>> getTripDays(String uid, String tripId) async {
    List<TripDay> tripDays = [];
    await _db
        .collection("users")
        .doc(uid)
        .collection("trips")
        .doc(tripId)
        .collection("days")
        .orderBy('dayNumber')
        .get()
        .then((querySnapshot) {
      for (var tripDay in querySnapshot.docs) {
        tripDays.add(TripDay.fromFirestore(tripDay));
      }
    });
    return tripDays;
  }

  Future<void> updateTripDay(String uid, String tripId, String dayId,
      Map<String, dynamic> data) async {
    await _db
        .collection("users")
        .doc(uid)
        .collection("trips")
        .doc(tripId)
        .collection("days")
        .doc(dayId)
        .update(data);
  }

  Future<void> batchUpdateAfterTripDayDeletion(String uid, String tripId,
      String dayId, List<TripDay> tripDays, DateTime newEndDate) async {
    final batch = _db.batch();

    // Find day to delete and add it to batch
    var dayRef = _db
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(tripId)
        .collection("days")
        .doc(dayId);
    batch.delete(dayRef);

    // Update dayNumber and date for the remaining days after deletion
    for (var day in tripDays) {
      var updateDayRef = _db
          .collection('users')
          .doc(uid)
          .collection('trips')
          .doc(tripId)
          .collection("days")
          .doc(day.dayId);
      batch
          .update(updateDayRef, {"dayNumber": day.dayNumber, "date": day.date});
    }

    // Update trip endDate
    var tripRef =
        _db.collection('users').doc(uid).collection('trips').doc(tripId);
    batch.update(tripRef, {"endDate": Timestamp.fromDate(newEndDate)});

    await batch.commit();
  }

  Future<void> batchUpdateAfterTripDayReorder(
      String uid, String tripId, List<TripDay> tripDays) async {
    final batch = _db.batch();

    // Update dayNumber and date for days after reorder
    for (var day in tripDays) {
      var updateDayRef = _db
          .collection('users')
          .doc(uid)
          .collection('trips')
          .doc(tripId)
          .collection("days")
          .doc(day.dayId);
      batch
          .update(updateDayRef, {"dayNumber": day.dayNumber, "date": day.date});
    }

    await batch.commit();
  }

  Future<void> batchUpdateAfterAddingNewTripDay(
      String uid, String tripId, int dayNumber, DateTime date) async {
    final batch = _db.batch();
    final data = <String, dynamic>{
      "dayNumber": dayNumber,
      "date": Timestamp.fromDate(date),
    };

    // Add new day
    var tripDayRef = _db
        .collection("users")
        .doc(uid)
        .collection("trips")
        .doc(tripId)
        .collection("days")
        .doc();
    batch.set(tripDayRef, data);

    // Update trip endDate
    var tripRef =
        _db.collection('users').doc(uid).collection('trips').doc(tripId);
    batch.update(tripRef, {"endDate": Timestamp.fromDate(date)});

    await batch.commit();
  }

  Future<void> batchUpdateAfterEditedTripDates(
      String uid,
      String tripId,
      List<TripDay> daysToUpdate,
      DateTime? startDate,
      DateTime? endDate,
      List<DateTime>? newDayDates,
      List<TripDay>? daysToDelete,
      int lastDayNumber) async {
    final batch = _db.batch();

    if (startDate != null) {
      // Update date for existing days after edited trip start date
      for (var day in daysToUpdate) {
        var updateDayRef = _db
            .collection('users')
            .doc(uid)
            .collection('trips')
            .doc(tripId)
            .collection("days")
            .doc(day.dayId);
        batch.update(
            updateDayRef, {"date": day.date, "dayNumber": day.dayNumber});
      }

      // Update trip startDate
      var tripRef =
          _db.collection('users').doc(uid).collection('trips').doc(tripId);
      batch.update(tripRef, {
        "startDate": Timestamp.fromDate(startDate),
      });
    }

    if (endDate != null) {
      // Update trip endDate
      var tripRef =
          _db.collection('users').doc(uid).collection('trips').doc(tripId);
      batch.update(tripRef, {
        "endDate": Timestamp.fromDate(endDate),
      });
    }

    if (daysToDelete != null) {
      for (var day in daysToDelete) {
        var deleteDayRef = _db
            .collection('users')
            .doc(uid)
            .collection('trips')
            .doc(tripId)
            .collection("days")
            .doc(day.dayId);
        batch.delete(deleteDayRef);
      }
    } else if (newDayDates != null) {
      for (var datetime in newDayDates) {
        var tripDayRef = _db
            .collection("users")
            .doc(uid)
            .collection("trips")
            .doc(tripId)
            .collection("days")
            .doc();
        final data = <String, dynamic>{
          "dayNumber": ++lastDayNumber,
          "date": Timestamp.fromDate(datetime),
        };
        batch.set(tripDayRef, data);
      }
    }

    await batch.commit();
  }

  // Trip Day Checkpoints

  Future<DocumentReference<Map<String, dynamic>>> addCheckpointToTripDay(
      String uid, String tripId, String dayId, Checkpoint checkpoint) async {
    final data = <String, dynamic>{
      "title": checkpoint.title,
      "coordinates": GeoPoint(
          checkpoint.coordinates.latitude, checkpoint.coordinates.longitude),
      "checkpointNumber": checkpoint.chekpointNumber,
      "address": checkpoint.address,
    };

    if (checkpoint.polyline != null) {
      List<GeoPoint> polylineGeopoints = [];
      for (var polylineCoordinate in checkpoint.polyline!.points) {
        polylineGeopoints.add(GeoPoint(
            polylineCoordinate.latitude, polylineCoordinate.longitude));
      }
      data["polylineCoordinates"] = polylineGeopoints;
    }

    return await _db
        .collection("users")
        .doc(uid)
        .collection("trips")
        .doc(tripId)
        .collection("days")
        .doc(dayId)
        .collection("checkpoints")
        .add(data);
  }

  Future<List<Checkpoint>> getTripDayCheckpoints(
      String uid, String tripId, String dayId) async {
    List<Checkpoint> checkpoints = [];
    await _db
        .collection("users")
        .doc(uid)
        .collection("trips")
        .doc(tripId)
        .collection("days")
        .doc(dayId)
        .collection("checkpoints")
        .orderBy("checkpointNumber")
        .get()
        .then((querySnapshot) {
      for (var checkpoint in querySnapshot.docs) {
        checkpoints.add(Checkpoint.fromFirestore(checkpoint));
      }
    });
    return checkpoints;
  }

  Future<void> batchUpdateAfterTripDayCheckpointDeletion(
      String uid,
      String tripId,
      String dayId,
      String checkpointId,
      List<Checkpoint> tripDayCheckpoints) async {
    final batch = _db.batch();

    // Find checkpoint to delete and add it to batch
    var checkpointRef = _db
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(tripId)
        .collection("days")
        .doc(dayId)
        .collection("checkpoints")
        .doc(checkpointId);
    batch.delete(checkpointRef);

    // Update checkpointNumber for the remaining checkpoints
    for (var checkpoint in tripDayCheckpoints) {
      var updateDayRef = _db
          .collection('users')
          .doc(uid)
          .collection('trips')
          .doc(tripId)
          .collection("days")
          .doc(dayId)
          .collection("checkpoints")
          .doc(checkpoint.checkpointId);

      dynamic polylineGeopoints;
      if (checkpoint.polyline != null) {
        polylineGeopoints = [];
        for (var polylineCoordinate in checkpoint.polyline!.points) {
          polylineGeopoints.add(GeoPoint(
              polylineCoordinate.latitude, polylineCoordinate.longitude));
        }
      }
      batch.update(updateDayRef, {
        "checkpointNumber": checkpoint.chekpointNumber,
        "polylineCoordinates": polylineGeopoints,
      });
    }

    await batch.commit();
  }

  Future<String> batchUpdateAfterTripDayCheckpointAddition(
      String uid,
      String tripId,
      String dayId,
      Checkpoint checkpoint,
      List<Checkpoint> tripDayCheckpoints) async {
    final batch = _db.batch();

    final data = <String, dynamic>{
      "title": checkpoint.title,
      "coordinates": GeoPoint(
          checkpoint.coordinates.latitude, checkpoint.coordinates.longitude),
      "checkpointNumber": checkpoint.chekpointNumber,
      "address": checkpoint.address,
      "isVisited": checkpoint.isVisited,
    };

    if (checkpoint.polyline != null) {
      List<GeoPoint> polylineGeopoints = [];
      for (var polylineCoordinate in checkpoint.polyline!.points) {
        polylineGeopoints.add(GeoPoint(
            polylineCoordinate.latitude, polylineCoordinate.longitude));
      }
      data["polylineCoordinates"] = polylineGeopoints;
    }
    // Find checkpoint to delete and add it to batch
    var checkpointRef = _db
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(tripId)
        .collection("days")
        .doc(dayId)
        .collection("checkpoints")
        .doc();
    batch.set(checkpointRef, data);

    // Update checkpointNumber for the remaining checkpoints
    for (var checkpoint in tripDayCheckpoints) {
      var updateDayRef = _db
          .collection('users')
          .doc(uid)
          .collection('trips')
          .doc(tripId)
          .collection("days")
          .doc(dayId)
          .collection("checkpoints")
          .doc(checkpoint.checkpointId);

      dynamic polylineGeopoints;
      if (checkpoint.polyline != null) {
        polylineGeopoints = [];
        for (var polylineCoordinate in checkpoint.polyline!.points) {
          polylineGeopoints.add(GeoPoint(
              polylineCoordinate.latitude, polylineCoordinate.longitude));
        }
      }
      batch.update(updateDayRef, {
        "checkpointNumber": checkpoint.chekpointNumber,
        "polylineCoordinates": polylineGeopoints,
      });
    }

    await batch.commit();
    return checkpointRef.id;
  }

  Future<void> updateCheckpoint(String uid, String tripId, String dayId,
      String checkpointId, Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(tripId)
        .collection("days")
        .doc(dayId)
        .collection("checkpoints")
        .doc(checkpointId)
        .update(data);
  }
}
