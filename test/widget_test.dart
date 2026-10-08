import 'package:comp_585_project/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('student can open the prototype dashboard', (tester) async {
    await tester.pumpWidget(const EquipmentRentalApp());

    expect(find.text('Welcome, Matador'), findsOneWidget);
    expect(find.text('Continue as student'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue as student'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, Matador'), findsOneWidget);
    expect(find.text('My Equipment'), findsOneWidget);
    expect(find.text('Browse'), findsOneWidget);
  });
}
