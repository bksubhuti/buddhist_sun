import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/solar_calc.dart';

/// Interactive 3D Solar Compass, Celestial Dome & Gnomon Shadow Simulator.
class SunShadowPage extends StatefulWidget {
  const SunShadowPage({Key? key}) : super(key: key);

  @override
  State<SunShadowPage> createState() => _SunShadowPageState();
}

class _SunShadowPageState extends State<SunShadowPage>
    with SingleTickerProviderStateMixin {
  // Mode: Live tracking vs Interactive Scrubber
  bool _isLive = true;
  DateTime _displayTime = DateTime.now();
  Timer? _liveTimer;
  String? _activeMilestone = 'now';

  // Compass tracking (enabled by default)
  bool _compassTracking = true;
  StreamSubscription<CompassEvent>? _compassSub;
  double _sensorHeading = 0.0;

  // 3D Camera Orbit controls
  // Pitch (tilt): 0 rad = top-down, pi/2 (~1.57 rad) = horizon edge-on
  static const double _dayPitch =
      82.0 * math.pi / 180.0; // ~1.431 rad (~82° pitch, 8° down from horizon)
  static const double _nightPitch =
      1.38; // ~79 degrees side view (11° down from horizon)
  double _pitch = _dayPitch;
  bool _wasBelowHorizon = false;
  late AnimationController _tiltController;
  late Animation<double> _tiltAnimation;

  // Yaw (azimuth rotation): 0 = looking North
  double _yaw = 0.0;

  // Diurnal sun path curve cache
  List<SolarPosition> _dayArc = [];
  DateTime? _cachedArcDate;

  // Touch drag state
  Offset? _lastPanPos;

  @override
  void initState() {
    super.initState();
    final initialPos = getSolarPositionAt(_displayTime);
    _wasBelowHorizon = initialPos.elevation <= 0.0;
    _pitch = _wasBelowHorizon ? _nightPitch : _dayPitch;

    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _tiltAnimation =
        Tween<double>(begin: _pitch, end: _pitch).animate(_tiltController);
    _tiltController.addListener(() {
      setState(() {
        _pitch = _tiltAnimation.value;
      });
    });

    _refreshDayArc();
    _startLiveTimer();
    _startCompass();
  }

  @override
  void dispose() {
    _tiltController.dispose();
    _liveTimer?.cancel();
    _compassSub?.cancel();
    super.dispose();
  }

  void _checkHorizonTilt({bool animate = true}) {
    final pos = getSolarPositionAt(_displayTime);
    final isBelow = pos.elevation <= 0.0;
    if (isBelow != _wasBelowHorizon) {
      _wasBelowHorizon = isBelow;
      final targetPitch = isBelow ? _nightPitch : _dayPitch;
      if (animate && mounted) {
        _tiltAnimation = Tween<double>(
          begin: _pitch,
          end: targetPitch,
        ).animate(CurvedAnimation(
          parent: _tiltController,
          curve: Curves.easeInOutCubic,
        ));
        _tiltController.forward(from: 0.0);
      } else {
        setState(() {
          _pitch = targetPitch;
        });
      }
    }
  }

  void _startLiveTimer() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isLive && mounted) {
        setState(() {
          _displayTime = DateTime.now();
          if (_cachedArcDate == null ||
              _cachedArcDate!.day != _displayTime.day) {
            _refreshDayArc();
          }
          _checkHorizonTilt(animate: true);
        });
      }
    });
  }

  void _refreshDayArc() {
    final now = DateTime.now();
    _cachedArcDate = DateTime(now.year, now.month, now.day);
    _dayArc = getDaySolarArc(_cachedArcDate!, samples: 72);
  }

  void _startCompass() {
    _compassSub?.cancel();
    _compassTracking = true;
    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      final raw = event.heading ?? 0.0;
      final heading = (raw < 0) ? raw + 360.0 : raw;
      setState(() {
        _sensorHeading = heading;
        if (_compassTracking) {
          _yaw = heading * (math.pi / 180.0);
        }
      });
    });
  }

  void _toggleCompass() {
    setState(() {
      _compassTracking = !_compassTracking;
      if (_compassTracking) {
        _startCompass();
      } else {
        _compassSub?.cancel();
        _compassSub = null;
      }
    });
  }

  void _resetCamera() {
    setState(() {
      _pitch = _wasBelowHorizon ? _nightPitch : _dayPitch;
      _startCompass();
    });
  }

  void _toggleRealTimeClock() {
    setState(() {
      _isLive = !_isLive;
      if (_isLive) {
        _displayTime = DateTime.now();
        _activeMilestone = 'now';
        _checkHorizonTilt(animate: true);
      } else {
        _activeMilestone = null;
      }
    });
  }

  void _jumpToTime(DateTime target, String milestone) {
    setState(() {
      _isLive = false;
      _displayTime = target;
      _activeMilestone = milestone;
      _checkHorizonTilt(animate: true);
    });
  }

  bool _isNearMilestone(DateTime target, {int thresholdMinutes = 6}) {
    final currentMinutes = _displayTime.hour * 60 + _displayTime.minute;
    final targetMinutes = target.hour * 60 + target.minute;
    return (currentMinutes - targetMinutes).abs() <= thresholdMinutes;
  }

  void _updateActiveMilestoneFromScrubber() {
    final aruna = getSelectedDawn();
    final sunrise = getSunrise();
    final noon = getSolarNoonRaw();
    final sunset = getSunset();
    final dusk = getCivilDusk();
    final now = DateTime.now();

    if (_isNearMilestone(noon, thresholdMinutes: 6)) {
      _activeMilestone = 'noon';
    } else if (_isNearMilestone(sunrise, thresholdMinutes: 6)) {
      _activeMilestone = 'sunrise';
    } else if (_isNearMilestone(aruna, thresholdMinutes: 6)) {
      _activeMilestone = 'aruna';
    } else if (_isNearMilestone(sunset, thresholdMinutes: 6)) {
      _activeMilestone = 'sunset';
    } else if (_isNearMilestone(dusk, thresholdMinutes: 6)) {
      _activeMilestone = 'dusk';
    } else if (_isNearMilestone(now, thresholdMinutes: 6)) {
      _activeMilestone = 'now';
    } else {
      _activeMilestone = null;
    }
  }

  void _showVinayaInfoDialog() {
    final t = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.wb_sunny, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.vinayaTitle,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${t.vinayaIntro}\n',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              Text(
                '${t.vinayaBulletKala}\n\n'
                '${t.vinayaBulletMajjhantika}\n\n'
                '${t.vinayaBulletVikala}\n\n'
                '${t.vinayaBulletSimulation}',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    // Calculate instantaneous solar position for the current displayed moment
    final pos = getSolarPositionAt(_displayTime);
    final noonRaw = getSolarNoonRaw();
    final isBeforeNoon = _displayTime.isBefore(noonRaw);
    final diffFromNoon = _displayTime.difference(noonRaw);

    // Milestones for quick jump highlighting & contextual status banner
    final aruna = getSelectedDawn();
    final sunrise = getSunrise();
    final sunset = getSunset();
    final dusk = getCivilDusk();

    // Determine current monastic / solar phase for the top banner:
    final diffToAruna = _displayTime.difference(aruna);
    final diffToDusk = _displayTime.difference(dusk);

    // Aruṇa phase: before Aruṇa on displayed date or within 60 minutes after Aruṇa
    final bool isArunaPhase = _displayTime.isBefore(aruna) ||
        (diffToAruna.inMinutes >= 0 && diffToAruna.inMinutes <= 60);

    // Dusk phase: within ±60 minutes of civil dusk
    final bool isDuskPhase = !isArunaPhase &&
        _displayTime.isAfter(noonRaw) &&
        diffToDusk.inMinutes.abs() <= 60;

    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    late final String bannerText;
    late final IconData bannerIcon;
    late final Color bannerIconColor;
    late final Color bannerBgColor;
    late final Color bannerBorderColor;
    late final Color bannerTextColor;

    if (isArunaPhase) {
      final isBeforeAruna = _displayTime.isBefore(aruna);
      bannerText = isBeforeAruna
          ? t.bannerArunaTo(_formatDuration(diffToAruna.abs()))
          : t.bannerArunaPast(_formatDuration(diffToAruna));
      bannerIcon = Icons.wb_twilight;
      bannerIconColor =
          isDark ? Colors.orange.shade300 : Colors.orange.shade800;
      bannerBgColor = Colors.orange.withValues(alpha: isDark ? 0.16 : 0.12);
      bannerBorderColor = Colors.orange.withValues(alpha: isDark ? 0.40 : 0.35);
      bannerTextColor =
          isDark ? Colors.orange.shade200 : Colors.orange.shade900;
    } else if (isDuskPhase) {
      final isBeforeDusk = _displayTime.isBefore(dusk);
      bannerText = isBeforeDusk
          ? t.bannerDuskTo(_formatDuration(diffToDusk.abs()))
          : t.bannerDuskPast(_formatDuration(diffToDusk));
      bannerIcon = Icons.nights_stay_outlined;
      bannerIconColor =
          isDark ? Colors.indigo.shade300 : Colors.indigo.shade700;
      bannerBgColor = Colors.indigo.withValues(alpha: isDark ? 0.18 : 0.14);
      bannerBorderColor = Colors.indigo.withValues(alpha: isDark ? 0.42 : 0.35);
      bannerTextColor =
          isDark ? Colors.indigo.shade200 : Colors.indigo.shade900;
    } else if (isBeforeNoon) {
      bannerText = t.bannerKalaTo(_formatDuration(diffFromNoon.abs()));
      bannerIcon = Icons.wb_sunny;
      bannerIconColor = Colors.amber.shade700;
      bannerBgColor = Colors.amber.withValues(alpha: isDark ? 0.15 : 0.12);
      bannerBorderColor = Colors.amber.withValues(alpha: isDark ? 0.40 : 0.35);
      bannerTextColor = isDark ? Colors.amber.shade200 : Colors.amber.shade900;
    } else {
      bannerText = t.bannerVikalaPast(_formatDuration(diffFromNoon));
      bannerIcon = Icons.wb_twilight;
      bannerIconColor = Colors.blueGrey;
      bannerBgColor = Colors.blueGrey.withValues(alpha: isDark ? 0.15 : 0.12);
      bannerBorderColor =
          Colors.blueGrey.withValues(alpha: isDark ? 0.40 : 0.35);
      bannerTextColor =
          isDark ? Colors.blueGrey.shade200 : Colors.blueGrey.shade800;
    }

    // 24-hour scrubber bounds (00:00 to 23:59)
    const double sliderMin = 0.0;
    const double sliderMax = 1439.0;

    // Format times for display
    final timeStr =
        '${_displayTime.hour.toString().padLeft(2, '0')}:${_displayTime.minute.toString().padLeft(2, '0')}:${_displayTime.second.toString().padLeft(2, '0')}';
    final noonStr =
        '${noonRaw.hour.toString().padLeft(2, '0')}:${noonRaw.minute.toString().padLeft(2, '0')}:${noonRaw.second.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.sunAndShadow,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${_displayTime.day}.${_displayTime.month}.${_displayTime.year} • GPS: ${Prefs.lat.toStringAsFixed(3)}, ${Prefs.lng.toStringAsFixed(3)}',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _compassTracking
                ? 'Compass Active: ${_sensorHeading.toStringAsFixed(0)}° (Tap to unlock)'
                : t.alignCompass,
            icon: Icon(
              _compassTracking ? Icons.explore : Icons.explore_off_outlined,
              color: _compassTracking ? primaryColor : null,
            ),
            onPressed: _toggleCompass,
          ),
          IconButton(
            tooltip: t.reset3DPerspective,
            icon: const Icon(Icons.refresh),
            onPressed: _resetCamera,
          ),
          IconButton(
            tooltip: t.vinayaContext,
            icon: const Icon(Icons.info_outline),
            onPressed: _showVinayaInfoDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Status Pill / Vinaya Banner ───────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: bannerBgColor,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: bannerBorderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      bannerIcon,
                      color: bannerIconColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bannerText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: bannerTextColor,
                        ),
                      ),
                    ),
                    if (_isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fiber_manual_record,
                                size: 8, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── 3D Perspective Canvas with Gesture Orbit ───────────────
            Expanded(
              flex: 5,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  _lastPanPos = details.localPosition;
                },
                onPanUpdate: (details) {
                  if (_lastPanPos != null) {
                    final dx = details.localPosition.dx - _lastPanPos!.dx;
                    final dy = details.localPosition.dy - _lastPanPos!.dy;
                    setState(() {
                      // Dragging vertically tilts perspective pitch (0° = flat top-down sundial, 85° = side view)
                      _pitch = (_pitch + dy * 0.008)
                          .clamp(0.0, 85.0 * math.pi / 180.0);
                      // Only adjust yaw manually if compass tracking is disabled
                      if (!_compassTracking) {
                        _yaw -= dx * 0.008;
                      }
                    });
                  }
                  _lastPanPos = details.localPosition;
                },
                onPanEnd: (_) => _lastPanPos = null,
                onDoubleTap: _resetCamera,
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: SolarDomePainter(
                        pitch: _pitch,
                        yaw: _yaw,
                        sunPosition: pos,
                        dayArc: _dayArc,
                        isDark: theme.brightness == Brightness.dark,
                        primaryColor: primaryColor,
                      ),
                      size: Size.infinite,
                    ),
                    // Hint chip at bottom-left of canvas
                    Positioned(
                      left: 12,
                      bottom: 8,
                      child: Text(
                        _compassTracking
                            ? (pos.elevation <= 0
                                ? t.compassLiveSunBelow(
                                    _sensorHeading.toStringAsFixed(0))
                                : t.compassLiveDrag(
                                    _sensorHeading.toStringAsFixed(0)))
                            : (pos.elevation <= 0
                                ? t.sunBelowHorizonDrag
                                : t.dragToRotateCompass),
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Instant Readouts Metric Cards ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Row(
                children: [
                  _buildMetricCard(
                    context,
                    label: t.elevation,
                    value: '${pos.elevation.toStringAsFixed(1)}°',
                    subtext: pos.elevation > 0
                        ? t.aboveHorizon
                        : t.nightUnderHorizon,
                    icon: Icons.north_east,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricCard(
                    context,
                    label: t.azimuth,
                    value: '${pos.azimuth.toStringAsFixed(1)}°',
                    subtext: _azimuthToDirection(pos.azimuth),
                    icon: Icons.explore,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricCard(
                    context,
                    label: t.shadowLength,
                    value: pos.shadowLength != null
                        ? '${pos.shadowLength!.toStringAsFixed(2)} ${t.timesPin}'
                        : t.noDirectShadow,
                    subtext: pos.shadowLength != null
                        ? t.minAtNoon
                        : (pos.elevation > 0 ? t.sunAtHorizon : t.belowHorizon),
                    icon: Icons.straighten,
                    color: Colors.teal,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricCard(
                    context,
                    label: t.solar_noon,
                    value: noonStr,
                    subtext: t.dailyMinShadow,
                    icon: Icons.wb_sunny_outlined,
                    color: Colors.amber,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Interactive Time Scrubber & Quick Jumps ────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 16, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      // Real-Time Clock Toggle Button (Activated vs Not Activated)
                      OutlinedButton.icon(
                        onPressed: _toggleRealTimeClock,
                        icon: Icon(
                          _isLive
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 14,
                          color: _isLive
                              ? Colors.green
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                        ),
                        label: Text(
                          _isLive
                              ? t.realTimeClockActivated
                              : t.realTimeClockInactive,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isLive
                                ? Colors.green
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _isLive
                              ? Colors.green.withValues(alpha: 0.12)
                              : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.2),
                          side: BorderSide(
                            color: _isLive
                                ? Colors.green.withValues(alpha: 0.6)
                                : theme.dividerColor.withValues(alpha: 0.35),
                            width: _isLive ? 1.4 : 0.8,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),

                  // 24-Hour Slider (00:00 to 23:59)
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      min: sliderMin,
                      max: sliderMax,
                      value: (_displayTime.hour * 60 + _displayTime.minute)
                          .toDouble()
                          .clamp(sliderMin, sliderMax),
                      onChanged: (val) {
                        final totalMinutes = val.round().clamp(0, 1439);
                        final h = totalMinutes ~/ 60;
                        final m = totalMinutes % 60;
                        setState(() {
                          _isLive = false;
                          _displayTime = DateTime(_displayTime.year,
                              _displayTime.month, _displayTime.day, h, m, 0);
                          _updateActiveMilestoneFromScrubber();
                          _checkHorizonTilt(animate: true);
                        });
                      },
                    ),
                  ),

                  // ── Label under the slider (Scrub Time & 24h span) ────────
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 0.0, bottom: 8.0, left: 6.0, right: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '00:00',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _isLive
                                ? theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.35)
                                : Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _isLive
                                  ? theme.dividerColor.withValues(alpha: 0.2)
                                  : Colors.amber.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tune,
                                size: 13,
                                color: _isLive
                                    ? theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6)
                                    : Colors.amber[800],
                              ),
                              const SizedBox(width: 5),
                              Text(
                                t.scrubTime(timeStr),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  color: _isLive
                                      ? theme.colorScheme.onSurface
                                          .withValues(alpha: 0.8)
                                      : (theme.brightness == Brightness.dark
                                          ? Colors.amber[200]
                                          : Colors.amber[900]),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '23:59',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quick Jump Buttons Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildJumpChip(
                          context: context,
                          label: _isLive
                              ? t.realTimeClockActiveChip
                              : t.realTimeClockChip,
                          icon: _isLive ? Icons.check_circle : Icons.schedule,
                          isHighlight: _isLive,
                          onTap: _toggleRealTimeClock,
                        ),
                        const SizedBox(width: 6),
                        _buildJumpChip(
                          context: context,
                          label: t.aruna,
                          icon: Icons.wb_twilight,
                          isHighlight: _activeMilestone == 'aruna',
                          onTap: () => _jumpToTime(aruna, 'aruna'),
                        ),
                        const SizedBox(width: 6),
                        _buildJumpChip(
                          context: context,
                          label: t.sunrise,
                          icon: Icons.wb_sunny_outlined,
                          isHighlight: _activeMilestone == 'sunrise',
                          onTap: () => _jumpToTime(sunrise, 'sunrise'),
                        ),
                        const SizedBox(width: 6),
                        _buildJumpChip(
                          context: context,
                          label: t.solarNoonMinShadow,
                          icon: Icons.wb_sunny,
                          isHighlight: _activeMilestone == 'noon',
                          onTap: () => _jumpToTime(noonRaw, 'noon'),
                        ),
                        const SizedBox(width: 6),
                        _buildJumpChip(
                          context: context,
                          label: t.sunset,
                          icon: Icons.nights_stay_outlined,
                          isHighlight: _activeMilestone == 'sunset',
                          onTap: () => _jumpToTime(sunset, 'sunset'),
                        ),
                        const SizedBox(width: 6),
                        _buildJumpChip(
                          context: context,
                          label: t.dusk,
                          icon: Icons.nights_stay,
                          isHighlight: _activeMilestone == 'dusk',
                          onTap: () => _jumpToTime(dusk, 'dusk'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              subtext,
              style: TextStyle(
                fontSize: 9,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJumpChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Glowing golden amber for active highlight in both light and dark modes
    final activeTextColor = isDark ? Colors.amber[200]! : Colors.amber[900]!;
    final activeIconColor = isDark ? Colors.amberAccent : Colors.amber[800]!;
    final activeBg = isDark
        ? Colors.amber.withValues(alpha: 0.28)
        : Colors.amber.withValues(alpha: 0.22);
    final activeBorderColor = isDark ? Colors.amberAccent : Colors.amber[700]!;

    return ActionChip(
      avatar: Icon(
        icon,
        size: 14,
        color: isHighlight
            ? activeIconColor
            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          color: isHighlight ? activeTextColor : theme.colorScheme.onSurface,
        ),
      ),
      backgroundColor: isHighlight ? activeBg : null,
      side: BorderSide(
        color: isHighlight
            ? activeBorderColor
            : theme.dividerColor.withValues(alpha: 0.2),
        width: isHighlight ? 1.6 : 0.8,
      ),
      elevation: isHighlight ? 2.0 : 0.0,
      onPressed: onTap,
    );
  }

  String _azimuthToDirection(double az) {
    if (az >= 337.5 || az < 22.5) return 'N (North)';
    if (az >= 22.5 && az < 67.5) return 'NE (Northeast)';
    if (az >= 67.5 && az < 112.5) return 'E (East)';
    if (az >= 112.5 && az < 157.5) return 'SE (Southeast)';
    if (az >= 157.5 && az < 202.5) return 'S (South)';
    if (az >= 202.5 && az < 247.5) return 'SW (Southwest)';
    if (az >= 247.5 && az < 292.5) return 'W (West)';
    return 'NW (Northwest)';
  }

  String _formatDuration(Duration d) {
    final absD = d.abs();
    final h = absD.inHours;
    final m = absD.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3D Solar Dome & Shadow Custom Painter
// ─────────────────────────────────────────────────────────────────────────────

class SolarDomePainter extends CustomPainter {
  final double pitch;
  final double yaw;
  final SolarPosition sunPosition;
  final List<SolarPosition> dayArc;
  final bool isDark;
  final Color primaryColor;

  // Dynamic visual parameters (scale cleanly with dome radius)
  double _getGnomonHeight(double radius) => radius * 0.29;
  double _getCameraDist(double radius) => radius * 3.16;

  SolarDomePainter({
    required this.pitch,
    required this.yaw,
    required this.sunPosition,
    required this.dayArc,
    required this.isDark,
    required this.primaryColor,
  });

  /// 3D spherical / Cartesian projection onto 2D canvas coordinates.
  /// (X = East, Y = North, Z = Zenith Up)
  Offset _project(double x, double y, double z, Offset center, double radius) {
    final cameraDist = _getCameraDist(radius);

    // Yaw rotation (around Z axis)
    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);
    final x1 = x * cosY - y * sinY;
    final y1 = x * sinY + y * cosY;
    final z1 = z;

    // Pitch rotation (tilt camera downward around screen horizontal axis)
    final cosP = math.cos(pitch);
    final sinP = math.sin(pitch);

    // Perspective depth factor
    final depth = cameraDist - (-y1 * sinP + z1 * cosP);
    final k = cameraDist / math.max(depth, radius * 0.4);

    final screenX = center.dx + (x1 * k);
    final screenY = center.dy - ((y1 * cosP + z1 * sinP) * k);
    return Offset(screenX, screenY);
  }

  /// Convert spherical azimuth and elevation to Cartesian (X, Y, Z).
  Offset _projectSpherical(
      double azimuthDeg, double elevationDeg, Offset center, double radius) {
    final azRad = azimuthDeg * (math.pi / 180.0);
    final elRad = elevationDeg * (math.pi / 180.0);

    final x = radius * math.cos(elRad) * math.sin(azRad);
    final y = radius * math.cos(elRad) * math.cos(azRad);
    final z = radius * math.sin(elRad);

    return _project(x, y, z, center, radius);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2.0, size.height * 0.50);
    final radius = math.min(size.width, size.height) * 0.38;

    // Background sky subtle gradient disc
    _drawSkyAtmosphere(canvas, center, radius);

    // Ground compass disc (concentric rings, cardinal ticks, meridian)
    _drawGroundDisc(canvas, center, radius);

    // Celestial dome wireframe lines (horizon, elevation parallels, prime meridian)
    _drawCelestialDome(canvas, center, radius);

    // Diurnal Sun Path curve for today
    _drawDayArc(canvas, center, radius);

    // Dynamic Cast Shadow on ground plane
    _drawCastShadow(canvas, center, radius);

    // Central 3D Gnomon (brass pin standing vertical at center)
    _drawGnomon(canvas, center, radius);

    // Sun Sphere & Light Rays
    _drawSun(canvas, center, radius);
  }

  void _drawSkyAtmosphere(Canvas canvas, Offset center, double radius) {
    final horizonRect = Rect.fromCircle(center: center, radius: radius * 1.2);
    final skyPaint = Paint()
      ..shader = RadialGradient(
        colors: isDark
            ? [
                Colors.indigo.shade900.withValues(alpha: 0.18),
                Colors.black.withValues(alpha: 0.0),
              ]
            : [
                Colors.lightBlue.shade100.withValues(alpha: 0.25),
                Colors.white.withValues(alpha: 0.0),
              ],
      ).createShader(horizonRect);
    canvas.drawOval(
      Rect.fromCenter(
          center: center, width: radius * 2.4, height: radius * 1.6),
      skyPaint,
    );
  }

  void _drawGroundDisc(Canvas canvas, Offset center, double radius) {
    final scale = (radius / 150.0).clamp(0.25, 2.0);
    final discFill = Paint()
      ..color = isDark
          ? const Color(0xFF1B222E).withValues(alpha: 0.65)
          : const Color(0xFFE8EEF5).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Draw elliptical ground polygon by sampling 48 boundary points
    final groundPath = Path();
    const steps = 48;
    for (int i = 0; i < steps; i++) {
      final angle = (i * 360.0 / steps) * (math.pi / 180.0);
      final x = radius * math.sin(angle);
      final y = radius * math.cos(angle);
      final pt = _project(x, y, 0.0, center, radius);
      if (i == 0) {
        groundPath.moveTo(pt.dx, pt.dy);
      } else {
        groundPath.lineTo(pt.dx, pt.dy);
      }
    }
    groundPath.close();
    canvas.drawPath(groundPath, discFill);

    // Rim stroke
    final rimPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (1.2 * scale).clamp(0.8, 1.5);
    canvas.drawPath(groundPath, rimPaint);

    // Concentric inner shadow-measurement circles (0.5x, 0.75x)
    for (final s in [0.35, 0.65]) {
      final ringPath = Path();
      for (int i = 0; i < steps; i++) {
        final angle = (i * 360.0 / steps) * (math.pi / 180.0);
        final x = (radius * s) * math.sin(angle);
        final y = (radius * s) * math.cos(angle);
        final pt = _project(x, y, 0.0, center, radius);
        if (i == 0) {
          ringPath.moveTo(pt.dx, pt.dy);
        } else {
          ringPath.lineTo(pt.dx, pt.dy);
        }
      }
      ringPath.close();
      final ringPaint = Paint()
        ..color = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (0.8 * scale).clamp(0.5, 1.0);
      canvas.drawPath(ringPath, ringPaint);
    }

    // North-South True Meridian line (Crucial for Solar Noon!)
    final northPt = _project(0.0, radius, 0.0, center, radius);
    final southPt = _project(0.0, -radius, 0.0, center, radius);
    final meridianPaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.4)
      ..strokeWidth = (1.5 * scale).clamp(1.0, 1.8)
      ..style = PaintingStyle.stroke;
    canvas.drawLine(northPt, southPt, meridianPaint);

    // East-West Line
    final eastPt = _project(radius, 0.0, 0.0, center, radius);
    final westPt = _project(-radius, 0.0, 0.0, center, radius);
    final ewPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.15)
          : Colors.black.withValues(alpha: 0.15)
      ..strokeWidth = (1.0 * scale).clamp(0.6, 1.2);
    canvas.drawLine(eastPt, westPt, ewPaint);

    // Cardinal direction labels (N, E, S, W)
    _drawCardinalLabel(canvas, 'N', 0.0, radius, center, Colors.redAccent);
    _drawCardinalLabel(canvas, 'E', 90.0, radius, center,
        isDark ? Colors.white70 : Colors.black87);
    _drawCardinalLabel(canvas, 'S', 180.0, radius, center,
        isDark ? Colors.white70 : Colors.black87);
    _drawCardinalLabel(canvas, 'W', 270.0, radius, center,
        isDark ? Colors.white70 : Colors.black87);
  }

  void _drawCardinalLabel(Canvas canvas, String label, double azimuthDeg,
      double radius, Offset center, Color color) {
    final scale = (radius / 150.0).clamp(0.25, 2.0);
    final azRad = azimuthDeg * (math.pi / 180.0);
    // Position label slightly outside the rim
    final offsetDist = radius + (14.0 * scale).clamp(6.0, 16.0);
    final x = offsetDist * math.sin(azRad);
    final y = offsetDist * math.cos(azRad);
    final pt = _project(x, y, 0.0, center, radius);

    final fontSize = (12.0 * scale).clamp(7.5, 12.0);
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(pt.dx - tp.width / 2.0, pt.dy - tp.height / 2.0));
  }

  void _drawCelestialDome(Canvas canvas, Offset center, double radius) {
    final scale = (radius / 150.0).clamp(0.25, 2.0);
    final domePaint = Paint()
      ..color = isDark
          ? Colors.cyan.withValues(alpha: 0.15)
          : Colors.blue.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (0.9 * scale).clamp(0.6, 1.2);

    // Parallel altitude rings above horizon (30° and 60° elevation)
    for (final el in [30.0, 60.0]) {
      final arcPath = Path();
      const steps = 40;
      for (int i = 0; i <= steps; i++) {
        final az = (i * 360.0 / steps);
        final pt = _projectSpherical(az, el, center, radius);
        if (i == 0) {
          arcPath.moveTo(pt.dx, pt.dy);
        } else {
          arcPath.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(arcPath, domePaint);
    }

    // Subterranean altitude rings below horizon (-30° and -60° elevation)
    final subDomePaint = Paint()
      ..color = isDark
          ? Colors.indigoAccent.withValues(alpha: 0.12)
          : Colors.blueGrey.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (0.8 * scale).clamp(0.5, 1.0);

    for (final el in [-30.0, -60.0]) {
      final arcPath = Path();
      const steps = 40;
      for (int i = 0; i <= steps; i++) {
        final az = (i * 360.0 / steps);
        final pt = _projectSpherical(az, el, center, radius);
        if (i == 0) {
          arcPath.moveTo(pt.dx, pt.dy);
        } else {
          arcPath.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(arcPath, subDomePaint);
    }

    // Upper vertical meridian arc (passing through Zenith from North to South)
    final meridianArc = Path();
    for (int el = 0; el <= 180; el += 5) {
      final pt = el <= 90
          ? _projectSpherical(0.0, el.toDouble(), center, radius) // North side
          : _projectSpherical(
              180.0, (180 - el).toDouble(), center, radius); // South side
      if (el == 0) {
        meridianArc.moveTo(pt.dx, pt.dy);
      } else {
        meridianArc.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(meridianArc, domePaint);

    // Subterranean meridian arc (passing through Nadir from North to South underneath)
    final subMeridianArc = Path();
    for (int el = 0; el <= 180; el += 5) {
      final pt = el <= 90
          ? _projectSpherical(0.0, -el.toDouble(), center, radius)
          : _projectSpherical(180.0, -(180 - el).toDouble(), center, radius);
      if (el == 0) {
        subMeridianArc.moveTo(pt.dx, pt.dy);
      } else {
        subMeridianArc.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(subMeridianArc, subDomePaint);

    // Zenith marker dot at top of dome (+90°)
    final zenithPt = _projectSpherical(0.0, 90.0, center, radius);
    canvas.drawCircle(
      zenithPt,
      (2.5 * scale).clamp(1.2, 2.8),
      Paint()
        ..color = isDark ? Colors.cyanAccent : Colors.blue
        ..style = PaintingStyle.fill,
    );

    // Nadir marker dot at bottom of subterranean sphere (-90°)
    final nadirPt = _projectSpherical(0.0, -90.0, center, radius);
    canvas.drawCircle(
      nadirPt,
      (2.5 * scale).clamp(1.2, 2.8),
      Paint()
        ..color = isDark ? Colors.indigoAccent : Colors.blueGrey
        ..style = PaintingStyle.fill,
    );
  }

  void _drawDayArc(Canvas canvas, Offset center, double radius) {
    if (dayArc.isEmpty) return;

    final scale = (radius / 150.0).clamp(0.25, 2.0);
    final dayPath = Path();
    final nightPath = Path();
    bool inDay = false;
    bool inNight = false;

    for (int i = 0; i < dayArc.length; i++) {
      final p = dayArc[i];
      final pt = _projectSpherical(p.azimuth, p.elevation, center, radius);
      if (p.elevation >= 0) {
        if (!inDay) {
          dayPath.moveTo(pt.dx, pt.dy);
          inDay = true;
        } else {
          dayPath.lineTo(pt.dx, pt.dy);
        }
        inNight = false;
      } else {
        if (!inNight) {
          nightPath.moveTo(pt.dx, pt.dy);
          inNight = true;
        } else {
          nightPath.lineTo(pt.dx, pt.dy);
        }
        inDay = false;
      }
    }

    // Draw night arc (subterranean nocturnal path beneath the horizon)
    final nightArcPaint = Paint()
      ..color = isDark
          ? Colors.blueGrey.withValues(alpha: 0.45)
          : Colors.indigo.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (1.6 * scale).clamp(0.9, 1.8);
    canvas.drawPath(nightPath, nightArcPaint);

    // Draw day arc (luminous golden sun curve)
    final dayArcGlow = Paint()
      ..color = Colors.amber.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (4.5 * scale).clamp(2.0, 4.5);
    canvas.drawPath(dayPath, dayArcGlow);

    final dayArcPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = (2.0 * scale).clamp(1.0, 2.2);
    canvas.drawPath(dayPath, dayArcPaint);
  }

  void _drawCastShadow(Canvas canvas, Offset center, double radius) {
    // No direct shadows cast when the sun is too close to horizon (<= 4.0°) or below
    if (sunPosition.elevation <= 4.0) return;

    final scale = (radius / 150.0).clamp(0.25, 2.0);
    final gh = _getGnomonHeight(radius);

    // Atmospheric shadow clarity fades in smoothly between 4.0° and 8.0° elevation
    final atmosphereFade =
        ((sunPosition.elevation - 4.0) / 4.0).clamp(0.0, 1.0);

    final shadowAz = sunPosition.shadowAzimuth;
    final shadowAzRad = shadowAz * (math.pi / 180.0);

    // Trigonometric shadow length
    final elRad = math.max(sunPosition.elevation, 1.0) * (math.pi / 180.0);
    final rawLength = gh / math.tan(elRad);

    // Confine shadow strictly inside the circular measuring disc (never beyond rim)
    final maxDiscShadow = radius * 0.94;
    final displayLength = rawLength.clamp(2.0, maxDiscShadow);

    // When the physical shadow extends past the disc, fade out the tip so it drops off the board cleanly
    final tipFade = (rawLength > maxDiscShadow)
        ? (maxDiscShadow / rawLength).clamp(0.40, 1.0)
        : 1.0;
    final combinedAlpha = atmosphereFade * tipFade;

    // Base origin point on ground
    final originPt = _project(0.0, 0.0, 0.0, center, radius);

    // Tip point of shadow on ground
    final tipX = displayLength * math.sin(shadowAzRad);
    final tipY = displayLength * math.cos(shadowAzRad);
    final tipPt = _project(tipX, tipY, 0.0, center, radius);

    // Perpendicular vector for shadow polygon width
    final perpAzRad = shadowAzRad + (math.pi / 2.0);
    final baseWidth = (3.5 * scale).clamp(1.4, 3.8);
    final b1X = baseWidth * math.sin(perpAzRad);
    final b1Y = baseWidth * math.cos(perpAzRad);
    final b1 = _project(b1X, b1Y, 0.0, center, radius);
    final b2 = _project(-b1X, -b1Y, 0.0, center, radius);

    final tipWidth = (2.0 * scale).clamp(0.9, 2.2);
    final t1X = tipX + tipWidth * math.sin(perpAzRad);
    final t1Y = tipY + tipWidth * math.cos(perpAzRad);
    final t1 = _project(t1X, t1Y, 0.0, center, radius);
    final t2 = _project(tipX - tipWidth * math.sin(perpAzRad),
        tipY - tipWidth * math.cos(perpAzRad), 0.0, center, radius);

    // Draw shadow polygon
    final shadowPath = Path()
      ..moveTo(b1.dx, b1.dy)
      ..lineTo(t1.dx, t1.dy)
      ..lineTo(tipPt.dx, tipPt.dy)
      ..lineTo(t2.dx, t2.dy)
      ..lineTo(b2.dx, b2.dy)
      ..close();

    final shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                Colors.deepOrange.withValues(alpha: 0.92 * combinedAlpha),
                Colors.orange.shade700.withValues(alpha: 0.70 * combinedAlpha),
              ]
            : [
                Colors.brown.shade900.withValues(alpha: 0.70 * combinedAlpha),
                Colors.brown.shade700.withValues(alpha: 0.25 * combinedAlpha),
              ],
      ).createShader(Rect.fromPoints(originPt, tipPt))
      ..style = PaintingStyle.fill;

    canvas.drawPath(shadowPath, shadowPaint);

    // In dark mode, draw a bright orange edge highlight for crisp visibility
    if (isDark) {
      final shadowOutline = Paint()
        ..color = Colors.orangeAccent.withValues(alpha: 0.8 * combinedAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.0 * scale).clamp(0.6, 1.0);
      canvas.drawPath(shadowPath, shadowOutline);
    }

    // Shadow tip indicator ring
    final tipPaint = Paint()
      ..color = (isDark ? Colors.amberAccent : Colors.tealAccent)
          .withValues(alpha: combinedAlpha)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(tipPt, (2.8 * scale).clamp(1.2, 3.0), tipPaint);
  }

  void _drawGnomon(Canvas canvas, Offset center, double radius) {
    final scale = (radius / 150.0).clamp(0.25, 2.0);
    final gh = _getGnomonHeight(radius);
    final basePt = _project(0.0, 0.0, 0.0, center, radius);
    final topPt = _project(0.0, 0.0, gh, center, radius);

    // Gnomon pedestal / base ring
    final pedestalPaint = Paint()
      ..color = Colors.amber.shade800
      ..style = PaintingStyle.fill;
    canvas.drawCircle(basePt, (4.5 * scale).clamp(2.0, 4.8), pedestalPaint);

    // Vertical pin (brass rod)
    final rodPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.amber.shade300, Colors.amber.shade900],
      ).createShader(Rect.fromPoints(basePt, topPt))
      ..strokeWidth = (3.2 * scale).clamp(1.5, 3.4)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(basePt, topPt, rodPaint);

    // Golden tip sphere at gnomon apex
    final tipGlow = Paint()
      ..color = Colors.amberAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(topPt, (3.5 * scale).clamp(1.6, 3.8), tipGlow);
  }

  void _drawSun(Canvas canvas, Offset center, double radius) {
    final scale = (radius / 150.0).clamp(0.25, 2.0);
    final gh = _getGnomonHeight(radius);
    final sunPt = _projectSpherical(
        sunPosition.azimuth, sunPosition.elevation, center, radius);
    final gnomonTop = _project(0.0, 0.0, gh, center, radius);
    final originPt = _project(0.0, 0.0, 0.0, center, radius);

    // If sun is above horizon, draw a luminous volumetric beam of light hitting the stick
    if (sunPosition.elevation > 0.0) {
      final sunriseFade = (sunPosition.elevation / 4.0).clamp(0.25, 1.0);
      final gnomonMid = Offset(
        (gnomonTop.dx + originPt.dx) * 0.5,
        (gnomonTop.dy + originPt.dy) * 0.5,
      );

      // 1. Volumetric shaft of sunlight covering the full stick from top to base
      // Triangle (sunPt -> gnomonTop -> originPt) is always strictly convex and never self-intersects
      final beamPath = Path()
        ..moveTo(sunPt.dx, sunPt.dy)
        ..lineTo(gnomonTop.dx, gnomonTop.dy)
        ..lineTo(originPt.dx, originPt.dy)
        ..close();

      final beamPaint = Paint()
        ..shader = ui.Gradient.linear(
          sunPt,
          gnomonMid,
          isDark
              ? [
                  Colors.amber.withValues(alpha: 0.45 * sunriseFade),
                  Colors.amberAccent.withValues(alpha: 0.25 * sunriseFade),
                  Colors.amber.withValues(alpha: 0.10 * sunriseFade),
                ]
              : [
                  Colors.amber.withValues(alpha: 0.38 * sunriseFade),
                  Colors.amberAccent.withValues(alpha: 0.20 * sunriseFade),
                  Colors.yellow.withValues(alpha: 0.06 * sunriseFade),
                ],
          const [0.0, 0.55, 1.0],
        )
        ..style = PaintingStyle.fill;
      canvas.drawPath(beamPath, beamPaint);

      // 2. Line 1: Solid glowing ray of sunlight to the TOP of the pole (gnomonTop)
      final topBeamGlow = Paint()
        ..shader = ui.Gradient.linear(
          sunPt,
          gnomonTop,
          isDark
              ? [
                  Colors.amberAccent.withValues(alpha: 0.70 * sunriseFade),
                  Colors.amber.withValues(alpha: 0.30 * sunriseFade),
                ]
              : [
                  Colors.amber.withValues(alpha: 0.65 * sunriseFade),
                  Colors.amber.shade700.withValues(alpha: 0.30 * sunriseFade),
                ],
        )
        ..strokeWidth = (3.8 * scale).clamp(1.6, 4.0)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(sunPt, gnomonTop, topBeamGlow);

      final topBeamLine = Paint()
        ..shader = ui.Gradient.linear(
          sunPt,
          gnomonTop,
          isDark
              ? [
                  Colors.white.withValues(alpha: 0.95 * sunriseFade),
                  Colors.amber.shade200.withValues(alpha: 0.65 * sunriseFade),
                ]
              : [
                  Colors.amber.shade100.withValues(alpha: 0.95 * sunriseFade),
                  Colors.amber.shade600.withValues(alpha: 0.60 * sunriseFade),
                ],
        )
        ..strokeWidth = (1.6 * scale).clamp(0.8, 1.8)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(sunPt, gnomonTop, topBeamLine);

      // 3. Line 2: Solid glowing ray of sunlight to the BASE of the pole (originPt)
      final baseBeamGlow = Paint()
        ..shader = ui.Gradient.linear(
          sunPt,
          originPt,
          isDark
              ? [
                  Colors.amberAccent.withValues(alpha: 0.70 * sunriseFade),
                  Colors.amber.withValues(alpha: 0.30 * sunriseFade),
                ]
              : [
                  Colors.amber.withValues(alpha: 0.65 * sunriseFade),
                  Colors.amber.shade700.withValues(alpha: 0.30 * sunriseFade),
                ],
        )
        ..strokeWidth = (3.8 * scale).clamp(1.6, 4.0)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(sunPt, originPt, baseBeamGlow);

      final baseBeamLine = Paint()
        ..shader = ui.Gradient.linear(
          sunPt,
          originPt,
          isDark
              ? [
                  Colors.white.withValues(alpha: 0.95 * sunriseFade),
                  Colors.amber.shade200.withValues(alpha: 0.65 * sunriseFade),
                ]
              : [
                  Colors.amber.shade100.withValues(alpha: 0.95 * sunriseFade),
                  Colors.amber.shade600.withValues(alpha: 0.60 * sunriseFade),
                ],
        )
        ..strokeWidth = (1.6 * scale).clamp(0.8, 1.8)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(sunPt, originPt, baseBeamLine);

      // 4. Optical ray passing from gnomon apex to shadow tip on ground
      if (sunPosition.elevation > 4.0) {
        final atmosphereFade =
            ((sunPosition.elevation - 4.0) / 4.0).clamp(0.0, 1.0);
        final shadowAz = sunPosition.shadowAzimuth;
        final shadowAzRad = shadowAz * (math.pi / 180.0);
        final elRad = math.max(sunPosition.elevation, 1.0) * (math.pi / 180.0);
        final rawLength = gh / math.tan(elRad);
        final displayLength = rawLength.clamp(2.0, radius * 0.94);
        final tipX = displayLength * math.sin(shadowAzRad);
        final tipY = displayLength * math.cos(shadowAzRad);
        final tipPt = _project(tipX, tipY, 0.0, center, radius);

        final shadowRayPaint = Paint()
          ..color = (isDark ? Colors.amberAccent : Colors.amber)
              .withValues(alpha: 0.35 * atmosphereFade)
          ..strokeWidth = (1.3 * scale).clamp(0.7, 1.5)
          ..style = PaintingStyle.stroke;
        canvas.drawLine(gnomonTop, tipPt, shadowRayPaint);
      }

      // 5. Glint / flare at the gnomon apex where Line 1 strikes the tip
      final haloRadius = (9.0 * scale).clamp(3.5, 9.0);
      final tipFlareHalo = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.amberAccent.withValues(alpha: 0.85 * sunriseFade),
            Colors.amber.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: gnomonTop, radius: haloRadius));
      canvas.drawCircle(gnomonTop, haloRadius, tipFlareHalo);

      final tipFlareCore = Paint()
        ..color = Colors.white.withValues(alpha: sunriseFade)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(gnomonTop, (2.8 * scale).clamp(1.2, 3.0), tipFlareCore);

      // 6. Highlight glint where Line 2 strikes the base of the gnomon on the ground disc
      final baseGlint = Paint()
        ..color = (isDark ? Colors.amberAccent : Colors.amber)
            .withValues(alpha: 0.75 * sunriseFade)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(originPt, (2.4 * scale).clamp(1.0, 2.5), baseGlint);
    } else {
      // Sun is below horizon (night/twilight):
      // Draw subtle connecting ray from ground center to the sun underneath
      final nightRayPaint = Paint()
        ..color = Colors.indigoAccent.withValues(alpha: 0.3)
        ..strokeWidth = (1.0 * scale).clamp(0.6, 1.2)
        ..style = PaintingStyle.stroke;
      canvas.drawLine(originPt, sunPt, nightRayPaint);
    }

    // ── Solar Corona (Ethereal Multi-Layered Atmosphere & Radiant Streamers) ──
    if (sunPosition.isDay) {
      // 1. Broad outer diffuse coronal aura
      final outerCoronaR = (42.0 * scale).clamp(14.0, 42.0);
      final outerCoronaPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.amber.shade200.withValues(alpha: 0.38),
            Colors.amber.withValues(alpha: 0.22),
            Colors.orange.withValues(alpha: 0.08),
            Colors.orange.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.38, 0.72, 1.0],
        ).createShader(Rect.fromCircle(center: sunPt, radius: outerCoronaR));
      canvas.drawCircle(sunPt, outerCoronaR, outerCoronaPaint);

      // 2. Mid-layer vibrant coronal glow
      final midCoronaR = (24.0 * scale).clamp(8.0, 24.0);
      final midCoronaPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.70),
            Colors.amberAccent.withValues(alpha: 0.50),
            Colors.amber.withValues(alpha: 0.18),
            Colors.amber.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.35, 0.70, 1.0],
        ).createShader(Rect.fromCircle(center: sunPt, radius: midCoronaR));
      canvas.drawCircle(sunPt, midCoronaR, midCoronaPaint);

      // 3. Radiant Coronal Streamers / Rays (12 radiating spicules & flares)
      const int numRays = 12;
      final rayPaint = Paint()
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < numRays; i++) {
        final angle = (i * 2.0 * math.pi) / numRays;
        final isMajor = i % 3 == 0;
        final isCardinal = i % 6 == 0;
        final innerR = (8.5 * scale).clamp(3.0, 8.5);
        final outerR = (isCardinal ? 32.0 : (isMajor ? 24.0 : 17.0)) * scale;

        final p1 = Offset(
          sunPt.dx + math.cos(angle) * innerR,
          sunPt.dy + math.sin(angle) * innerR,
        );
        final p2 = Offset(
          sunPt.dx + math.cos(angle) * outerR,
          sunPt.dy + math.sin(angle) * outerR,
        );

        rayPaint
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.85),
              Colors.amberAccent.withValues(alpha: isMajor ? 0.65 : 0.40),
              Colors.orange.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(Rect.fromPoints(p1, p2))
          ..strokeWidth = (isCardinal
              ? (2.2 * scale).clamp(1.0, 2.2)
              : (isMajor
                  ? (1.6 * scale).clamp(0.8, 1.6)
                  : (1.1 * scale).clamp(0.6, 1.1)));

        canvas.drawLine(p1, p2, rayPaint);
      }

      // 4. Inner Chromosphere halo (fiery ring immediately around photosphere)
      final chromoR = (13.5 * scale).clamp(5.0, 13.5);
      final chromospherePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.amber.shade400.withValues(alpha: 0.80),
            Colors.deepOrange.withValues(alpha: 0.35),
            Colors.deepOrange.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(Rect.fromCircle(center: sunPt, radius: chromoR));
      canvas.drawCircle(sunPt, chromoR, chromospherePaint);
    } else {
      // Subterranean nocturnal aura (soft twilight glow beneath ground)
      final nightHaloR = (18.0 * scale).clamp(7.0, 18.0);
      final nightGlow = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.indigoAccent.withValues(alpha: 0.45),
            Colors.deepPurple.withValues(alpha: 0.15),
            Colors.indigo.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: sunPt, radius: nightHaloR));
      canvas.drawCircle(sunPt, nightHaloR, nightGlow);
    }

    // ── Sun Photosphere Disc (Radiant Center) ──
    final sunRadius = (sunPosition.isDay ? 10.5 : 8.5) * scale;
    final sunDiscPaint = Paint()
      ..shader = RadialGradient(
        colors: sunPosition.isDay
            ? [
                Colors.white,
                Colors.amber.shade200,
                Colors.amber.shade500,
              ]
            : [
                Colors.amber.shade300,
                Colors.deepOrangeAccent,
                Colors.deepOrange.shade800,
              ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: sunPt, radius: sunRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(sunPt, sunRadius, sunDiscPaint);

    // Brilliant white-hot core
    if (sunPosition.isDay) {
      final corePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(sunPt, (4.0 * scale).clamp(1.5, 4.0), corePaint);
    } else {
      // Subterranean glowing core
      final corePaint = Paint()
        ..color = Colors.amber.shade100
        ..style = PaintingStyle.fill;
      canvas.drawCircle(sunPt, (2.8 * scale).clamp(1.2, 3.0), corePaint);

      // Degree label next to the sub-horizon sun
      final fontSize = (10.0 * scale).clamp(6.5, 10.0);
      final tp = TextPainter(
        text: TextSpan(
          text: '${sunPosition.elevation.toStringAsFixed(1)}°',
          style: TextStyle(
            color: isDark ? Colors.amberAccent : Colors.deepOrange,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(sunPt.dx + 14.0, sunPt.dy - tp.height / 2.0));
    }
  }

  @override
  bool shouldRepaint(covariant SolarDomePainter oldDelegate) {
    return oldDelegate.pitch != pitch ||
        oldDelegate.yaw != yaw ||
        oldDelegate.sunPosition.time != sunPosition.time ||
        oldDelegate.isDark != isDark;
  }
}

/// Compact, live-ticking 3D Sun & Shadow preview widget for the Home screen.
class MiniSunShadowWidget extends StatefulWidget {
  final double size;
  final double? pitch;
  final double? yaw;

  const MiniSunShadowWidget({
    Key? key,
    this.size = 185.0,
    this.pitch,
    this.yaw,
  }) : super(key: key);

  @override
  State<MiniSunShadowWidget> createState() => _MiniSunShadowWidgetState();
}

class _MiniSunShadowWidgetState extends State<MiniSunShadowWidget> {
  Timer? _ticker;
  DateTime _currentTime = DateTime.now();
  List<SolarPosition> _dayArc = [];
  DateTime? _cachedArcDate;
  StreamSubscription<CompassEvent>? _compassSub;
  double _compassYaw = 0.0;

  // 3D Perspective constants (8° point down from horizon, matching big screen)
  static const double _dayPitch =
      82.0 * math.pi / 180.0; // ~1.431 rad (~82° pitch, 8° down from horizon)
  static const double _nightPitch =
      1.38; // ~79° side view (11° down from horizon)

  @override
  void initState() {
    super.initState();
    _refreshDayArc();
    _startCompass();
    // 1-second interval keeps shadow direction, length, and solar position live in real time
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final now = DateTime.now();
      if (_cachedArcDate == null ||
          _cachedArcDate!.day != now.day ||
          _cachedArcDate!.month != now.month) {
        _refreshDayArc();
      }
      setState(() {
        _currentTime = now;
      });
    });
  }

  void _startCompass() {
    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      final raw = event.heading ?? 0.0;
      final heading = (raw < 0) ? raw + 360.0 : raw;
      setState(() {
        _compassYaw = heading * (math.pi / 180.0);
      });
    });
  }

  void _refreshDayArc() {
    final now = DateTime.now();
    _cachedArcDate = DateTime(now.year, now.month, now.day);
    _dayArc = getDaySolarArc(_cachedArcDate!, samples: 48);
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sunPos = getSolarPositionAt(_currentTime);

    // 3D Perspective angle matching SunShadowPage screenshot:
    // Daytime: 0.72 rad (~41° overhead perspective)
    // Nighttime: 1.38 rad (~79° side view)
    final defaultPitch = sunPos.elevation <= 0.0 ? _nightPitch : _dayPitch;
    final pitch = widget.pitch ?? defaultPitch;

    // Yaw tracks phone compass heading in real-time (matching screenshot), or uses override if passed
    final yaw = widget.yaw ?? _compassYaw;

    final loc = AppLocalizations.of(context);
    final liveLabel = loc?.liveSunShadow ?? 'Live Sun and Shadow';
    final tooltipMsg =
        loc?.sunShadowTooltip ?? 'Sun & Shadow (Live) - Tap to expand';

    return Semantics(
      label: liveLabel,
      button: true,
      child: Tooltip(
        message: tooltipMsg,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SunShadowPage(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(widget.size / 2.0),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isDark ? const Color(0xFF141923) : const Color(0xFFF3F6FA),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : Colors.black26)
                        .withValues(alpha: isDark ? 0.35 : 0.12),
                    blurRadius: 8.0,
                    spreadRadius: 1.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: SolarDomePainter(
                    pitch: pitch,
                    yaw: yaw,
                    sunPosition: sunPos,
                    dayArc: _dayArc,
                    isDark: isDark,
                    primaryColor: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
