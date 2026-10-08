import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/user_role.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.onContinue});

  final ValueChanged<UserRole> onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;
            final brandPanel = _BrandPanel(compact: !isWide);
            final loginPanel = _LoginPanel(onContinue: onContinue);

            if (isWide) {
              return Row(
                children: [
                  Expanded(flex: 5, child: brandPanel),
                  Expanded(flex: 6, child: loginPanel),
                ],
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 220, child: brandPanel),
                  loginPanel,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.csunRed,
      padding: EdgeInsets.all(compact ? 28 : 56),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: const Text(
              'CSUN',
              style: TextStyle(
                color: AppColors.csunRed,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Equipment Checkout',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 28 : 42,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 14),
            const Text(
              'Reserve university equipment, monitor due dates, and keep projects moving.',
              style: TextStyle(color: Colors.white, fontSize: 17, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({required this.onContinue});

  final ValueChanged<UserRole> onContinue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome, Matador',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in with your university account to continue.',
                style: TextStyle(color: AppColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 28),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'CSUN email',
                  hintText: 'student@my.csun.edu',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 14),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => onContinue(UserRole.student),
                child: const Text('Continue as student'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => onContinue(UserRole.staff),
                icon: const Icon(Icons.badge_outlined),
                label: const Text('Open staff demo'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Prototype only: authentication will be connected to Firebase in a later phase.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
