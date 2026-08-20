import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DurationPickerDialog extends StatefulWidget {
  final int initialMinutes;

  const DurationPickerDialog({
    Key? key,
    required this.initialMinutes,
  }) : super(key: key);

  @override
  State<DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<DurationPickerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _textController;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  late int _selectedHours;
  late int _selectedMinutes;

  static const List<int> _presetOptions = [
    5,
    10,
    15,
    20,
    25,
    30,
    45,
    60,
    90,
    120,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedHours = widget.initialMinutes ~/ 60;
    _selectedMinutes = widget.initialMinutes % 60;

    _textController =
        TextEditingController(text: widget.initialMinutes.toString());
    _hourController = FixedExtentScrollController(initialItem: _selectedHours);
    _minuteController =
        FixedExtentScrollController(initialItem: _selectedMinutes);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  int get _totalMinutesFromWheels => (_selectedHours * 60) + _selectedMinutes;

  int get _currentSelectedMinutes {
    if (_tabController.index == 0) {
      return _totalMinutesFromWheels;
    } else {
      return int.tryParse(_textController.text) ?? widget.initialMinutes;
    }
  }

  void _submit() {
    int minutes = _currentSelectedMinutes;
    if (minutes <= 0) minutes = 1;
    if (minutes > 720) minutes = 720; // 12 hours max

    Navigator.of(context).pop(minutes);
  }

  void _setPreset(int minutes) {
    if (minutes < 1) minutes = 1;
    if (minutes > 720) minutes = 720;
    _textController.text = minutes.toString();

    setState(() {
      _selectedHours = minutes ~/ 60;
      _selectedMinutes = minutes % 60;
    });

    if (_hourController.hasClients) {
      _hourController.jumpToItem(_selectedHours);
    }
    if (_minuteController.hasClients) {
      _minuteController.jumpToItem(_selectedMinutes);
    }
  }

  void _quickAdd(int addMinutes) {
    int current = int.tryParse(_textController.text) ?? 0;
    current += addMinutes;
    if (current < 1) current = 1;
    if (current > 720) current = 720;
    _textController.text = current.toString();

    setState(() {
      _selectedHours = current ~/ 60;
      _selectedMinutes = current % 60;
    });

    if (_hourController.hasClients) {
      _hourController.jumpToItem(_selectedHours);
    }
    if (_minuteController.hasClients) {
      _minuteController.jumpToItem(_selectedMinutes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final currentMins = _currentSelectedMinutes;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Column(
        children: [
          Row(
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
          const SizedBox(height: 12),
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: primary,
              ),
              labelColor: theme.colorScheme.onPrimary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              dividerColor: Colors.transparent,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Time Dial'),
                Tab(text: 'Number Input'),
              ],
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
              // Main Tab View
              SizedBox(
                height: 170,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // TAB 1 (LEFT / DEFAULT): Hour & Minute Wheels Dial
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Hours Wheel
                            Column(
                              children: [
                                Text(
                                  'Hours',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 70,
                                  height: 110,
                                  child: ListWheelScrollView.useDelegate(
                                    itemExtent: 38,
                                    controller: _hourController,
                                    physics: const FixedExtentScrollPhysics(),
                                    perspective: 0.005,
                                    diameterRatio: 1.2,
                                    useMagnifier: true,
                                    magnification: 1.15,
                                    onSelectedItemChanged: (index) {
                                      setState(() => _selectedHours = index);
                                      _textController.text =
                                          _totalMinutesFromWheels.toString();
                                    },
                                    childDelegate:
                                        ListWheelChildBuilderDelegate(
                                      childCount: 13,
                                      builder: (context, index) {
                                        final isSelected =
                                            index == _selectedHours;
                                        return Center(
                                          child: Text(
                                            index.toString().padLeft(2, '0'),
                                            style: TextStyle(
                                              fontSize: isSelected ? 22 : 16,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? primary
                                                  : theme.colorScheme
                                                      .onSurfaceVariant
                                                      .withAlpha(120),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                ':',
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                            ),
                            // Minutes Wheel
                            Column(
                              children: [
                                Text(
                                  'Minutes',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 70,
                                  height: 110,
                                  child: ListWheelScrollView.useDelegate(
                                    itemExtent: 38,
                                    controller: _minuteController,
                                    physics: const FixedExtentScrollPhysics(),
                                    perspective: 0.005,
                                    diameterRatio: 1.2,
                                    useMagnifier: true,
                                    magnification: 1.15,
                                    onSelectedItemChanged: (index) {
                                      setState(() => _selectedMinutes = index);
                                      _textController.text =
                                          _totalMinutesFromWheels.toString();
                                    },
                                    childDelegate:
                                        ListWheelChildBuilderDelegate(
                                      childCount: 60,
                                      builder: (context, index) {
                                        final isSelected =
                                            index == _selectedMinutes;
                                        return Center(
                                          child: Text(
                                            index.toString().padLeft(2, '0'),
                                            style: TextStyle(
                                              fontSize: isSelected ? 22 : 16,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? primary
                                                  : theme.colorScheme
                                                      .onSurfaceVariant
                                                      .withAlpha(120),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          'Total: $_totalMinutesFromWheels min',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // TAB 2 (RIGHT): Direct Number Entry
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 90,
                              child: TextField(
                                controller: _textController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 8,
                                  ),
                                  filled: true,
                                  fillColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide:
                                        BorderSide(color: primary, width: 2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'minutes',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Quick adjustment chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildQuickAddChip('+5m', 5),
                            _buildQuickAddChip('+10m', 10),
                            _buildQuickAddChip('+15m', 15),
                            _buildQuickAddChip('+30m', 30),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 16),

              // Presets Section Below
              Row(
                children: [
                  Text(
                    'Presets',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.start,
                children: _presetOptions.map((minutes) {
                  final isSelected = currentMins == minutes;
                  return ChoiceChip(
                    label: Text(
                      '$minutes m',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => _setPreset(minutes),
                    selectedColor: primary.withAlpha(50),
                    side: BorderSide(
                      color: isSelected ? primary : Colors.transparent,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  );
                }).toList(),
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

  Widget _buildQuickAddChip(String label, int minutes) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      onPressed: () => _quickAdd(minutes),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
