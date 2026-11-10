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
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;
  int _selectedIndex = 0;
  bool _showProfile = false;
  bool _showNotifications = false;

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

  void _toggleNotifications() {
    setState(() => _showNotifications = !_showNotifications);
  }

  void _showMobileNotifications() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _NotificationsPanel(
        isBottomSheet: true,
        onSeeMore: () {
          Navigator.of(context).pop();
          Future<void>.delayed(const Duration(milliseconds: 220), () {
            if (mounted) {
              _showNotificationHistory(panelAlreadyClosed: true);
            }
          });
        },
      ),
    );
  }

  void _showNotificationHistory({bool panelAlreadyClosed = false}) {
    if (!panelAlreadyClosed) {
      setState(() => _showNotifications = false);
    }

    Future<void>.delayed(
      Duration(milliseconds: panelAlreadyClosed ? 0 : 260),
      () {
        if (!mounted) {
          return;
        }

        showGeneralDialog<void>(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Dismiss notifications',
          barrierColor: Colors.black.withValues(alpha: 0.18),
          transitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (context, animation, secondaryAnimation) {
            return const _NotificationHistoryDialog();
          },
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return FadeTransition(
              opacity: curvedAnimation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.96,
                  end: 1,
                ).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, snapshot) {
        final name =
            (snapshot.data?.data()?['name'] as String?) ??
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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    _TopBar(
                      role: _role,
                      name: name,
                      onAccountAction: _handleAccountAction,
                      onNotificationsTap: _toggleNotifications,
                    ),
                    Expanded(child: _selectedScreen),
                  ],
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: !_showNotifications,
                    child: AnimatedOpacity(
                      opacity: _showNotifications ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleNotifications,
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.06),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 68,
                  right: 24,
                  child: AnimatedSlide(
                    offset: _showNotifications
                        ? Offset.zero
                        : const Offset(0, -0.04),
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: AnimatedOpacity(
                      opacity: _showNotifications ? 1 : 0,
                      duration: const Duration(milliseconds: 140),
                      child: IgnorePointer(
                        ignoring: !_showNotifications,
                        child: _NotificationsPanel(
                          onSeeMore: _showNotificationHistory,
                        ),
                      ),
                    ),
                  ),
                ),
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
          IconButton(
            onPressed: _showMobileNotifications,
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none),
          ),
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(clipBehavior: Clip.none, children: [_selectedScreen]),
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
  const _TopBar({
    required this.role,
    required this.name,
    required this.onAccountAction,
    required this.onNotificationsTap,
  });

  final UserRole role;
  final String name;
  final ValueChanged<String> onAccountAction;
  final VoidCallback onNotificationsTap;

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
            onPressed: onNotificationsTap,
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

class _NotificationsPanel extends StatelessWidget {
  const _NotificationsPanel({
    required this.onSeeMore,
    this.isBottomSheet = false,
  });

  final VoidCallback onSeeMore;
  final bool isBottomSheet;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      borderRadius: isBottomSheet
          ? const BorderRadius.vertical(top: Radius.circular(18))
          : BorderRadius.circular(12),
      color: const Color(0xFFFCFCFD),
      child: SizedBox(
        width: isBottomSheet ? double.infinity : 340,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 480),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    Text(
                      '2 new',
                      style: TextStyle(
                        color: AppColors.csunRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: const [
                      _NotificationItem(
                        icon: Icons.schedule_outlined,
                        title: 'Pickup deadline approaching',
                        timeLabel: '5 hours ago',
                        message:
                            'Your Canon EOS R50 camera is ready for pickup. '
                            'Please collect it within 24 hours.',
                      ),
                      _NotificationItem(
                        icon: Icons.assignment_return_outlined,
                        title: 'Rental due soon',
                        timeLabel: '5 hours ago',
                        message:
                            'Your MacBook Pro rental is due in 3 days. '
                            'Return it to avoid late equipment fees.',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onSeeMore,
                    child: const Text('See More'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.timeLabel,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String timeLabel;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.csunRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.csunRed, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationHistoryDialog extends StatefulWidget {
  const _NotificationHistoryDialog();

  @override
  State<_NotificationHistoryDialog> createState() =>
      _NotificationHistoryDialogState();
}

class _NotificationHistoryDialogState
    extends State<_NotificationHistoryDialog> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'Today';

  static const _filters = ['Today', 'This week', '10 days ago', '30+ days ago'];

  static const _notifications = [
    _NotificationRecord(
      icon: Icons.schedule_outlined,
      title: 'Pickup deadline approaching',
      message: 'Your Canon EOS R50 camera is ready for pickup. Please collect it within 24 hours.',
      ageInDays: 0,
    ),
    _NotificationRecord(
      icon: Icons.assignment_return_outlined,
      title: 'Rental due soon',
      message: 'Your MacBook Pro rental is due in 3 days. Return it to avoid late equipment fees.',
      ageInDays: 5,
    ),
    _NotificationRecord(
      icon: Icons.event_available_outlined,
      title: 'Reservation confirmed',
      message: 'Your Sony Alpha camera reservation was confirmed.',
      ageInDays: 12,
    ),
    _NotificationRecord(
      icon: Icons.assignment_turned_in_outlined,
      title: 'Rental returned',
      message: 'Your GoPro HERO rental was successfully checked in.',
      ageInDays: 35,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_NotificationRecord> get _filteredNotifications {
    final query = _searchController.text.trim().toLowerCase();

    return _notifications.where((notification) {
      final matchesSearch =
          query.isEmpty ||
          notification.title.toLowerCase().contains(query) ||
          notification.message.toLowerCase().contains(query);
      final matchesDate = switch (_selectedFilter) {
        'Today' => notification.ageInDays == 0,
        'This week' => notification.ageInDays <= 7,
        '10 days ago' =>
          notification.ageInDays > 7 && notification.ageInDays <= 10,
        '30+ days ago' => notification.ageInDays > 30,
        _ => true,
      };

      return matchesSearch && matchesDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _filteredNotifications;

    return Dialog(
      backgroundColor: const Color(0xFFFCFCFD),
      elevation: 3,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'All notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search notifications',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in _filters) ...[
                      FilterChip(
                        label: Text(filter),
                        selected: _selectedFilter == filter,
                        onSelected: (_) => setState(() {
                          _selectedFilter = filter;
                        }),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 360,
                child: notifications.isEmpty
                    ? const Center(
                        child: Text('No notifications match your filters.'),
                      )
                    : ListView.separated(
                        itemCount: notifications.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return _NotificationHistoryItem(
                            notification: notification,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationHistoryItem extends StatelessWidget {
  const _NotificationHistoryItem({required this.notification});

  final _NotificationRecord notification;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(notification.icon, color: AppColors.csunRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  notification.message,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _notificationAgeLabel(notification.ageInDays),
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _notificationAgeLabel(int ageInDays) {
    if (ageInDays == 0) {
      return 'Today';
    }
    if (ageInDays == 1) {
      return '1 day ago';
    }
    return '$ageInDays days ago';
  }
}

class _NotificationRecord {
  const _NotificationRecord({
    required this.icon,
    required this.title,
    required this.message,
    required this.ageInDays,
  });

  final IconData icon;
  final String title;
  final String message;
  final int ageInDays;
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
