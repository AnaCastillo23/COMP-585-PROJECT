import 'package:flutter/material.dart';

class Equipment {
  const Equipment({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.availableUnits,
    required this.totalUnits,
    required this.icon,
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final int availableUnits;
  final int totalUnits;
  final IconData icon;

  bool get isAvailable => availableUnits > 0;
}
