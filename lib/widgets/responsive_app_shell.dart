import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/user_role.dart';
import '../screens/profile_screen.dart';
import '../screens/staff/staff_dashboard.dart';
import '../screens/student/equipment_catalog.dart';
import '../screens/student/my_rentals.dart';
import '../screens/student/student_dashboard.dart';

class ResponsiveAppShell extends StatefulWidget {
  const ResponsiveAppShell({
    super.key,
    required this.initialRole,
    required this.onSignOut,
  });

  final UserRole initialRole;
  final VoidCallback onSignOut;

  @override
  State<ResponsiveAppShell> createState() => _ResponsiveAppShellState();
}

class _ResponsiveAppShellState extends State<ResponsiveAppShell> {
  late UserRole _role;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
  }

  List<_Destination> get _destinations => _role == UserRole.student
      ? const [
          _Destination('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
          _Destination('Browse', Icons.grid_view_outlined, Icons.grid_view),
          _Destination(
            'My Rentals',
            Icons.assignment_outlined,
            Icons.assignment,
          ),
          _Destination('Profile', Icons.person_outline, Icons.person),
        ]
      : const [
          _Destination('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
          _Destination(
            'Inventory',
            Icons.inventory_2_outlined,
            Icons.inventory_2,
          ),
          _Destination(
            'Checkouts',
            Icons.qr_code_scanner,
            Icons.qr_code_scanner,
          ),
          _Destination('Profile', Icons.person_outline, Icons.person),
        ];

  Widget get _selectedScreen {
    if (_role == UserRole.student) {
      return switch (_selectedIndex) {
        0 => StudentDashboardScreen(
          onBrowseAll: () => setState(() => _selectedIndex = 1),
        ),
        1 => const EquipmentCatalogScreen(),
        2 => const MyRentalsScreen(),
        _ => ProfileScreen(role: _role),
      };
    }

    return switch (_selectedIndex) {
      0 => const StaffDashboardScreen(),
      1 => const _ComingSoonScreen(
        title: 'Inventory Management',
        description: 'Add, edit, filter, and inspect university equipment.',
        icon: Icons.inventory_2_outlined,
      ),
      2 => const _ComingSoonScreen(
        title: 'Checkout and Return',
        description: 'Scan a student and an equipment QR code to complete staff-assisted transactions.',
        icon: Icons.qr_code_scanner,
      ),
      _ => ProfileScreen(role: _role),
    };
  }

  void _switchRole() {
    setState(() {
      _role = _role == UserRole.student ? UserRole.staff : UserRole.student;
      _selectedIndex = 0;
    });
  }

  void _handleAccountAction(String action) {
    if (action == 'switch-role') {
      _switchRole();
    } else if (action == 'sign-out') {
      widget.onSignOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        return desktop ? _buildDesktop() : _buildMobile();
      },
    );
  }

  Widget _buildDesktop() {
    return Scaffold(
      body: Row(
        children: [
          _DesktopSidebar(
            destinations: _destinations,
            selectedIndex: _selectedIndex,
            onSelected: (index) => setState(() => _selectedIndex = index),
            onSignOut: widget.onSignOut,
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  pageTitle: _destinations[_selectedIndex].label,
                  role: _role,
                  onAccountAction: _handleAccountAction,
                ),
                Expanded(child: _selectedScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              color: AppColors.csunRed,
              child: const Text(
                'CSUN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _destinations[_selectedIndex].label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleAccountAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'switch-role',
                child: Text(
                  'Switch to ${_role == UserRole.student ? 'staff' : 'student'} view',
                ),
              ),
              const PopupMenuItem(value: 'sign-out', child: Text('Sign out')),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.charcoal,
                foregroundColor: Colors.white,
                child: Text(
                  'MR',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _selectedScreen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.onSignOut,
  });

  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      child: ColoredBox(
        color: AppColors.charcoal,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                height: 86,
                color: AppColors.csunRed,
                alignment: Alignment.center,
                child: const Text(
                  'CSUN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              for (var index = 0; index < destinations.length; index++)
                _SidebarItem(
                  destination: destinations[index],
                  selected: selectedIndex == index,
                  onTap: () => onSelected(index),
                ),
              const Spacer(),
              _SidebarItem(
                destination: const _Destination(
                  'Sign out',
                  Icons.logout,
                  Icons.logout,
                ),
                selected: false,
                onTap: onSignOut,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : const Color(0xFFD3D3D3);

    return Material(
      color: selected
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? AppColors.csunRed : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                color: color,
                size: 25,
              ),
              const SizedBox(height: 6),
              Text(
                destination.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.pageTitle,
    required this.role,
    required this.onAccountAction,
  });

  final String pageTitle;
  final UserRole role;
  final ValueChanged<String> onAccountAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              pageTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            onPressed: () {},
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: onAccountAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'switch-role',
                child: Text(
                  'Switch to ${role == UserRole.student ? 'staff' : 'student'} view',
                ),
              ),
              const PopupMenuItem(value: 'sign-out', child: Text('Sign out')),
            ],
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.csunRed,
                  foregroundColor: Colors.white,
                  child: Text(
                    'MR',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mehrdad R.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      role.label,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.csunRed),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'This workflow is intentionally left as a placeholder in the bare-bones version.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
