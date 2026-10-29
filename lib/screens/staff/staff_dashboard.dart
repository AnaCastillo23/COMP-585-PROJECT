import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/activity_entry.dart';
import '../../models/equipment.dart';
import '../../models/loan.dart';
import '../../services/activity_service.dart';
import '../../services/equipment_service.dart';
import '../../services/loan_service.dart';
import 'equipment_form_dialog.dart';
import 'manage_equipment_screen.dart';

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({
    super.key,
    this.equipmentService,
    this.onViewInventory,
  });

  final EquipmentService? equipmentService;
  final VoidCallback? onViewInventory;

  @override
  Widget build(BuildContext context) {
    final service = equipmentService ?? FirestoreEquipmentService();

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
          _StatsRow(service: service),
          const SizedBox(height: 28),
          _QuickActions(service: service, onViewInventory: onViewInventory),
          const SizedBox(height: 28),
          const _ActivityList(),
        ],
      ),
    );
  }
}

// ───────────────────────── Stats ─────────────────────────

/// Holds its streams in State so they aren't recreated on every rebuild.
class _StatsRow extends StatefulWidget {
  const _StatsRow({required this.service});

  final EquipmentService service;

  @override
  State<_StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<_StatsRow> {
  late final Stream<List<Equipment>> _equipment =
      widget.service.watchEquipment();
  late final Stream<List<Loan>> _loans = LoanService().watchActiveLoans();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Equipment>>(
      stream: _equipment,
      builder: (context, equipmentSnap) {
        return StreamBuilder<List<Loan>>(
          stream: _loans,
          builder: (context, loanSnap) {
            final items = equipmentSnap.data ?? const <Equipment>[];

            final total = items.fold<int>(0, (s, e) => s + e.totalUnits);
            final available =
                items.fold<int>(0, (s, e) => s + e.availableUnits);
            final maintenance = items.fold<int>(
              0,
              (s, e) => s + e.countWithStatus(EquipmentStatus.maintenance),
            );
           // final unavailable = items.fold<int>(
             // 0,
            //  (s, e) => s + e.countWithStatus(EquipmentStatus.unavailable),
            //);

            // Units out on a loan are also "unavailable". Whatever
            // unavailable units are NOT on a loan show up as Reserved.
            final reserved = items.fold<int>(
              0,
              (s, e) => s + e.countWithStatus(EquipmentStatus.reserved),
            );
            final checkedOut = loanSnap.data?.length ?? 0;

            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _StaffStat(
                  label: 'Total assets',
                  value: '$total',
                  icon: Icons.inventory_2_outlined,
                ),
                _StaffStat(
                  label: 'Available',
                  value: '$available',
                  icon: Icons.check_circle_outline,
                ),
                _StaffStat(
                  label: 'Checked out',
                  value: '$checkedOut',
                  icon: Icons.logout_outlined,
                ),
                _StaffStat(
                  label: 'Reserved',
                  value: '$reserved',
                  icon: Icons.event_outlined,
                ),
                _StaffStat(
                  label: 'Maintenance',
                  value: '$maintenance',
                  icon: Icons.build_outlined,
                ),
              ],
            );
          },
        );
      },
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

// ───────────────────────── Quick actions ─────────────────────────

//_QuickActions widget builds the staff dashboard's quick actions section, which includes a featured action for scanning equipment and
// four additional quick action tiles for finding students, viewing reservations, adding equipment, and reporting issues. The layout adapts to the available width, displaying the tiles in rows or columns as appropriate.
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.service, this.onViewInventory});

  final EquipmentService service;
  final VoidCallback? onViewInventory;

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
        final tiles = [
          const _QuickActionTile(
            icon: Icons.person_search_outlined,
            title: 'Find student',
            description: 'Look up a student or their loans',
          ),
          const _QuickActionTile(
            icon: Icons.event_outlined,
            title: 'Reservations',
            description: 'View upcoming pickups',
          ),
          _QuickActionTile(
            icon: Icons.add_box_outlined,
            title: 'Add equipment',
            description: 'Register a new asset',
            onTap: () => showEquipmentFormDialog(context, service),
          ),
          const _QuickActionTile(
            icon: Icons.build_outlined,
            title: 'Report issue',
            description: 'Flag damaged equipment',
          ),
        ];

        // The layout adapts to the available width, displaying the tiles in rows or columns.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Quick actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: onViewInventory ??
                      () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ManageEquipmentScreen(
                                equipmentService: service,
                              ),
                            ),
                          ),
                  icon: const Icon(Icons.inventory_2_outlined, size: 16),
                  label: const Text('View inventory'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.csunRed,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
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

// Quick action tile: icon, title, description, and an optional tap action.
class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 104,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
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
        ),
      ),
    );
  }
}

// ───────────────────────── Recent activity ─────────────────────────

class _ActivityList extends StatefulWidget {
  const _ActivityList();

  @override
  State<_ActivityList> createState() => _ActivityListState();
}

class _ActivityListState extends State<_ActivityList> {
  static const _pageSize = 5;

  // Created once so typing in the search box doesn't restart the stream.
  late final Stream<List<ActivityEntry>> _stream =
      ActivityService().watchRecent();

  final _searchController = TextEditingController();
  String _selectedType = 'All activity types';
  String _selectedStatus = 'All statuses';
  String _selectedRange = 'Last 7 days';
  int _page = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ActivityEntry> _filter(List<ActivityEntry> all) {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();
    final cutoff = switch (_selectedRange) {
      'Last 7 days' => now.subtract(const Duration(days: 7)),
      'Last 30 days' => now.subtract(const Duration(days: 30)),
      _ => null, // All time
    };

    return all.where((e) {
      final matchesSearch = query.isEmpty ||
          '${e.title} ${e.detail}'.toLowerCase().contains(query);
      final matchesType =
          _selectedType == 'All activity types' || e.type == _selectedType;
      final matchesStatus =
          _selectedStatus == 'All statuses' || e.status == _selectedStatus;
      final matchesRange = cutoff == null || e.at.isAfter(cutoff);
      return matchesSearch && matchesType && matchesStatus && matchesRange;
    }).toList();
  }

  void _updateFilter(VoidCallback update) {
    setState(() {
      update();
      _page = 0;
    });
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          onTypeChanged: (v) => _updateFilter(() => _selectedType = v!),
          onStatusChanged: (v) => _updateFilter(() => _selectedStatus = v!),
          onRangeChanged: (v) => _updateFilter(() => _selectedRange = v!),
          onClear: _clearFilters,
        ),
        const SizedBox(height: 18),
        StreamBuilder<List<ActivityEntry>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Could not load activity.\n${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final all = snapshot.data!;
            final filtered = _filter(all);

            final pageCount =
                filtered.isEmpty ? 1 : (filtered.length / _pageSize).ceil();
            final page = _page.clamp(0, pageCount - 1);
            final start = page * _pageSize;
            final end = (start + _pageSize).clamp(0, filtered.length);
            final pageItems = filtered.sublist(start, end);

            // Show at most 5 page buttons, centered on the current page.
            final first =
                (page - 2).clamp(0, (pageCount - 5).clamp(0, pageCount));
            final last = (first + 5).clamp(0, pageCount);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (filtered.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: Text(
                        all.isEmpty
                            ? 'No activity yet. Checkouts and returns will appear here.'
                            : 'No activity matches your filters.',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) => _ActivityTable(
                      activities: [for (final e in pageItems) _toUi(e)],
                      isWide: constraints.maxWidth >= 700,
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Showing ${pageItems.length} of ${filtered.length} activities',
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const Spacer(),
                    _ActivityPageButton(
                      icon: Icons.chevron_left,
                      onPressed: page > 0
                          ? () => setState(() => _page = page - 1)
                          : null,
                    ),
                    for (var i = first; i < last; i++)
                      _ActivityPageButton(
                        label: '${i + 1}',
                        active: i == page,
                        onPressed: () => setState(() => _page = i),
                      ),
                    _ActivityPageButton(
                      icon: Icons.chevron_right,
                      onPressed: page < pageCount - 1
                          ? () => setState(() => _page = page + 1)
                          : null,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// Maps a Firestore activity entry onto the row widgets' display model.
_ActivityEntry _toUi(ActivityEntry e) {
  final icon = switch (e.type) {
    'Return' => Icons.assignment_return_outlined,
    'Checkout' => Icons.inventory_2_outlined,
    'Reservation' => Icons.event_outlined,
    'Maintenance' => Icons.build_outlined,
    _ => Icons.history,
  };
  final (fg, bg) = switch (e.status) {
    'Completed' => (const Color(0xFF247A4A), const Color(0xFFDDF3E5)),
    'Pickup pending' => (const Color(0xFFB36B00), const Color(0xFFFFEBCB)),
    'Damaged' || 'Needs attention' => (AppColors.csunRed, const Color(0xFFFFE0E4)),
    'Checked out' => (const Color(0xFF1377C9), const Color(0xFFDCEEFF)),
    _ => (AppColors.muted, const Color(0xFFE9EDF2)),
  };

  return _ActivityEntry(
    title: e.title,
    detail: e.detail,
    type: e.type,
    status: e.status,
    timestamp: _timeAgo(e.at),
    icon: icon,
    statusColor: fg,
    statusBackground: bg,
  );
}

String _timeAgo(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  if (diff.inDays < 7) {
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }
  return ActivityService.shortDate(t);
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
      // Key forces a rebuild so "Clear filters" resets the displayed value.
      key: ValueKey(value),
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
                  background: const Color(0xFFE9EDF2),
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
              // Would open an activity details page (not implemented yet).
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
                background: const Color(0xFFE9EDF2),
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

/// Display model for one table row (built from a Firestore [ActivityEntry]).
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
  const _ActivityPageButton({
    this.label,
    this.icon,
    this.active = false,
    this.onPressed,
  });

  final String? label;
  final IconData? icon;
  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: SizedBox(
        width: 28,
        height: 28,
        child: OutlinedButton(
          onPressed: onPressed,
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