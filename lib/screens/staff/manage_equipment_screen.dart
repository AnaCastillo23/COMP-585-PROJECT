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
      EquipmentStatus.unavailable => (
          AppColors.csunRed,
          const Color(0xFFFFE0E4),
        ),
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
  static const _pageSize = 5;

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

  // Returns the unit ID if the search text exactly matches one, else null.
String? _exactUnitId(List<Equipment> all) {
  final q = _searchController.text.trim().toLowerCase();
  if (q.isEmpty) return null;

  for (final item in all) {
    for (final u in item.units) {
      if (u.id.toLowerCase() == q) return u.id;
    }
  }
  return null;
}

List<Equipment> _filter(List<Equipment> all) {
  final q = _searchController.text.trim().toLowerCase();
  final exactId = _exactUnitId(all);
  bool statusOk(EquipmentUnit u) =>
      _status == _allStatuses || u.status.label == _status;

  return all.where((item) {
    final matchesCategory =
        _category == _allCategories || item.category == _category;
    final matchesStatus = item.units.any(statusOk);

    final matchesSearch = q.isEmpty ||
        (exactId != null
            ? item.units.any((u) => u.id == exactId && statusOk(u))
            : item.name.toLowerCase().contains(q) ||
                item.category.toLowerCase().contains(q) ||
                item.units.any((u) => u.id.toLowerCase().contains(q)));

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

  Future<void> _setStatus(EquipmentUnit unit, EquipmentStatus status) async {
    try {
      await _service.setUnitStatus(unit.id, status);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not update ${unit.id}: $e');
    }
  }

  Future<void> _delete(Equipment item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${item.name}?'),
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
          final filtered = _filter(all);
          final exactId = _exactUnitId(all);
          final statusFilter = _status == _allStatuses
              ? null
              : EquipmentStatus.values.firstWhere((s) => s.label == _status);

          // Pagination
          final pageCount =
              filtered.isEmpty ? 1 : (filtered.length / _pageSize).ceil();
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
                    TextButton.icon(
                      onPressed: () =>
                          showEquipmentFormDialog(context, _service),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add equipment'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.csunRed,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _InventoryFilters(
                  searchController: _searchController,
                  selectedCategory: _category,
                  selectedStatus: _status,
                  categories: const [_allCategories, ...Equipment.categories],
                  statuses: [
                    _allStatuses,
                    for (final s in EquipmentStatus.values) s.label,
                  ],
                  onSearchChanged: (_) => _updateFilter(() {}),
                  onCategoryChanged: (v) =>
                      _updateFilter(() => _category = v!),
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
                        onlyUnitId: exactId,
                        statusFilter: statusFilter,
                        isWide: constraints.maxWidth >= 700,
                        onEdit: (item) => showEquipmentFormDialog(
                          context,
                          _service,
                          existing: item,
                        ),
                        onDelete: _delete,
                        onUnitStatus: _setStatus,
                      );
                    },
                  ),
                const SizedBox(height: 10),

                // Footer: count + page buttons
                Row(
                  children: [
                    Text(
                      'Showing ${pageItems.length} of ${filtered.length} items'
                      '${filtered.length != all.length ? ' (${all.length} total)' : ''}',
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const Spacer(),
                    _PageButton(
                      icon: Icons.chevron_left,
                      onPressed:
                          page > 0 ? () => setState(() => _page = page - 1) : null,
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
        hintText: 'Search by name or unit ID(e.g. EQ-0000)',
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
        foregroundColor: AppColors.csunRed,
        padding: const EdgeInsets.symmetric(horizontal: 4),
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
    required this.onlyUnitId,
    required this.statusFilter,
    required this.onEdit,
    required this.onDelete,
    required this.onUnitStatus,
  });

  final List<Equipment> items;
  final bool isWide;
  final String? onlyUnitId; // if non-null, only this unit is shown (search match)
  final EquipmentStatus? statusFilter; // if non-null, only units with this status are shown
  final void Function(Equipment item) onEdit;
  final void Function(Equipment item) onDelete;
  final void Function(EquipmentUnit unit, EquipmentStatus status) onUnitStatus;

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
          if (isWide) const _InventoryHeader(),
          if (isWide) const Divider(height: 1, color: AppColors.border),
          for (var i = 0; i < items.length; i++) ...[
            _InventoryRow(
              item: items[i],
              onlyUnitId: onlyUnitId,
              statusFilter: statusFilter,
              isWide: isWide,
              onEdit: () => onEdit(items[i]),
              onDelete: () => onDelete(items[i]),
              onUnitStatus: onUnitStatus,
            ),
            if (i != items.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
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

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({
    required this.item,
    required this.isWide,
    required this.onlyUnitId,
    required this.statusFilter,
    required this.onEdit,
    required this.onDelete,
    required this.onUnitStatus,
  });

  final Equipment item;
  final bool isWide;
  final String? onlyUnitId; // non-null = show just this unit
  final EquipmentStatus? statusFilter; // non-null = show only units with this status
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(EquipmentUnit unit, EquipmentStatus status) onUnitStatus;

  
  bool get _isFiltered => onlyUnitId != null || statusFilter != null;

  // Units this row displays: narrowed by exact ID and/or status filter.
  List<EquipmentUnit> get _units => item.units
      .where((u) =>
          (onlyUnitId == null || u.id == onlyUnitId) &&
          (statusFilter == null || u.status == statusFilter))
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

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: ValueKey(
          '${item.id}-${onlyUnitId ?? 'all'}-${statusFilter?.name ?? 'any'}',
        ),
        initiallyExpanded: _isFiltered,
        tilePadding: EdgeInsets.symmetric(
          horizontal: isWide ? 18 : 14,
          vertical: 4,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: isWide
            ? Row(
                children: [
                  Expanded(flex: 5, child: _ItemSummary(item: item)),
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
                          color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                  Expanded(flex: 4, child: statusArea),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ItemSummary(item: item),
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
                            color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  statusArea,
                ],
              ),
        children: [
          const Text(
            'Units — tap an ID to change its status',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (units.isEmpty)
            const Text('This item has no units.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final unit in units)
                  _UnitChip(
                    unit: unit,
                    onChanged: (status) => onUnitStatus(unit, status),
                  ),
              ],
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onDelete,
                style: TextButton.styleFrom(foregroundColor: AppColors.csunRed),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Image + name + description (equivalent of _ActivitySummary).
class _ItemSummary extends StatelessWidget {
  const _ItemSummary({required this.item});

  final Equipment item;

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
              Text(
                item.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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

class _UnitChip extends StatelessWidget {
  const _UnitChip({required this.unit, required this.onChanged});

  final EquipmentUnit unit;
  final ValueChanged<EquipmentStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = _statusColors(unit.status);

    return PopupMenuButton<EquipmentStatus>(
      tooltip: 'Change status',
      initialValue: unit.status,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final s in EquipmentStatus.values)
          PopupMenuItem(value: s, child: Text(s.label)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              unit.id,
              style: TextStyle(
                color: foreground,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              unit.status.label,
              style: TextStyle(color: foreground, fontSize: 11),
            ),
            Icon(Icons.arrow_drop_down, size: 16, color: foreground),
          ],
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
          const Icon(Icons.inventory_2_outlined,
              size: 44, color: AppColors.muted),
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