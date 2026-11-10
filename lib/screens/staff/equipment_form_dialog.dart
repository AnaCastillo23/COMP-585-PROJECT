import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/image_compress.dart';
import '../../models/equipment.dart';
import '../../services/equipment_service.dart';
import '../../widgets/equipment_image.dart';

Future<void> showEquipmentFormDialog(
  BuildContext context,
  EquipmentService service, {
  Equipment? existing,
}) {
  return showDialog(
    context: context,
    builder: (_) => _EquipmentFormDialog(service: service, existing: existing),
  );
}

class _EquipmentFormDialog extends StatefulWidget {
  const _EquipmentFormDialog({required this.service, this.existing});

  final EquipmentService service;
  final Equipment? existing;

  @override
  State<_EquipmentFormDialog> createState() => _EquipmentFormDialogState();
}

class _EquipmentFormDialogState extends State<_EquipmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final _name = TextEditingController(text: widget.existing?.name);
  late final _description =
      TextEditingController(text: widget.existing?.description);
  late final _units = TextEditingController(
      text: (widget.existing?.totalUnits ?? 1).toString());

  late String _category =
      Equipment.categories.contains(widget.existing?.category)
          ? widget.existing!.category
          : Equipment.categories.first;

  // Applies to units created by this save.
  EquipmentStatus _status = EquipmentStatus.available;

  Uint8List? _newImage; // compressed bytes, only set when staff pick a new one
  bool _processingImage = false;
  bool _saving = false;

  bool get _isNew => widget.existing == null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _units.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _processingImage = true);
    // Let the spinner paint before the (synchronous) compression runs.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final original = await file.readAsBytes();
    final compressed = compressImage(original);

    if (!mounted) return;
    setState(() => _processingImage = false);

    if (compressed == null) {
      _showMessage('Could not use that image. Try a different photo.');
      return;
    }
    setState(() => _newImage = compressed);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final count = int.parse(_units.text.trim());
    final old = widget.existing;

    if (old != null && count < old.totalUnits) {
      final removing = old.totalUnits - count;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Remove units?'),
          content: Text(
            'This deletes $removing unit${removing == 1 ? '' : 's'}, starting '
            'with units that are not available. Their IDs cannot be recovered.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    final item = Equipment(
      id: old?.id ?? '', // new items get their ID from the service
      name: _name.text.trim(),
      category: _category,
      description: _description.text.trim(),
      availableUnits: old?.availableUnits ?? 0,
      totalUnits: old?.totalUnits ?? 0,
      imageBytes: _newImage ?? old?.imageBytes,
      units: old?.units ?? const [],
    );

    setState(() => _saving = true);
    try {
      await widget.service.saveEquipment(
        item,
        unitCount: count,
        newUnitStatus: _status,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isNew
                ? 'Added ${item.name} with $count '
                    'unit${count == 1 ? '' : 's'}'
                : 'Saved ${item.name}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Could not save: $e');
    }
  }

  Widget _preview() {
    final Widget content;
    if (_processingImage) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_newImage != null) {
      content = Image.memory(_newImage!, fit: BoxFit.cover);
    } else if (widget.existing != null) {
      content = EquipmentImage(equipment: widget.existing!);
    } else {
      content = const Center(
        child: Icon(Icons.image_outlined, size: 40, color: Colors.black38),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: ColoredBox(color: const Color(0xFFF1F3F6), child: content),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _newImage != null || widget.existing?.imageBytes != null;

    return AlertDialog(
      title: Text(_isNew ? 'Add equipment' : 'Edit equipment'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _preview(),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: (_saving || _processingImage) ? null : _pickImage,
                  icon: const Icon(Icons.upload_outlined),
                  label: Text(hasImage ? 'Change image' : 'Upload image'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final c in Equipment.categories)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _units,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _isNew ? 'Number of units' : 'Total units',
                    helperText: _isNew
                        ? 'Each unit gets its own ID (EQ-0000)'
                        : 'Raising adds units with new IDs. Lowering removes '
                            'units that are not available first.',
                    helperMaxLines: 3,
                  ),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n < 1 || n > Equipment.maxUnits) {
                      return 'Enter a number from 1 to ${Equipment.maxUnits}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EquipmentStatus>(
                  initialValue: _status,
                  decoration: InputDecoration(
                    labelText: 'Status of new units',
                    helperText: _isNew
                        ? null
                        : 'Change an existing unit from the inventory screen',
                    helperMaxLines: 2,
                  ),
                  items: [
                    for (final s in EquipmentStatus.values)
                      DropdownMenuItem(value: s, child: Text(s.label)),
                  ],
                  onChanged: (v) => setState(() => _status = v!),
                ),
                if (!_isNew && widget.existing!.units.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Current unit IDs',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final unit in widget.existing!.units)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            unit.id,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (_saving || _processingImage) ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}