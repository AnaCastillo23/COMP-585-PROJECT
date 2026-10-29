import 'package:flutter/foundation.dart';

import '../models/reservation.dart';
import '../models/waitlist_entry.dart';

abstract interface class ReservationService implements Listenable {
  Future<Reservation> createReservation({
    required String studentUid,
    required String equipmentId,
    required String equipmentName,
  });

  Future<WaitlistEntry> joinWaitlist({
    required String studentUid,
    required String equipmentId,
    required String equipmentName,
  });

  Future<List<Reservation>> getReservationsForStudent(String studentUid);

  Future<List<WaitlistEntry>> getWaitlistEntriesForStudent(String studentUid);
}

class ReservationServiceException implements Exception {
  const ReservationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InMemoryReservationService extends ChangeNotifier
    implements ReservationService {
  InMemoryReservationService({
    DateTime Function()? clock,
    Map<String, int> initialWaitlistCounts = const {},
  }) : _clock = clock ?? DateTime.now,
       _waitlistCounts = Map<String, int>.from(initialWaitlistCounts);

  // Two students are already waiting for the unavailable recorder.
  // This is temporary demo data for the weekly video.
  static final shared = InMemoryReservationService(
    initialWaitlistCounts: const {'EQ-1003': 2},
  );

  final DateTime Function() _clock;
  final List<Reservation> _reservations = [];
  final List<WaitlistEntry> _waitlistEntries = [];
  final Map<String, int> _waitlistCounts;

  int _nextReservationId = 1;
  int _nextWaitlistId = 1;

  @override
  Future<Reservation> createReservation({
    required String studentUid,
    required String equipmentId,
    required String equipmentName,
  }) async {
    final currentTime = _clock();

    _throwIfStudentAlreadyRequestedEquipment(
      studentUid: studentUid,
      equipmentId: equipmentId,
      currentTime: currentTime,
    );

    final reservation = Reservation.create(
      id: 'reservation-${_nextReservationId++}',
      studentUid: studentUid,
      equipmentId: equipmentId,
      equipmentName: equipmentName,
      reservedAt: currentTime,
    );

    _reservations.add(reservation);
    notifyListeners();

    return reservation;
  }

  @override
  Future<WaitlistEntry> joinWaitlist({
    required String studentUid,
    required String equipmentId,
    required String equipmentName,
  }) async {
    final currentTime = _clock();

    _throwIfStudentAlreadyRequestedEquipment(
      studentUid: studentUid,
      equipmentId: equipmentId,
      currentTime: currentTime,
    );

    final position = (_waitlistCounts[equipmentId] ?? 0) + 1;
    _waitlistCounts[equipmentId] = position;

    final entry = WaitlistEntry(
      id: 'waitlist-${_nextWaitlistId++}',
      studentUid: studentUid,
      equipmentId: equipmentId,
      equipmentName: equipmentName,
      joinedAt: currentTime,
      position: position,
    );

    _waitlistEntries.add(entry);
    notifyListeners();

    return entry;
  }

  @override
  Future<List<Reservation>> getReservationsForStudent(String studentUid) async {
    final studentReservations =
        _reservations
            .where((reservation) => reservation.studentUid == studentUid)
            .toList()
          ..sort((a, b) => b.reservedAt.compareTo(a.reservedAt));

    return List<Reservation>.unmodifiable(studentReservations);
  }

  @override
  Future<List<WaitlistEntry>> getWaitlistEntriesForStudent(
    String studentUid,
  ) async {
    final studentEntries =
        _waitlistEntries
            .where((entry) => entry.studentUid == studentUid)
            .toList()
          ..sort((a, b) => b.joinedAt.compareTo(a.joinedAt));

    return List<WaitlistEntry>.unmodifiable(studentEntries);
  }

  void _throwIfStudentAlreadyRequestedEquipment({
    required String studentUid,
    required String equipmentId,
    required DateTime currentTime,
  }) {
    final hasActiveReservation = _reservations.any(
      (reservation) =>
          reservation.studentUid == studentUid &&
          reservation.equipmentId == equipmentId &&
          reservation.status == ReservationStatus.pendingPickup &&
          !reservation.isExpiredAt(currentTime),
    );

    final isAlreadyWaitlisted = _waitlistEntries.any(
      (entry) =>
          entry.studentUid == studentUid && entry.equipmentId == equipmentId,
    );

    if (hasActiveReservation || isAlreadyWaitlisted) {
      throw const ReservationServiceException(
        'You already have an active reservation or waitlist entry '
        'for this item.',
      );
    }
  }
}
