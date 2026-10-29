import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity_entry.dart';

class ActivityService {
  ActivityService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Newest first. Single-field orderBy, so no composite index is needed.
  Stream<List<ActivityEntry>> watchRecent({int limit = 100}) => _db
      .collection('activity')
      .orderBy('at', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(ActivityEntry.fromDoc).toList());

  /// Builds the map for a new activity doc. Write it inside the same
  /// transaction/batch as the action it describes:
  ///   tx.set(db.collection('activity').doc(), ActivityService.record(...));
  static Map<String, dynamic> record({
    required String type,
    required String title,
    required String detail,
    required String status,
    String? unitId,
  }) =>
      {
        'type': type,
        'title': title,
        'detail': detail,
        'status': status,
        'unitId': ?unitId,
        'at': FieldValue.serverTimestamp(),
      };

  /// "Student ID ending in 4821" without exposing the full ID.
  static String maskedStudent(String studentId) {
    final tail = studentId.length >= 4
        ? studentId.substring(studentId.length - 4)
        : studentId;
    return 'Student ID ending in $tail';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';
}