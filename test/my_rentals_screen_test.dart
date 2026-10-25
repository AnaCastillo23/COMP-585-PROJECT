import 'package:comp_585_project/screens/student/my_rentals.dart';
import 'package:comp_585_project/services/reservation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('new reservation appears under pending pickup', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final currentTime = DateTime.now();
    final service = InMemoryReservationService(clock: () => currentTime);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyRentalsScreen(
            reservationService: service,
            studentUid: 'student-1',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('You do not have any equipment waiting for pickup.'),
      findsOneWidget,
    );

    await service.createReservation(
      studentUid: 'student-1',
      equipmentId: 'test-camera',
      equipmentName: 'Test Reservation Camera',
    );

    await tester.pumpAndSettle();

    expect(find.text('Test Reservation Camera'), findsOneWidget);
    expect(find.text('Pickup details'), findsOneWidget);
  });

  testWidgets('new waitlist entry appears with its queue position', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final currentTime = DateTime.now();
    final service = InMemoryReservationService(
      clock: () => currentTime,
      initialWaitlistCounts: const {'EQ-1003': 2},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyRentalsScreen(
            reservationService: service,
            studentUid: 'student-1',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('You are not currently on any equipment waitlists.'),
      findsOneWidget,
    );

    await service.joinWaitlist(
      studentUid: 'student-1',
      equipmentId: 'EQ-1003',
      equipmentName: 'Zoom H6 Audio Recorder',
    );

    await tester.pumpAndSettle();

    expect(find.text('Zoom H6 Audio Recorder'), findsOneWidget);
    expect(find.text('Waitlist position #3'), findsOneWidget);
    expect(find.text('Waitlist details'), findsOneWidget);
  });
}
