import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  User? get currentUser => auth.currentUser;

  String get currentUserId {
    final user = currentUser;
    if (user == null) {
      throw StateError('No authenticated Firebase user is available.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get users =>
      firestore.collection('users');

  DocumentReference<Map<String, dynamic>> get currentUserDocument =>
      users.doc(currentUserId);

  CollectionReference<Map<String, dynamic>> get currentUserVehicles =>
      currentUserDocument.collection('vehicles');
}
