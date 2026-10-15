import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../models/equipment.dart';
import '../../widgets/equipment_card.dart';

class EquipmentCatalogScreen extends StatefulWidget {
  const EquipmentCatalogScreen({super.key});

  @override
  State<EquipmentCatalogScreen> createState() => _EquipmentCatalogScreenState();
}

class _EquipmentCatalogScreenState extends State<EquipmentCatalogScreen> {
  String _query = '';
  String _category = 'All';

  List<String> get _categories => [
    'All',
    ...{for (final item in mockEquipment) item.category},
  ];

  List<Equipment> get _filteredEquipment {
    final normalizedQuery = _query.trim().toLowerCase();
    return mockEquipment.where((item) {
      final matchesCategory = _category == 'All' || item.category == _category;
      final matchesSearch =
          normalizedQuery.isEmpty ||
          item.name.toLowerCase().contains(normalizedQuery) ||
          item.category.toLowerCase().contains(normalizedQuery);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _reserve(Equipment equipment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${equipment.name} selected. Reservations will be connected in the next phase.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEquipment;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1200
            ? 4
            : constraints.maxWidth >= 850
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Browse Equipment',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'Search available cameras, audio kits, computers, and accessories.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Search by equipment name or category',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final category in _categories) ...[
                      FilterChip(
                        label: Text(category),
                        selected: _category == category,
                        onSelected: (_) => setState(() => _category = category),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${filtered.length} items',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 64),
                  child: Center(
                    child: Text('No equipment matches your search.'),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 320,
                  ),
                  itemBuilder: (context, index) {
                    final equipment = filtered[index];
                    return EquipmentCard(
                      equipment: equipment,
                      onReserve: () => _reserve(equipment),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
