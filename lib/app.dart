import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'models/user_role.dart';
import 'screens/login_screen.dart';
import 'widgets/responsive_app_shell.dart';

class EquipmentRentalApp extends StatefulWidget {
  const EquipmentRentalApp({super.key});

  @override
  State<EquipmentRentalApp> createState() => _EquipmentRentalAppState();
}

class _EquipmentRentalAppState extends State<EquipmentRentalApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  UserRole? _activeRole;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'CSUN Equipment Checkout',
      theme: AppTheme.lightTheme,
      home: _activeRole == null
          ? LoginScreen(
              onContinue: (role) {
                // Close any pushed screens (create account, staff login)
                // so the new home screen is what the user sees.
                _navigatorKey.currentState?.popUntil((route) => route.isFirst);
                setState(() => _activeRole = role);
              },
            )
          : ResponsiveAppShell(
              initialRole: _activeRole!,
              onSignOut: () {
                _navigatorKey.currentState?.popUntil((route) => route.isFirst);
                setState(() => _activeRole = null);
              },
            ),
    );
  }
}