import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as devtools show log;

class UserService {
  UserService();

  final db = FirebaseFirestore.instance;
  late final StreamSubscription<QuerySnapshot> usernameListener;
  List allUsernameList = [];

  // Creates a new user with username
  addUser(String username, String uid) {
    final userData = <String, dynamic>{
      "username": username,
    };

    // Adds a new user document with unique uid and username to users collection
    db
        .collection("users")
        .doc(uid)
        .set(userData)
        .onError((e, _) => devtools.log("Error writing document: $e"));
  }

  // Adds a new unique user username document to usernames collection
  addUsername(String username, String uid) {
    db.collection("usernames").doc(username).set({"userId": uid}).onError(
        (e, _) => devtools.log("Error writing document: $e"));
  }

  // Listener for Usernames collection in firestore
  listenToUserNames() {
    usernameListener = db.collection("usernames").snapshots().listen(
      (querySnapshot) {
        for (var docSnapshot in querySnapshot.docs) {
          allUsernameList.add(docSnapshot.id);
        }
      },
    );
  }

  cancelListenToUsernames() async {
    await usernameListener.cancel();
  }
}
