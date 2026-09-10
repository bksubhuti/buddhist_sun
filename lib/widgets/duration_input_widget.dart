import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DurationInputWidget extends StatefulWidget {
  final int initialMinutes;
  final ValueChanged<int> onChanged;

  const DurationInputWidget({
    Key? key,
    required this.initialMinutes,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<DurationInputWidget> createState() => DurationInputWidgetState();
}

class DurationInputWidgetState extends State<DurationInputWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _textController;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  late int _selectedHours;
  late int _selectedMinutes;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final initial = widget.initialMinutes > 0 ? widget.initialMinutes : 20;
    _selectedHours = initial ~/ 60;
    _selectedMinutes = initial % 60;

    _textController = TextEditingController(text: initial.toString());
    _hourController = FixedExtentScrollController(initialItem: _selectedHours);
    _minuteController =
        FixedExtentScrollController(initialItem: _selectedMinutes);
  }

  @override
  void didUpdateWidget(covariant DurationInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMinutes != widget.initialMinutes &&
        widget.initialMinutes != currentMinutes) {
      setMinutes(widget.initialMinutes, notifyParent: false);
    }
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

  int get currentMinutes {
    if (_tabController.index == 0) {
      return _totalMinutesFromWheels;
    } else {
      final parsed = int.tryParse(_textController.text);
      return (parsed != null && parsed > 0) ? parsed : _totalMinutesFromWheels;
    }
  }

  void setMinutes(int minutes, {bool notifyParent = true}) {
    if (minutes < 1) minutes = 1;
    if (minutes > 720) minutes = 720;
    _textController.text = minutes.toString();

    _selectedHours = minutes ~/ 60;
    _selectedMinutes = minutes % 60;

    if (mounted) {
      setState(() {});
    }

    if (_hourController.hasClients) {
      _hourController.jumpToItem(_selectedHours);
    }
    if (_minuteController.hasClients) {
      _minuteController.jumpToItem(_selectedMinutes);
    }

    if (notifyParent) {
      widget.onChanged(minutes);
    }
  }

  void _quickAdd(int addMinutes) {
    int current = int.tryParse(_textController.text) ?? _totalMinutesFromWheels;
    current += addMinutes;
    setMinutes(current);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mode Selector TabBar (Left: Time Dial / Default, Right: Number Input)
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
            onTap: (_) {
              setState(() {});
              widget.onChanged(currentMinutes);
            },
          ),
        ),
        const SizedBox(height: 8),

        // Tab Views
        SizedBox(
          height: 165,
          child: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1 (LEFT / DEFAULT): Hour & Minute Wheels Dial
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NotificationListener<ScrollEndNotification>(
                    onNotification: (notification) {
                      widget.onChanged(_totalMinutesFromWheels);
                      return false;
                    },
                    child: Row(
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
                              height: 105,
                              child: ListWheelScrollView.useDelegate(
                                itemExtent: 36,
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
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: 13,
                                  builder: (context, index) {
                                    final isSelected = index == _selectedHours;
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
                                              : theme
                                                  .colorScheme.onSurfaceVariant
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
                          padding: const EdgeInsets.symmetric(horizontal: 8),
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
                              height: 105,
                              child: ListWheelScrollView.useDelegate(
                                itemExtent: 36,
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
                                childDelegate: ListWheelChildBuilderDelegate(
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
                                              : theme
                                                  .colorScheme.onSurfaceVariant
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
                              borderSide: BorderSide(color: primary, width: 2),
                            ),
                          ),
                          onChanged: (val) {
                            final mins = int.tryParse(val) ?? 0;
                            if (mins > 0) {
                              setState(() {
                                _selectedHours = mins ~/ 60;
                                _selectedMinutes = mins % 60;
                              });
                              if (_hourController.hasClients) {
                                _hourController.jumpToItem(_selectedHours);
                              }
                              if (_minuteController.hasClients) {
                                _minuteController.jumpToItem(_selectedMinutes);
                              }
                              widget.onChanged(mins);
                            }
                          },
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
                      _buildQuickAddChip(context, '+5m', 5),
                      _buildQuickAddChip(context, '+10m', 10),
                      _buildQuickAddChip(context, '+15m', 15),
                      _buildQuickAddChip(context, '+30m', 30),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAddChip(BuildContext context, String label, int minutes) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      onPressed: () => _quickAdd(minutes),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
