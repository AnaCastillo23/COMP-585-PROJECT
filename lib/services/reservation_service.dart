import 'package:flutter/foundation.dart';

import '../models/reservation.dart';

abstract interface class ReservationService implements Listenable {
  Future<Reservation> createReservation({
    required String studentUid,
    required String equipmentId,
    required String equipmentName,
  });

  Future<List<Reservation>> getReservationsForStudent(String studentUid);
}

class ReservationServiceException implements Exception {
  const ReservationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InMemoryReservationService extends ChangeNotifier
    implements ReservationService {
  InMemoryReservationService({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static final shared = InMemoryReservationService();

  final DateTime Function() _clock;
  final List<Reservation> _reservations = [];
  int _nextId = 1;

  @override
  Future<Reservation> createReservation({
    required String studentUid,
    required String equipmentId,
    required String equipmentName,
  }) async {
    final currentTime = _clock();

    final alreadyReserved = _reservations.any(
      (reservation) =>
          reservation.studentUid == studentUid &&
          reservation.equipmentId == equipmentId &&
          reservation.status == ReservationStatus.pendingPickup &&
          !reservation.isExpiredAt(currentTime),
    );

    if (alreadyReserved) {
      throw const ReservationServiceException(
        'You already have an active reservation for this item.',
      );
    }

    final reservation = Reservation.create(
      id: 'reservation-${_nextId++}',
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
  Future<List<Reservation>> getReservationsForStudent(String studentUid) async {
    final studentReservations =
        _reservations
            .where((reservation) => reservation.studentUid == studentUid)
            .toList()
          ..sort((a, b) => b.reservedAt.compareTo(a.reservedAt));

    return List<Reservation>.unmodifiable(studentReservations);
  }
}
