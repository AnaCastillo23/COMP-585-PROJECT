import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../models/rental.dart';
import '../../widgets/equipment_card.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key, required this.onBrowseAll});

  final VoidCallback onBrowseAll;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidePanel = constraints.maxWidth >= 1120;
        final dashboard = _DashboardContent(onBrowseAll: onBrowseAll);
        final rentals = const _RentalSummaryPanel();

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
                    const SizedBox(width: 330, child: _RentalSummaryPanel()),
                  ],
                )
              else ...[
                dashboard,
                const SizedBox(height: 24),
                rentals,
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
  const _DashboardContent({required this.onBrowseAll});

  final VoidCallback onBrowseAll;

  void _showReservationMessage(BuildContext context, String equipmentName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$equipmentName selected. Reservation checkout will be connected later.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(
              label: 'Available items',
              value: '21',
              icon: Icons.inventory_2_outlined,
            ),
            _StatCard(
              label: 'Checked out',
              value: '2',
              icon: Icons.assignment_return_outlined,
            ),
            _StatCard(
              label: 'Reservations',
              value: '1',
              icon: Icons.event_available_outlined,
            ),
            _StatCard(
              label: 'Due soon',
              value: '1',
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
                mainAxisExtent: 320,
              ),
              itemBuilder: (context, index) {
                final equipment = mockEquipment[index];
                return EquipmentCard(
                  equipment: equipment,
                  onReserve: () =>
                      _showReservationMessage(context, equipment.name),
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
          Column(
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
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RentalSummaryPanel extends StatelessWidget {
  const _RentalSummaryPanel();

  @override
  Widget build(BuildContext context) {
    final rentals = mockRentals;

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
              Text(
                'My Equipment',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Return reminders and pickup deadlines',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < rentals.length; index++) ...[
            _RentalSummaryItem(rental: rentals[index]),
            if (index != rentals.length - 1) const Divider(height: 28),
          ],
        ],
      ),
    );
  }
}

class _RentalSummaryItem extends StatelessWidget {
  const _RentalSummaryItem({required this.rental});

  final Rental rental;

  @override
  Widget build(BuildContext context) {
    final checkedOut = rental.status == RentalStatus.checkedOut;
    final days = rental.daysRemaining;
    final urgencyColor = checkedOut && days != null && days <= 5
        ? AppColors.csunRed
        : checkedOut
        ? AppColors.success
        : AppColors.warning;
    final statusText = checkedOut
        ? '$days days remaining'
        : 'Pick up within 19 hours';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: urgencyColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            checkedOut ? Icons.inventory_2_outlined : Icons.event_outlined,
            color: urgencyColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rental.equipmentName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 3),
              Text(
                rental.assetTag,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                statusText,
                style: TextStyle(
                  color: urgencyColor,
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
