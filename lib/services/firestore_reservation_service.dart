
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reservation.dart';
import '../models/waitlist_entry.dart';
import 'reservation_service.dart';

/// Firestore-backed waitlist that keeps the existing staff-side data format.
///
/// Document ID: {equipmentId}_{studentUid}
class FirestoreReservationService extends InMemoryReservationService {
  FirestoreReservationService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  static final shared = FirestoreReservationService();

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _waitlist =>
      _db.collection('waitlist');

  DateTime _created(Map<String, dynamic> data) {
    final value = data['createdAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Future<WaitlistEntry> joinWaitlist({
    required String studentUid,
    required String equipmentId,
    required String equipmentName,
  }) async {
    if (studentUid.isEmpty || equipmentId.isEmpty) {
      throw const ReservationServiceException(
        'You must be signed in to join a waitlist.',
      );
    }

    final now = DateTime.now();
    final entryRef = _waitlist.doc('${equipmentId}_$studentUid');

    // Keep the existing check against in-memory reservations for now.
    // Reservation storage can be connected separately.
    final reservations = await getReservationsForStudent(studentUid);

    final hasActiveReservation = reservations.any(
      (reservation) =>
          reservation.equipmentId == equipmentId &&
          reservation.status == ReservationStatus.pendingPickup &&
          !reservation.isExpiredAt(now),
    );

    if (hasActiveReservation) {
      throw const ReservationServiceException(
        'You already have an active reservation for this item.',
      );
    }

    // Read the student's profile before creating the entry.
    final userSnapshot = await _db
        .collection('users')
        .doc(studentUid)
        .get();

    if (!userSnapshot.exists) {
      throw const ReservationServiceException(
        'Your student profile could not be found.',
      );
    }

    final user = userSnapshot.data()!;
    final name = (user['name'] ??
            user['displayName'] ??
            user['email'] ??
            'Student')
        .toString();
    final email = (user['email'] ?? '').toString();

    // A transaction prevents two simultaneous requests from creating
    // duplicate entries for the same student and equipment type.
    await _db.runTransaction<void>((transaction) async {
      final existing = await transaction.get(entryRef);

      if (existing.exists) {
        throw const ReservationServiceException(
          'You are already on this equipment waitlist.',
        );
      }

      transaction.set(entryRef, {
        'equipmentId': equipmentId,
        'equipmentName': equipmentName,
        'studentRefId': studentUid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    // Calculate the student's position from the saved queue.
    final queueSnapshot = await _waitlist
        .where('equipmentId', isEqualTo: equipmentId)
        .get();

    final queue = queueSnapshot.docs.toList()
      ..sort((a, b) {
        final comparison = _created(
          a.data(),
        ).compareTo(_created(b.data()));

        if (comparison != 0) return comparison;

        // Stable tie-breaker if two timestamps are identical.
        return a.id.compareTo(b.id);
      });

    final position = queue.indexWhere((doc) => doc.id == entryRef.id) + 1;

    notifyListeners();

    return WaitlistEntry(
      id: entryRef.id,
      studentUid: studentUid,
      equipmentId: equipmentId,
      equipmentName: equipmentName,
      joinedAt: now,
      position: position > 0 ? position : queue.length,
    );
  }

  @override
  Future<List<WaitlistEntry>> getWaitlistEntriesForStudent(
    String studentUid,
  ) async {
    final mine = await _waitlist
        .where('studentRefId', isEqualTo: studentUid)
        .get();

    final entries = <WaitlistEntry>[];

    for (final doc in mine.docs) {
      final data = doc.data();
      final equipmentId = data['equipmentId'] as String? ?? '';
      final joinedAt = _created(data);

      final queueSnapshot = await _waitlist
          .where('equipmentId', isEqualTo: equipmentId)
          .get();

      final queue = queueSnapshot.docs.toList()
        ..sort((a, b) {
          final comparison = _created(
            a.data(),
          ).compareTo(_created(b.data()));

          if (comparison != 0) return comparison;
          return a.id.compareTo(b.id);
        });

      final index = queue.indexWhere((entry) => entry.id == doc.id);

      entries.add(
        WaitlistEntry(
          id: doc.id,
          studentUid: studentUid,
          equipmentId: equipmentId,
          equipmentName:
              data['equipmentName'] as String? ?? equipmentId,
          joinedAt: joinedAt,
          position: index >= 0 ? index + 1 : queue.length + 1,
        ),
      );
    }

    entries.sort((a, b) => b.joinedAt.compareTo(a.joinedAt));

    return List<WaitlistEntry>.unmodifiable(entries);
  }

  /// Removes the student's own waitlist entry.
  Future<void> leaveWaitlist({
    required String studentUid,
    required String equipmentId,
  }) async {
    final entryRef = _waitlist.doc('${equipmentId}_$studentUid');

    await _db.runTransaction<void>((transaction) async {
      final entry = await transaction.get(entryRef);

      if (!entry.exists) {
        throw const ReservationServiceException(
          'This waitlist entry no longer exists.',
        );
      }

      if (entry.data()?['studentRefId'] != studentUid) {
        throw const ReservationServiceException(
          'You cannot remove another student from a waitlist.',
        );
      }

      transaction.delete(entryRef);
    });

    notifyListeners();
  }
}
