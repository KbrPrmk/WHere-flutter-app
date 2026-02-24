import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  Future<void> addFavorite({
    required String placeName,
    required String aiText,
    required double lat,
    required double lon,
  }) async {
    await _db.collection('users').doc(_uid).collection('favorites').add({
      'placeName': placeName,
      'aiText': aiText,
      'lat': lat,
      'lon': lon,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> favoritesStream() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> removeFavorite(String docId) async {
    await _db.collection('users').doc(_uid).collection('favorites').doc(docId).delete();
  }
}
