import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/user_role.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.role});

  final UserRole role;

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _maskedId(String id) {
    if (id.length < 4) return 'Not provided';
    return '•••• ${id.substring(id.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('You are not signed in.'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final name =
            (data?['name'] as String?) ?? user.displayName ?? 'User';
        final email =
            (data?['email'] as String?) ?? user.email ?? 'No email available';
        final studentId = (data?['studentId'] as String?) ?? '';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: AppColors.csunRed,
                      foregroundColor: Colors.white,
                      child: Text(
                        _initials(name),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      role.label,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('University Email'),
                      subtitle: Text(email),
                    ),
                    if (role == UserRole.student) ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: const Text('CSUN ID'),
                        subtitle: Text(_maskedId(studentId)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}