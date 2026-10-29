import 'package:comp_585_project/services/reservation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const studentUid = 'student-1';
  const equipmentId = 'camera-1';
  const equipmentName = 'Canon Camera';

  test('creates and stores a student reservation', () async {
    final currentTime = DateTime.utc(2026, 10, 23, 12);
    final service = InMemoryReservationService(clock: () => currentTime);

    final reservation = await service.createReservation(
      studentUid: studentUid,
      equipmentId: equipmentId,
      equipmentName: equipmentName,
    );

    final reservations = await service.getReservationsForStudent(studentUid);

    expect(reservations, hasLength(1));
    expect(reservations.single, same(reservation));
    expect(
      reservation.pickupDeadline,
      currentTime.add(const Duration(days: 1)),
    );
  });

  test('prevents duplicate active reservations', () async {
    final currentTime = DateTime.utc(2026, 10, 23, 12);
    final service = InMemoryReservationService(clock: () => currentTime);

    await service.createReservation(
      studentUid: studentUid,
      equipmentId: equipmentId,
      equipmentName: equipmentName,
    );

    await expectLater(
      service.createReservation(
        studentUid: studentUid,
        equipmentId: equipmentId,
        equipmentName: equipmentName,
      ),
      throwsA(isA<ReservationServiceException>()),
    );
  });

  test('allows another reservation after the pickup deadline', () async {
    var currentTime = DateTime.utc(2026, 10, 23, 12);
    final service = InMemoryReservationService(clock: () => currentTime);

    await service.createReservation(
      studentUid: studentUid,
      equipmentId: equipmentId,
      equipmentName: equipmentName,
    );

    currentTime = currentTime.add(const Duration(days: 1, seconds: 1));

    await service.createReservation(
      studentUid: studentUid,
      equipmentId: equipmentId,
      equipmentName: equipmentName,
    );

    final reservations = await service.getReservationsForStudent(studentUid);
    expect(reservations, hasLength(2));
  });

  test('assigns sequential waitlist positions', () async {
    final currentTime = DateTime.utc(2026, 10, 23, 12);
    final service = InMemoryReservationService(
      clock: () => currentTime,
      initialWaitlistCounts: const {'recorder-1': 2},
    );

    final firstEntry = await service.joinWaitlist(
      studentUid: 'student-1',
      equipmentId: 'recorder-1',
      equipmentName: 'Audio Recorder',
    );

    final secondEntry = await service.joinWaitlist(
      studentUid: 'student-2',
      equipmentId: 'recorder-1',
      equipmentName: 'Audio Recorder',
    );

    expect(firstEntry.position, 3);
    expect(secondEntry.position, 4);

    final firstStudentEntries = await service.getWaitlistEntriesForStudent(
      'student-1',
    );

    expect(firstStudentEntries, hasLength(1));
    expect(firstStudentEntries.single.position, 3);
  });

  test('prevents joining a waitlist when already reserved', () async {
    final currentTime = DateTime.utc(2026, 10, 23, 12);
    final service = InMemoryReservationService(clock: () => currentTime);

    await service.createReservation(
      studentUid: studentUid,
      equipmentId: equipmentId,
      equipmentName: equipmentName,
    );

    await expectLater(
      service.joinWaitlist(
        studentUid: studentUid,
        equipmentId: equipmentId,
        equipmentName: equipmentName,
      ),
      throwsA(isA<ReservationServiceException>()),
    );
  });
}
