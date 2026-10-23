import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../models/rental.dart';
import '../../models/reservation.dart';
import '../../services/reservation_service.dart';

class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({
    super.key,
    this.reservationService,
    this.studentUid = 'prototype-student',
  });

  final ReservationService? reservationService;

  // Temporary fallback until authentication passes the signed-in UID.
  final String studentUid;

  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen> {
  late final ReservationService _reservationService;

  List<Reservation> _reservations = [];
  bool _loadingReservations = true;
  bool _reservationLoadFailed = false;

  @override
  void initState() {
    super.initState();

    _reservationService =
        widget.reservationService ?? InMemoryReservationService.shared;

    _reservationService.addListener(_handleReservationsChanged);
    unawaited(_loadReservations());
  }

  @override
  void dispose() {
    _reservationService.removeListener(_handleReservationsChanged);
    super.dispose();
  }

  void _handleReservationsChanged() {
    unawaited(_loadReservations());
  }

  Future<void> _loadReservations() async {
    try {
      final reservations = await _reservationService.getReservationsForStudent(
        widget.studentUid,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _reservations = reservations;
        _loadingReservations = false;
        _reservationLoadFailed = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingReservations = false;
        _reservationLoadFailed = true;
      });
    }
  }

  void _showReservationDetails(Reservation reservation) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(reservation.equipmentName),
            content: Text(
              'Reservation: ${reservation.id}\n\n'
              'Pickup deadline: '
              '${_formatDateTime(reservation.pickupDeadline)}\n\n'
              'Bring your student ID when picking up the equipment. '
              'The two-week rental period begins after staff checks it out.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkedOutRentals = mockRentals
        .where((rental) => rental.status == RentalStatus.checkedOut)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Rentals', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          const Text(
            'Checked-out items have a fixed 14-day rental period. '
            'Reservations expire if not picked up within one day.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          Text('Pending Pickup', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (_loadingReservations)
            const Center(child: CircularProgressIndicator())
          else if (_reservationLoadFailed)
            const _MessageCard(
              icon: Icons.error_outline,
              message: 'Reservations could not be loaded.',
              color: AppColors.csunRed,
            )
          else if (_reservations.isEmpty)
            const _MessageCard(
              icon: Icons.event_available_outlined,
              message: 'You do not have any equipment waiting for pickup.',
              color: AppColors.muted,
            )
          else
            for (final reservation in _reservations) ...[
              _ReservationCard(
                reservation: reservation,
                onDetails: () => _showReservationDetails(reservation),
              ),
              const SizedBox(height: 14),
            ],
          const SizedBox(height: 28),
          Text('Checked Out', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (checkedOutRentals.isEmpty)
            const _MessageCard(
              icon: Icons.inventory_2_outlined,
              message: 'You do not currently have any checked-out equipment.',
              color: AppColors.muted,
            )
          else
            for (final rental in checkedOutRentals) ...[
              _RentalCard(rental: rental),
              const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.reservation, required this.onDetails});

  final Reservation reservation;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final currentTime = DateTime.now();
    final expired = reservation.isExpiredAt(currentTime);
    final remaining = reservation.pickupTimeRemainingAt(currentTime);
    final accent = expired ? AppColors.csunRed : AppColors.warning;

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
                reservation.equipmentName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 5),
              Text(
                reservation.id,
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
                  expired
                      ? 'Pickup window expired'
                      : _formatRemainingTime(remaining),
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
            onPressed: onDetails,
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Pickup details'),
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
                child: Icon(Icons.event_available_outlined, color: accent),
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

class _RentalCard extends StatelessWidget {
  const _RentalCard({required this.rental});

  final Rental rental;

  @override
  Widget build(BuildContext context) {
    final remaining = rental.daysRemaining;
    final urgent = remaining != null && remaining <= 5;
    final accent = urgent ? AppColors.csunRed : AppColors.success;

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
                  '$remaining days remaining',
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
            icon: const Icon(Icons.assignment_return_outlined),
            label: const Text('Return details'),
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
                child: Icon(Icons.inventory_2_outlined, color: accent),
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

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatRemainingTime(Duration remaining) {
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

String _formatDateTime(DateTime value) {
  final localValue = value.toLocal();
  final hour = localValue.hour % 12 == 0 ? 12 : localValue.hour % 12;
  final minute = localValue.minute.toString().padLeft(2, '0');
  final period = localValue.hour >= 12 ? 'PM' : 'AM';

  return '${localValue.month}/${localValue.day}/${localValue.year} '
      'at $hour:$minute $period';
}
