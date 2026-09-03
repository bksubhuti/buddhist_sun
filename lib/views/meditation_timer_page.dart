import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buddhist_sun/l10n/app_localizations.dart';
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
  static const List<int> _intervalOptions = [
    0,
    1,
    2,
    3,
    5,
    10,
    15,
    20,
    25,
    30,
    45,
    60
  ];

  List<int> _getIntervalOptions(int current) {
    final options = List<int>.from(_intervalOptions);
    if (!options.contains(current)) {
      options.add(current);
      options.sort();
    }
    return options;
  }

  Widget _buildVolumeCard(
    BuildContext context,
    MeditationTimerProvider timerProvider,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final t = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
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
                    size: 20,
                    color: primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.bellVolume,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '${timerProvider.volume}%',
                style: theme.textTheme.titleSmall?.copyWith(
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
            onChangeEnd: (val) {
              timerProvider.previewSound(timerProvider.startSound);
            },
          ),
        ],
      ),
    );
  }

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
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.meditationTimer),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: t.aboutTimer,
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
              if (timerProvider.mode == MeditationTimerMode.timed) ...[
                _buildTimedModeContent(context, timerProvider),
                const SizedBox(height: 14),
                _buildRecentTimesButtons(context, timerProvider),
              ] else if (timerProvider.mode == MeditationTimerMode.endAt)
                _buildEndAtModeContent(context, timerProvider)
              else
                _buildUnlimitedModeContent(context),

              const SizedBox(height: 16),

              // 3. Start Meditation Button (Below show time button)
              FilledButton.icon(
                onPressed: () => _startMeditation(context),
                icon: const Icon(Icons.play_arrow_rounded, size: 36),
                label: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 20.0, horizontal: 8.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      t.startMeditation,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
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

              const SizedBox(height: 16),

              // 4. Bell Volume (Below start button and above settings)
              _buildVolumeCard(context, timerProvider),

              const SizedBox(height: 16),

              // 5. Expansion View for Bells & Other Settings
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
    final t = AppLocalizations.of(context)!;

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
            label: t.timerModeTimed,
            icon: Icons.timer,
            isSelected: timerProvider.mode == MeditationTimerMode.timed,
            onTap: () => timerProvider.setMode(MeditationTimerMode.timed),
          ),
          _buildModeTab(
            context: context,
            label: t.timerModeEndAt,
            icon: Icons.alarm,
            isSelected: timerProvider.mode == MeditationTimerMode.endAt,
            onTap: () => timerProvider.setMode(MeditationTimerMode.endAt),
          ),
          _buildModeTab(
            context: context,
            label: t.timerModeOpen,
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
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
    final t = AppLocalizations.of(context)!;

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
                Flexible(
                  child: Text(
                    t.tapToChangeDuration,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTimesButtons(
    BuildContext context,
    MeditationTimerProvider timerProvider,
  ) {
    final alternateTimes = timerProvider.alternateRecentTimes;
    if (alternateTimes.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (int i = 0; i < alternateTimes.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _buildRecentTimeButton(
              context: context,
              minutes: alternateTimes[i],
              timerProvider: timerProvider,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecentTimeButton({
    required BuildContext context,
    required int minutes,
    required MeditationTimerProvider timerProvider,
  }) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 72,
      child: FilledButton.tonal(
        onPressed: () {
          timerProvider.setMode(MeditationTimerMode.timed);
          timerProvider.setDurationMinutes(minutes);
          _startMeditation(context);
        },
        style: FilledButton.styleFrom(
          backgroundColor:
              theme.colorScheme.surfaceContainerHighest.withAlpha(150),
          foregroundColor: theme.colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withAlpha(90),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(35),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _formatDurationTitle(minutes),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
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
    final t = AppLocalizations.of(context)!;

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
    final timeStr =
        diffHours > 0 ? '$diffHours hr $remMins min' : '$remMins min';
    final timeUntilStr = t.timeUntilEndAt(timeStr);

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
                Flexible(
                  child: Text(
                    t.tapToChangeEndTime,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
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
    final t = AppLocalizations.of(context)!;

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
            t.openUnlimitedMode,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.openUnlimitedModeDesc,
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
    final t = AppLocalizations.of(context)!;

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
            t.bellsAndSettings,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Start: ${timerProvider.startSound.displayName}'
            ' • ${timerProvider.intervalMinutes > 0 ? "${t.everyNMinutes(timerProvider.intervalMinutes)} (${timerProvider.intervalSound.displayName})" : "Interval: ${t.off}"}'
            ' • End: ${timerProvider.endSound.displayName}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Start Bell
            _buildSoundRow(
              context: context,
              label: t.startingBell,
              selectedSound: timerProvider.startSound,
              timerProvider: timerProvider,
              onChanged: (sound) => timerProvider.setStartSound(sound),
            ),
            const Divider(height: 24),

            // Interval Bell (in the middle of Start Bell and End Bell)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    t.intervalBell,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DropdownButton<int>(
                  value: timerProvider.intervalMinutes,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(16),
                  items: _getIntervalOptions(timerProvider.intervalMinutes)
                      .map((min) {
                    return DropdownMenuItem<int>(
                      value: min,
                      child: Text(min == 0 ? t.off : t.everyNMinutes(min)),
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
                label: t.intervalSound,
                selectedSound: timerProvider.intervalSound,
                timerProvider: timerProvider,
                onChanged: (sound) => timerProvider.setIntervalSound(sound),
              ),
            ],
            const Divider(height: 24),

            // End Bell
            _buildSoundRow(
              context: context,
              label: t.endingBell,
              selectedSound: timerProvider.endSound,
              timerProvider: timerProvider,
              onChanged: (sound) => timerProvider.setEndSound(sound),
            ),
            const Divider(height: 24),

            // Keep Screen On Switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                t.keepScreenAwake,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                t.keepScreenAwakeDesc,
                style: const TextStyle(fontSize: 12),
              ),
              value: timerProvider.keepScreenOn,
              onChanged: (val) => timerProvider.setKeepScreenOn(val),
            ),
            const Divider(height: 24),

            // Countdown Graphic Style (Subtractive vs Additive)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.timerRingStyle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.timerRingStyleDesc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'subtractive',
                        label: Text(t.styleSubtractive),
                        icon: const Icon(Icons.remove_circle_outline, size: 16),
                      ),
                      ButtonSegment(
                        value: 'additive',
                        label: Text(t.styleAdditive),
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                      ),
                    ],
                    selected: {timerProvider.ringStyle},
                    onSelectionChanged: (newSelection) {
                      timerProvider.setRingStyle(newSelection.first);
                    },
                  ),
                ),
              ],
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
            if (sound != null) {
              onChanged(sound);
              if (sound.id != 'none') {
                timerProvider.previewSound(sound);
              }
            }
          },
        ),
        if (selectedSound.id != 'none') ...[
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.play_circle_outline,
                color: theme.colorScheme.primary, size: 22),
            tooltip: 'Preview sound',
            visualDensity: VisualDensity.compact,
            onPressed: () => timerProvider.previewSound(selectedSound),
          ),
        ],
      ],
    );
  }

  void _showInfoDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.self_improvement),
            const SizedBox(width: 8),
            Text(t.meditationTimer),
          ],
        ),
        content: Text(t.timerInfoDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.ok),
          ),
        ],
      ),
    );
  }
}
