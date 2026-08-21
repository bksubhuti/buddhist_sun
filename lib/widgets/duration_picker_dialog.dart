import 'package:flutter/material.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/widgets/duration_input_widget.dart';

class DurationPickerDialog extends StatefulWidget {
  final int initialMinutes;

  const DurationPickerDialog({
    Key? key,
    required this.initialMinutes,
  }) : super(key: key);

  @override
  State<DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<DurationPickerDialog> {
  late int _currentMinutes;
  late List<int> _presets;
  final GlobalKey<DurationInputWidgetState> _inputKey =
      GlobalKey<DurationInputWidgetState>();

  static const int _maxPresets = 12;

  @override
  void initState() {
    super.initState();
    _currentMinutes = widget.initialMinutes > 0 ? widget.initialMinutes : 30;
    _presets = List<int>.from(Prefs.meditationPresets)..sort();
  }

  void _submit() {
    int minutes = _currentMinutes;
    if (minutes <= 0) minutes = 1;
    if (minutes > 720) minutes = 720; // 12 hours max

    Navigator.of(context).pop(minutes);
  }

  void _selectPreset(int minutes) {
    setState(() {
      _currentMinutes = minutes;
    });
    _inputKey.currentState?.setMinutes(minutes, notifyParent: false);
  }

  void _handleAddPresetPressed() {
    if (_presets.length >= _maxPresets) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 8),
              Text('Maximum Presets'),
            ],
          ),
          content: const Text(
            '12 is the maximum presets.\n\nYou can delete or edit other presets by long-pressing on each preset.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      _showAddPresetDialog();
    }
  }

  /// Popup dialog for long-press on a preset (Edit or Delete)
  void _showPresetActionPopup(int minutes) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Preset: $minutes min'),
        content: Text(
          'Choose an action for the $minutes minute preset:',
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deletePreset(minutes);
            },
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 4),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showEditPresetDialog(minutes);
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Edit Preset Dialog using reusable DurationInputWidget
  Future<void> _showEditPresetDialog(int oldMinutes) async {
    int editedMinutes = oldMinutes;

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Icon(Icons.edit_outlined,
                    color: Theme.of(ctx).colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text('Edit ${oldMinutes}m Preset'),
              ],
            ),
            content: SizedBox(
              width: 320,
              child: DurationInputWidget(
                initialMinutes: oldMinutes,
                onChanged: (val) {
                  editedMinutes = val;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (editedMinutes > 0 && editedMinutes <= 720) {
                    Navigator.of(ctx).pop(editedMinutes);
                  }
                },
                child: const Text('Save Preset'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null && mounted) {
      _presets.remove(oldMinutes);
      if (!_presets.contains(result)) {
        _presets.add(result);
      }
      _presets.sort();
      Prefs.meditationPresets = _presets;
      _selectPreset(result);
    }
  }

  /// Add Preset Dialog using reusable DurationInputWidget
  Future<void> _showAddPresetDialog() async {
    int newMinutes = _currentMinutes > 0 ? _currentMinutes : 20;

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Icon(Icons.add_circle_outline,
                    color: Theme.of(ctx).colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                const Text('Add Preset'),
              ],
            ),
            content: SizedBox(
              width: 320,
              child: DurationInputWidget(
                initialMinutes: newMinutes,
                onChanged: (val) {
                  newMinutes = val;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (newMinutes > 0 && newMinutes <= 720) {
                    Navigator.of(ctx).pop(newMinutes);
                  }
                },
                child: const Text('Add Preset'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null && mounted) {
      if (!_presets.contains(result)) {
        _presets.add(result);
        _presets.sort();
        Prefs.meditationPresets = _presets;
      }
      _selectPreset(result);
    }
  }

  void _deletePreset(int minutes) {
    _presets.remove(minutes);
    _presets.sort();
    Prefs.meditationPresets = _presets;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Row(
        children: [
          Icon(Icons.timer_outlined, color: primary, size: 24),
          const SizedBox(width: 8),
          Text(
            'Set Duration',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reusable Duration Input (Time Dial on left / default, Number Input on right)
              DurationInputWidget(
                key: _inputKey,
                initialMinutes: _currentMinutes,
                onChanged: (mins) {
                  _currentMinutes = mins;
                },
              ),

              const Divider(height: 16),

              // Presets Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Presets',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Long-press to edit / delete',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(140),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Dynamic Presets Wrap with Add Button at the end
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ..._presets.map((minutes) {
                    final isSelected = _currentMinutes == minutes;
                    return GestureDetector(
                      onLongPress: () => _showPresetActionPopup(minutes),
                      child: ChoiceChip(
                        label: Text(
                          minutes >= 60 && minutes % 60 == 0
                              ? '${minutes ~/ 60}h'
                              : '${minutes}m',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) => _selectPreset(minutes),
                        selectedColor: primary.withAlpha(50),
                        side: BorderSide(
                          color: isSelected ? primary : Colors.transparent,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 0),
                      ),
                    );
                  }).toList(),

                  // Add Preset Button
                  ActionChip(
                    avatar: Icon(Icons.add, size: 16, color: primary),
                    label: Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    onPressed: _handleAddPresetPressed,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Set Duration'),
        ),
      ],
    );
  }
}
