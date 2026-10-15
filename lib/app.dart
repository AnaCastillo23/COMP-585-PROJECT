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
  UserRole? _activeRole;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CSUN Equipment Checkout',
      theme: AppTheme.lightTheme,
      home: _activeRole == null
          ? LoginScreen(
              onContinue: (role) => setState(() => _activeRole = role),
            )
          : ResponsiveAppShell(
              initialRole: _activeRole!,
              onSignOut: () => setState(() => _activeRole = null),
            ),
    );
  }
}
