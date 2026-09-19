import 'dart:async';
import 'package:flutter/material.dart';
import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:buddhist_sun/src/models/colored_text.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/solar_calc.dart';

/// Adaptive Home target display widget.
///
/// In Noon Mode: Displays Solar Noon prominently (54pt).
/// In Dawn Mode (within 6h before dawn until 2h after dawn):
///   - Displays Solar Noon smaller up top.
///   - Displays upcoming Dawn just below (40pt, not as big as 54pt Noon).
/// Fits gracefully within the same vertical envelope on the Home screen.
class HomeTargetDisplayWidget extends StatefulWidget {
  final DateTime? currentTime;
  const HomeTargetDisplayWidget({Key? key, this.currentTime}) : super(key: key);

  @override
  State<HomeTargetDisplayWidget> createState() =>
      _HomeTargetDisplayWidgetState();
}

class _HomeTargetDisplayWidgetState extends State<HomeTargetDisplayWidget>
    with WidgetsBindingObserver {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = widget.currentTime ?? DateTime.now();
    WidgetsBinding.instance.addObserver(this);
    if (widget.currentTime == null) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(covariant HomeTargetDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentTime != null) {
      _timer?.cancel();
      _now = widget.currentTime!;
    } else if (oldWidget.currentTime != null) {
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

  void _startTimer() {
    _timer?.cancel();
    _now = DateTime.now();
    if (mounted) setState(() {});

    final int delayMs = 1000 - _now.millisecond;
    _timer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _now = DateTime.now());
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final targetInfo = getCountdownTargetInfo(_now);
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (!targetInfo.isDawnMode) {
      // ════════════════════════════════════════════════════
      // NOON MODE (Default / After Dawn + 2h)
      // ════════════════════════════════════════════════════
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ColoredText(
                getSolarNoonTimeString(targetInfo.solarNoon),
                style: const TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (Prefs.safety > 0) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.health_and_safety_outlined,
                  color: primaryColor,
                  size: 32,
                ),
              ],
            ],
          ),
          ColoredText(
            AppLocalizations.of(context)!.solar_noon,
            style: const TextStyle(fontSize: 27, letterSpacing: 2),
          ),
        ],
      );
    }

    // ════════════════════════════════════════════════════
    // DAWN MODE (6h before Dawn to 2h after Dawn)
    // ════════════════════════════════════════════════════
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Up top: Solar Noon (smaller)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ColoredText(
              getSolarNoonTimeString(targetInfo.solarNoon),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (Prefs.safety > 0) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.health_and_safety_outlined,
                color: primaryColor,
                size: 18,
              ),
            ],
          ],
        ),
        ColoredText(
          AppLocalizations.of(context)!.solar_noon,
          style: const TextStyle(fontSize: 13, letterSpacing: 1.5),
        ),

        const SizedBox(height: 6),

        // Just below: Dawn (not as big as Noon 54pt)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ColoredText(
              formatHM(targetInfo.upcomingDawn),
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (Prefs.safety > 0) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.health_and_safety_outlined,
                color: primaryColor,
                size: 24,
              ),
            ],
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ColoredText(
            "${AppLocalizations.of(context)!.dawn} (${getSelectedDawnMethodString(context)})",
            style: const TextStyle(fontSize: 16, letterSpacing: 1.2),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
