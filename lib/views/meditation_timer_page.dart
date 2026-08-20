import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buddhist_sun/src/models/meditation_timer_state.dart';
import 'package:buddhist_sun/src/provider/meditation_timer_provider.dart';
import 'package:buddhist_sun/widgets/duration_picker_dialog.dart';
import 'package:buddhist_sun/views/active_meditation_page.dart';

class MeditationTimerPage extends StatefulWidget {
  const MeditationTimerPage({Key? key}) : super(key: key);

  @override
  State<MeditationTimerPage> createState() => _MeditationTimerPageState();
}

class _MeditationTimerPageState extends State<MeditationTimerPage> {
  static const List<int> _intervalOptions = [0, 5, 10, 15, 20, 30, 45, 60];

  Future<void> _openDurationPicker(BuildContext context) async {
    final timerProvider = context.read<MeditationTimerProvider>();
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => DurationPickerDialog(
        initialMinutes: timerProvider.durationMinutes,
      ),
    );

    if (result != null && mounted) {
      timerProvider.setDurationMinutes(result);
    }
  }

  Future<void> _pickEndAtTime(BuildContext context) async {
    final timerProvider = context.read<MeditationTimerProvider>();
    final initialTime = TimeOfDay(
      hour: timerProvider.endAtHour,
      minute: timerProvider.endAtMinute,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null && mounted) {
      timerProvider.setEndAtTime(picked.hour, picked.minute);
    }
  }

  void _startMeditation(BuildContext context) {
    final timerProvider = context.read<MeditationTimerProvider>();
    timerProvider.startSession();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ActiveMeditationPage(),
      ),
    );
  }

  String _formatDurationTitle(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours hr${hours > 1 ? "s" : ""}';
      }
      return '$hours hr $mins min';
    }
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = context.watch<MeditationTimerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditation Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About Timer',
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Mode Selector Tabs
              _buildModeSelector(context, timerProvider),
              const SizedBox(height: 16),

              // 2. Timer Time Display (Show time card / tap to edit)
              if (timerProvider.mode == MeditationTimerMode.timed)
                _buildTimedModeContent(context, timerProvider)
              else if (timerProvider.mode == MeditationTimerMode.endAt)
                _buildEndAtModeContent(context, timerProvider)
              else
                _buildUnlimitedModeContent(context),

              const SizedBox(height: 16),

              // 3. Start Meditation Button (Below show time button)
              FilledButton.icon(
                onPressed: () => _startMeditation(context),
                icon: const Icon(Icons.play_arrow_rounded, size: 36),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    'Start Meditation',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                style: FilledButton.styleFrom(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 4. Expansion View for Bells & Other Settings
              _buildSoundSettingsExpansionCard(context, timerProvider),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(
    BuildContext context,
    MeditationTimerProvider timerProvider,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _buildModeTab(
            context: context,
            label: 'Timed',
            icon: Icons.timer,
            isSelected: timerProvider.mode == MeditationTimerMode.timed,
            onTap: () => timerProvider.setMode(MeditationTimerMode.timed),
          ),
          _buildModeTab(
            context: context,
            label: 'End At',
            icon: Icons.alarm,
            isSelected: timerProvider.mode == MeditationTimerMode.endAt,
            onTap: () => timerProvider.setMode(MeditationTimerMode.endAt),
          ),
          _buildModeTab(
            context: context,
            label: 'Open',
            icon: Icons.all_inclusive,
            isSelected: timerProvider.mode == MeditationTimerMode.unlimited,
            onTap: () => timerProvider.setMode(MeditationTimerMode.unlimited),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimedModeContent(
    BuildContext context,
    MeditationTimerProvider timerProvider,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () => _openDurationPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: primary.withAlpha(60),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              _formatDurationTitle(timerProvider.durationMinutes),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_outlined, size: 16, color: primary),
                const SizedBox(width: 4),
                Text(
                  'Tap to change duration & presets',
                  style: TextStyle(
                    fontSize: 13,
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndAtModeContent(
    BuildContext context,
    MeditationTimerProvider timerProvider,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final hour = timerProvider.endAtHour == 0
        ? 12
        : (timerProvider.endAtHour > 12
            ? timerProvider.endAtHour - 12
            : timerProvider.endAtHour);
    final amPm = timerProvider.endAtHour >= 12 ? 'PM' : 'AM';
    final minuteStr = timerProvider.endAtMinute.toString().padLeft(2, '0');

    // Calculate approximate duration until endAt time
    final now = DateTime.now();
    var target = DateTime(
      now.year,
      now.month,
      now.day,
      timerProvider.endAtHour,
      timerProvider.endAtMinute,
    );
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }
    final diffMinutes = target.difference(now).inMinutes;
    final diffHours = diffMinutes ~/ 60;
    final remMins = diffMinutes % 60;
    final timeUntilStr = diffHours > 0
        ? '$diffHours hr $remMins min from now'
        : '$remMins min from now';

    return GestureDetector(
      onTap: () => _pickEndAtTime(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: primary.withAlpha(60),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$hour:$minuteStr $amPm',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              timeUntilStr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_outlined, size: 16, color: primary),
                const SizedBox(width: 4),
                Text(
                  'Tap to change end time',
                  style: TextStyle(
                    fontSize: 12,
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlimitedModeContent(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primary.withAlpha(60),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.all_inclusive_rounded, size: 48, color: primary),
          const SizedBox(height: 8),
          Text(
            'Open / Unlimited Mode',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Counts up continuously until you finish. Interval bells will chime as configured below.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundSettingsExpansionCard(
    BuildContext context,
    MeditationTimerProvider timerProvider,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          leading: Icon(Icons.tune_rounded, color: primary),
          title: Text(
            'Bells & Settings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Bell: ${timerProvider.startSound.displayName} • Vol: ${timerProvider.volume}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Dedicated Bell Volume
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          timerProvider.volume == 0
                              ? Icons.volume_off_outlined
                              : (timerProvider.volume < 50
                                  ? Icons.volume_down_outlined
                                  : Icons.volume_up_outlined),
                          size: 18,
                          color: primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Bell Volume',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${timerProvider.volume}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: timerProvider.volume.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${timerProvider.volume}%',
                  onChanged: (val) {
                    timerProvider.setVolume(val.round());
                  },
                ),
              ],
            ),
            const Divider(height: 20),

            // Start Bell
            _buildSoundRow(
              context: context,
              label: 'Starting Bell',
              selectedSound: timerProvider.startSound,
              timerProvider: timerProvider,
              onChanged: (sound) => timerProvider.setStartSound(sound),
            ),
            const Divider(height: 24),

            // Interval Bell
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Interval Bell',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DropdownButton<int>(
                  value: timerProvider.intervalMinutes,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(16),
                  items: _intervalOptions.map((min) {
                    return DropdownMenuItem<int>(
                      value: min,
                      child: Text(min == 0 ? 'Off' : 'Every ${min}m'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) timerProvider.setIntervalMinutes(val);
                  },
                ),
              ],
            ),
            if (timerProvider.intervalMinutes > 0) ...[
              const SizedBox(height: 8),
              _buildSoundRow(
                context: context,
                label: 'Interval Sound',
                selectedSound: timerProvider.intervalSound,
                timerProvider: timerProvider,
                onChanged: (sound) => timerProvider.setIntervalSound(sound),
              ),
            ],
            const Divider(height: 24),

            // End Bell
            _buildSoundRow(
              context: context,
              label: 'Ending Bell',
              selectedSound: timerProvider.endSound,
              timerProvider: timerProvider,
              onChanged: (sound) => timerProvider.setEndSound(sound),
            ),
            const Divider(height: 24),

            // Keep Screen On Switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Keep Screen Awake',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Prevent phone display from sleeping while meditating',
                style: TextStyle(fontSize: 12),
              ),
              value: timerProvider.keepScreenOn,
              onChanged: (val) => timerProvider.setKeepScreenOn(val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundRow({
    required BuildContext context,
    required String label,
    required MeditationSoundItem selectedSound,
    required MeditationTimerProvider timerProvider,
    required ValueChanged<MeditationSoundItem> onChanged,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DropdownButton<MeditationSoundItem>(
          value: selectedSound,
          underline: const SizedBox(),
          borderRadius: BorderRadius.circular(16),
          items: MeditationSoundItem.allSounds.map((sound) {
            return DropdownMenuItem<MeditationSoundItem>(
              value: sound,
              child: Text(sound.displayName),
            );
          }).toList(),
          onChanged: (sound) {
            if (sound != null) onChanged(sound);
          },
        ),
        const SizedBox(width: 4),
        if (selectedSound.id != 'none')
          IconButton(
            icon: Icon(Icons.play_circle_outline, color: primary, size: 22),
            tooltip: 'Preview sound',
            onPressed: () => timerProvider.previewSound(selectedSound),
          ),
      ],
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.self_improvement),
            SizedBox(width: 8),
            Text('Meditation Timer'),
          ],
        ),
        content: const Text(
          'A quiet, dedicated timer for your meditation practice.\n\n'
          '• Timed: Meditate for a fixed duration.\n'
          '• End At: Meditate until a specific time of day.\n'
          '• Open: Meditate freely with optional interval chimes.\n\n'
          'Tap the timer circle during a session to pause or resume.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
