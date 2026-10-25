import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../models/equipment.dart';
import '../../models/rental.dart';
import '../../models/reservation.dart';
import '../../models/waitlist_entry.dart';
import '../../services/reservation_service.dart';
import '../../widgets/equipment_card.dart';
import '../../widgets/equipment_reservation_flow.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({
    super.key,
    required this.onBrowseAll,
    this.reservationService,
    this.studentUid = 'prototype-student',
  });

  final VoidCallback onBrowseAll;
  final ReservationService? reservationService;
  final String studentUid;

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  late final ReservationService _reservationService;

  List<Reservation> _reservations = [];
  List<WaitlistEntry> _waitlistEntries = [];

  @override
  void initState() {
    super.initState();

    _reservationService =
        widget.reservationService ?? InMemoryReservationService.shared;

    _reservationService.addListener(_handleRequestsChanged);
    unawaited(_loadStudentRequests());
  }

  @override
  void dispose() {
    _reservationService.removeListener(_handleRequestsChanged);
    super.dispose();
  }

  void _handleRequestsChanged() {
    unawaited(_loadStudentRequests());
  }

  Future<void> _loadStudentRequests() async {
    final reservations = await _reservationService.getReservationsForStudent(
      widget.studentUid,
    );

    final waitlistEntries = await _reservationService
        .getWaitlistEntriesForStudent(widget.studentUid);

    if (!mounted) {
      return;
    }

    setState(() {
      _reservations = reservations;
      _waitlistEntries = waitlistEntries;
    });
  }

  void _requestEquipment(Equipment equipment) {
    unawaited(
      showEquipmentReservationFlow(
        context: context,
        equipment: equipment,
        reservationService: _reservationService,
        studentUid: widget.studentUid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTime = DateTime.now();

    final activeReservationCount = _reservations.where((reservation) {
      return reservation.status == ReservationStatus.pendingPickup &&
          !reservation.isExpiredAt(currentTime);
    }).length;

    final activeRequestCount = activeReservationCount + _waitlistEntries.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidePanel = constraints.maxWidth >= 1120;

        final dashboard = _DashboardContent(
          onBrowseAll: widget.onBrowseAll,
          onRequestEquipment: _requestEquipment,
          activeRequestCount: activeRequestCount,
        );

        final equipmentPanel = _EquipmentSummaryPanel(
          reservations: _reservations,
          waitlistEntries: _waitlistEntries,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, Matador',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'Find equipment for your next class project and keep track of every due date.',
                style: TextStyle(color: AppColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 22),
              const _PolicyBanner(),
              const SizedBox(height: 22),
              if (showSidePanel)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: dashboard),
                    const SizedBox(width: 24),
                    SizedBox(width: 330, child: equipmentPanel),
                  ],
                )
              else ...[
                dashboard,
                const SizedBox(height: 24),
                equipmentPanel,
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PolicyBanner extends StatelessWidget {
  const _PolicyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.csunRed.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.csunRed),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Reservations are held for one day. After pickup, the standard rental period is 14 days.',
              style: TextStyle(fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.onBrowseAll,
    required this.onRequestEquipment,
    required this.activeRequestCount,
  });

  final VoidCallback onBrowseAll;
  final ValueChanged<Equipment> onRequestEquipment;
  final int activeRequestCount;

  @override
  Widget build(BuildContext context) {
    final availableItemCount = mockEquipment.fold<int>(
      0,
      (total, equipment) => total + equipment.availableUnits,
    );

    final checkedOutRentals = mockRentals
        .where((rental) => rental.status == RentalStatus.checkedOut)
        .toList();

    final dueSoonCount = checkedOutRentals.where((rental) {
      final remaining = rental.daysRemaining;
      return remaining != null && remaining <= 5;
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(
              label: 'Available items',
              value: '$availableItemCount',
              icon: Icons.inventory_2_outlined,
            ),
            _StatCard(
              label: 'Checked out',
              value: '${checkedOutRentals.length}',
              icon: Icons.assignment_return_outlined,
            ),
            _StatCard(
              label: 'Reservations',
              value: '$activeRequestCount',
              icon: Icons.event_available_outlined,
            ),
            _StatCard(
              label: 'Due soon',
              value: '$dueSoonCount',
              icon: Icons.schedule_outlined,
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: Text(
                'Featured equipment',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(onPressed: onBrowseAll, child: const Text('Browse all')),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 820
                ? 3
                : constraints.maxWidth >= 520
                ? 2
                : 1;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 336,
              ),
              itemBuilder: (context, index) {
                final equipment = mockEquipment[index];

                return EquipmentCard(
                  equipment: equipment,
                  onReserve: () => onRequestEquipment(equipment),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.csunRed.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: AppColors.csunRed, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentSummaryPanel extends StatelessWidget {
  const _EquipmentSummaryPanel({
    required this.reservations,
    required this.waitlistEntries,
  });

  final List<Reservation> reservations;
  final List<WaitlistEntry> waitlistEntries;

  @override
  Widget build(BuildContext context) {
    final actions = _buildSortedActions();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, color: AppColors.csunRed),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'My Equipment',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Ordered by the next required action',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          if (actions.isEmpty)
            const Text(
              'You do not currently have any equipment activity.',
              style: TextStyle(color: AppColors.muted),
            )
          else
            for (var index = 0; index < actions.length; index++) ...[
              _EquipmentSummaryItem(action: actions[index]),
              if (index != actions.length - 1) const Divider(height: 28),
            ],
        ],
      ),
    );
  }

  List<_EquipmentAction> _buildSortedActions() {
    final actions = <_EquipmentAction>[
      for (final rental in mockRentals)
        if (rental.status == RentalStatus.checkedOut)
          _EquipmentAction.fromRental(rental),
      for (final reservation in reservations)
        if (reservation.status == ReservationStatus.pendingPickup)
          _EquipmentAction.fromReservation(reservation),
      for (final entry in waitlistEntries) _EquipmentAction.fromWaitlist(entry),
    ];

    actions.sort((first, second) {
      final firstDeadline = first.deadline;
      final secondDeadline = second.deadline;

      if (firstDeadline != null && secondDeadline != null) {
        final deadlineComparison = firstDeadline.compareTo(secondDeadline);

        if (deadlineComparison != 0) {
          return deadlineComparison;
        }

        return first.equipmentName.compareTo(second.equipmentName);
      }

      if (firstDeadline != null) {
        return -1;
      }

      if (secondDeadline != null) {
        return 1;
      }

      final positionComparison = (first.waitlistPosition ?? 0).compareTo(
        second.waitlistPosition ?? 0,
      );

      if (positionComparison != 0) {
        return positionComparison;
      }

      return first.equipmentName.compareTo(second.equipmentName);
    });

    return actions;
  }
}

enum _EquipmentActionType { returnEquipment, pickupReservation, waitlist }

class _EquipmentAction {
  const _EquipmentAction({
    required this.equipmentName,
    required this.subtitle,
    required this.type,
    this.deadline,
    this.waitlistPosition,
  });

  factory _EquipmentAction.fromRental(Rental rental) {
    return _EquipmentAction(
      equipmentName: rental.equipmentName,
      subtitle: rental.assetTag,
      type: _EquipmentActionType.returnEquipment,
      deadline: rental.dueDate,
    );
  }

  factory _EquipmentAction.fromReservation(Reservation reservation) {
    return _EquipmentAction(
      equipmentName: reservation.equipmentName,
      subtitle: reservation.id,
      type: _EquipmentActionType.pickupReservation,
      deadline: reservation.pickupDeadline,
    );
  }

  factory _EquipmentAction.fromWaitlist(WaitlistEntry entry) {
    return _EquipmentAction(
      equipmentName: entry.equipmentName,
      subtitle: entry.id,
      type: _EquipmentActionType.waitlist,
      waitlistPosition: entry.position,
    );
  }

  final String equipmentName;
  final String subtitle;
  final _EquipmentActionType type;
  final DateTime? deadline;
  final int? waitlistPosition;
}

class _EquipmentSummaryItem extends StatelessWidget {
  const _EquipmentSummaryItem({required this.action});

  final _EquipmentAction action;

  @override
  Widget build(BuildContext context) {
    final currentTime = DateTime.now();

    late final Color color;
    late final IconData icon;
    late final String statusText;

    switch (action.type) {
      case _EquipmentActionType.returnEquipment:
        icon = Icons.inventory_2_outlined;

        if (action.deadline == null) {
          color = AppColors.muted;
          statusText = 'Return date unavailable';
        } else {
          final remaining = action.deadline!.difference(currentTime);
          final urgent = remaining.inHours <= 120;

          color = urgent ? AppColors.csunRed : AppColors.success;
          statusText = _formatReturnTime(remaining);
        }

      case _EquipmentActionType.pickupReservation:
        icon = Icons.event_outlined;

        if (action.deadline == null) {
          color = AppColors.muted;
          statusText = 'Pickup deadline unavailable';
        } else {
          final remaining = action.deadline!.difference(currentTime);

          color = remaining.inSeconds <= 0
              ? AppColors.csunRed
              : AppColors.warning;
          statusText = _formatPickupTime(remaining);
        }

      case _EquipmentActionType.waitlist:
        icon = Icons.format_list_numbered;
        color = const Color(0xFF1565C0);
        statusText = 'Waitlist position #${action.waitlistPosition}';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                action.equipmentName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 3),
              Text(
                action.subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                statusText,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatReturnTime(Duration remaining) {
  if (remaining.inSeconds <= 0) {
    return 'Return overdue';
  }

  final days = (remaining.inHours / 24).ceil();
  return '$days ${days == 1 ? 'day' : 'days'} remaining';
}

String _formatPickupTime(Duration remaining) {
  if (remaining.inSeconds <= 0) {
    return 'Pickup window expired';
  }

  final hours = remaining.inHours;
  final minutes = remaining.inMinutes.remainder(60);

  if (hours > 0) {
    return '$hours hr $minutes min remaining to pick up';
  }

  if (remaining.inMinutes > 0) {
    return '${remaining.inMinutes} min remaining to pick up';
  }

  return 'Less than 1 minute remaining to pick up';
}
