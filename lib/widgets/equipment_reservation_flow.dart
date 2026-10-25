import 'package:flutter/material.dart';

import '../models/equipment.dart';
import '../services/reservation_service.dart';

Future<void> showEquipmentReservationFlow({
  required BuildContext context,
  required Equipment equipment,
  required ReservationService reservationService,
  required String studentUid,
}) async {
  final available = equipment.isAvailable;

  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          available
              ? 'Reserve ${equipment.name}?'
              : 'Join waitlist for ${equipment.name}?',
        ),
        content: Text(
          available
              ? 'This equipment will be held for pickup for 24 hours. '
                    'If it is not picked up during that time, it becomes '
                    'available again.\n\n'
                    'The two-week rental period begins only after staff '
                    'completes the checkout.'
              : 'This equipment is currently unavailable. You can join its '
                    'waitlist, and your current position will appear in '
                    'My Rentals.\n\n'
                    'Your 24-hour pickup period will begin only after '
                    'equipment becomes available and is assigned to you. '
                    'Would you like to join the waitlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(available ? 'Confirm reservation' : 'Join waitlist'),
          ),
        ],
      );
    },
  );

  if (!context.mounted || accepted != true) {
    return;
  }

  try {
    if (available) {
      final reservation = await reservationService.createReservation(
        studentUid: studentUid,
        equipmentId: equipment.id,
        equipmentName: equipment.name,
      );

      if (!context.mounted) {
        return;
      }

      _showMessage(
        context,
        '${equipment.name} reserved. '
        'Pick it up by ${_formatDeadline(reservation.pickupDeadline)}.',
      );
    } else {
      final waitlistEntry = await reservationService.joinWaitlist(
        studentUid: studentUid,
        equipmentId: equipment.id,
        equipmentName: equipment.name,
      );

      if (!context.mounted) {
        return;
      }

      _showMessage(
        context,
        'You joined the waitlist for ${equipment.name}. '
        'Your position is #${waitlistEntry.position}.',
      );
    }
  } on ReservationServiceException catch (error) {
    if (!context.mounted) {
      return;
    }

    _showMessage(context, error.message);
  } catch (_) {
    if (!context.mounted) {
      return;
    }

    _showMessage(
      context,
      'The equipment request could not be completed. Please try again.',
    );
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String _formatDeadline(DateTime deadline) {
  final localDeadline = deadline.toLocal();
  final hour = localDeadline.hour % 12 == 0 ? 12 : localDeadline.hour % 12;
  final minute = localDeadline.minute.toString().padLeft(2, '0');
  final period = localDeadline.hour >= 12 ? 'PM' : 'AM';

  return '${localDeadline.month}/${localDeadline.day}/${localDeadline.year} '
      'at $hour:$minute $period';
}
