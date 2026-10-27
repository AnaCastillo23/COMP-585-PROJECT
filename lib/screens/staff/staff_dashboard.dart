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
          const _QuickActions(),
          const SizedBox(height: 28),
          const _ActivityList(),
        ],
      ),
    );
  }
}

//_QuickActions widget builds the staff dashboard's quick actions section, which includes a featured action for scanning equipment and
// four additional quick action tiles for finding students, viewing reservations, adding equipment, and reporting issues. The layout adapts to the available width, displaying the tiles in rows or columns as appropriate.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  // widget for the quick actions section of the staff dashboard
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      // LayoutBuilder is used to determine the available width and adjust the layout of the quick action tiles
      builder: (context, constraints) {
        // if the width is greater than or equal to 620 pixels, the tiles are displayed in two rows of two tiles each;
        // 620 pixels was used based on the approximate space needed for two action tiles to fit side by side with some spacing between them.
        // because the tiles use Expanded widgets, they will automatically adjust their width to fill the available space in each row.
        // this width will be divided between the two tiles after accounting for a 12 pixel gap.
        // otherwise, they are displayed in a single column stcaked vertically.
        // The featured quick action for scanning equipment is always displayed at the top of the section.
        // each _QuickActionTile receives an icon, title, and description as parameters, which are used to build the tile's content.
        final isWide = constraints.maxWidth >= 620;
        const tiles = [
          _QuickActionTile(
            icon: Icons.person_search_outlined,
            title: 'Find student',
            description: 'Look up a student or their loans',
          ),
          _QuickActionTile(
            icon: Icons.event_outlined,
            title: 'Reservations',
            description: 'View upcoming pickups',
          ),
          _QuickActionTile(
            icon: Icons.add_box_outlined,
            title: 'Add equipment',
            description: 'Register a new asset',
          ),
          _QuickActionTile(
            icon: Icons.build_outlined,
            title: 'Report issue',
            description: 'Flag damaged equipment',
          ),
        ];

        // The layout adapts to the available width, displaying the tiles in rows or columns.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const _FeaturedQuickAction(),
            const SizedBox(height: 12),
            if (isWide)
              Row(
                children: [
                  Expanded(child: tiles[0]),
                  const SizedBox(width: 12),
                  Expanded(child: tiles[1]),
                ],
              )
            else
              tiles[0],
            const SizedBox(height: 12),
            if (isWide)
              Row(
                children: [
                  Expanded(child: tiles[2]),
                  const SizedBox(width: 12),
                  Expanded(child: tiles[3]),
                ],
              )
            else
              Column(
                children: [tiles[1], const SizedBox(height: 12), tiles[2]],
              ),
            if (!isWide) ...[const SizedBox(height: 12), tiles[3]],
          ],
        );
      },
    );
  }
}

// the scan equipment quick action tile is a featured action that is displayed at the top of the quick actions section of the staff dashboard.
//It has a larger size than the other quick action tiles, and it includes an icon, title, and description.
class _FeaturedQuickAction extends StatelessWidget {
  const _FeaturedQuickAction();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.csunRed,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan equipment',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Start a checkout or return',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}

// this is for the quick action tiles that are displayed in the quick actions section of the staff dashboard
// each tile has an icon, title, and description
class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 104,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.csunRed, size: 21),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
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

// for the activity list section of the staff dashboard, which displays recent activity in a table format with filters for searching and sorting
class _ActivityList extends StatefulWidget {
  const _ActivityList();

  @override
  State<_ActivityList> createState() => _ActivityListState();
}

class _ActivityListState extends State<_ActivityList> {
  final _searchController = TextEditingController();
  String _selectedType = 'All activity types';
  String _selectedStatus = 'All statuses';
  String _selectedRange = 'Last 7 days';

  // this is static list at the moment of recent activity entries, which will be replaced with dynamic data in the future
  static const _activities = [
    // all values are hardcoded for now, will be replaced with dynamic data in the future.
    // all entries are stored here, and they contain a title, detail, type, status, timestamp, icon, status color, and status background color.
    _ActivityEntry(
      title: 'Camera CAM-018 returned',
      detail: 'Student ID ending in 4821',
      type: 'Return',
      status: 'Completed',
      timestamp: '12 min ago',
      icon: Icons.photo_camera_outlined,
      statusColor: Color(
        0xFF247A4A,
      ), // the color of the status pill, which is green for completed
      statusBackground: Color(0xFFDDF3E5),
    ),
    _ActivityEntry(
      title: 'Laptop reservation ready',
      detail: 'Pickup window ends tomorrow at 3:30 PM',
      type: 'Reservation',
      status: 'Pickup pending',
      timestamp: '28 min ago',
      icon: Icons.laptop_mac_outlined,
      statusColor: Color(0xFFB36B00),
      statusBackground: Color(0xFFFFEBCB),
    ),
    _ActivityEntry(
      title: 'Tripod condition updated',
      detail: 'TRI-031 marked for staff inspection',
      type: 'Maintenance',
      status: 'Needs attention',
      timestamp: '46 min ago',
      icon: Icons.build_outlined,
      statusColor: AppColors.csunRed,
      statusBackground: Color(0xFFFFE0E4),
    ),
    _ActivityEntry(
      title: 'Laptop LPT-024 checked out',
      detail: 'Due Oct 21, 2026',
      type: 'Checkout',
      status: 'Checked out',
      timestamp: '1 hr ago',
      icon: Icons.inventory_2_outlined,
      statusColor: Color(0xFF1377C9),
      statusBackground: Color(0xFFDCEEFF),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // filtering the activities based on the search query, selected type, selected status, and selected range.
  // The filtered activities are returned as a list of _ActivityEntry objects.
  List<_ActivityEntry> get _filteredActivities {
    final query = _searchController.text.trim().toLowerCase();

    return _activities.where((activity) {
      final matchesSearch =
          query.isEmpty ||
          '${activity.title} ${activity.detail}'.toLowerCase().contains(query);
      final matchesType =
          _selectedType == 'All activity types' ||
          activity.type == _selectedType;
      final matchesStatus =
          _selectedStatus == 'All statuses' ||
          activity.status == _selectedStatus;

      return matchesSearch && matchesType && matchesStatus;
    }).toList();
  }

  void _updateFilter(VoidCallback update) {
    setState(update);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Scrollable.ensureVisible(
        context,
        alignment: 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _clearFilters() {
    _updateFilter(() {
      _searchController.clear();
      _selectedType = 'All activity types';
      _selectedStatus = 'All statuses';
      _selectedRange = 'Last 7 days';
    });
  }

  @override
  Widget build(BuildContext context) {
    final activities = _filteredActivities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // header for the recent activity section, which includes a title and a button to view all activities
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent activity',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.arrow_forward, size: 16),
              // view all button would take the user to a page showing all activity entries, which is not implemented yet
              // pagination is also a visual placeholder for now, as the activity list is static and does not support pagination yet.
              label: const Text('View all'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.csunRed,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ActivityFilters(
          searchController: _searchController,
          selectedType: _selectedType,
          selectedStatus: _selectedStatus,
          selectedRange: _selectedRange,
          onSearchChanged: (_) => _updateFilter(() {}),
          onTypeChanged: (value) => _updateFilter(() => _selectedType = value!),
          onStatusChanged: (value) =>
              _updateFilter(() => _selectedStatus = value!),
          onRangeChanged: (value) =>
              _updateFilter(() => _selectedRange = value!),
          onClear: _clearFilters,
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            return _ActivityTable(
              activities: activities,
              isWide: constraints.maxWidth >= 700,
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          // controls for switching between pages of activity entries, which includes a label showing the number of activities being displayed and buttons for navigating to different pages
          children: [
            Text(
              // result count shows how many activities currently match the filters or the search.
              'Showing ${activities.length} of ${activities.length} activities',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const Spacer(),
            const _ActivityPageButton(icon: Icons.chevron_left),
            const _ActivityPageButton(label: '1', active: true),
            const _ActivityPageButton(label: '2'),
            const _ActivityPageButton(label: '3'),
            const _ActivityPageButton(label: '4'),
            const _ActivityPageButton(label: '5'),
            const _ActivityPageButton(icon: Icons.chevron_right),
          ],
        ),
      ],
    );
  }
}

class _ActivityFilters extends StatelessWidget {
  const _ActivityFilters({
    required this.searchController,
    required this.selectedType,
    required this.selectedStatus,
    required this.selectedRange,
    required this.onSearchChanged,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onRangeChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final String selectedType;
  final String selectedStatus;
  final String selectedRange;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onRangeChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    // search and filter controls for the recent activity section, which includes a search bar and dropdowns for filtering by activity type, status, and date range
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(9),
      ),
      // LayoutBuilder is used to determine the available width and adjust the layout of the search and filter controls
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          final controls = [
            Expanded(
              flex: 2,
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search activity or asset ID',
                  prefixIcon: Icon(Icons.search, size: 20),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              // this is for drop down filters
              child: _ActivityDropdown(
                value: selectedType,
                items: const [
                  'All activity types',
                  'Return',
                  'Reservation',
                  'Maintenance',
                  'Checkout',
                ],
                onChanged: onTypeChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActivityDropdown(
                value: selectedStatus,
                items: const [
                  'All statuses',
                  'Completed',
                  'Pickup pending',
                  'Needs attention',
                  'Checked out',
                ],
                onChanged: onStatusChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActivityDropdown(
                value: selectedRange,
                items: const ['Last 7 days', 'Last 30 days', 'All time'],
                onChanged: onRangeChanged,
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.csunRed,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: const Text('Clear filters'),
            ),
          ];

          if (isWide) {
            return Row(children: controls);
          }

          return Column(
            children: [
              controls[0],
              const SizedBox(height: 10),
              Row(children: [controls[2], controls[3]]),
              const SizedBox(height: 10),
              Row(children: [controls[4], controls[6]]),
            ],
          );
        },
      ),
    );
  }
}

class _ActivityDropdown extends StatelessWidget {
  const _ActivityDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
      onChanged: onChanged,
    );
  }
}

class _ActivityTable extends StatelessWidget {
  const _ActivityTable({required this.activities, required this.isWide});

  final List<_ActivityEntry> activities;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          if (isWide) const _ActivityHeader(),
          for (var index = 0; index < activities.length; index++) ...[
            isWide
                ? _ActivityWideRow(activity: activities[index])
                : _ActivityCompactRow(activity: activities[index]),
            if (index != activities.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _ActivityHeader extends StatelessWidget {
  const _ActivityHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 5, child: _HeaderLabel('ACTIVITY')),
          Expanded(flex: 2, child: _HeaderLabel('TYPE')),
          Expanded(flex: 2, child: _HeaderLabel('STATUS')),
          Expanded(flex: 2, child: _HeaderLabel('TIMESTAMP')),
          SizedBox(width: 20),
        ],
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _ActivityWideRow extends StatelessWidget {
  const _ActivityWideRow({required this.activity});

  final _ActivityEntry activity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            Expanded(flex: 5, child: _ActivitySummary(activity: activity)),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _ActivityPill(
                  label: activity.type,
                  foreground: AppColors.muted,
                  background: Color(0xFFE9EDF2),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _ActivityPill(
                  // activity pills are for easy identification of the activity type and status, with different colors for each status
                  label: activity.status,
                  foreground: activity.statusColor,
                  background: activity.statusBackground,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                activity.timestamp,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
            const SizedBox(
              // chevron icon would take the user to the activity details page, which is not implemented yet
              width: 20,
              child: Icon(Icons.chevron_right, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCompactRow extends StatelessWidget {
  const _ActivityCompactRow({required this.activity});

  final _ActivityEntry activity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _ActivitySummary(activity: activity)),
              Text(
                activity.timestamp,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ActivityPill(
                label: activity.type,
                foreground: AppColors.muted,
                background: Color(0xFFE9EDF2),
              ),
              const SizedBox(width: 8),
              _ActivityPill(
                label: activity.status,
                foreground: activity.statusColor,
                background: activity.statusBackground,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivitySummary extends StatelessWidget {
  const _ActivitySummary({required this.activity});

  final _ActivityEntry activity;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.csunRed.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(activity.icon, color: AppColors.csunRed, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                activity.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                activity.detail,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityPill extends StatelessWidget {
  const _ActivityPill({
    required this.label,
    this.foreground = AppColors.csunRed,
    this.background = const Color(0xFFFFE7EA),
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityEntry {
  const _ActivityEntry({
    required this.title,
    required this.detail,
    required this.type,
    required this.status,
    required this.timestamp,
    required this.icon,
    required this.statusColor,
    required this.statusBackground,
  });

  final String title;
  final String detail;
  final String type;
  final String status;
  final String timestamp;
  final IconData icon;
  final Color statusColor;
  final Color statusBackground;
}

class _ActivityPageButton extends StatelessWidget {
  const _ActivityPageButton({this.label, this.icon, this.active = false});

  final String? label;
  final IconData? icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: SizedBox(
        width: 28,
        height: 28,
        child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            backgroundColor: active ? AppColors.csunRed : Colors.white,
            foregroundColor: active ? Colors.white : AppColors.ink,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          child: icon != null
              ? Icon(icon, size: 16)
              : Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
