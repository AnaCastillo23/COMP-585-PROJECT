import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/theme/app_theme.dart';
import '../models/user_role.dart';
import '../screens/profile_screen.dart';
import '../screens/staff/staff_dashboard.dart';
import '../screens/student/equipment_catalog.dart';
import '../screens/student/my_rentals.dart';
import '../screens/student/student_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/user_display.dart';
import '../screens/staff/manage_equipment_screen.dart';
import '../screens/staff/checkout_screen.dart';

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
  bool _showProfile = false;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    _userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots();
  }
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
        ];

  Widget get _selectedScreen {
    if (_showProfile) {
      return ProfileScreen(role: _role);
    }

    if (_role == UserRole.student) {
      return switch (_selectedIndex) {
        0 => StudentDashboardScreen(
          onBrowseAll: () => setState(() => _selectedIndex = 1),
        ),
        1 => const EquipmentCatalogScreen(),
        2 => const MyRentalsScreen(),
        _ => const StudentDashboardScreen(onBrowseAll: _noop),
      };
    }

    return switch (_selectedIndex) {
    0 => StaffDashboardScreen(
      onViewInventory: () => setState(() {
        _selectedIndex = 1;
        _showProfile = false;
      }),
    ),
    1 => const ManageEquipmentScreen(),
    2 => const CheckoutsScreen(),
    _ => const StaffDashboardScreen(),
  };
}

  static void _noop() {}

  void _switchRole() {
    setState(() {
      _role = _role == UserRole.student ? UserRole.staff : UserRole.student;
      _selectedIndex = 0;
      _showProfile = false;
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    widget.onSignOut();
  }

  void _handleAccountAction(String action) {
    if (action == 'switch-role') {
      _switchRole();
    } else if (action == 'profile') {
      setState(() => _showProfile = true);
    } else if (action == 'sign-out') {
      _signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, snapshot) {
        final name = (snapshot.data?.data()?['name'] as String?) ??
          FirebaseAuth.instance.currentUser?.displayName ??
          'User';
        return LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 900;
            return desktop ? _buildDesktop(name) : _buildMobile(name);
          },
        );
      },
    );
  }

  // This is the widget for the desktop layout, which includes a sidebar and a top bar.
  Widget _buildDesktop(String name) {
    return Scaffold(
      body: Row(
        children: [
          _DesktopSidebar(
            destinations: _destinations,
            // If the profile screen is being shown, we don't want any of the sidebar items to be selected.
            selectedIndex: _showProfile ? null : _selectedIndex,
            onSelected: (index) => setState(() {
              _selectedIndex = index;
              _showProfile = false;
            }),
            onSignOut: _signOut,
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(role: _role, name: name, onAccountAction: _handleAccountAction),
                Expanded(child: _selectedScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(String name) {
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
            const Spacer(),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleAccountAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'switch-role',
                child: Text(
                  'Switch to ${_role == UserRole.student ? 'staff' : 'student'} view', // this controls switching between users
                ),
              ),
              // Add a menu item for the user's profile
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20), // added a profile icon to the profile option in the drop down menu
                    SizedBox(width: 12),
                    Text('Profile'),
                  ],
                ),
              ),
              // Add a menu item for signing out
              const PopupMenuItem(
                value: 'sign-out',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20), // added a logout icon to the sign out option in the drop down menu
                    SizedBox(width: 12),
                    Text('Log out'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.charcoal,
                foregroundColor: Colors.white,
                child: Text(
                  initialsFor(name),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _selectedScreen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() {
          _selectedIndex = index;
          _showProfile = false;
        }),
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
  final int? selectedIndex;
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
              // _SidebarItem(
              //   destination: const _Destination(
              //     'Sign out',
              //     Icons.logout,
              //     Icons.logout,
              //   ),
              //   selected: false,
              //   onTap: onSignOut,
              // ),
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
  const _TopBar({required this.role, required this.name, required this.onAccountAction});

  final UserRole role;
  final String name;
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
          const Spacer(),
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
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sign-out',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 12),
                    Text('Log out'),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.csunRed,
                  foregroundColor: Colors.white,
                  child: Text(
                    initialsFor(name),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shortName(name),
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

/*class _ComingSoonScreen extends StatelessWidget {
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
} */

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
