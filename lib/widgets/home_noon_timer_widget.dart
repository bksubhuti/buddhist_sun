import 'dart:async';
import 'package:flutter/material.dart';
import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/solar_calc.dart';
import 'package:buddhist_sun/src/services/solar_time.dart';
import 'package:buddhist_sun/src/services/background_time_player.dart';
import 'package:buddhist_sun/src/services/notification_service.dart';
import 'package:buddhist_sun/widgets/screen_awake_toggle.dart';
import 'package:buddhist_sun/widgets/app_help_dialog.dart';

/// Compact, space-efficient Noon Countdown Timer pill widget for the Home screen.
/// Displays the live countdown to Solar Noon, a quick toggle for Voice Announcements
/// and a Screen Always On (coffee cup) toggle.
class HomeNoonTimerWidget extends StatefulWidget {
  final DateTime? currentTime;
  const HomeNoonTimerWidget({Key? key, this.currentTime}) : super(key: key);

  @override
  State<HomeNoonTimerWidget> createState() => _HomeNoonTimerWidgetState();
}

class _HomeNoonTimerWidgetState extends State<HomeNoonTimerWidget>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Timer? _timer;
  late DateTime _now;
  bool _speakIsOn = false;

  @override
  void initState() {
    super.initState();
    _now = widget.currentTime ?? DateTime.now();
    WidgetsBinding.instance.addObserver(this);
    _speakIsOn = Prefs.speakIsOn;
    if (widget.currentTime == null) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.currentTime != null) return;
    if (state == AppLifecycleState.resumed) {
      _startTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _timer?.cancel();
    }
  }

  @override
  void didUpdateWidget(covariant HomeNoonTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentTime != null) {
      _timer?.cancel();
      _now = widget.currentTime!;
    } else if (oldWidget.currentTime != null) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _now = DateTime.now();
    _speakIsOn = Prefs.speakIsOn;

    if (mounted) setState(() {});

    final int delayMs = 1000 - _now.millisecond;
    _timer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      _tick();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) _tick();
      });
    });
  }

  void _tick() {
    final now = DateTime.now();
    final targetInfo = getCountdownTargetInfo(now);
    final isFinished = targetInfo.isLate;

    if (isFinished &&
        (_speakIsOn || Prefs.speakIsOn || BackgroundTimePlayer.isPlaying)) {
      Future.delayed(const Duration(seconds: 5), () {
        if (!Prefs.speakIsOn) {
          unawaited(BackgroundTimePlayer.stop());
        }
      });
    }

    setState(() {
      _now = now;
      _speakIsOn = isFinished ? false : Prefs.speakIsOn;
    });
  }

  Future<void> _toggleVoice() async {
    final bValue = !_speakIsOn;
    final now = DateTime.now();
    final targetInfo = getCountdownTargetInfo(now);
    final target = targetInfo.targetDateTime;
    final difference = target.difference(now);

    if (bValue) {
      if (difference.inMinutes > 120) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.speech_only_within_2_hours,
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      if (difference.isNegative) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.late),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }
    }

    setState(() {
      _speakIsOn = bValue;
      Prefs.instance.setBool(SPEAKISON, bValue);
      Prefs.speakIsOn = bValue;
    });

    final service = SolarTimerService();
    service.delegate?.setSpeakIsOn(bValue);

    if (bValue) {
      // Speak initial countdown via TTS immediately
      service.initialVoicing = true;
      unawaited(service.speakInitialCountdown(target));

      final targetTitle = targetInfo.isDawnMode
          ? "${AppLocalizations.of(context)!.buddhistSunCountdown} - ${AppLocalizations.of(context)!.dawn}"
          : "${AppLocalizations.of(context)!.buddhistSunCountdown} - ${AppLocalizations.of(context)!.solar_noon}";

      await BackgroundTimePlayer.startForTarget(
        target: target,
        title: targetTitle,
        artist: AppLocalizations.of(context)!.buddhistSun,
        album: AppLocalizations.of(context)!.timer,
      );
    } else {
      try {
        await service.flutterTts.stop();
      } catch (_) {}
      await BackgroundTimePlayer.stop();
      service.initialVoicing = false;
      await cancelAllTimerNotifications();
    }
  }

  Widget _buildInfoButton(BuildContext context, ThemeData theme) {
    return IconButton(
      icon: const Icon(Icons.info_outline_rounded),
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      color: theme.colorScheme.onSurface.withAlpha(140),
      tooltip: AppLocalizations.of(context)!.help,
      onPressed: () => _showSwitchesHelp(context),
    );
  }

  void _showSwitchesHelp(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    showAppHelpDialog(
      context,
      title: t.countdownSwitchesHelpTitle,
      icon: Icons.info_outline_rounded,
      sections: [
        HelpSection(
          title: t.screenAwakeLabel,
          icon: Icons.coffee,
          content: t.screenAwakeHelp,
        ),
        HelpSection(
          title: t.voiceLabel,
          icon: Icons.record_voice_over,
          content: t.voiceHelp,
        ),
      ],
    );
  }

  String _formatDuration(Duration diff, BuildContext context) {
    if (diff.isNegative) {
      return AppLocalizations.of(context)!.late;
    }

    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    if (h > 0) {
      return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final targetInfo = getCountdownTargetInfo(_now);
    final target = targetInfo.targetDateTime;
    final difference = target.difference(_now);
    final bool isPassed = targetInfo.isLate;
    final Color lateColor = theme.brightness == Brightness.dark
        ? Colors.amber
        : Colors.orange.shade800;

    final String countdownStr = _formatDuration(difference, context);

    if (isPassed) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
            borderRadius: BorderRadius.circular(22.0),
            border: Border.all(
              color: lateColor.withAlpha(100),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 26,
                    color: lateColor,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            countdownStr,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: lateColor,
                            ),
                          ))),
                  const SizedBox(width: 4),
                  _buildInfoButton(context, theme),
                ],
              ),
              const SizedBox(height: 4),
              // Bottom: Screen Always On (coffee cup) Toggle
              const ScreenAwakeToggle(),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
          borderRadius: BorderRadius.circular(22.0),
          border: Border.all(
            color: _speakIsOn
                ? primaryColor.withAlpha(140)
                : theme.colorScheme.outlineVariant.withAlpha(60),
            width: _speakIsOn ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top: Countdown Display
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.hourglass_bottom_rounded,
                  size: 28,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Flexible(
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          countdownStr,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ))),
                const SizedBox(width: 4),
                _buildInfoButton(context, theme),
              ],
            ),
            const SizedBox(height: 4),
            // Bottom: Screen Always On and Voice Announcements tap toggles.
            // Wraps onto two lines on very narrow screens.
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 4,
              children: [
                const ScreenAwakeToggle(),
                Tooltip(
                  message: AppLocalizations.of(context)!.speech_notify,
                  child: TapToggleChip(
                    value: _speakIsOn,
                    onIcon: Icons.record_voice_over,
                    offIcon: Icons.voice_over_off,
                    label: AppLocalizations.of(context)!.voiceLabel,
                    onTap: _toggleVoice,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
