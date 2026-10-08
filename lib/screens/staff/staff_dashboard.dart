import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Staff Dashboard',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'Monitor reservations, checkouts, returns, and equipment condition.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 22),
          const Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _StaffStat(
                label: 'Total assets',
                value: '48',
                icon: Icons.inventory_2_outlined,
              ),
              _StaffStat(
                label: 'Available',
                value: '21',
                icon: Icons.check_circle_outline,
              ),
              _StaffStat(
                label: 'Checked out',
                value: '19',
                icon: Icons.logout_outlined,
              ),
              _StaffStat(
                label: 'Reserved',
                value: '5',
                icon: Icons.event_outlined,
              ),
              _StaffStat(
                label: 'Maintenance',
                value: '3',
                icon: Icons.build_outlined,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan equipment'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_search_outlined),
                label: const Text('Find student'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Add equipment'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Recent activity',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const _ActivityList(),
        ],
      ),
    );
  }
}

class _StaffStat extends StatelessWidget {
  const _StaffStat({
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
      width: 190,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.csunRed),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          Text(label, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList();

  @override
  Widget build(BuildContext context) {
    const activities = [
      (
        'Camera CAM-018 returned',
        'Student ID ending in 4821 • 12 minutes ago',
        Icons.assignment_return,
      ),
      (
        'Laptop reservation ready',
        'Pickup window ends tomorrow at 3:30 PM',
        Icons.event_available,
      ),
      (
        'Tripod condition updated',
        'TRI-031 marked for staff inspection',
        Icons.build_outlined,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < activities.length; index++) ...[
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.csunRed.withValues(alpha: 0.1),
                foregroundColor: AppColors.csunRed,
                child: Icon(activities[index].$3, size: 20),
              ),
              title: Text(
                activities[index].$1,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(activities[index].$2),
              trailing: const Icon(Icons.chevron_right),
            ),
            if (index != activities.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}
