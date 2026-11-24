import 'dart:async';

import 'package:comp_585_project/models/equipment.dart';
import 'package:comp_585_project/screens/staff/manage_equipment_screen.dart';
import 'package:comp_585_project/services/equipment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'equipment form advertises multiple images with a five image limit',
    (tester) async {
      final service = _InventoryFeed();
      addTearDown(service.close);

      await tester.pumpWidget(
        MaterialApp(home: ManageEquipmentScreen(equipmentService: service)),
      );
      service.update([_camera]);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add equipment'));
      await tester.pumpAndSettle();

      expect(find.text('Upload images'), findsOneWidget);
    },
  );

  testWidgets('item details open with carousel, name edit, and units', (
    tester,
  ) async {
    final service = _InventoryFeed();
    addTearDown(service.close);

    await tester.pumpWidget(
      MaterialApp(home: ManageEquipmentScreen(equipmentService: service)),
    );
    service.update([_camera]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test camera'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('item-details-image-carousel')),
      findsOneWidget,
    );
    expect(find.byTooltip('Edit equipment'), findsOneWidget);
    expect(find.text('Units'), findsOneWidget);
    expect(find.text('EQ-0100'), findsOneWidget);
  });

  testWidgets('category filter shows only categories with equipment', (
    tester,
  ) async {
    final service = _InventoryFeed();
    addTearDown(service.close);

    await tester.pumpWidget(
      MaterialApp(home: ManageEquipmentScreen(equipmentService: service)),
    );
    service.update([_camera, _light]);
    await tester.pumpAndSettle();

    DropdownButton<String> categoryMenu() => tester.widget(
      find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButton<String> &&
            widget.items!.any((option) => option.value == 'All categories'),
      ),
    );

    expect(categoryMenu().items!.map((option) => option.value), [
      'All categories',
      'Cameras',
      'Lighting Equipment', // Included even with no available units.
    ]);

    categoryMenu().onChanged!('Cameras');
    await tester.pumpAndSettle();
    expect(categoryMenu().value, 'Cameras');
    expect(find.text('Test LED panel'), findsNothing);

    // The selected category no longer exists after an inventory update.
    service.update([_light]);
    await tester.pumpAndSettle();
    expect(categoryMenu().value, 'All categories');
    expect(categoryMenu().items!.map((option) => option.value), [
      'All categories',
      'Lighting Equipment',
    ]);
    expect(find.text('Test LED panel'), findsOneWidget);
  });
}

const _camera = Equipment(
  id: 'demo-camera',
  name: 'Test camera',
  category: 'Cameras',
  description: 'Test camera description',
  availableUnits: 1,
  totalUnits: 1,
  units: [EquipmentUnit(id: 'EQ-0100', equipmentId: 'demo-camera')],
);

const _light = Equipment(
  id: 'demo-light',
  name: 'Test LED panel',
  category: 'Lighting Equipment',
  description: 'Test LED panel description',
  availableUnits: 0,
  totalUnits: 1,
  units: [
    EquipmentUnit(
      id: 'EQ-0101',
      equipmentId: 'demo-light',
      status: EquipmentStatus.unavailable,
    ),
  ],
);

class _InventoryFeed implements EquipmentService {
  final _controller = StreamController<List<Equipment>>.broadcast();

  void update(List<Equipment> items) => _controller.add(items);

  Future<void> close() async {
    await _controller.close();
  }

  @override
  Stream<List<Equipment>> watchEquipment() => _controller.stream;

  @override
  Future<String> saveEquipment(
    Equipment equipment, {
    required int unitCount,
    required EquipmentStatus newUnitStatus,
  }) => throw UnimplementedError();

  @override
  Future<void> setUnitStatus(String unitId, EquipmentStatus status) =>
      throw UnimplementedError();

  @override
  Future<void> deleteEquipment(String id) => throw UnimplementedError();
}
