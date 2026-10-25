import 'package:comp_585_project/screens/student/equipment_catalog.dart';
import 'package:comp_585_project/services/reservation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('unavailable equipment can be added to the waitlist', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final service = InMemoryReservationService(
      initialWaitlistCounts: const {'EQ-1003': 2},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EquipmentCatalogScreen(
            reservationService: service,
            studentUid: 'student-1',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final waitlistButton = find.widgetWithText(TextButton, 'Join waitlist');

    expect(waitlistButton, findsOneWidget);

    await tester.tap(waitlistButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Join waitlist for Zoom H6 Audio Recorder?'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Join waitlist'));
    await tester.pumpAndSettle();

    final entries = await service.getWaitlistEntriesForStudent('student-1');

    expect(entries, hasLength(1));
    expect(entries.single.equipmentId, 'EQ-1003');
    expect(entries.single.position, 3);
  });
}
