import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/equipment.dart';
import '../../models/loan.dart';
import '../../services/equipment_service.dart';
import '../../services/loan_service.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

class CheckoutsScreen extends StatefulWidget {
  const CheckoutsScreen({super.key, this.equipmentService, this.loanService});

  final EquipmentService? equipmentService;
  final LoanService? loanService;

  @override
  State<CheckoutsScreen> createState() => _CheckoutsScreenState();
}

class _CheckoutsScreenState extends State<CheckoutsScreen> {
  static const _allLoans = 'All active loans';
  static const _overdueOnly = 'Overdue only';
  static const _pageSize = 5;

  late final EquipmentService _equipment =
      widget.equipmentService ?? FirestoreEquipmentService();
  late final LoanService _loans = widget.loanService ?? LoanService();

  // Created once so typing in the search box doesn't restart the stream.
  late final Stream<List<Loan>> _stream = _loans.watchActiveLoans();

  final _searchController = TextEditingController();
  String _filter = _allLoans;
  int _page = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Loan> _applyFilters(List<Loan> all) {
    final q = _searchController.text.trim().toLowerCase();

    final list = all.where((loan) {
      final matchesFilter = _filter == _allLoans || loan.isOverdue;
      final matchesSearch = q.isEmpty ||
          loan.studentName.toLowerCase().contains(q) ||
          loan.studentId.contains(q) ||
          loan.equipmentName.toLowerCase().contains(q) ||
          loan.unitId.toLowerCase().contains(q);
      return matchesFilter && matchesSearch;
    }).toList();

    // Soonest due first, so overdue loans float to the top.
    list.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return list;
  }

  void _updateFilter(VoidCallback update) {
    setState(() {
      update();
      _page = 0;
    });
  }

  void _clearFilters() => _updateFilter(() {
        _searchController.clear();
        _filter = _allLoans;
      });

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _newCheckout() async {
    final items = await _equipment.watchEquipment().first;
    if (!mounted) return;

    final done = await showDialog<bool>(
      context: context,
      builder: (_) => _NewCheckoutDialog(items: items, loans: _loans),
    );
    if (done == true) _showMessage('Checkout created');
  }

  Future<void> _return(Loan loan) async {
    // null = cancelled; otherwise the status the unit should end up with.
    final status = await showDialog<EquipmentStatus>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Return ${loan.unitId}?'),
        content: Text(
          '${loan.equipmentName} from ${loan.studentName}. '
          'Mark it as damaged if it needs maintenance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(EquipmentStatus.maintenance),
            child: const Text('Return as damaged'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.csunRed),
            onPressed: () =>
                Navigator.of(dialogContext).pop(EquipmentStatus.available),
            child: const Text('Return'),
          ),
        ],
      ),
    );
    if (status == null || !mounted) return;

    try {
      await _loans.returnUnit(loan, unitStatusAfter: status);
      if (!mounted) return;
      _showMessage('${loan.unitId} returned');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not return ${loan.unitId}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Loan>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load checkouts.\n${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data!;
          final filtered = _applyFilters(all);
          final overdueCount = all.where((l) => l.isOverdue).length;

          final pageCount =
              filtered.isEmpty ? 1 : (filtered.length / _pageSize).ceil();
          final page = _page.clamp(0, pageCount - 1);
          final start = page * _pageSize;
          final end = (start + _pageSize).clamp(0, filtered.length);
          final pageItems = filtered.sublist(start, end);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checkouts',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${all.length} active loan${all.length == 1 ? '' : 's'}'
                  '${overdueCount > 0 ? ' • $overdueCount overdue' : ''}',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _newCheckout,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New checkout'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.csunRed,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _CheckoutFilters(
                  searchController: _searchController,
                  selectedFilter: _filter,
                  filters: const [_allLoans, _overdueOnly],
                  onSearchChanged: (_) => _updateFilter(() {}),
                  onFilterChanged: (v) => _updateFilter(() => _filter = v!),
                  onClear: _clearFilters,
                ),
                const SizedBox(height: 18),
                if (all.isEmpty)
                  _EmptyState(onNew: _newCheckout)
                else if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: Text('No loans match your filters.')),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) => _CheckoutTable(
                      loans: pageItems,
                      isWide: constraints.maxWidth >= 700,
                      onReturn: _return,
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Showing ${pageItems.length} of ${filtered.length} loans',
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const Spacer(),
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
              ],
            ),
          );
        },
      ),
    );
  }
}

// ───────────────────────── Filters ─────────────────────────

class _CheckoutFilters extends StatelessWidget {
  const _CheckoutFilters({
    required this.searchController,
    required this.selectedFilter,
    required this.filters,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final String selectedFilter;
  final List<String> filters;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onFilterChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      decoration: const InputDecoration(
        hintText: 'Search student, student ID, item, or unit ID',
        prefixIcon: Icon(Icons.search, size: 20),
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
    );
    final dropdown = DropdownButtonFormField<String>(
      key: ValueKey(selectedFilter),
      initialValue: selectedFilter,
      isExpanded: true,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
      items: [
        for (final f in filters) DropdownMenuItem(value: f, child: Text(f)),
      ],
      onChanged: onFilterChanged,
    );
    final clear = TextButton(
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
                Expanded(flex: 3, child: search),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: dropdown),
                const SizedBox(width: 10),
                clear,
              ],
            );
          }
          return Column(
            children: [
              search,
              const SizedBox(height: 10),
              dropdown,
              const SizedBox(height: 6),
              Align(alignment: Alignment.centerRight, child: clear),
            ],
          );
        },
      ),
    );
  }
}

// ───────────────────────── Table ─────────────────────────

class _CheckoutTable extends StatelessWidget {
  const _CheckoutTable({
    required this.loans,
    required this.isWide,
    required this.onReturn,
  });

  final List<Loan> loans;
  final bool isWide;
  final void Function(Loan loan) onReturn;

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
          if (isWide) const _CheckoutHeader(),
          if (isWide) const Divider(height: 1, color: AppColors.border),
          for (var i = 0; i < loans.length; i++) ...[
            isWide
                ? _CheckoutWideRow(loan: loans[i], onReturn: onReturn)
                : _CheckoutCompactRow(loan: loans[i], onReturn: onReturn),
            if (i != loans.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _CheckoutHeader extends StatelessWidget {
  const _CheckoutHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 4, child: _HeaderLabel('STUDENT')),
          Expanded(flex: 4, child: _HeaderLabel('EQUIPMENT')),
          Expanded(flex: 2, child: _HeaderLabel('DUE')),
          Expanded(flex: 2, child: _HeaderLabel('STATUS')),
          SizedBox(width: 90),
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

class _TwoLine extends StatelessWidget {
  const _TwoLine({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final overdue = loan.isOverdue;
    return _Pill(
      label: overdue ? 'Overdue' : 'Checked out',
      foreground: overdue ? AppColors.csunRed : const Color(0xFF1377C9),
      background:
          overdue ? const Color(0xFFFFE0E4) : const Color(0xFFDCEEFF),
    );
  }
}

class _CheckoutWideRow extends StatelessWidget {
  const _CheckoutWideRow({required this.loan, required this.onReturn});

  final Loan loan;
  final void Function(Loan loan) onReturn;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: _TwoLine(
                title: loan.studentName,
                subtitle: 'ID ${loan.studentId}',
              ),
            ),
            Expanded(
              flex: 4,
              child: _TwoLine(
                title: loan.equipmentName,
                subtitle: loan.unitId,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _formatDate(loan.dueAt),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusPill(loan: loan),
              ),
            ),
            SizedBox(
              width: 90,
              child: OutlinedButton(
                onPressed: () => onReturn(loan),
                child: const Text('Return'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutCompactRow extends StatelessWidget {
  const _CheckoutCompactRow({required this.loan, required this.onReturn});

  final Loan loan;
  final void Function(Loan loan) onReturn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TwoLine(
            title: '${loan.equipmentName} • ${loan.unitId}',
            subtitle: '${loan.studentName} (ID ${loan.studentId})',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatusPill(loan: loan),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Due ${_formatDate(loan.dueAt)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
              OutlinedButton(
                onPressed: () => onReturn(loan),
                child: const Text('Return'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── New checkout dialog ─────────────────────────

class _NewCheckoutDialog extends StatefulWidget {
  const _NewCheckoutDialog({required this.items, required this.loans});

  final List<Equipment> items;
  final LoanService loans;

  @override
  State<_NewCheckoutDialog> createState() => _NewCheckoutDialogState();
}

class _NewCheckoutDialogState extends State<_NewCheckoutDialog> {
  final _idController = TextEditingController();

  StudentInfo? _student;
  Equipment? _item;
  EquipmentUnit? _unit;
  DateTime _due = DateTime.now().add(const Duration(days: 7));

  bool _searching = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  List<Equipment> get _availableItems => widget.items
      .where((e) => e.units.any((u) => u.status == EquipmentStatus.available))
      .toList();

  List<EquipmentUnit> get _availableUnits => _item == null
      ? const []
      : _item!.units
          .where((u) => u.status == EquipmentStatus.available)
          .toList();

  Future<void> _findStudent() async {
    final id = _idController.text.trim();
    if (!RegExp(r'^[0-9]{9}$').hasMatch(id)) {
      setState(() => _error = 'Enter a 9-digit student ID.');
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
      _student = null;
    });
    try {
      final student = await widget.loans.findStudent(id);
      if (!mounted) return;
      setState(() {
        _student = student;
        if (student == null) _error = 'No student found with that ID.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Lookup failed: $e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null) {
      // Due at the end of the chosen day.
      setState(() => _due = DateTime(picked.year, picked.month, picked.day, 23, 59));
    }
  }

  Future<void> _confirm() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.loans.checkOut(
        student: _student!,
        item: _item!,
        unit: _unit!,
        dueAt: _due,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _student != null && _item != null && _unit != null;

    return AlertDialog(
      title: const Text('New checkout'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 1: student
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _idController,
                      keyboardType: TextInputType.number,
                      maxLength: 9,
                      onSubmitted: (_) => _findStudent(),
                      onChanged: (_) {
                        if (_student != null) setState(() => _student = null);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Student ID',
                        hintText: '9-digit CSUN ID',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.csunRed,
                      ),
                      onPressed: _searching ? null : _findStudent,
                      child: _searching
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Find'),
                    ),
                  ),
                ],
              ),
              if (_student != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 18, color: Color(0xFF247A4A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _student!.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],

              // Step 2: equipment + unit + due date (after student is found)
              if (_student != null) ...[
                const SizedBox(height: 18),
                if (_availableItems.isEmpty)
                  const Text('No equipment is currently available.')
                else ...[
                  DropdownButtonFormField<Equipment>(
                    initialValue: _item,
                    isExpanded: true,
                    hint: const Text('Choose equipment'),
                    items: [
                      for (final e in _availableItems)
                        DropdownMenuItem(
                          value: e,
                          child: Text(
                            '${e.name} (${e.countWithStatus(EquipmentStatus.available)} available)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (e) => setState(() {
                      _item = e;
                      _unit = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<EquipmentUnit>(
                    // New key per item so the unit picker resets.
                    key: ValueKey(_item?.id),
                    initialValue: _unit,
                    isExpanded: true,
                    hint: const Text('Choose unit'),
                    items: [
                      for (final u in _availableUnits)
                        DropdownMenuItem(value: u, child: Text(u.id)),
                    ],
                    onChanged:
                        _item == null ? null : (u) => setState(() => _unit = u),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text('Due ${_formatDate(_due)}'),
                  ),
                ],
              ],

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.csunRed, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.csunRed),
          onPressed: ready && !_saving ? _confirm : null,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Check out'),
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
  const _EmptyState({required this.onNew});

  final VoidCallback onNew;

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
          const Icon(Icons.assignment_return_outlined,
              size: 44, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            'Nothing checked out',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'Start a checkout to see active loans here.',
            style: TextStyle(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.add),
            label: const Text('New checkout'),
          ),
        ],
      ),
    );
  }
}