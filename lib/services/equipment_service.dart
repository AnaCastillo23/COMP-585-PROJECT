import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/equipment.dart';

abstract interface class EquipmentService {
  /// Equipment types, each with its units, updating live.
  Stream<List<Equipment>> watchEquipment();

  /// Adds (empty id) or edits an item so that it has [unitCount] units.
  /// New units get their own generated EQ-0000 IDs and [newUnitStatus].
  /// Returns the item's ID.
  Future<String> saveEquipment(
    Equipment equipment, {
    required int unitCount,
    required EquipmentStatus newUnitStatus,
  });

  Future<void> setUnitStatus(String unitId, EquipmentStatus status);

  /// Deletes the item and all of its units.
  Future<void> deleteEquipment(String id);
}

class FirestoreEquipmentService implements EquipmentService {
  FirestoreEquipmentService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final Random _random = Random.secure();

  CollectionReference<Map<String, dynamic>> get _types =>
      _db.collection('equipment');

  CollectionReference<Map<String, dynamic>> get _units =>
      _db.collection('equipmentUnits');

  @override
  Stream<List<Equipment>> watchEquipment() {
    late final StreamController<List<Equipment>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? typeSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? unitSub;
    QuerySnapshot<Map<String, dynamic>>? types;
    QuerySnapshot<Map<String, dynamic>>? units;

    void emit() {
      final typeSnap = types;
      final unitSnap = units;
      if (typeSnap == null || unitSnap == null) return;

      final byType = <String, List<EquipmentUnit>>{};
      for (final doc in unitSnap.docs) {
        final unit = EquipmentUnit.fromMap(doc.id, doc.data());
        byType.putIfAbsent(unit.equipmentId, () => []).add(unit);
      }

      controller.add([
        for (final doc in typeSnap.docs)
          Equipment.fromMap(
            doc.id,
            doc.data(),
            units: (byType[doc.id] ?? [])
              ..sort((a, b) => a.id.compareTo(b.id)),
          ),
      ]);
    }

    controller = StreamController<List<Equipment>>(
      onListen: () {
        typeSub = _types.orderBy('name').snapshots().listen((snap) {
          types = snap;
          emit();
        }, onError: controller.addError);
        unitSub = _units.snapshots().listen((snap) {
          units = snap;
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await typeSub?.cancel();
        await unitSub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<String> saveEquipment(
    Equipment e, {
    required int unitCount,
    required EquipmentStatus newUnitStatus,
  }) {
    return _db.runTransaction<String>((tx) async {
      final isNew = e.id.isEmpty;
      final typeRef = isNew ? _types.doc() : _types.doc(e.id);
      final current = isNew ? <EquipmentUnit>[] : e.units;
      final toAdd = unitCount - current.length;

      // All reads come first: find IDs that aren't taken yet.
      final newIds = <String>[];
      if (toAdd > 0) {
        final tried = <String>{};
        var attempts = 0;
        while (newIds.length < toAdd) {
          if (++attempts > toAdd * 10 + 100) {
            throw StateError('Could not find enough free IDs. Try again.');
          }
          final candidate = Equipment.formatId(_random.nextInt(10000));
          if (!tried.add(candidate)) continue;
          if (!(await tx.get(_units.doc(candidate))).exists) {
            newIds.add(candidate);
          }
        }
      }

      // Then the writes.
      tx.set(typeRef, e.toMap(), SetOptions(merge: true));

      for (final id in newIds) {
        tx.set(
          _units.doc(id),
          EquipmentUnit(
            id: id,
            equipmentId: typeRef.id,
            status: newUnitStatus,
          ).toMap(),
        );
      }

      if (toAdd < 0) {
        final removable = [...current]..sort(_removalOrder);
        for (final unit in removable.take(-toAdd)) {
          tx.delete(_units.doc(unit.id));
        }
      }

      return typeRef.id;
    });
  }

  /// When lowering the unit count: units that aren't available go first,
  /// then the highest IDs.
  static int _removalOrder(EquipmentUnit a, EquipmentUnit b) {
    final aAvailable = a.status == EquipmentStatus.available ? 1 : 0;
    final bAvailable = b.status == EquipmentStatus.available ? 1 : 0;
    if (aAvailable != bAvailable) return aAvailable - bAvailable;
    return b.id.compareTo(a.id);
  }

  @override
  Future<void> setUnitStatus(String unitId, EquipmentStatus status) {
    return _units.doc(unitId).update({'status': status.name});
  }

  @override
  Future<void> deleteEquipment(String id) async {
    final units = await _units.where('equipmentId', isEqualTo: id).get();
    final batch = _db.batch();
    for (final doc in units.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_types.doc(id));
    await batch.commit();
  }
}