import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class FirebaseStorageService {
  FirebaseStorageService();

  final storage = FirebaseStorage.instance;

  Future<void> uploadFile(String path, File fileToUpload) async {
    final storageRef = storage.ref();
    final tripFileRef =
        storageRef.child("$path/${fileToUpload.path.split('/').last}");
    try {
      await tripFileRef.putFile(fileToUpload);
    } on FirebaseException catch (e) {
      print(e);
    }
  }

  Future<void> downloadFile(String path, String fileName) async {
    final storageRef = storage.ref();
    final tripFileRef = storageRef.child("$path/$fileName");
    final appDocDir = await getApplicationDocumentsDirectory();
    final filePath = "${appDocDir.path}/$path/$fileName";
    final file = await File(filePath).create(recursive: true);
    final downloadTask = tripFileRef.writeToFile(file);
    downloadTask.then((p0) => print(p0.state.name));
  }

  Future<void> deleteFile(String path, String fileName) async {
    final storageRef = storage.ref();
    final tripFileRef = storageRef.child("$path/$fileName");
    try {
      await tripFileRef.delete();
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteAllFilesInDirectory(String path) async {
    final storageRef = storage.ref();
    final tripFileRef = storageRef.child(path);
    tripFileRef.listAll().then((allFiles) {
      for (var file in allFiles.items) {
        storageRef.child(file.fullPath).delete();
      }
    });
  }
}
