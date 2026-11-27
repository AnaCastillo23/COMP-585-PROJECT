// lib/screens/staff/equipment_detail_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/equipment.dart';
import '../../services/equipment_detail_service.dart';
import '../../services/equipment_service.dart';
import '../../services/firestore_equipment_detail_service.dart';
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

String _fmtDate(DateTime d) => '${d.month}/${d.day}/${d.year}';

class EquipmentDetailScreen extends StatefulWidget {
  const EquipmentDetailScreen({
    super.key,
    required this.equipment,
    required this.equipmentService,
    this.detailService,
  });

  final Equipment equipment;
  final EquipmentService equipmentService;
  final EquipmentDetailService? detailService;

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  late final EquipmentDetailService _detail =
      widget.detailService ?? FirestoreEquipmentDetailService();

  StreamSubscription<List<Equipment>>? _sub;

  late Equipment _item = widget.equipment;
  EquipmentGuide _guide = const EquipmentGuide();
  List<StudentRef> _waitlist = [];

  Map<String, LoanInfo> _loans = {};
  bool _loansLoaded = false;
  bool _loansFailed = false;
  String? _loanSignature;

  String get _id => widget.equipment.id;

  @override
  void initState() {
    super.initState();
    _loadGuideAndWaitlist();
    _loadLoans(_item);

    // Keeps unit statuses live; loans reload whenever a status changes.
    _sub = widget.equipmentService.watchEquipment().listen((all) {
      final match = all.where((e) => e.id == _id).firstOrNull;
      if (match == null || !mounted) return;
      setState(() => _item = match);
      _loadLoans(match);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadGuideAndWaitlist() async {
    EquipmentGuide? loadedGuide;
    List<StudentRef>? loadedWaitlist;
    String? error;

    try {
      loadedGuide = await _detail.getGuide(_id);
    } catch (e) {
      error = '$e';
    }
    try {
      loadedWaitlist = await _detail.getWaitlist(_id);
    } catch (e) {
      error = '$e';
    }

    if (!mounted) return;
    final guide = loadedGuide;
    final waitlist = loadedWaitlist;
    setState(() {
      if (guide != null) _guide = guide;
      if (waitlist != null) _waitlist = waitlist;
    });
    if (error != null) _message('Could not load waitlist or care guide: $error');
  }

  Future<void> _loadLoans(Equipment item) async {
    final signature =
        item.units.map((u) => '${u.id}:${u.status.name}').join(',');
    if (signature == _loanSignature) return;
    _loanSignature = signature;

    try {
      final loans = await _detail.activeLoansByUnit(_id);
      if (!mounted) return;
      setState(() {
        _loans = loans;
        _loansLoaded = true;
        _loansFailed = false;
      });
    } catch (_) {
      _loanSignature = null; // try again on the next change
      if (!mounted) return;
      setState(() {
        _loansLoaded = true;
        _loansFailed = true;
      });
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _setStatus(EquipmentUnit unit, EquipmentStatus status) async {
    try {
      await widget.equipmentService.setUnitStatus(unit.id, status);
    } catch (e) {
      if (!mounted) return;
      _message('Could not update ${unit.id}: $e');
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${_item.name}?'),
        content: const Text(
          'This removes the item and all of its units. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.csunRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.equipmentService.deleteEquipment(_item.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _message('Could not delete: $e');
    }
  }

  Future<void> _addToWaitlist() async {
    final student = await showDialog<StudentRef>(
      context: context,
      builder: (_) => _AddToWaitlistDialog(
        service: _detail,
        excludeIds: {for (final s in _waitlist) s.id},
      ),
    );
    if (student == null) return;
    try {
      await _detail.addToWaitlist(
        _id,
        student,
        equipmentName: _item.name,
      );
    } catch (e) {
      if (!mounted) return;
      _message('Could not add to waitlist: $e');
      return;
    }
    await _loadGuideAndWaitlist();
    if (!mounted) return;
    _message('${student.name} added to the waitlist');
  }

  Future<void> _removeFromWaitlist(StudentRef student) async {
    try {
      await _detail.removeFromWaitlist(_id, student.id);
    } catch (e) {
      if (!mounted) return;
      _message('Could not remove from waitlist: $e');
      return;
    }
    await _loadGuideAndWaitlist();
  }

  Future<void> _saveGuide(EquipmentGuide guide) async {
    try {
      await _detail.saveGuide(_id, guide);
    } catch (e) {
      if (!mounted) return;
      _message('Could not save: $e');
      return;
    }
    await _loadGuideAndWaitlist();
  }

  Future<void> _editCare() async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _TextDialog(
        title: 'Care instructions',
        hint: 'How to handle, clean, charge, and store this item.',
        initial: _guide.careInstructions,
      ),
    );
    if (text == null) return;
    await _saveGuide(
      EquipmentGuide(
        careInstructions: text,
        gettingToKnow: _guide.gettingToKnow,
      ),
    );
  }

  Future<void> _editGettingToKnow() async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _TextDialog(
        title: 'Get to know your device',
        hint: 'Buttons, settings, tips, and first steps for new users.',
        initial: _guide.gettingToKnow,
      ),
    );
    if (text == null) return;
    await _saveGuide(
      EquipmentGuide(
        careInstructions: _guide.careInstructions,
        gettingToKnow: text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;

    final unitsSection = _Section(
      title: 'Units (${item.units.length})',
      child: item.units.isEmpty
          ? const Text('This item has no units.')
          : Column(
              children: [
                for (var i = 0; i < item.units.length; i++) ...[
                  _UnitRow(
                    unit: item.units[i],
                    loan: _loans[item.units[i].id],
                    loansLoaded: _loansLoaded,
                    loansFailed: _loansFailed,
                    onStatus: (s) => _setStatus(item.units[i], s),
                  ),
                  if (i != item.units.length - 1)
                    const Divider(height: 1, color: AppColors.border),
                ],
              ],
            ),
    );

    final waitlistSection = _Section(
      title: 'Waitlist (${_waitlist.length})',
      trailing: TextButton.icon(
        onPressed: _addToWaitlist,
        icon: const Icon(Icons.person_add_alt, size: 16),
        label: const Text('Add'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.csunRed,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
      child: _waitlist.isEmpty
          ? const Text(
              'Nobody is waiting for this item.',
              style: TextStyle(color: AppColors.muted),
            )
          : Column(
              children: [
                for (var i = 0; i < _waitlist.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFFE9EDF2),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _waitlist[i].name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              if (_waitlist[i].email.isNotEmpty)
                                Text(
                                  _waitlist[i].email,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove from waitlist',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => _removeFromWaitlist(_waitlist[i]),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );

    final careSection = _TextSection(
      title: 'Care instructions',
      emptyText: 'No care instructions yet.',
      body: _guide.careInstructions,
      onEdit: _editCare,
    );

    final knowSection = _TextSection(
      title: 'Get to know your device',
      emptyText: 'Nothing added yet.',
      body: _guide.gettingToKnow,
      onEdit: _editGettingToKnow,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(item.name),
        actions: [
          IconButton(
            tooltip: 'Edit item',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showEquipmentFormDialog(
              context,
              widget.equipmentService,
              existing: item,
            ),
          ),
          IconButton(
            tooltip: 'Delete item',
            icon: const Icon(Icons.delete_outline),
            color: AppColors.csunRed,
            onPressed: _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(item: item),
                const SizedBox(height: 28),
                _TwoColumn(
                  left: unitsSection,
                  right: waitlistSection,
                  leftFlex: 3,
                  rightFlex: 2,
                ),
                const SizedBox(height: 16),
                _TwoColumn(left: careSection, right: knowSection),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Layout pieces ─────────────────────────

/// Image on its own at the left; name, category, availability and details on
/// the right.
class _Header extends StatelessWidget {
  const _Header({required this.item});

  final Equipment item;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth >= 600 ? 200.0 : 120.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: size,
                height: size,
                child: EquipmentImage(equipment: item),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Pill(
                        label: item.category,
                        foreground: AppColors.muted,
                        background: const Color(0xFFE9EDF2),
                      ),
                      _Pill(
                        label:
                            '${item.availableUnits} of ${item.totalUnits} available',
                        foreground: const Color(0xFF247A4A),
                        background: const Color(0xFFDDF3E5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Details',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description.isEmpty
                        ? 'No details added yet. Use Edit to add them.'
                        : item.description,
                    style: TextStyle(
                      color: item.description.isEmpty
                          ? AppColors.muted
                          : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Two cards side by side on wide screens, stacked on narrow ones.
class _TwoColumn extends StatelessWidget {
  const _TwoColumn({
    required this.left,
    required this.right,
    this.leftFlex = 1,
    this.rightFlex = 1,
  });

  final Widget left;
  final Widget right;
  final int leftFlex;
  final int rightFlex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(children: [left, const SizedBox(height: 16), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: leftFlex, child: left),
            const SizedBox(width: 16),
            Expanded(flex: rightFlex, child: right),
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// A card holding one block of staff-written text with its own Edit button.
class _TextSection extends StatelessWidget {
  const _TextSection({
    required this.title,
    required this.emptyText,
    required this.body,
    required this.onEdit,
  });

  final String title;
  final String emptyText;
  final String body;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final empty = body.trim().isEmpty;

    return _Section(
      title: title,
      trailing: TextButton.icon(
        onPressed: onEdit,
        icon: Icon(empty ? Icons.add : Icons.edit_outlined, size: 16),
        label: Text(empty ? 'Add' : 'Edit'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.csunRed,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            empty ? emptyText : body,
            style: TextStyle(color: empty ? AppColors.muted : AppColors.ink),
          ),
          const SizedBox(height: 10),
          const Text(
            'Shown to students when they check out this item.',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

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
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ───────────────────────── Units ─────────────────────────

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    required this.unit,
    required this.loan,
    required this.loansLoaded,
    required this.loansFailed,
    required this.onStatus,
  });

  final EquipmentUnit unit;
  final LoanInfo? loan;
  final bool loansLoaded;
  final bool loansFailed;
  final ValueChanged<EquipmentStatus> onStatus;

  Widget? _info() {
    switch (unit.status) {
      case EquipmentStatus.unavailable:
        if (!loansLoaded) {
          return const Text(
            'Loading loan details...',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          );
        }
        if (loansFailed) {
          return const Text(
            'Could not load loan details.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          );
        }
        final l = loan;
        if (l == null) {
          return const Text(
            'No active loan on record for this unit.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          );
        }
        final overdue = DateTime.now().isAfter(l.dueDate);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Checked out by ${l.studentName}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              overdue
                  ? 'Due ${_fmtDate(l.dueDate)} (overdue)'
                  : 'Due ${_fmtDate(l.dueDate)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: overdue ? FontWeight.w700 : FontWeight.w400,
                color: overdue ? AppColors.csunRed : AppColors.muted,
              ),
            ),
          ],
        );
      case EquipmentStatus.reserved:
        return const Text(
          'Reserved, waiting for pickup',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        );
      case EquipmentStatus.maintenance:
        return const Text(
          'In maintenance',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        );
      case EquipmentStatus.available:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _statusColors(unit.status);
    final info = _info();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      unit.id,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _Pill(
                      label: unit.status.label,
                      foreground: fg,
                      background: bg,
                    ),
                  ],
                ),
                if (info != null) ...[
                  const SizedBox(height: 6),
                  info,
                ],
              ],
            ),
          ),
          PopupMenuButton<EquipmentStatus>(
            tooltip: 'Change status',
            icon: const Icon(Icons.more_vert, size: 18),
            initialValue: unit.status,
            onSelected: onStatus,
            itemBuilder: (_) => [
              for (final s in EquipmentStatus.values)
                PopupMenuItem(value: s, child: Text(s.label)),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Dialogs ─────────────────────────

/// Pick an existing student. Students already on the waitlist are hidden.
class _AddToWaitlistDialog extends StatefulWidget {
  const _AddToWaitlistDialog({required this.service, required this.excludeIds});

  final EquipmentDetailService service;
  final Set<String> excludeIds;

  @override
  State<_AddToWaitlistDialog> createState() => _AddToWaitlistDialogState();
}

class _AddToWaitlistDialogState extends State<_AddToWaitlistDialog> {
  final _search = TextEditingController();
  late Future<List<StudentRef>> _results = widget.service.searchStudents('');

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add to waitlist'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _search,
              autofocus: true,
              onChanged: (v) => setState(
                () => _results = widget.service.searchStudents(v),
              ),
              decoration: const InputDecoration(
                hintText: 'Search students by name or email',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              child: FutureBuilder<List<StudentRef>>(
                future: _results,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return const Center(
                      child: Text('Could not load students.'),
                    );
                  }
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = [
                    for (final s in snap.data ?? const <StudentRef>[])
                      if (!widget.excludeIds.contains(s.id)) s,
                  ];
                  if (list.isEmpty) {
                    return const Center(child: Text('No students found.'));
                  }
                  return ListView(
                    children: [
                      for (final s in list)
                        ListTile(
                          dense: true,
                          title: Text(s.name),
                          subtitle: Text(s.email),
                          onTap: () => Navigator.of(context).pop(s),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.hint,
    required this.initial,
  });

  final String title;
  final String hint;
  final String initial;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: TextField(
          controller: _controller,
          autofocus: true,
          minLines: 5,
          maxLines: 12,
          decoration: InputDecoration(
            hintText: widget.hint,
            alignLabelWithHint: true,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}