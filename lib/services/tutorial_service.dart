import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Tracks whether a student has seen the intro tutorial, using a
/// `hasSeenTutorial` field on their `users/{uid}` Firestore document.
///
/// A missing field counts as "not seen", so existing accounts will see the
/// tutorial once and no migration is needed.
class TutorialService {
  TutorialService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Returns true if the tutorial should NOT be shown.
  /// On any error or missing profile we return true so a Firestore problem
  /// never blocks the student from reaching the app.
  Future<bool> hasSeenTutorial(String uid) async {
    try {
      final snapshot = await _userDoc(uid).get();
      final data = snapshot.data();

      // No profile doc yet (e.g. signup is still saving it): treat as a new
      // student and show the tutorial.
      if (data == null) {
        return false;
      }

      return data['hasSeenTutorial'] == true;
    } catch (error) {
      // Usually a Firestore security-rules problem. Logged so it is not silent.
      debugPrint('TutorialService.hasSeenTutorial failed: $error');
      return true;
    }
  }

  Future<void> markTutorialSeen(String uid) async {
    try {
      await _userDoc(uid).set({
        'hasSeenTutorial': true,
      }, SetOptions(merge: true));
    } catch (error) {
      // Non-critical: worst case the student sees the tutorial again.
      debugPrint('TutorialService.markTutorialSeen failed: $error');
    }
  }
}