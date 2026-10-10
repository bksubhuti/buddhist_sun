import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/models/vitd_body_size_chart.dart';
import 'package:buddhist_sun/src/provider/vitamin_d_provider.dart';
import 'package:buddhist_sun/src/services/country_service.dart';
import 'package:buddhist_sun/src/services/vitamin_d_calc.dart';
import 'package:buddhist_sun/views/sun_shadow_view.dart';
import 'package:buddhist_sun/widgets/vitamin_d_painters.dart';

/// Green for good sun, goals reached, low burn and the Online tag.
const Color _vitDGreen = Color(0xFF43A047);

/// Free vitamin D sun timer for monastics: live sun angle, estimated IU,
/// per-session log and daily total, with all settings on the same scroll.
/// With [embedded] it is a bottom-nav page (no own AppBar), like MoonPage.
class VitaminDPage extends StatefulWidget {
  final bool embedded;

  const VitaminDPage({Key? key, this.embedded = false}) : super(key: key);

  @override
  State<VitaminDPage> createState() => _VitaminDPageState();
}

class _VitaminDPageState extends State<VitaminDPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final VitaminDController _c;
  Timer? _sunRefresh;
  VitDSunWindow? _window;
  DateTime _windowDay = DateTime(1970);

  bool get _hasLocation => Prefs.hasValidLocation;

  @override
  void initState() {
    super.initState();
    // The bottom-nav container tracks lastScreen for the embedded page.
    if (!widget.embedded) Prefs.lastScreen = 'vitamin_d';
    _c = VitaminDController();
    _c.addListener(_onChange);
    _updateWindow();
    // Re-check the region by IP: the saved GPS fix may be from another
    // country (travel without a new GPS reading).
    CountryService.getCountryCode().then((code) {
      if (code != null && mounted && !_c.isRunning) _c.refresh();
    });
    // Keep the sun display live when no session is running.
    _sunRefresh = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_c.isRunning) _c.refresh();
      _updateWindow();
    });
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  void _updateWindow() {
    final now = DateTime.now();
    if (_window != null &&
        now.year == _windowDay.year &&
        now.month == _windowDay.month &&
        now.day == _windowDay.day) {
      return;
    }
    _windowDay = now;
    final w = findVitDSunWindow(now);
    if (mounted) setState(() => _window = w);
  }

  @override
  void dispose() {
    _sunRefresh?.cancel();
    _c.removeListener(_onChange);
    _c.dispose();
    super.dispose();
  }

  // ── Formatting helpers ───────────────────────────────────────────────
  String _iu(double v) => NumberFormat('#,##0').format(v.round());

  String _clock(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String _time(BuildContext context, DateTime t) =>
      MaterialLocalizations.of(context)
          .formatTimeOfDay(TimeOfDay.fromDateTime(t));

  String _coverageLabel(AppLocalizations t, VitDCoverage c) {
    switch (c) {
      case VitDCoverage.fullRobe:
        return t.vitDCoverFullRobe;
      case VitDCoverage.oneShoulder:
        return t.vitDCoverOneShoulder;
      case VitDCoverage.angsa:
        return t.vitDCoverAngsa;
      case VitDCoverage.upperBare:
        return t.vitDCoverUpperBare;
      case VitDCoverage.bathingCloth:
        return t.vitDCoverBathing;
      case VitDCoverage.layFaceHands:
        return t.vitDCoverFaceHands;
      case VitDCoverage.layShortSleeves:
        return t.vitDCoverShortSleeves;
      case VitDCoverage.layShorts:
        return t.vitDCoverShorts;
      case VitDCoverage.laySwimwear:
        return t.vitDCoverSwimwear;
      default:
        return _coverageLabel(t, c.maleEquivalent);
    }
  }

  String _coverageDesc(AppLocalizations t, VitDCoverage c) {
    switch (c) {
      case VitDCoverage.fullRobe:
        return t.vitDCoverFullRobeDesc;
      case VitDCoverage.oneShoulder:
        return t.vitDCoverOneShoulderDesc;
      case VitDCoverage.angsa:
        return t.vitDCoverAngsaDesc;
      case VitDCoverage.upperBare:
        return t.vitDCoverUpperBareDesc;
      case VitDCoverage.bathingCloth:
        return t.vitDCoverBathingDesc;
      case VitDCoverage.layFaceHands:
        return t.vitDCoverFaceHandsDesc;
      case VitDCoverage.layShortSleeves:
        return t.vitDCoverShortSleevesDesc;
      case VitDCoverage.layShorts:
        return t.vitDCoverShortsDesc;
      case VitDCoverage.laySwimwear:
        return t.vitDCoverSwimwearDesc;
      default:
        return _coverageDesc(t, c.maleEquivalent);
    }
  }

  String _skyLabel(AppLocalizations t, VitDSky s) {
    switch (s) {
      case VitDSky.clear:
        return t.vitDSkyClear;
      case VitDSky.partlyCloudy:
        return t.vitDSkyPartly;
      case VitDSky.mostlyCloudy:
        return t.vitDSkyMostly;
      case VitDSky.overcast:
        return t.vitDSkyOvercast;
      case VitDSky.forecast:
        return t.vitDSkyForecast;
    }
  }

  IconData _skyIcon(VitDSky s) {
    switch (s) {
      case VitDSky.clear:
        return Icons.wb_sunny_rounded;
      case VitDSky.partlyCloudy:
        return Icons.wb_cloudy_outlined;
      case VitDSky.mostlyCloudy:
        return Icons.cloud_rounded;
      case VitDSky.overcast:
        return Icons.cloud_queue_rounded;
      case VitDSky.forecast:
        return Icons.satellite_alt_rounded;
    }
  }

  String _postureLabel(AppLocalizations t, VitDPosture p) {
    switch (p) {
      case VitDPosture.standing:
        return t.vitDPostureStanding;
      case VitDPosture.walking:
        return t.vitDPostureWalking;
      case VitDPosture.sitting:
        return t.vitDPostureSitting;
      case VitDPosture.lying:
        return t.vitDPostureLying;
    }
  }

  IconData _postureIcon(VitDPosture p) {
    switch (p) {
      case VitDPosture.standing:
        return Icons.accessibility_new_rounded;
      case VitDPosture.walking:
        return Icons.directions_walk_rounded;
      case VitDPosture.sitting:
        return Icons.self_improvement;
      case VitDPosture.lying:
        return Icons.airline_seat_flat_rounded;
    }
  }

  String _skinLabel(AppLocalizations t, VitDSkinType s) {
    switch (s) {
      case VitDSkinType.type1:
        return t.vitDSkin1;
      case VitDSkinType.type2:
        return t.vitDSkin2;
      case VitDSkinType.type3:
        return t.vitDSkin3;
      case VitDSkinType.type4:
        return t.vitDSkin4;
      case VitDSkinType.type5:
        return t.vitDSkin5;
      case VitDSkinType.type6:
        return t.vitDSkin6;
    }
  }

  BoxDecoration _cardDecoration(ThemeData theme) => BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
      );

  // ── Build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppLocalizations.of(context)!;

    final body = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_hasLocation) ...[
              _buildNoLocationBanner(context),
              const SizedBox(height: 12),
            ],
            if (_c.isUsa) ...[
              _buildUsaBadge(context),
              const SizedBox(height: 8),
            ],
            _buildQuickBar(context),
            const SizedBox(height: 8),
            _buildUvRow(context),
            const SizedBox(height: 12),
            _buildTimerCard(context),
            const SizedBox(height: 16),
            _buildSunCard(context),
            const SizedBox(height: 16),
            _buildTodayCard(context),
            const SizedBox(height: 16),
            _buildSettingsCard(context),
            const SizedBox(height: 16),
            _buildGuidanceCard(context),
            const SizedBox(height: 12),
            _buildDisclaimer(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return Container(color: Prefs.getChosenColor(context), child: body);
    }
    return Scaffold(
      appBar: AppBar(title: Text(t.vitDTitle)),
      body: body,
    );
  }

  Widget _buildNoLocationBanner(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off_outlined,
              color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(t.vitDNoLocation,
                style: TextStyle(color: theme.colorScheme.onErrorContainer)),
          ),
        ],
      ),
    );
  }

  Widget _buildUsaBadge(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withAlpha(120),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.primary.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined,
                size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'USA: Safe Sun & UV Timer',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Live sun: key numbers first, compact angle drawing beside them.
  Widget _buildSunCard(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final primary = theme.colorScheme.primary;
    final rate = _c.rate;
    final el = rate.elevation;

    final Color statusColor;
    final IconData statusIcon;
    final String statusText;
    if (el <= 0) {
      statusColor = theme.colorScheme.outline;
      statusIcon = Icons.nightlight_round;
      statusText = t.vitDStatusNight;
    } else if (el >= vitDOptimalElevation) {
      statusColor = _vitDGreen;
      statusIcon = Icons.check_circle_rounded;
      statusText = t.vitDStatusGood;
    } else if (el > vitDMinElevation) {
      statusColor = const Color(0xFFEF6C00);
      statusIcon = Icons.trending_down_rounded;
      statusText = t.vitDStatusLow;
    } else {
      statusColor = theme.colorScheme.outline;
      statusIcon = Icons.block_rounded;
      statusText = t.vitDStatusNone;
    }

    final burn = rate.minutesToBurn;
    final w = _window;
    String windowText = '';
    if (w != null) {
      windowText = w.reaches45
          ? t.vitDWindowToday(_time(context, w.start!), _time(context, w.end!))
          : t.vitDWindowNever(
              w.peakElevation.toStringAsFixed(0), _time(context, w.peakTime));
    }

    Widget stat(String label, String value, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(label,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(170))),
              ),
              Text(value,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(statusText,
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 11,
                child: Column(
                  children: [
                    stat(t.vitDSunAngle, '${el.toStringAsFixed(1)}°',
                        color: primary),
                    stat(
                        _c.uvFromOnline
                            ? '${t.vitDUvIndexLabel} (${t.vitDUvSourceOnline})'
                            : t.vitDUvIndex,
                        rate.uvIndex.toStringAsFixed(1)),
                    if (!_c.isUsa)
                      stat(t.vitDRate,
                          t.vitDIuPerMin(rate.iuPerMinute.toStringAsFixed(0))),
                    stat(t.vitDEfficiency,
                        '${(rate.efficiency * 100).toStringAsFixed(0)}%'),
                    stat(
                      t.vitDBurnTime,
                      burn == null || burn > 600
                          ? '—'
                          : t.vitDMinutes(burn.toStringAsFixed(0)),
                      color: burn != null && burn < 30
                          ? theme.colorScheme.error
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 9,
                child: AspectRatio(
                  aspectRatio: 1.25,
                  child: CustomPaint(
                    painter: SunAnglePainter(
                      elevation: el,
                      primary: primary,
                      onSurface: theme.colorScheme.onSurface,
                      skinColor: vitDSkinColors[_c.skin.index],
                      lay: _c.coverage.isLay,
                      female: _c.coverage.isFemale,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (windowText.isNotEmpty) ...[
            const Divider(height: 18),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 16, color: primary),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(windowText, style: theme.textTheme.bodySmall)),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Text(t.vitDShadowRule,
              style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withAlpha(150))),
        ],
      ),
    );
  }

  /// Sky choices: "Forecast" only with online UV data.
  List<VitDSky> get _skies => VitDSky.values
      .where((s) => s != VitDSky.forecast || _c.uvOnline)
      .toList();

  List<VitDCoverage> get _coverChoices => _c.coverTab == 2
      ? VitDCoverageInfo.female
      : (_c.coverTab == 1 ? VitDCoverageInfo.lay : VitDCoverageInfo.monastic);

  String _uvStatusText(AppLocalizations t) {
    if (_c.uvLoading && !_c.uvFromOnline) return t.vitDUvLoading;
    if (_c.uvFromOnline) return t.vitDUvScale(_c.uvScale.toStringAsFixed(2));
    if (_c.uvError) return t.vitDUvError;
    return t.vitDUvLoading;
  }

  // 0. Quick choices that change from day to day; they set the same
  // values as the settings below.
  Widget _buildQuickBar(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    Widget dropdown<T>({
      required String label,
      required T value,
      required List<T> items,
      required Widget Function(T) icon,
      required String Function(T) text,
      required ValueChanged<T> onChanged,
      bool iconOnly = false,
    }) =>
        DropdownButtonFormField<T>(
          // Keyed by value so it follows changes made in the settings below.
          key: ValueKey('$label-$value'),
          initialValue: items.contains(value) ? value : null,
          isExpanded: true,
          isDense: true,
          // Icon-only fields show just the picture; the open menu has words.
          selectedItemBuilder: iconOnly
              ? (_) => items.map((v) => Center(child: icon(v))).toList()
              : null,
          decoration: InputDecoration(
            labelText: iconOnly ? null : label,
            isDense: true,
            filled: true,
            fillColor: theme.colorScheme.surface.withAlpha(160),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          items: items
              .map((v) => DropdownMenuItem<T>(
                    value: v,
                    child: Row(
                      children: [
                        icon(v),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(text(v),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        );

    return Row(
      children: [
        Expanded(
          child: dropdown<VitDSky>(
            label: t.vitDSkyTitle,
            value: _c.sky,
            items: _skies,
            icon: (s) => Icon(_skyIcon(s), size: 18),
            text: (s) => _skyLabel(t, s),
            onChanged: _c.setSky,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 76,
          child: dropdown<VitDPosture>(
            iconOnly: true,
            label: t.vitDPostureTitle,
            value: _c.posture,
            items: VitDPosture.values,
            icon: (p) => Icon(_postureIcon(p), size: 22),
            text: (p) => _postureLabel(t, p),
            onChanged: _c.setPosture,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 76,
          child: dropdown<VitDCoverage>(
            iconOnly: true,
            label: t.vitDCoverageTitle,
            value: _c.coverage,
            items: _coverChoices,
            icon: (c) => SizedBox(
              width: 16,
              height: 22,
              child: CustomPaint(
                painter: CoveragePainter(
                  coverage: c,
                  skinColor: vitDSkinColors[_c.skin.index],
                ),
              ),
            ),
            text: (c) => _coverageLabel(t, c.maleEquivalent),
            onChanged: _c.setCoverage,
          ),
        ),
      ],
    );
  }

  /// UV index now, and where it comes from (offline estimate or online).
  Widget _buildUvRow(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final primary = theme.colorScheme.primary;
    final uvi = _c.rate.uvIndex;
    final online = _c.uvFromOnline;
    // Green tag when online, grey when offline.
    final Color tagColor =
        online ? _vitDGreen : theme.colorScheme.outline;
    final Color uvColor = uvi >= 8
        ? theme.colorScheme.error
        : (uvi >= 6
            ? const Color(0xFFEF6C00)
            : (uvi >= 3 ? const Color(0xFFF9A825) : _vitDGreen));

    return _tapCard(
      context,
      onTap: () => _showInfo(
          context, Icons.wb_sunny_outlined, t.vitDUvInfoTitle, t.vitDUvInfo),
      child: Row(
        children: [
          Icon(Icons.wb_sunny_outlined, size: 18, color: uvColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(t.vitDUvIndexLabel, style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(width: 4),
          Icon(Icons.info_outline_rounded, size: 18, color: primary),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: tagColor.withAlpha(35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_c.uvOnline && _c.uvLoading)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.5)),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                        online ? Icons.cloud_done_outlined : Icons.cloud_off,
                        size: 12,
                        color: tagColor),
                  ),
                Text(online ? t.vitDUvSourceOnline : t.vitDUvSourceOffline,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: tagColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(uvi.toStringAsFixed(1),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: uvColor)),
        ],
      ),
    );
  }

  // 2. Timer with session IU, today's total and burn meter.
  Widget _buildTimerCard(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final primary = theme.colorScheme.primary;
    final running = _c.isRunning;
    final goal = _c.dailyGoalIu;
    final todayTarget = _c.todayTargetIu;
    final catchUp = _c.catchUp;
    final todayIu = _c.todayIu;
    final pct = _c.todayPercentOfGoal;
    final med = _c.todayMed;
    final rate = _c.rate;

    final Color burnColor = med >= 0.75
        ? theme.colorScheme.error
        : (med >= 0.5 ? const Color(0xFFEF6C00) : _vitDGreen);

    // Target: IU still needed today and the sun time to get it.
    final remaining = _c.remainingIu;
    final targetMins = _c.targetMinutes;
    final halfBurnMins = rate.medPerMinute > 0
        ? (0.5 - med).clamp(0.0, 1.0) / rate.medPerMinute
        : null;
    final String targetTimeText;
    String? targetNote;
    if (remaining <= 0) {
      targetTimeText = '✓';
      targetNote =
          catchUp && todayTarget == 0 ? t.vitDCoveredByWeek : t.vitDGoalReached;
    } else if (targetMins == null) {
      targetTimeText = '—';
      targetNote = t.vitDTargetUnreachable;
    } else {
      targetTimeText = running
          ? _clock(Duration(seconds: (targetMins * 60).round()))
          : t.vitDMinutes(formatSessionDuration(targetMins * 60));
      if (med >= 0.5) {
        targetNote = t.vitDEnoughSun;
      } else if (halfBurnMins != null && targetMins > halfBurnMins) {
        targetNote = t.vitDTargetOverBurn(halfBurnMins.floor().toString());
        if (catchUp) targetNote = '$targetNote ${t.vitDCatchUpSpread}';
      }
    }
    final firstSession = _c.todaySessions.isEmpty && !running;

    // Below 45° there is little vitamin D: block starting a new session.
    String? startBlockedLabel;
    if (rate.elevation < vitDOptimalElevation) {
      final w = _window;
      if (w == null || !w.reaches45) {
        startBlockedLabel = t.vitDStartNo45;
      } else if (DateTime.now().isBefore(w.peakTime)) {
        startBlockedLabel = t.vitDStartTooEarly(_time(context, w.start!));
      } else {
        startBlockedLabel = t.vitDStartTooLate;
      }
    }

    Widget targetCell(String label, String value, String sub) => Expanded(
          child: Column(
            children: [
              Text(label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )),
              ),
              Text(sub,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall),
            ],
          ),
        );

    final targetBlock = Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: primary.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_c.isUsa)
                targetCell(
                  'Safe Sun Dose',
                  '0.35 – 0.50 MED',
                  '${(med * 100).toStringAsFixed(0)}% reached today',
                )
              else
                targetCell(
                  catchUp ? t.vitDTodayTargetWeekly : t.vitDDailyTarget,
                  catchUp && todayTarget == 0
                      ? '✓'
                      : '${_iu(todayTarget.toDouble())} IU',
                  catchUp && todayTarget == 0
                      ? t.vitDCoveredByWeek
                      : t.vitDRemaining(_iu(remaining)),
                ),
              Container(
                  width: 1,
                  height: 56,
                  color: theme.colorScheme.outlineVariant),
              targetCell(
                running
                    ? (_c.isUsa ? 'Safe Time Left' : t.vitDTargetTimeLeft)
                    : (_c.isUsa ? 'Safe Sun Time' : t.vitDTargetTime),
                targetTimeText,
                _c.isUsa
                    ? 'Time to ½ MED'
                    : (firstSession ? t.vitDTargetTimeFull : t.vitDTargetTimeRest),
              ),
            ],
          ),
          if (targetNote != null && !_c.isUsa) ...[
            const SizedBox(height: 6),
            Text(targetNote,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: med >= 0.5 ||
                            (halfBurnMins != null &&
                                targetMins != null &&
                                targetMins > halfBurnMins)
                        ? const Color(0xFFEF6C00)
                        : null)),
          ],
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          targetBlock,
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      running ? t.vitDSessionRunning : t.vitDSessionIdle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                          color:
                              running ? primary : theme.colorScheme.onSurface,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _clock(_c.activeElapsed),
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w300,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    if (!_c.isUsa) ...[
                      Text(
                        t.vitDApproxIu(_iu(_c.activeIu)),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                            color: primary, fontWeight: FontWeight.bold),
                      ),
                      Text(t.vitDThisSession,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall),
                    ] else ...[
                      Text(
                        '${(_c.activeMed * 100).toStringAsFixed(0)}% MED',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                            color: primary, fontWeight: FontWeight.bold),
                      ),
                      const Text('Sunburn dose progress',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Live sun & shadow view (tap opens the full Sun & Shadow page)
              const MiniSunShadowWidget(size: 132),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            // Start only when the sun is at or above 45°; Stop always works.
            onPressed: running
                ? () => _c.stop()
                : (startBlockedLabel == null ? () => _c.start() : null),
            icon: Icon(
                running
                    ? Icons.stop_rounded
                    : (startBlockedLabel == null
                        ? Icons.play_arrow_rounded
                        : Icons.schedule_rounded),
                size: 32),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  running ? t.vitDStop : (startBlockedLabel ?? t.vitDStart),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: running ? theme.colorScheme.error : null,
              foregroundColor: running ? theme.colorScheme.onError : null,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
          ),
          const Divider(height: 28),
          if (!_c.isUsa) ...[
            // Today total vs need — tap anywhere for an explanation
            _tapCard(
              context,
              onTap: () => _showInfo(
                  context,
                  Icons.wb_sunny_outlined,
                  t.vitDTodayInfoTitle,
                  t.vitDTodayInfo(_iu(todayTarget.toDouble()))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(t.vitDToday,
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.info_outline_rounded,
                                size: 18, color: primary),
                          ],
                        ),
                      ),
                      Text(
                          '${t.vitDApproxIu(_iu(todayIu))}  •  ${pct.toStringAsFixed(0)}%',
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold, color: primary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (pct / 100).clamp(0.0, 1.0),
                      minHeight: 10,
                      // Green = done, primary (purple) = still to go.
                      color: _vitDGreen,
                      backgroundColor: primary.withAlpha(70),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                      catchUp
                          ? t.vitDOfTodayTarget(_iu(todayTarget.toDouble()))
                          : t.vitDOfDailyNeed(_iu(goal.toDouble())),
                      style: theme.textTheme.bodySmall),
                  if (running && med >= vitDSaturationStart && remaining > 0) ...[
                    const SizedBox(height: 4),
                    Text(t.vitDTaperNote,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildWeekCard(context),
            const SizedBox(height: 10),
          ],
          // Sunburn meter — tap anywhere for an explanation
          _tapCard(
            context,
            onTap: () => _showInfo(
                context,
                Icons.local_fire_department_outlined,
                t.vitDBurnInfoTitle,
                t.vitDBurnInfo),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(t.vitDBurnDose,
                                style: theme.textTheme.bodyMedium),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.info_outline_rounded,
                              size: 18, color: primary),
                        ],
                      ),
                    ),
                    Text('${(med * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold, color: burnColor)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: med.clamp(0.0, 1.0),
                    minHeight: 8,
                    color: burnColor,
                    backgroundColor: burnColor.withAlpha(40),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  med >= 0.75
                      ? t.vitDBurnWarnHigh
                      : (med >= 0.5 ? t.vitDBurnWarnMid : t.vitDBurnHint),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: med >= 0.5 ? burnColor : null,
                      fontWeight: med >= 0.5 ? FontWeight.w600 : null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Each session is saved; the day total sums them.
  Widget _buildTodayCard(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final sessions = _c.todaySessions;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.vitDTodaySessions,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(t.vitDNoSessions, style: theme.textTheme.bodySmall),
            )
          else
            ...sessions.map((s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: SizedBox(
                    width: 30,
                    height: 40,
                    child: CustomPaint(
                      painter: CoveragePainter(
                        coverage: s.coverage,
                        skinColor: vitDSkinColors[s.skin.index],
                      ),
                    ),
                  ),
                  title: Text(
                    '${_time(context, s.start)} – ${_time(context, s.end)}  •  ${t.vitDMinutes(formatSessionDuration(s.seconds))}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Row(
                    children: [
                      Icon(_skyIcon(s.sky), size: 14),
                      const SizedBox(width: 2),
                      Icon(_postureIcon(s.posture), size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${_skyLabel(t, s.sky)} • ${_coverageLabel(t, s.coverage.maleEquivalent)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_c.isUsa)
                        Text(t.vitDApproxIu(_iu(s.iu)),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary))
                      else
                        Text('${(s.med * 100).toStringAsFixed(0)}% MED',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: t.vitDDeleteSession,
                        onPressed: () => _confirmDelete(context, s),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  /// Rolling 7-day total: a sunny day covers cloudy ones (each day
  /// credited up to 3 days' worth).
  Widget _buildWeekCard(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final primary = theme.colorScheme.primary;
    const green = _vitDGreen;
    final daily = _c.dailyGoalIu.toDouble();
    final totals = _c.weekDayTotals;
    final counted = _c.weekDaysCounted;
    final pct = _c.weekPercent;
    final shortfall = _c.weekShortfall;
    final locale = Localizations.localeOf(context).toString();
    final today = DateTime.now();

    final bars = List<Widget>.generate(VitaminDController.weekDays, (i) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: VitaminDController.weekDays - 1 - i));
      final active = i >= VitaminDController.weekDays - counted;
      final isToday = i == VitaminDController.weekDays - 1;
      final frac = daily > 0 ? (totals[i] / daily).clamp(0.0, 1.0) : 0.0;
      final done = totals[i] >= daily;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            children: [
              Container(
                height: 34,
                alignment: Alignment.bottomCenter,
                decoration: BoxDecoration(
                  color: active
                      ? primary.withAlpha(45)
                      : theme.colorScheme.outlineVariant.withAlpha(60),
                  borderRadius: BorderRadius.circular(5),
                  border:
                      isToday ? Border.all(color: primary, width: 1.5) : null,
                ),
                child: FractionallySizedBox(
                  heightFactor: frac,
                  widthFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: done ? green : green.withAlpha(150),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  DateFormat.E(locale).format(day),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: isToday ? FontWeight.bold : null,
                    color: active ? null : theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });

    return _tapCard(
      context,
      onTap: () => _showInfo(context, Icons.date_range_rounded,
          t.vitDWeekInfoTitle, t.vitDWeekInfo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(t.vitDWeek,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.info_outline_rounded, size: 18, color: primary),
                  ],
                ),
              ),
              Flexible(
                child: Text(
                  '${t.vitDApproxIu(_iu(_c.weekTotal))} / ${_iu(_c.weekTarget.toDouble())} IU  •  ${pct.toStringAsFixed(0)}%',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold, color: primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: bars),
          const SizedBox(height: 6),
          Text(
            '${t.vitDWeekAvg(_iu(_c.weekTotal / counted))}  •  ${shortfall > 0 ? t.vitDWeekBehind(_iu(shortfall)) : t.vitDWeekAhead(_iu(-shortfall))}',
            style: theme.textTheme.bodySmall,
          ),
          if (counted == VitaminDController.weekDays && pct < 50) ...[
            const SizedBox(height: 4),
            Text(t.vitDLowWeek,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFEF6C00),
                    fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  /// A small tappable card inside the timer card.
  Widget _tapCard(BuildContext context,
      {required VoidCallback onTap, required Widget child}) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withAlpha(140),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: child,
        ),
      ),
    );
  }

  void _showInfo(
      BuildContext context, IconData icon, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(icon),
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, VitDSession s) async {
    final t = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.vitDDeleteSession),
        content: Text(t.vitDDeleteConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(MaterialLocalizations.of(ctx).deleteButtonTooltip)),
        ],
      ),
    );
    if (ok == true) _c.deleteSession(s);
  }

  Widget _buildBodySizeChart(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final head = theme.textTheme.labelSmall
        ?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary);
    final body = theme.textTheme.bodySmall
        ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    Widget cell(String s, TextStyle? style) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Text(s, textAlign: TextAlign.center, style: style),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Table(
          border: TableBorder(
              horizontalInside:
                  BorderSide(color: theme.colorScheme.outlineVariant)),
          children: [
            TableRow(children: [
              cell(t.vitDBodySizeWeight, head),
              cell(t.vitDBodySizeRate, head),
              cell(t.vitDBodySizeNeed, head),
              cell(t.vitDBodySizeTime, head),
            ]),
            for (final r in vitDBodySizeChart)
              TableRow(
                decoration: r.$1 == 68
                    ? BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withAlpha(90))
                    : null,
                children: [
                  cell('${r.$1} kg\n${r.$2} lb', body),
                  cell(r.$3, body),
                  cell('${_iu(r.$4.toDouble())} IU', body),
                  cell(r.$5, body),
                ],
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(t.vitDBodySizeNote,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4)),
      ],
    );
  }

  // 4. Settings: skin, robe coverage, sky, body size chart — same scroll view.
  Widget _buildSettingsCard(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final primary = theme.colorScheme.primary;

    Widget sectionTitle(String text, [String? sub]) => Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              if (sub != null) Text(sub, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );

    Widget selectable({
      required bool selected,
      required VoidCallback onTap,
      required Widget child,
    }) =>
        Material(
          color: selected
              ? primary.withAlpha(40)
              : theme.colorScheme.surface.withAlpha(160),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? primary : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: child,
          ),
        );

    // Skin tone grid
    final skinGrid = GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.3,
      children: VitDSkinType.values.map((s) {
        return selectable(
          selected: _c.skin == s,
          onTap: () => _c.setSkin(s),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: vitDSkinColors[s.index],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withAlpha(40)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.vitDSkinType(s.number),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(_skinLabel(t, s),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );

    // Robe coverage grid with monk pictures
    final coverGrid = GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.78,
      children: (_c.coverTab == 2
              ? VitDCoverageInfo.female
              : (_c.coverTab == 1
                  ? VitDCoverageInfo.lay
                  : VitDCoverageInfo.monastic))
          .map((c) {
        return selectable(
          selected: _c.coverage == c,
          onTap: () => _c.setCoverage(c),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: CoveragePainter(
                      coverage: c,
                      skinColor: vitDSkinColors[_c.skin.index],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(_coverageLabel(t, c.maleEquivalent),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  '${(c == VitDCoverage.femaleSwimwear ? t.vitDCoverSwimwearFemaleDesc : _coverageDesc(t, c.maleEquivalent))} • ${(exposedFractionFor(c, _c.hairDays) * 100).round()}%',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: Icon(Icons.tune_rounded, color: primary),
          title: Text(t.vitDSettings,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sectionTitle(t.vitDSkinTitle, t.vitDSkinSubtitle),
            skinGrid,
            sectionTitle(t.vitDCoverageTitle, t.vitDCoverageSubtitle),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 0, label: Text(t.vitDTabMonk)),
                ButtonSegment(value: 1, label: Text(t.vitDTabLay)),
                ButtonSegment(value: 2, label: Text(t.vitDTabLayFemale)),
              ],
              selected: {_c.coverTab},
              onSelectionChanged: (v) => _c.setCoverTab(v.first),
            ),
            const SizedBox(height: 10),
            coverGrid,
            if (_c.coverTab == 0) ...[
              sectionTitle(t.vitDHairTitle, t.vitDHairSubtitle),
              Slider(
                value: _c.hairDays.toDouble(),
                min: 0,
                max: vitDMaxHairDays.toDouble(),
                divisions: vitDMaxHairDays,
                label: '${_c.hairDays}',
                onChanged: (v) => _c.setHairDays(v.round()),
              ),
              Text(
                _c.hairDays == 0
                    ? t.vitDHairToday
                    : t.vitDHairValue(_c.hairDays,
                        (scalpExposure(_c.hairDays) * 100).round()),
                style: theme.textTheme.bodySmall,
              ),
            ],
            sectionTitle(t.vitDPostureTitle, t.vitDPostureSubtitle),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: VitDPosture.values
                  .map((p) => ChoiceChip(
                        avatar: Icon(_postureIcon(p), size: 18),
                        label: Text(_postureLabel(t, p)),
                        selected: _c.posture == p,
                        onSelected: (_) => _c.setPosture(p),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 6),
            Text(
              t.vitDPostureFactor(postureFactor(_c.posture, _c.rate.elevation)
                  .toStringAsFixed(1)),
              style: theme.textTheme.bodySmall,
            ),
            sectionTitle(t.vitDSkyTitle),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skies
                  .map((s) => ChoiceChip(
                        avatar: Icon(_skyIcon(s), size: 18),
                        label: Text(_skyLabel(t, s)),
                        selected: _c.sky == s,
                        onSelected: (_) => _c.setSky(s),
                      ))
                  .toList(),
            ),
            if (_c.uvOnline) ...[
              const SizedBox(height: 6),
              Text(t.vitDSkyForecastHint, style: theme.textTheme.bodySmall),
            ],
            sectionTitle(t.vitDUvSourceTitle),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(
                  _c.uvOnline ? Icons.cloud_done_outlined : Icons.cloud_off,
                  color: primary),
              title: Text(t.vitDUvOnline, style: const TextStyle(fontSize: 14)),
              subtitle: Text(t.vitDUvOnlineDesc,
                  style: const TextStyle(fontSize: 12)),
              value: _c.uvOnline,
              onChanged: _hasLocation ? (v) => _c.setUvOnline(v) : null,
            ),
            if (_c.uvOnline) ...[
              Text(_uvStatusText(t), style: theme.textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(t.vitDUvAttribution,
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurface.withAlpha(150))),
            ],
            if (!_c.isUsa) ...[
              sectionTitle(t.vitDBodySizeTitle, t.vitDBodySizeSubtitle),
              _buildBodySizeChart(context),
              sectionTitle(t.vitDTargetTitle),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title:
                    Text(t.vitDTargetAuto, style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                    t.vitDGoalStandard(_iu(_c.autoGoalIu.toDouble())),
                    style: const TextStyle(fontSize: 12)),
                value: !_c.isCustomTarget,
                onChanged: (auto) => _c.setCustomTarget(auto ? 0 : _c.autoGoalIu),
              ),
              if (_c.isCustomTarget)
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _c.dailyGoalIu.toDouble().clamp(200, 5000),
                        min: 200,
                        max: 5000,
                        divisions: 48,
                        label: '${_c.dailyGoalIu} IU',
                        onChanged: (v) =>
                            _c.setCustomTarget((v / 100).round() * 100),
                      ),
                    ),
                    SizedBox(
                      width: 92,
                      child: Text('${_iu(_c.dailyGoalIu.toDouble())} IU',
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.vitDCatchUpTitle,
                    style: const TextStyle(fontSize: 14)),
                subtitle:
                    Text(t.vitDCatchUpDesc, style: const TextStyle(fontSize: 12)),
                value: _c.catchUp,
                onChanged: (v) => _c.setCatchUp(v),
              ),
            ],
            if (kDebugMode) ...[
              const Divider(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Debug: Force USA Mode',
                    style: TextStyle(fontSize: 14)),
                subtitle: Text(
                    'Simulate USA mode (isUsaLocation: ${_c.isUsa})',
                    style: const TextStyle(fontSize: 12)),
                value: Prefs.vitDDebugForceUsa,
                onChanged: (v) {
                  setState(() {
                    Prefs.vitDDebugForceUsa = v;
                    _c.refresh();
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 5. Benefits, short vs long sessions, dangers, method.
  Widget _buildGuidanceCard(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final primary = theme.colorScheme.primary;

    Widget section(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(body,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4)),
            ],
          ),
        );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(Icons.menu_book_rounded, color: primary),
          title: Text(t.vitDGuideTitle,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            section(Icons.favorite_rounded, t.vitDGuideBenefitsTitle,
                t.vitDGuideBenefits),
            section(Icons.airline_seat_flat_rounded, t.vitDGuideBestTitle,
                t.vitDGuideBest),
            section(Icons.local_fire_department_outlined, t.vitDGuideBurnTitle,
                t.vitDGuideBurn),
            section(
                Icons.timer_outlined, t.vitDGuideNoonTitle, t.vitDGuideNoon),
            section(Icons.straighten_rounded, t.vitDGuideShortTitle,
                t.vitDGuideShort),
            section(Icons.warning_amber_rounded, t.vitDGuideDangersTitle,
                t.vitDGuideDangers),
            section(Icons.self_improvement, t.vitDGuideMonksTitle,
                t.vitDGuideMonks),
            section(Icons.calculate_outlined, t.vitDGuideMethodTitle,
                '${t.vitDGuideMethod}\n\n${t.vitDGuideMethod2}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimer(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.medical_information_outlined,
                  size: 20, color: theme.colorScheme.outline),
              const SizedBox(width: 10),
              Expanded(
                child: Text(t.vitDDisclaimer,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4)),
              ),
            ],
          ),
          if (_c.isUsa) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined,
                    size: 20, color: theme.colorScheme.outline),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Regional notice: in the United States this tool works only as a UV and safe sun exposure timer. Vitamin D (IU) estimates are not available in this region. Target: 0.35 – 0.50 MED.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.outline),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
