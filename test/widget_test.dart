import 'package:comp_585_project/app.dart';
import 'package:comp_585_project/screens/student/student_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login screen shows current authentication options', (
    tester,
  ) async {
    await tester.pumpWidget(const EquipmentRentalApp());

    expect(find.text('Welcome, Matador'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Sign in as student'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(OutlinedButton, 'Sign in as staff'),
      findsOneWidget,
    );
    expect(find.text('Create an account'), findsOneWidget);
  });

  testWidgets('student dashboard renders at mobile width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StudentDashboardScreen(onBrowseAll: () {})),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Welcome back, Matador'), findsOneWidget);
    expect(find.text('My Equipment'), findsOneWidget);
    expect(find.text('Available items'), findsOneWidget);
  });
}
