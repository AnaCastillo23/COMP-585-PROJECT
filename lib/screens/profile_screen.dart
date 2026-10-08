import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/user_role.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          Container(
            constraints: const BoxConstraints(maxWidth: 680),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.csunRed,
                  foregroundColor: Colors.white,
                  child: Text(
                    'MR',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Mehrdad Rakhshieh',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${role.label} account',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 24),
                const ListTile(
                  leading: Icon(Icons.email_outlined),
                  title: Text('University email'),
                  subtitle: Text('mehrdad@my.csun.edu'),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.badge_outlined),
                  title: Text('CSUN ID'),
                  subtitle: Text('•••• 4821'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
