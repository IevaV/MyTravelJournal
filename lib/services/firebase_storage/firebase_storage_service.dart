import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class FirebaseStorageService {
  FirebaseStorageService();

  final storage = FirebaseStorage.instance;

  Future<void> uploadFile(String uid, String tripId, File fileToUpload) async {
    final storageRef = storage.ref();
    final tripFileRef =
        storageRef.child("$uid/$tripId/${fileToUpload.path.split('/').last}");
    try {
      await tripFileRef.putFile(fileToUpload);
    } on FirebaseException catch (e) {
      print(e);
    }
  }

  Future<void> downloadFile(String uid, String tripId, String fileName) async {
    final storageRef = storage.ref();
    final tripFileRef = storageRef.child("$uid/$tripId/$fileName");
    final appDocDir = await getApplicationDocumentsDirectory();
    final filePath = "${appDocDir.path}/$tripId/$fileName";
    final file = await File(filePath).create(recursive: true);
    final downloadTask = tripFileRef.writeToFile(file);
    downloadTask.then((p0) => print(p0.state.name));
  }

  Future<void> deleteFile(String uid, String tripId, String fileName) async {
    final storageRef = storage.ref();
    final tripFileRef = storageRef.child("$uid/$tripId/$fileName");
    await tripFileRef.delete();
  }

  Future<void> deleteAllFilesInDirectory(String uid, String tripId) async {
    final storageRef = storage.ref();
    final tripFileRef = storageRef.child("$uid/$tripId");
    tripFileRef.listAll().then((allFiles) {
      for (var file in allFiles.items) {
        storageRef.child(file.fullPath).delete();
      }
    });
  }
}
