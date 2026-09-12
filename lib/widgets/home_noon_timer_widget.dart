import 'dart:async';
import 'package:flutter/material.dart';
import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/solar_calc.dart';
import 'package:buddhist_sun/src/services/solar_time.dart';
import 'package:buddhist_sun/src/services/background_time_player.dart';
import 'package:buddhist_sun/src/services/notification_service.dart';

/// Compact, space-efficient Noon Countdown Timer pill widget for the Home screen.
/// Displays the live countdown to Solar Noon and a quick toggle for Voice Announcements.
class HomeNoonTimerWidget extends StatefulWidget {
  const HomeNoonTimerWidget({Key? key}) : super(key: key);

  @override
  State<HomeNoonTimerWidget> createState() => _HomeNoonTimerWidgetState();
}

class _HomeNoonTimerWidgetState extends State<HomeNoonTimerWidget>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Timer? _timer;
  DateTime _now = DateTime.now();
  bool _speakIsOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _speakIsOn = Prefs.speakIsOn;
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(covariant HomeNoonTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _now = DateTime.now();
    _speakIsOn = Prefs.speakIsOn;

    final target = getSolarNoonDateTime();
    if (target.difference(_now).isNegative) {
      // Finished: stop counting, do not start periodic timer
      if (mounted) setState(() {});
      return;
    }

    if (mounted) setState(() {});

    final int delayMs = 1000 - _now.millisecond;
    _timer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      _tick();
      if (getSolarNoonDateTime().difference(DateTime.now()).isNegative) {
        return;
      }
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) _tick();
      });
    });
  }

  void _tick() {
    final now = DateTime.now();
    final target = getSolarNoonDateTime();
    final isFinished = target.difference(now).isNegative;

    if (isFinished) {
      // Finished: cancel timer completely
      _timer?.cancel();
      _timer = null;
    }

    setState(() {
      _now = now;
      _speakIsOn = isFinished ? false : Prefs.speakIsOn;
    });
  }

  Future<void> _toggleVoice() async {
    final bValue = !_speakIsOn;
    final now = DateTime.now();
    final target = getSolarNoonDateTime();
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

      await BackgroundTimePlayer.startForTarget(
        target: target,
        title:
            "${AppLocalizations.of(context)!.buddhistSunCountdown} - ${AppLocalizations.of(context)!.solar_noon}",
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
    final target = getSolarNoonDateTime();
    final difference = target.difference(_now);
    final bool isPassed = difference.isNegative;
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 26,
                color: lateColor,
              ),
              const SizedBox(width: 10),
              Text(
                countdownStr,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: lateColor,
                ),
              ),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left: Countdown Display
            Icon(
              Icons.hourglass_bottom_rounded,
              size: 28,
              color: primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              countdownStr,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),

            const SizedBox(width: 14),
            // Vertical Divider
            Container(
              height: 24,
              width: 1,
              color: theme.colorScheme.outlineVariant.withAlpha(90),
            ),
            const SizedBox(width: 10),

            // Right: Voice Announcements Toggle
            Tooltip(
              message: AppLocalizations.of(context)!.speech_notify,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _toggleVoice,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4.0, vertical: 2.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.volume_off,
                        size: 19,
                        color: !_speakIsOn
                            ? theme.iconTheme.color?.withAlpha(160)
                            : theme.iconTheme.color?.withAlpha(80),
                      ),
                      const SizedBox(width: 2),
                      Transform.scale(
                        scale: 0.75,
                        child: Switch(
                          value: _speakIsOn,
                          onChanged: (val) => _toggleVoice(),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.record_voice_over,
                        size: 20,
                        color: _speakIsOn
                            ? primaryColor
                            : theme.iconTheme.color?.withAlpha(80),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
