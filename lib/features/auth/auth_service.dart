import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:football_challenges/core/style/snack_bar.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? myUser;
  bool isLoading = false;
  List<DocumentSnapshot> searchResults = [];
  List<DocumentSnapshot> allRooms = [];

  AuthService() {
    _auth.authStateChanges().listen((user) {
      myUser = user;
      notifyListeners();
    });
    if (_auth.currentUser == null) {
    } else {
      myUser = _auth.currentUser;
      notifyListeners();
    }
  }

  Future<void> _signInSilently() async {
    final GoogleSignInAccount? googleUser =
        await _googleSignIn.signInSilently();
    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      myUser = userCredential.user;

      // Save user data to Firestore
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(myUser!.uid);
      if (!(await userDoc.get()).exists) {
        await userDoc.set({
          'displayName': myUser!.displayName,
          'email': myUser!.email,
          'photoURL': myUser!.photoURL,
        });
      }
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      myUser = userCredential.user;

      // Save user data to Firestore
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(myUser!.uid);
      if (!(await userDoc.get()).exists) {
        await userDoc.set({
          'displayName': myUser!.displayName,
          'email': myUser!.email,
          'photoURL': myUser!.photoURL,
        });
      }

      notifyListeners();
    } catch (e) {
      showSnackBar(e.toString());
    }
  }

  Future<void> signOut() async {
    isLoading = true;

    await _auth.signOut();
    await _googleSignIn.signOut();
    isLoading = false;
    notifyListeners();
  }

  Future<void> updateDisplayName(String displayName) async {
    isLoading = true;

    await myUser!.updateDisplayName(displayName);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(myUser!.uid)
        .update({
      'displayName': displayName,
    });
    await myUser!.reload();
    myUser = _auth.currentUser;

    isLoading = false;
    notifyListeners();
  }

  Future<void> updatePhotoURL(String photoURL) async {
    isLoading = true;
    notifyListeners();
    await myUser!.updatePhotoURL(photoURL);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(myUser!.uid)
        .update({
      'photoURL': photoURL,
    });
    await myUser!.reload();
    myUser = _auth.currentUser;
    isLoading = false;
    notifyListeners();
  }

  Stream<QuerySnapshot> get roomsStream {
    return FirebaseFirestore.instance.collection('rooms').snapshots();
  }

  void updateRoomList(QuerySnapshot snapshot) {
    allRooms = snapshot.docs;
  }

  void notify() {
    notifyListeners();
  }

  void slientSearchRooms(String query) {
    if (query.isEmpty) {
      searchResults = allRooms;
    } else {
      searchResults = allRooms
          .where((room) =>
              (room['roomName'] as String)
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              (room['roomId'] as String).contains(query))
          .toList();
    }
  }

  void searchRooms(String query) {
    if (query.isEmpty) {
      searchResults = allRooms;
    } else {
      searchResults = allRooms
          .where((room) =>
              (room['roomName'] as String)
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              (room['roomId'] as String).contains(query))
          .toList();
      notifyListeners();
    }
  }
}
