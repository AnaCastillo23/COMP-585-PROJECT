import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../models/equipment.dart';
import '../../services/reservation_service.dart';
import '../../widgets/equipment_card.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EquipmentCatalogScreen extends StatefulWidget {
  const EquipmentCatalogScreen({
    super.key,
    this.reservationService,
  });

  final ReservationService? reservationService;

  @override
  State<EquipmentCatalogScreen> createState() => _EquipmentCatalogScreenState();
}

class _EquipmentCatalogScreenState extends State<EquipmentCatalogScreen> {
  late final ReservationService _reservationService;

  String _query = '';
  String _category = 'All';
  String? _reservingEquipmentId;

  @override
  void initState() {
    super.initState();
    _reservationService =
        widget.reservationService ?? InMemoryReservationService.shared;
  }

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

  Future<void> _reserve(Equipment equipment) async {
    if (equipment.availableUnits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This equipment is currently unavailable.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Reserve ${equipment.name}?'),
          content: const Text(
            'The equipment will be held for pickup for 24 hours. '
            'If it is not picked up during that time, it becomes available '
            'again.\n\n'
            'The two-week rental period begins only after staff completes '
            'the checkout.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirm reservation'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() => _reservingEquipmentId = equipment.id);

    try {
      final reservation = await _reservationService.createReservation(
        studentUid: FirebaseAuth.instance.currentUser!.uid,
        equipmentId: equipment.id,
        equipmentName: equipment.name,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${equipment.name} reserved. '
            'Pick it up by ${_formatDeadline(reservation.pickupDeadline)}.',
          ),
        ),
      );
    } on ReservationServiceException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _reservingEquipmentId = null);
      }
    }
  }

  String _formatDeadline(DateTime deadline) {
    final localDeadline = deadline.toLocal();
    final hour = localDeadline.hour % 12 == 0 ? 12 : localDeadline.hour % 12;
    final minute = localDeadline.minute.toString().padLeft(2, '0');
    final period = localDeadline.hour >= 12 ? 'PM' : 'AM';

    return '${localDeadline.month}/${localDeadline.day}/${localDeadline.year} '
        'at $hour:$minute $period';
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
                        onSelected: (_) {
                          setState(() => _category = category);
                        },
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
                      onReserve: () {
                        if (_reservingEquipmentId == null) {
                          _reserve(equipment);
                        }
                      },
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
