import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

enum EquipmentStatus {
  available('Available'),
  reserved('Reserved'),
  unavailable('Checked out'),
  maintenance('Maintenance');

  const EquipmentStatus(this.label);
  final String label;

  static EquipmentStatus fromName(String? name) {
    return EquipmentStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => EquipmentStatus.available,
    );
  }
}

/// One physical item, for example a single camera. The ID is its own EQ-0000.
class EquipmentUnit {
  const EquipmentUnit({
    required this.id,
    required this.equipmentId,
    this.status = EquipmentStatus.available,
  });

  final String id;
  final String equipmentId;
  final EquipmentStatus status;

  factory EquipmentUnit.fromMap(String id, Map<String, dynamic> map) {
    return EquipmentUnit(
      id: id,
      equipmentId: map['equipmentId'] as String? ?? '',
      status: EquipmentStatus.fromName(map['status'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'equipmentId': equipmentId,
      'status': status.name,
    };
  }
}

class Equipment {
  const Equipment({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.availableUnits,
    required this.totalUnits,
    this.icon = Icons.devices_other,
    this.imageBytes,
    this.units = const [],
  });

  /// The only categories staff can choose from.
  static const List<String> categories = [
    'Cameras',
    'Stabilizers',
    'Audio',
    'Tripods',
    'Lighting',
    'Computers',
  ];

  /// Most units staff can create for one item.
  static const int maxUnits = 50;

  /// 1 -> EQ-0001
  static String formatId(int number) =>
      'EQ-${number.toString().padLeft(4, '0')}';

  factory Equipment.fromMap(
    String id,
    Map<String, dynamic> map, {
    List<EquipmentUnit> units = const [],
  }) {
    final storedCategory = map['category'] as String?;

    Uint8List? image;
    final encoded = map['imageBase64'] as String?;

    if (encoded != null && encoded.isNotEmpty) {
      try {
        image = base64Decode(encoded);
      } catch (_) {
        image = null;
      }
    }

    return Equipment(
      id: id,
      name: map['name'] as String? ?? '',
      category: categories.contains(storedCategory)
          ? storedCategory!
          : categories.first,
      description: map['description'] as String? ?? '',
      // Counts come from the units themselves, so they can't drift.
      totalUnits: units.length,
      availableUnits:
          units.where((u) => u.status == EquipmentStatus.available).length,
      imageBytes: image,
      units: units,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'description': description,
      if (imageBytes != null) 'imageBase64': base64Encode(imageBytes!),
    };
  }

  final String id;
  final String name;
  final String category;
  final String description;
  final int availableUnits;
  final int totalUnits;
  final IconData icon;
  final Uint8List? imageBytes;
  final List<EquipmentUnit> units;

  /// Can a student reserve this equipment right now?
  bool get isAvailable => availableUnits > 0;

  int countWithStatus(EquipmentStatus status) =>
      units.where((u) => u.status == status).length;

  Equipment copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    int? availableUnits,
    int? totalUnits,
    IconData? icon,
    Uint8List? imageBytes,
    List<EquipmentUnit>? units,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      availableUnits: availableUnits ?? this.availableUnits,
      totalUnits: totalUnits ?? this.totalUnits,
      icon: icon ?? this.icon,
      imageBytes: imageBytes ?? this.imageBytes,
      units: units ?? this.units,
    );
  }
}
