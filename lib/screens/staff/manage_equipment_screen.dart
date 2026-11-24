import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/equipment.dart';
import '../../services/equipment_service.dart';
import '../../widgets/equipment_image.dart';
import 'equipment_form_dialog.dart';

(Color, Color) _statusColors(EquipmentStatus status) => switch (status) {
  EquipmentStatus.available => (
    const Color(0xFF247A4A),
    const Color(0xFFDDF3E5),
  ),
  EquipmentStatus.unavailable => (AppColors.csunRed, const Color(0xFFFFE0E4)),
  EquipmentStatus.maintenance => (
    const Color(0xFFB36B00),
    const Color(0xFFFFEBCB),
  ),
  EquipmentStatus.reserved => (
    const Color(0xFF8A5BB5),
    const Color(0xFFEFE3FA),
  ),
};

class ManageEquipmentScreen extends StatefulWidget {
  const ManageEquipmentScreen({super.key, this.equipmentService});

  final EquipmentService? equipmentService;

  @override
  State<ManageEquipmentScreen> createState() => _ManageEquipmentScreenState();
}

class _ManageEquipmentScreenState extends State<ManageEquipmentScreen> {
  static const _allCategories = 'All categories';
  static const _allStatuses = 'All statuses';
  static const _pageSize = 10;

  late final EquipmentService _service =
      widget.equipmentService ?? FirestoreEquipmentService();

  // Created once, so typing in the search box doesn't restart the stream.
  late final Stream<List<Equipment>> _stream = _service.watchEquipment();

  final _searchController = TextEditingController();
  String _category = _allCategories;
  String _status = _allStatuses;
  int _page = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Returns the unit-ID query when the search text matches a unit ID.
  String? _unitIdQuery(List<Equipment> all) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return null;

    return all.any(
          (item) => item.units.any((unit) => unit.id.toLowerCase().contains(q)),
        )
        ? q
        : null;
  }

  List<Equipment> _filter(List<Equipment> all, String category) {
    final q = _searchController.text.trim().toLowerCase();
    final unitIdQuery = _unitIdQuery(all);
    bool statusOk(EquipmentUnit u) =>
        _status == _allStatuses || u.status.label == _status;

    return all.where((item) {
      final matchesCategory =
          category == _allCategories || item.category == category;
      final matchesStatus = _status == _allStatuses || item.units.any(statusOk);

      final matchesSearch = unitIdQuery != null
          ? item.units.any(
              (u) => u.id.toLowerCase().contains(unitIdQuery) && statusOk(u),
            )
          : q.isEmpty ||
                item.name.toLowerCase().contains(q) ||
                item.category.toLowerCase().contains(q);

      return matchesCategory && matchesStatus && matchesSearch;
    }).toList();
  }

  // Any filter change sends the user back to page 1.
  void _updateFilter(VoidCallback update) {
    setState(() {
      update();
      _page = 0;
    });
  }

  void _clearFilters() {
    _updateFilter(() {
      _searchController.clear();
      _category = _allCategories;
      _status = _allStatuses;
    });
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _showItemDetails(Equipment item) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFFEFC),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ItemDetailsCarousel(item: item),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit equipment',
                      onPressed: () async {
                        Navigator.of(dialogContext).pop();
                        await Future<void>.delayed(Duration.zero);
                        if (!mounted) return;
                        await showEquipmentFormDialog(
                          context,
                          _service,
                          existing: item,
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  '${item.category} • ${item.totalUnits} '
                  'unit${item.totalUnits == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Units',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                if (item.units.isEmpty)
                  const Text(
                    'This item has no units.',
                    style: TextStyle(color: AppColors.muted),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: _UnitsTable(units: item.units),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(Equipment item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${item.name}?'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        content: Text(
          'This removes the item and its ${item.totalUnits} '
          'unit${item.totalUnits == 1 ? '' : 's'} from the inventory. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.csunRed),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteEquipment(item.id);
      if (!mounted) return;
      _showMessage('Deleted ${item.name}');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not delete: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Equipment>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load inventory.\n${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data!;
          // Use the full inventory, not the search or status results. A
          // category still belongs in the filter when its units are checked out.
          final categoriesInUse = {for (final item in all) item.category};
          final filterCategories = [
            _allCategories,
            ...Equipment.categories.where(categoriesInUse.contains),
          ];
          final selectedCategory = filterCategories.contains(_category)
              ? _category
              : _allCategories;
          final filtered = _filter(all, selectedCategory);
          final unitIdQuery = _unitIdQuery(all);
          final statusFilter = _status == _allStatuses
              ? null
              : EquipmentStatus.values.firstWhere((s) => s.label == _status);

          // Pagination
          final pageCount = filtered.isEmpty
              ? 1
              : (filtered.length / _pageSize).ceil();
          final page = _page.clamp(0, pageCount - 1);
          final start = page * _pageSize;
          final end = (start + _pageSize).clamp(0, filtered.length);
          final pageItems = filtered.sublist(start, end);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Equipment inventory',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Every unit has its own ID. Open an item to see and '
                  'manage its units.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 22),

                // Section header (same pattern as "Recent activity")
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () =>
                          showEquipmentFormDialog(context, _service),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add equipment'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.csunRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _InventoryFilters(
                  searchController: _searchController,
                  selectedCategory: selectedCategory,
                  selectedStatus: _status,
                  categories: filterCategories,
                  statuses: [
                    _allStatuses,
                    for (final s in EquipmentStatus.values) s.label,
                  ],
                  onSearchChanged: (_) => _updateFilter(() {}),
                  onCategoryChanged: (v) => _updateFilter(() => _category = v!),
                  onStatusChanged: (v) => _updateFilter(() => _status = v!),
                  onClear: _clearFilters,
                ),
                const SizedBox(height: 18),

                if (all.isEmpty)
                  _EmptyState(
                    onAdd: () => showEquipmentFormDialog(context, _service),
                  )
                else if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: Text('No items match your filters.')),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return _InventoryTable(
                        items: pageItems,
                        unitIdQuery: unitIdQuery,
                        statusFilter: statusFilter,
                        isWide: constraints.maxWidth >= 700,
                        onEdit: (item) => showEquipmentFormDialog(
                          context,
                          _service,
                          existing: item,
                        ),
                        onDelete: _delete,
                        onItemNameTap: _showItemDetails,
                      );
                    },
                  ),
                const SizedBox(height: 10),

                // Footer: count on its own line, pagination controls on the right.
                Text(
                  'Showing ${pageItems.length} of ${filtered.length} items'
                  '${filtered.length != all.length ? ' (${all.length} total)' : ''}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      _PageButton(
                        icon: Icons.chevron_left,
                        onPressed: page > 0
                            ? () => setState(() => _page = page - 1)
                            : null,
                      ),
                      for (var i = 0; i < pageCount; i++)
                        _PageButton(
                          label: '${i + 1}',
                          active: i == page,
                          onPressed: () => setState(() => _page = i),
                        ),
                      _PageButton(
                        icon: Icons.chevron_right,
                        onPressed: page < pageCount - 1
                            ? () => setState(() => _page = page + 1)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ───────────────────────── Filters ─────────────────────────

class _InventoryFilters extends StatelessWidget {
  const _InventoryFilters({
    required this.searchController,
    required this.selectedCategory,
    required this.selectedStatus,
    required this.categories,
    required this.statuses,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onStatusChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final String selectedCategory;
  final String selectedStatus;
  final List<String> categories;
  final List<String> statuses;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      decoration: const InputDecoration(
        hintText: 'Search by item name, category, or unit ID (e.g. EQ-0000)',
        prefixIcon: Icon(Icons.search, size: 20),
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
    );
    final categoryDropdown = _InventoryDropdown(
      value: selectedCategory,
      items: categories,
      onChanged: onCategoryChanged,
    );
    final statusDropdown = _InventoryDropdown(
      value: selectedStatus,
      items: statuses,
      onChanged: onStatusChanged,
    );
    final clearButton = TextButton(
      onPressed: onClear,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.softActionForeground,
        backgroundColor: AppColors.softActionBackground,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: const StadiumBorder(),
      ),
      child: const Text('Clear filters'),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 760) {
            return Row(
              children: [
                Expanded(flex: 2, child: search),
                const SizedBox(width: 12),
                Expanded(child: categoryDropdown),
                const SizedBox(width: 12),
                Expanded(child: statusDropdown),
                const SizedBox(width: 10),
                clearButton,
              ],
            );
          }

          return Column(
            children: [
              search,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: categoryDropdown),
                  const SizedBox(width: 12),
                  Expanded(child: statusDropdown),
                ],
              ),
              const SizedBox(height: 6),
              Align(alignment: Alignment.centerRight, child: clearButton),
            ],
          );
        },
      ),
    );
  }
}

class _InventoryDropdown extends StatelessWidget {
  const _InventoryDropdown({
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

// ───────────────────────── Table ─────────────────────────

class _InventoryTable extends StatelessWidget {
  const _InventoryTable({
    required this.items,
    required this.isWide,
    required this.unitIdQuery,
    required this.statusFilter,
    required this.onEdit,
    required this.onDelete,
    required this.onItemNameTap,
  });

  final List<Equipment> items;
  final bool isWide;
  final String? unitIdQuery; // if non-null, only matching units are shown
  final EquipmentStatus?
  statusFilter; // if non-null, only units with this status are shown
  final void Function(Equipment item) onEdit;
  final void Function(Equipment item) onDelete;
  final void Function(Equipment item) onItemNameTap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (unitIdQuery != null) {
      for (final item in items) {
        final matchingUnits = item.units.where(
          (unit) =>
              unit.id.toLowerCase().contains(unitIdQuery!) &&
              (statusFilter == null || unit.status == statusFilter),
        );
        for (final unit in matchingUnits) {
          rows
            ..add(
              _UnitSearchRow(
                item: item,
                unit: unit,
                isWide: isWide,
                onItemNameTap: () => onItemNameTap(item),
                onEdit: () => onEdit(item),
                onDelete: () => onDelete(item),
              ),
            )
            ..add(const Divider(height: 1, color: AppColors.border));
        }
      }
      if (rows.isNotEmpty) rows.removeLast();
    } else {
      for (var i = 0; i < items.length; i++) {
        rows
          ..add(
            _InventoryRow(
              item: items[i],
              unitIdQuery: null,
              statusFilter: statusFilter,
              isWide: isWide,
              onEdit: () => onEdit(items[i]),
              onDelete: () => onDelete(items[i]),
              onItemNameTap: () => onItemNameTap(items[i]),
            ),
          )
          ..add(const Divider(height: 1, color: AppColors.border));
      }
      if (rows.isNotEmpty) rows.removeLast();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          if (isWide && unitIdQuery == null) const _InventoryHeader(),
          if (isWide && unitIdQuery == null)
            const Divider(height: 1, color: AppColors.border),
          ...rows,
        ],
      ),
    );
  }
}

class _InventoryHeader extends StatelessWidget {
  const _InventoryHeader();

  @override
  Widget build(BuildContext context) {
    // Left padding matches the row's tilePadding; right SizedBox leaves room
    // for the expand arrow.
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 5, child: _HeaderLabel('ITEM')),
          Expanded(flex: 2, child: _HeaderLabel('CATEGORY')),
          Expanded(flex: 2, child: _HeaderLabel('AVAILABILITY')),
          Expanded(flex: 4, child: _HeaderLabel('UNIT STATUS')),
          SizedBox(width: 40),
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

class _UnitSearchRow extends StatelessWidget {
  const _UnitSearchRow({
    required this.item,
    required this.unit,
    required this.isWide,
    required this.onItemNameTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Equipment item;
  final EquipmentUnit unit;
  final bool isWide;
  final VoidCallback onItemNameTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColors = _statusColors(unit.status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 18 : 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onItemNameTap,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Text(
                  unit.id,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                _Pill(
                  label: unit.status.label,
                  foreground: statusColors.$1,
                  background: statusColors.$2,
                ),
              ],
            ),
          ),
          _ItemActions(onEdit: onEdit, onDelete: onDelete, showEdit: false),
        ],
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({
    required this.item,
    required this.isWide,
    required this.unitIdQuery,
    required this.statusFilter,
    required this.onEdit,
    required this.onDelete,
    required this.onItemNameTap,
  });

  final Equipment item;
  final bool isWide;
  final String? unitIdQuery; // non-null = show matching units
  final EquipmentStatus?
  statusFilter; // non-null = show only units with this status
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onItemNameTap;

  bool get _isFiltered => unitIdQuery != null || statusFilter != null;

  // Units this row displays: narrowed by unit-ID query and/or status filter.
  List<EquipmentUnit> get _units => item.units
      .where(
        (u) =>
            (unitIdQuery == null ||
                u.id.toLowerCase().contains(unitIdQuery!)) &&
            (statusFilter == null || u.status == statusFilter),
      )
      .toList();

  int _count(EquipmentStatus s) => _units.where((u) => u.status == s).length;

  List<Widget> _statusPills() => [
    for (final s in EquipmentStatus.values)
      if (_count(s) > 0)
        _Pill(
          label: '${_count(s)} ${s.label.toLowerCase()}',
          foreground: _statusColors(s).$1,
          background: _statusColors(s).$2,
        ),
  ];

  @override
  Widget build(BuildContext context) {
    final units = _units;
    final availableText = _isFiltered
        ? '${units.length} of ${item.totalUnits} units'
        : '${_count(EquipmentStatus.available)} of ${units.length} available';

    final statusArea = units.isEmpty
        ? const Text(
            'No units',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          )
        : Wrap(spacing: 6, runSpacing: 4, children: _statusPills());
    if (unitIdQuery != null) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 18 : 14,
          vertical: 10,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  for (final unit in units)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          unit.id,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Pill(
                          label: unit.status.label,
                          foreground: _statusColors(unit.status).$1,
                          background: _statusColors(unit.status).$2,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _ItemActions(onEdit: onEdit, onDelete: onDelete),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 18 : 14, vertical: 4),
      child: isWide
          ? Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _ItemSummary(item: item, onNameTap: onItemNameTap),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _Pill(
                      label: item.category,
                      foreground: AppColors.muted,
                      background: const Color(0xFFE9EDF2),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    availableText,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(flex: 4, child: statusArea),
                _ItemActions(onEdit: onEdit, onDelete: onDelete),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ItemSummary(item: item, onNameTap: onItemNameTap),
                    ),
                    _ItemActions(onEdit: onEdit, onDelete: onDelete),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Pill(
                      label: item.category,
                      foreground: AppColors.muted,
                      background: const Color(0xFFE9EDF2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      availableText,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _UnitsTable extends StatelessWidget {
  const _UnitsTable({required this.units});

  final List<EquipmentUnit> units;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, color: Color(0xFFD8DDE4)),
        const SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'UNIT ID',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'STATUS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFD8DDE4)),
        for (var index = 0; index < units.length; index++) ...[
          SizedBox(
            height: 52,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      units[index].id,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _Pill(
                        label: units[index].status.label,
                        foreground: _statusColors(units[index].status).$1,
                        background: _statusColors(units[index].status).$2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (index < units.length - 1)
            const Divider(height: 1, color: Color(0xFFD8DDE4)),
        ],
      ],
    );
  }
}

class _ItemDetailsCarousel extends StatefulWidget {
  const _ItemDetailsCarousel({required this.item});

  final Equipment item;

  @override
  State<_ItemDetailsCarousel> createState() => _ItemDetailsCarouselState();
}

class _ItemDetailsCarouselState extends State<_ItemDetailsCarousel> {
  final _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.item.imageBytesList.isNotEmpty
        ? widget.item.imageBytesList
        : (widget.item.imageBytes == null
              ? const []
              : [widget.item.imageBytes!]);
    final pages = images.isEmpty
        ? <Widget>[
            ColoredBox(
              color: const Color(0xFFF1F3F6),
              child: Center(
                child: Icon(widget.item.icon, size: 56, color: Colors.black38),
              ),
            ),
          ]
        : <Widget>[
            for (final bytes in images)
              SizedBox.expand(
                child: Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: const Color(0xFFF1F3F6),
                    child: Center(
                      child: Icon(
                        widget.item.icon,
                        size: 56,
                        color: Colors.black38,
                      ),
                    ),
                  ),
                ),
              ),
          ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: ColoredBox(
              color: const Color(0xFFF1F3F6),
              child: PageView(
                key: const Key('item-details-image-carousel'),
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: pages,
              ),
            ),
          ),
        ),
        if (pages.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < pages.length; index++)
                Container(
                  width: _currentPage == index ? 18 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.csunRed
                        : const Color(0xFFC9CED6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ItemActions extends StatelessWidget {
  const _ItemActions({
    required this.onEdit,
    required this.onDelete,
    this.showEdit = true,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showEdit;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Item actions',
      color: Colors.white,
      onSelected: (action) {
        switch (action) {
          case 'edit':
            if (showEdit) onEdit();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => [
        if (showEdit)
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.edit_outlined),
              title: Text('Edit item'),
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline),
            title: Text('Delete item'),
          ),
        ),
      ],
      icon: const Icon(Icons.more_vert),
    );
  }
}

/// Image + name + description (equivalent of _ActivitySummary).
class _ItemSummary extends StatelessWidget {
  const _ItemSummary({required this.item, required this.onNameTap});

  final Equipment item;
  final VoidCallback onNameTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 44,
            height: 44,
            child: EquipmentImage(equipment: item),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: onNameTap,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 1,
                  ),
                  child: Text(
                    item.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.muted,
                    ),
                  ),
                ),
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  item.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Shared bits ─────────────────────────

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 44,
            color: AppColors.muted,
          ),
          const SizedBox(height: 12),
          Text(
            'No equipment yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'Add your first item to start building the inventory.',
            style: TextStyle(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
