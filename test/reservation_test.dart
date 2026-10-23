import 'package:comp_585_project/models/reservation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final reservedAt = DateTime.utc(2026, 10, 23, 12);

  Reservation createReservation() {
    return Reservation.create(
      id: 'reservation-1',
      studentUid: 'student-1',
      equipmentId: 'camera-1',
      equipmentName: 'Canon Camera',
      reservedAt: reservedAt,
    );
  }

  test('new reservation receives a one-day pickup deadline', () {
    final reservation = createReservation();

    expect(reservation.pickupDeadline, reservedAt.add(const Duration(days: 1)));
    expect(reservation.status, ReservationStatus.pendingPickup);
  });

  test('reservation remains active before its pickup deadline', () {
    final reservation = createReservation();
    final currentTime = reservedAt.add(const Duration(hours: 12));

    expect(reservation.isExpiredAt(currentTime), isFalse);
    expect(
      reservation.pickupTimeRemainingAt(currentTime),
      const Duration(hours: 12),
    );
  });

  test('reservation expires when its pickup deadline is reached', () {
    final reservation = createReservation();

    expect(reservation.isExpiredAt(reservation.pickupDeadline), isTrue);
    expect(
      reservation.pickupTimeRemainingAt(reservation.pickupDeadline),
      Duration.zero,
    );
  });
}
