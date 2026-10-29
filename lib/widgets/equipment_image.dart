import 'package:flutter/material.dart';

import '../models/equipment.dart';

class EquipmentImage extends StatelessWidget {
  const EquipmentImage({
    super.key,
    required this.equipment,
    this.fit = BoxFit.cover,
  });

  final Equipment equipment;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget placeholder() => ColoredBox(
          color: const Color(0xFFF1F3F6),
          child: Center(
            child: Icon(equipment.icon, size: 40, color: Colors.black38),
          ),
        );

    final bytes = equipment.imageBytes;
    if (bytes == null) return placeholder();

    return Image.memory(
      bytes,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => placeholder(),
    );
  }
}