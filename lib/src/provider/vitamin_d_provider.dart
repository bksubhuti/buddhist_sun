import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:vibration/vibration.dart';

import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/solar_calc.dart';
import 'package:buddhist_sun/src/services/vitamin_d_calc.dart';

/// One completed sun session.
class VitDSession {
  final DateTime start;
  final DateTime end;
  final double seconds;
  final double iu;
  final double med;
  final VitDCoverage coverage;
  final VitDSky sky;
  final VitDSkinType skin;
  final VitDPosture posture;
  final int hairDays;

  const VitDSession({
    required this.start,
    required this.end,
    required this.seconds,
    required this.iu,
    required this.med,
    required this.coverage,
    required this.sky,
    required this.skin,
    this.posture = VitDPosture.standing,
    this.hairDays = 0,
  });

  Map<String, dynamic> toJson() => {
        'start': start.millisecondsSinceEpoch,
        'end': end.millisecondsSinceEpoch,
        'seconds': seconds,
        'iu': iu,
        'med': med,
        'coverage': coverage.index,
        'sky': sky.index,
        'skin': skin.index,
        'posture': posture.index,
        'hairDays': hairDays,
      };

  factory VitDSession.fromJson(Map<String, dynamic> j) => VitDSession(
        start: DateTime.fromMillisecondsSinceEpoch(j['start'] as int),
        end: DateTime.fromMillisecondsSinceEpoch(j['end'] as int),
        seconds: (j['seconds'] as num).toDouble(),
        iu: (j['iu'] as num).toDouble(),
        med: (j['med'] as num).toDouble(),
        coverage: VitDCoverage.values[(j['coverage'] as int)
            .clamp(0, VitDCoverage.values.length - 1)],
        sky: VitDSky.values[(j['sky'] as int).clamp(0, VitDSky.values.length - 1)],
        skin: VitDSkinType.values[
            (j['skin'] as int).clamp(0, VitDSkinType.values.length - 1)],
        posture: VitDPosture.values[((j['posture'] as int?) ?? 0)
            .clamp(0, VitDPosture.values.length - 1)],
        hairDays: (j['hairDays'] as int?) ?? 0,
      );
}

/// Drives the vitamin D sun timer. State is persisted to [Prefs] on every
/// tick so a session survives leaving the page or the app being suspended;
/// missed time is integrated on return using the sun's actual path.
class VitaminDController extends ChangeNotifier with WidgetsBindingObserver {
  /// Rolling window length in days (today + previous days).
  static const int weekDays = 7;

  /// One day can be credited with at most this many days' worth.
  static const int maxCreditDays = 3;

  /// Sessions older than this are pruned from storage.
  static const int keepDays = 30;

  /// Missed time longer than this is not credited (phone left on a table).
  static const Duration maxCatchUp = Duration(hours: 4);

  /// Returns sun elevation for a moment; overridable for tests.
  final double Function(DateTime) elevationAt;
  final DateTime Function() now;

  VitDSkinType _skin = VitDSkinType.values[Prefs.vitDSkinType
      .clamp(0, VitDSkinType.values.length - 1)];
  VitDCoverage _coverage = VitDCoverage.values[Prefs.vitDCoverage
      .clamp(0, VitDCoverage.values.length - 1)];
  VitDSky _sky =
      VitDSky.values[Prefs.vitDSky.clamp(0, VitDSky.values.length - 1)];
  double _weightKg = Prefs.vitDWeightKg;
  VitDPosture _posture = VitDPosture.values[
      Prefs.vitDPosture.clamp(0, VitDPosture.values.length - 1)];
  late DateTime _shaveDate;
  late DateTime _firstUse;
  late int _coverTab;
  int _customTarget = Prefs.vitDCustomTarget;

  /// Vibrate when the target or half a burn dose is reached.
  final bool alerts;
  bool _targetAlerted = false;
  bool _burnAlerted = false;

  double? _targetMinutes;
  DateTime? _targetAt;
  bool _targetDirty = true;

  List<VitDSession> _sessions = [];
  Timer? _ticker;

  DateTime? _activeStart;
  DateTime? _lastTick;
  double _activeIu = 0;
  double _activeMed = 0;
  double _activeSeconds = 0;

  VitDRate? _rate;

  VitaminDController({
    double Function(DateTime)? elevationAt,
    DateTime Function()? now,
    this.alerts = true,
  })  : elevationAt =
            elevationAt ?? ((t) => getSolarPositionAt(t).elevation),
        now = now ?? DateTime.now {
    _loadSessions();
    _loadShaveDate();
    _loadFirstUse();
    _coverTab = Prefs.vitDCoverTab ??
        (_coverage.isFemale ? 2 : (_coverage.isLay ? 1 : 0));
    _rememberCoverage(_coverage);
    final startMs = Prefs.vitDActiveStart;
    if (startMs > 0) {
      _activeStart = DateTime.fromMillisecondsSinceEpoch(startMs);
      _lastTick = DateTime.fromMillisecondsSinceEpoch(
          Prefs.vitDActiveLastTick > 0 ? Prefs.vitDActiveLastTick : startMs);
      _activeIu = Prefs.vitDActiveIu;
      _activeMed = Prefs.vitDActiveMed;
      _activeSeconds = Prefs.vitDActiveSeconds;
      _catchUp();
      _startTicker();
    }
    _refreshRate();
    WidgetsBinding.instance.addObserver(this);
  }

  // ── Getters ──────────────────────────────────────────────────────────
  VitDSkinType get skin => _skin;
  VitDCoverage get coverage => _coverage;
  VitDSky get sky => _sky;
  double get weightKg => _weightKg;
  bool get isRunning => _activeStart != null;
  DateTime? get activeStart => _activeStart;
  double get activeIu => _activeIu;
  double get activeMed => _activeMed;
  Duration get activeElapsed =>
      Duration(milliseconds: (_activeSeconds * 1000).round());
  VitDRate get rate => _rate ?? _computeRate(now());
  VitDPosture get posture => _posture;
  /// Days since the head was shaved, counting up automatically each day.
  int get hairDays {
    final today = _midnight(now());
    final days = (today.difference(_shaveDate).inHours / 24).round();
    return days.clamp(0, vitDMaxHairDays);
  }

  DateTime get shaveDate => _shaveDate;

  /// Coverage tab: 0 = monk, 1 = lay man, 2 = lay woman.
  int get coverTab => _coverTab;

  /// Daily target: custom if set, otherwise from weight.
  int get dailyGoalIu => _customTarget > 0 ? _customTarget : autoGoalIu;
  int get autoGoalIu => suggestedDailyIu(_weightKg);
  bool get isCustomTarget => _customTarget > 0;

  bool get catchUp => Prefs.vitDCatchUp;

  // ── Rolling 7-day window ─────────────────────────────────────────────
  /// Days of the window that count (prorated for new users), 1..7.
  int get weekDaysCounted {
    final days = _midnight(now()).difference(_firstUse).inHours ~/ 24 + 1;
    return days.clamp(1, weekDays);
  }

  /// Raw IU per day for the last 7 days, oldest first; today is last
  /// and includes a running session.
  List<double> get weekDayTotals {
    final today = _midnight(now());
    final totals = List<double>.filled(weekDays, 0);
    for (final s in _sessions) {
      final d = today.difference(_midnight(s.start)).inHours ~/ 24;
      if (d >= 0 && d < weekDays) totals[weekDays - 1 - d] += s.iu;
    }
    totals[weekDays - 1] += _activeIu;
    return totals;
  }

  double _credit(double iu) =>
      iu.clamp(0.0, (dailyGoalIu * maxCreditDays).toDouble()).toDouble();

  /// Credited IU in the counted part of the window (each day capped).
  double get weekTotal {
    final totals = weekDayTotals;
    final counted = weekDaysCounted;
    double sum = 0;
    for (int i = weekDays - counted; i < weekDays; i++) {
      sum += _credit(totals[i]);
    }
    return sum;
  }

  int get weekTarget => dailyGoalIu * weekDaysCounted;

  double get weekPercent => weekTotal / weekTarget * 100.0;

  /// Positive when behind for the week, negative when ahead.
  double get weekShortfall => weekTarget - weekTotal;

  /// Today's target: the plain daily target, or with catch-up on, what
  /// the week still needs (0 when covered), at most [maxCreditDays] days.
  int get todayTargetIu {
    if (!catchUp) return dailyGoalIu;
    final totals = weekDayTotals;
    final counted = weekDaysCounted;
    double previous = 0;
    for (int i = weekDays - counted; i < weekDays - 1; i++) {
      previous += _credit(totals[i]);
    }
    final need = weekTarget - previous;
    return need.clamp(0.0, (dailyGoalIu * maxCreditDays).toDouble()).round();
  }

  double get remainingIu =>
      (todayTargetIu - todayIu).clamp(0.0, double.infinity).toDouble();

  /// Minutes of sun still needed today to reach the target under current
  /// settings, following the sun's path. For the first session this is the
  /// whole time; afterwards it is the remainder. 0 when reached, null when
  /// not reachable (sun too low/setting, or saturation first).
  double? get targetMinutes {
    if (remainingIu <= 0) return 0;
    final t = now();
    if (_targetDirty ||
        _targetAt == null ||
        t.difference(_targetAt!).inSeconds >= 20) {
      _targetMinutes = minutesToProduce(
        targetIu: remainingIu,
        start: t,
        medSoFar: todayMed,
        rateAt: _computeRate,
      );
      _targetAt = t;
      _targetDirty = false;
      return _targetMinutes;
    }
    if (_targetMinutes == null) return null;
    if (!isRunning) return _targetMinutes;
    final since = t.difference(_targetAt!).inMilliseconds / 60000.0;
    return (_targetMinutes! - since).clamp(0.0, double.infinity).toDouble();
  }

  /// Today's completed sessions, newest first.
  List<VitDSession> get todaySessions {
    final today = _dayKey(now());
    return _sessions.where((s) => _dayKey(s.start) == today).toList()
      ..sort((a, b) => b.start.compareTo(a.start));
  }

  double get todayIu =>
      todaySessions.fold<double>(0, (sum, s) => sum + s.iu) + _activeIu;

  double get todayMed =>
      todaySessions.fold<double>(0, (sum, s) => sum + s.med) + _activeMed;

  double get todayPercentOfGoal {
    final target = todayTargetIu;
    if (target <= 0) return 100.0;
    return todayIu / target * 100.0;
  }

  // ── Settings ─────────────────────────────────────────────────────────
  void setSkin(VitDSkinType v) {
    _tick();
    _skin = v;
    Prefs.vitDSkinType = v.index;
    _targetDirty = true;
    _refreshRate();
    notifyListeners();
  }

  /// Switches tab and restores the clothing last chosen in that tab.
  void setCoverTab(int tab) {
    if (tab == _coverTab) return;
    _coverTab = tab.clamp(0, 2);
    Prefs.vitDCoverTab = _coverTab;
    final saved = [
      Prefs.vitDCoverMonk,
      Prefs.vitDCoverMan,
      Prefs.vitDCoverWoman
    ][_coverTab];
    final group = _groupFor(_coverTab);
    final next = saved != null &&
            saved >= 0 &&
            saved < VitDCoverage.values.length &&
            group.contains(VitDCoverage.values[saved])
        ? VitDCoverage.values[saved]
        : group[1];
    setCoverage(next);
  }

  void setCoverage(VitDCoverage v) {
    _tick();
    _coverage = v;
    Prefs.vitDCoverage = v.index;
    _rememberCoverage(v);
    _targetDirty = true;
    _refreshRate();
    notifyListeners();
  }

  void setSky(VitDSky v) {
    _tick();
    _sky = v;
    Prefs.vitDSky = v.index;
    _targetDirty = true;
    _refreshRate();
    notifyListeners();
  }

  void setWeightKg(double v) {
    _tick();
    _weightKg = v;
    Prefs.vitDWeightKg = v;
    _targetDirty = true;
    _refreshRate();
    notifyListeners();
  }

  void setPosture(VitDPosture v) {
    _tick();
    _posture = v;
    Prefs.vitDPosture = v.index;
    _targetDirty = true;
    _refreshRate();
    notifyListeners();
  }

  void setHairDays(int v) {
    _tick();
    _shaveDate = _midnight(now())
        .subtract(Duration(days: v.clamp(0, vitDMaxHairDays)));
    Prefs.vitDShaveDate = _shaveDate.millisecondsSinceEpoch;
    _targetDirty = true;
    _refreshRate();
    notifyListeners();
  }

  void setCatchUp(bool v) {
    Prefs.vitDCatchUp = v;
    _targetDirty = true;
    notifyListeners();
  }

  /// [iu] of 0 returns to the automatic target from weight.
  void setCustomTarget(int iu) {
    _customTarget = iu;
    Prefs.vitDCustomTarget = iu;
    _targetDirty = true;
    notifyListeners();
  }

  // ── Session control ──────────────────────────────────────────────────
  void start() {
    if (isRunning) return;
    final t = now();
    _activeStart = t;
    _lastTick = t;
    _activeIu = 0;
    _activeMed = 0;
    _activeSeconds = 0;
    _targetAlerted = todayIu >= todayTargetIu;
    _burnAlerted = todayMed >= 0.5;
    _targetDirty = true;
    _persistActive();
    _startTicker();
    notifyListeners();
  }

  void stop() {
    if (!isRunning) return;
    _tick();
    _ticker?.cancel();
    _ticker = null;
    if (_activeSeconds >= 1) {
      _sessions.add(VitDSession(
        start: _activeStart!,
        end: _lastTick ?? now(),
        seconds: _activeSeconds,
        iu: _activeIu,
        med: _activeMed,
        coverage: _coverage,
        sky: _sky,
        skin: _skin,
        posture: _posture,
        hairDays: hairDays,
      ));
      _saveSessions();
    }
    _activeStart = null;
    _lastTick = null;
    _activeIu = 0;
    _activeMed = 0;
    _activeSeconds = 0;
    Prefs.vitDActiveStart = 0;
    _persistActive();
    notifyListeners();
  }

  void deleteSession(VitDSession s) {
    _sessions.removeWhere((x) =>
        x.start.millisecondsSinceEpoch == s.start.millisecondsSinceEpoch);
    _targetDirty = true;
    _saveSessions();
    notifyListeners();
  }

  /// Advances the running session (if any) and the live sun rate to now.
  void refresh() {
    _tick();
    notifyListeners();
  }

  // ── Internals ────────────────────────────────────────────────────────
  VitDRate _computeRate(DateTime t) => computeVitDRate(
        elevationDeg: elevationAt(t),
        skin: _skin,
        coverage: _coverage,
        sky: _sky,
        weightKg: _weightKg,
        posture: _posture,
        hairDays: hairDays,
      );

  void _refreshRate() => _rate = _computeRate(now());

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
      notifyListeners();
    });
  }

  /// Integrates exposure from the last tick to now.
  void _tick() {
    if (!isRunning || _lastTick == null) {
      _refreshRate();
      return;
    }
    final t = now();
    final gap = t.difference(_lastTick!);
    if (gap.inSeconds > 90) {
      _catchUp();
      return;
    }
    final seconds = gap.inMilliseconds / 1000.0;
    _refreshRate();
    _addExposure(_rate!, seconds);
    _lastTick = t;
    _persistActive();
    _checkAlerts();
  }

  void _checkAlerts() {
    if (!_targetAlerted && todayIu >= todayTargetIu) {
      _targetAlerted = true;
      _vibrate(const [0, 300, 150, 300]);
    }
    if (!_burnAlerted && todayMed >= 0.5) {
      _burnAlerted = true;
      _vibrate(const [0, 600, 200, 600, 200, 600]);
    }
  }

  Future<void> _vibrate(List<int> pattern) async {
    if (!alerts || kIsWeb) return;
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(pattern: pattern);
      }
    } catch (_) {}
  }

  /// Integrates a long gap (app suspended) in one-minute steps along the
  /// sun's path, crediting at most [maxCatchUp].
  void _catchUp() {
    if (_lastTick == null) return;
    final t = now();
    var from = _lastTick!;
    final limit = from.add(maxCatchUp);
    final until = t.isBefore(limit) ? t : limit;
    while (from.isBefore(until)) {
      var step = until.difference(from);
      if (step > const Duration(minutes: 1)) step = const Duration(minutes: 1);
      final mid = from.add(step ~/ 2);
      _addExposure(_computeRate(mid), step.inMilliseconds / 1000.0);
      from = from.add(step);
    }
    _lastTick = t;
    _refreshRate();
    _persistActive();
    _checkAlerts();
  }

  void _addExposure(VitDRate r, double seconds) {
    final medBefore = todayMed;
    final inc = integrateExposure(r, seconds, medBefore);
    _activeIu += inc.iu;
    _activeMed += inc.med;
    _activeSeconds += seconds;
  }

  void _persistActive() {
    if (_activeStart != null) {
      Prefs.vitDActiveStart = _activeStart!.millisecondsSinceEpoch;
      Prefs.vitDActiveLastTick = (_lastTick ?? now()).millisecondsSinceEpoch;
    }
    Prefs.vitDActiveIu = _activeIu;
    Prefs.vitDActiveMed = _activeMed;
    Prefs.vitDActiveSeconds = _activeSeconds;
  }

  void _loadSessions() {
    try {
      final list = jsonDecode(Prefs.vitDSessions) as List<dynamic>;
      _sessions = list
          .map((e) => VitDSession.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      _sessions = [];
    }
  }

  void _saveSessions() {
    final cutoff = now().subtract(const Duration(days: keepDays));
    _sessions.removeWhere((s) => s.start.isBefore(cutoff));
    Prefs.vitDSessions =
        jsonEncode(_sessions.map((s) => s.toJson()).toList());
  }

  static DateTime _midnight(DateTime t) => DateTime(t.year, t.month, t.day);

  static List<VitDCoverage> _groupFor(int tab) => tab == 2
      ? VitDCoverageInfo.female
      : (tab == 1 ? VitDCoverageInfo.lay : VitDCoverageInfo.monastic);

  void _rememberCoverage(VitDCoverage c) {
    final tab = c.isFemale ? 2 : (c.isLay ? 1 : 0);
    if (tab == 0) {
      Prefs.vitDCoverMonk = c.index;
    } else if (tab == 1) {
      Prefs.vitDCoverMan = c.index;
    } else {
      Prefs.vitDCoverWoman = c.index;
    }
    _coverTab = tab;
    Prefs.vitDCoverTab = tab;
  }

  /// First use: today, or the earliest stored session if older.
  void _loadFirstUse() {
    var first = Prefs.vitDFirstUse > 0
        ? DateTime.fromMillisecondsSinceEpoch(Prefs.vitDFirstUse)
        : _midnight(now());
    for (final s in _sessions) {
      final d = _midnight(s.start);
      if (d.isBefore(first)) first = d;
    }
    _firstUse = first;
    Prefs.vitDFirstUse = first.millisecondsSinceEpoch;
  }

  /// Loads the shave date, migrating the older fixed hair-days setting.
  void _loadShaveDate() {
    final ms = Prefs.vitDShaveDate;
    if (ms > 0) {
      _shaveDate = DateTime.fromMillisecondsSinceEpoch(ms);
    } else {
      _shaveDate = _midnight(now()).subtract(Duration(
          days: Prefs.vitDHairDays.clamp(0, vitDMaxHairDays)));
      Prefs.vitDShaveDate = _shaveDate.millisecondsSinceEpoch;
    }
  }

  static String _dayKey(DateTime t) => '${t.year}-${t.month}-${t.day}';

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isRunning) {
      _tick();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }
}
