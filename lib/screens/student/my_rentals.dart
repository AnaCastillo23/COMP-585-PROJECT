import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../models/rental.dart';

class MyRentalsScreen extends StatelessWidget {
  const MyRentalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rentals = mockRentals;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Rentals', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          const Text(
            'Checked-out items have a fixed 14-day rental period. Reservations expire if not picked up within one day.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 22),
          for (final rental in rentals) ...[
            _RentalCard(rental: rental),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _RentalCard extends StatelessWidget {
  const _RentalCard({required this.rental});

  final Rental rental;

  @override
  Widget build(BuildContext context) {
    final checkedOut = rental.status == RentalStatus.checkedOut;
    final remaining = rental.daysRemaining;
    final urgent = checkedOut && remaining != null && remaining <= 5;
    final accent = checkedOut
        ? urgent
              ? AppColors.csunRed
              : AppColors.success
        : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rental.equipmentName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 5),
              Text(
                '${rental.id}  •  ${rental.assetTag}',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  checkedOut
                      ? '$remaining days remaining'
                      : 'Pickup required within 19 hours',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );

          final action = OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(
              checkedOut ? Icons.assignment_return_outlined : Icons.qr_code_2,
            ),
            label: Text(checkedOut ? 'Return details' : 'Pickup details'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [details, const SizedBox(height: 16), action],
            );
          }

          return Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  checkedOut
                      ? Icons.inventory_2_outlined
                      : Icons.event_available_outlined,
                  color: accent,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(child: details),
              action,
            ],
          );
        },
      ),
    );
  }
}
