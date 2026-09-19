import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nrel_spa/nrel_spa.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/l10n/app_localizations.dart';

// ── helpers ──────────────────────────────────────────────────────────

String formatHM(DateTime dt) => _formatHM(dt);
String formatHMS(DateTime dt) => _formatHMS(dt);

String getSelectedDawnMethodString(BuildContext context) {
  switch (Prefs.dawnVal) {
    case 0:
      return AppLocalizations.of(context)!.nautical_twilight;
    case 1:
      return AppLocalizations.of(context)!.pa_auk;
    case 2:
      return AppLocalizations.of(context)!.na_uyana;
    case 3:
      return AppLocalizations.of(context)!.pa_auk_angle;
    case 4:
      return AppLocalizations.of(context)!.na_uyana_angle;
    case 5:
      return '${AppLocalizations.of(context)!.custom_dawn} (${Prefs.customDawnAngle}°)';
    case 6:
      return AppLocalizations.of(context)!.civil_twilight;
    case 7:
      return AppLocalizations.of(context)!.sunrise;
    default:
      return AppLocalizations.of(context)!.nautical_twilight;
  }
}

String getNowString() {
  // added fix for Daylight Savings (DLS).. let the offset work out by the TimeDate object itself.
  DateTime now = DateTime.now();
  debugPrint((now.timeZoneOffset.inMinutes / 60.0).toString()); // DLS fix
  return '${now.day}.${now.month}.${now.year}';
}

int getSafetyOffset() {
  int safetyOffset = 1;
  switch (Prefs.safety) {
    case 0:
      safetyOffset = 0;
      break;
    case 1:
      safetyOffset = 1;
      break;
    case 2:
      safetyOffset = 2;
      break;
    case 3:
      safetyOffset = 3;
      break;
    case 4:
      safetyOffset = 4;
      break;
    case 5:
      safetyOffset = 5;
      break;
    case 6:
      safetyOffset = 10;
      break;
  }
  return safetyOffset;
}

// ── NREL SPA core ────────────────────────────────────────────────────

/// Single SPA call for today, including custom zenith angles for twilights.
///   angles[0] → 96°  (civil / -6°)
///   angles[1] → Custom Dawn Angle
///   angles[2] → 102° (nautical / -12°)
///   angles[3] → 108° (astronomical / -18°)
///   angles[4] → 99.8° (Pa-Auk angle / -9.8°)
///   angles[5] → 97.7° (Na-Uyana angle / -7.7°)
SpaResult _getNrelResult([DateTime? date]) {
  DateTime d = date ?? DateTime.now();
  double tz = d.timeZoneOffset.inMinutes / 60.0;
  DateTime utcNoon = DateTime.utc(d.year, d.month, d.day, 12, 0, 0);

  double customZenith = 90.0 - Prefs.customDawnAngle;

  return getSpa(
    utcNoon,
    Prefs.lat,
    Prefs.lng,
    tz,
    customAngles: [96.0, customZenith, 102.0, 108.0, 99.8, 97.7],
  );
}

/// Convert NREL SPA fractional local-hours to a DateTime.
DateTime _fractionalHoursToDateTime(double hours, [DateTime? date]) {
  DateTime d = date ?? DateTime.now();
  int totalSeconds = (hours * 3600.0).round();
  int h = totalSeconds ~/ 3600;
  int m = (totalSeconds % 3600) ~/ 60;
  int s = totalSeconds % 60;
  return DateTime(d.year, d.month, d.day, h, m, s);
}

String _formatHM(DateTime dt) {
  return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
}

String _formatHMS(DateTime dt) {
  return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
}

// for dawnrise we want to add minutes to make it later = safer
DateTime _addSafety(DateTime dt) {
  return dt.add(Duration(minutes: getSafetyOffset()));
}

// for noon / sunset we subtract to finish eating earlier = safer
DateTime _subtractSafety(DateTime dt) {
  return dt.subtract(Duration(minutes: getSafetyOffset()));
}

// ── Astronomical Twilight (-18°, zenith 108°) ────────────────────────

DateTime getAstronomicalTwilight([DateTime? date]) {
  final result = _getNrelResult(date);
  return _addSafety(_fractionalHoursToDateTime(result.angles[3].sunrise, date));
}

String getAstronomicalTwilightString([DateTime? date]) =>
    _formatHM(getAstronomicalTwilight(date));

// ── Nautical Twilight (-12°, zenith 102°) ────────────────────────────

DateTime getNauticalTwilight([DateTime? date]) {
  final result = _getNrelResult(date);
  return _addSafety(_fractionalHoursToDateTime(result.angles[2].sunrise, date));
}

String getNauticalTwilightString([DateTime? date]) =>
    _formatHM(getNauticalTwilight(date));

// ── Custom Dawn ─────────────────────────────────────────

DateTime getCustomDawn([DateTime? date]) {
  final result = _getNrelResult(date);
  return _addSafety(_fractionalHoursToDateTime(result.angles[1].sunrise, date));
}

String getCustomDawnString([DateTime? date]) => _formatHM(getCustomDawn(date));

// ── Pa-Auk Angle Dawn (-9.8°, zenith 99.8°) ─────────────────────

DateTime getPaAukAngleDawn([DateTime? date]) {
  final result = _getNrelResult(date);
  return _addSafety(_fractionalHoursToDateTime(result.angles[4].sunrise, date));
}

String getPaAukAngleDawnString([DateTime? date]) =>
    _formatHM(getPaAukAngleDawn(date));

// ── Na-Uyana Angle Dawn (-7.7°, zenith 97.7°) ─────────────────

DateTime getNaUyanaAngleDawn([DateTime? date]) {
  final result = _getNrelResult(date);
  return _addSafety(_fractionalHoursToDateTime(result.angles[5].sunrise, date));
}

String getNaUyanaAngleDawnString([DateTime? date]) =>
    _formatHM(getNaUyanaAngleDawn(date));

// ── Civil Twilight (-6°, zenith 96°) ────────────────────────────────

DateTime getCivilTwilight([DateTime? date]) {
  final result = _getNrelResult(date);
  return _addSafety(_fractionalHoursToDateTime(result.angles[0].sunrise, date));
}

String getCivilTwilightString([DateTime? date]) =>
    _formatHM(getCivilTwilight(date));

// ── Sunrise ──────────────────────────────────────────────────────────

DateTime getSunrise([DateTime? date]) {
  final result = _getNrelResult(date);
  return _addSafety(_fractionalHoursToDateTime(result.sunrise, date));
}

String getSunriseString([DateTime? date]) => _formatHM(getSunrise(date));

// ── Pa-Auk: Sunrise − 40 min ────────────────────────────────────────

DateTime getSunrise40([DateTime? date]) {
  final result = _getNrelResult(date);
  DateTime sr = _fractionalHoursToDateTime(result.sunrise, date);
  return _addSafety(sr.subtract(const Duration(minutes: 40)));
}

String getSunrise40String([DateTime? date]) => _formatHM(getSunrise40(date));

// ── Na-Uyana: Sunrise − 30 min ──────────────────────────────────────

DateTime getSunrise30([DateTime? date]) {
  final result = _getNrelResult(date);
  DateTime sr = _fractionalHoursToDateTime(result.sunrise, date);
  return _addSafety(sr.subtract(const Duration(minutes: 30)));
}

String getSunrise30String([DateTime? date]) => _formatHM(getSunrise30(date));

// ── Selected Aruṇa (Dawn based on Settings) ─────────────────────────

/// Returns the Aruṇa (Dawn) DateTime corresponding to the user-selected
/// method in Settings (Prefs.dawnVal).
DateTime getSelectedDawn([DateTime? date]) {
  switch (Prefs.dawnVal) {
    case 0:
      return getNauticalTwilight(date);
    case 1:
      return getSunrise40(date);
    case 2:
      return getSunrise30(date);
    case 3:
      return getPaAukAngleDawn(date);
    case 4:
      return getNaUyanaAngleDawn(date);
    case 5:
      return getCustomDawn(date);
    case 6:
      return getCivilTwilight(date);
    case 7:
      return getSunrise(date);
    default:
      return getNauticalTwilight(date);
  }
}

/// Formatted Aruṇa string based on user's dawn setting.
String getSelectedDawnString([DateTime? date]) =>
    _formatHM(getSelectedDawn(date));

// ── Solar Noon ───────────────────────────────────────────────────────

/// Raw solar noon (no safety) — used by countdown timer internally.
DateTime getSolarNoonRaw([DateTime? date]) {
  final result = _getNrelResult(date);
  return _fractionalHoursToDateTime(result.solarNoon, date);
}

/// Solar noon with safety subtracted.
DateTime getSolarNoonDateTime([DateTime? date]) {
  return _subtractSafety(getSolarNoonRaw(date));
}

/// Formatted solar noon string with seconds precision.
String getSolarNoonTimeString([DateTime? date]) =>
    _formatHMS(getSolarNoonDateTime(date));

// ── Countdown Target Mode & Information ──────────────────────────────

enum CountdownTargetMode {
  dawn,
  noon,
}

class CountdownTargetInfo {
  final CountdownTargetMode mode;
  final DateTime targetDateTime;
  final bool isLate;
  final DateTime solarNoon;
  final DateTime upcomingDawn;

  const CountdownTargetInfo({
    required this.mode,
    required this.targetDateTime,
    required this.isLate,
    required this.solarNoon,
    required this.upcomingDawn,
  });

  bool get isDawnMode => mode == CountdownTargetMode.dawn;
}

/// Evaluates whether the current time is in Dawn Mode (within 6 hours before dawn
/// until 2 hours after dawn) or Noon Mode (switches 2 hours after dawn until 6 hours
/// before next dawn).
CountdownTargetInfo getCountdownTargetInfo([DateTime? currentTime]) {
  final now = currentTime ?? DateTime.now();
  final todayDawn = getSelectedDawn(now);
  final tomorrowDawn = getSelectedDawn(now.add(const Duration(days: 1)));
  final todayNoon = getSolarNoonDateTime(now);

  // 1) Window for today's dawn: [todayDawn - 6h, todayDawn + 2h]
  final todayDawnStart = todayDawn.subtract(const Duration(hours: 6));
  final todayDawnEnd = todayDawn.add(const Duration(hours: 2));

  if (!now.isBefore(todayDawnStart) && now.isBefore(todayDawnEnd)) {
    return CountdownTargetInfo(
      mode: CountdownTargetMode.dawn,
      targetDateTime: todayDawn,
      isLate: todayDawn.difference(now).isNegative,
      solarNoon: todayNoon,
      upcomingDawn: todayDawn,
    );
  }

  // 2) Window for tomorrow's dawn: [tomorrowDawn - 6h, tomorrowDawn + 2h]
  final tomorrowDawnStart = tomorrowDawn.subtract(const Duration(hours: 6));
  final tomorrowDawnEnd = tomorrowDawn.add(const Duration(hours: 2));

  if (!now.isBefore(tomorrowDawnStart) && now.isBefore(tomorrowDawnEnd)) {
    final tomorrowNoon = getSolarNoonDateTime(now.add(const Duration(days: 1)));
    return CountdownTargetInfo(
      mode: CountdownTargetMode.dawn,
      targetDateTime: tomorrowDawn,
      isLate: tomorrowDawn.difference(now).isNegative,
      solarNoon: tomorrowNoon,
      upcomingDawn: tomorrowDawn,
    );
  }

  // 3) Otherwise: Noon Mode
  return CountdownTargetInfo(
    mode: CountdownTargetMode.noon,
    targetDateTime: todayNoon,
    isLate: todayNoon.difference(now).isNegative,
    solarNoon: todayNoon,
    upcomingDawn: tomorrowDawn,
  );
}

// ── Sunset ───────────────────────────────────────────────────────────

DateTime getSunset([DateTime? date]) {
  final result = _getNrelResult(date);
  return _subtractSafety(_fractionalHoursToDateTime(result.sunset, date));
}

String getSunsetString([DateTime? date]) => _formatHM(getSunset(date));

// ── Civil Dusk (zenith 96°) ──────────────────────────────────────────

DateTime getCivilDusk() {
  final result = _getNrelResult();
  return _subtractSafety(_fractionalHoursToDateTime(result.angles[0].sunset));
}

String getDuskCivilString() => _formatHM(getCivilDusk());

// ── Nautical Dusk (zenith 102°) ──────────────────────────────────────

DateTime getNuaticleDusk() {
  final result = _getNrelResult();
  return _subtractSafety(_fractionalHoursToDateTime(result.angles[2].sunset));
}

String getDuskNauticleString() => _formatHM(getNuaticleDusk());

// ── Solar times for a specific date ──────────────────────────────────

/// Data class holding all solar times for a given date.
class SolarTimesForDate {
  final String astronomicalTwilight;
  final String nauticalTwilight;
  final String customDawn;
  final String civilTwilight;
  final String sunrise;
  final String paAukSR;
  final String naUyanaSR;
  final String paAukAngle;
  final String naUyanaAngle;
  final String solarNoon;
  final String sunset;

  SolarTimesForDate({
    required this.astronomicalTwilight,
    required this.nauticalTwilight,
    required this.customDawn,
    required this.civilTwilight,
    required this.sunrise,
    required this.paAukSR,
    required this.naUyanaSR,
    required this.paAukAngle,
    required this.naUyanaAngle,
    required this.solarNoon,
    required this.sunset,
  });
}

/// Compute all solar times for a specific [date] using the user's saved location.
SolarTimesForDate getSolarTimesForDate(DateTime date) {
  DateTime now = DateTime.now();
  double tz = now.timeZoneOffset.inMinutes / 60.0;
  DateTime utcNoon = DateTime.utc(date.year, date.month, date.day, 12, 0, 0);
  double customZenith = 90.0 - Prefs.customDawnAngle;

  final result = getSpa(
    utcNoon,
    Prefs.lat,
    Prefs.lng,
    tz,
    customAngles: [96.0, customZenith, 102.0, 108.0, 99.8, 97.7],
  );

  String fmtHM(double hours) {
    int totalSeconds = (hours * 3600.0).round();
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    return '${h}:${m.toString().padLeft(2, '0')}';
  }

  String fmtHMS(double hours) {
    int totalSeconds = (hours * 3600.0).round();
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    return '${h}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // Sunrise-based dawn methods
  String srString = fmtHM(result.sunrise);
  int srTotalSec = (result.sunrise * 3600.0).round();
  int sr40Sec = srTotalSec - 40 * 60;
  int sr30Sec = srTotalSec - 30 * 60;

  String fmtSec(int totalSec) {
    int h = totalSec ~/ 3600;
    int m = (totalSec % 3600) ~/ 60;
    return '${h}:${m.toString().padLeft(2, '0')}';
  }

  return SolarTimesForDate(
    astronomicalTwilight: fmtHM(result.angles[3].sunrise),
    nauticalTwilight: fmtHM(result.angles[2].sunrise),
    customDawn: fmtHM(result.angles[1].sunrise),
    civilTwilight: fmtHM(result.angles[0].sunrise),
    sunrise: srString,
    paAukSR: fmtSec(sr40Sec),
    naUyanaSR: fmtSec(sr30Sec),
    paAukAngle: fmtHM(result.angles[4].sunrise),
    naUyanaAngle: fmtHM(result.angles[5].sunrise),
    solarNoon: fmtHMS(result.solarNoon),
    sunset: fmtHM(result.sunset),
  );
}

// ── Real-Time Solar Position & Shadow Modeling ───────────────────────

/// Represents the sun's instantaneous spherical coordinates and resulting shadow.
class SolarPosition {
  final DateTime time;
  final double
      azimuth; // Degrees clockwise from North (0°=N, 90°=E, 180°=S, 270°=W)
  final double elevation; // Degrees above horizon (90° - zenith)
  final double zenith; // Degrees from zenith
  final double?
      shadowLength; // Shadow length ratio to gnomon height (null if below horizon)
  final double
      shadowAzimuth; // Azimuth where shadow points ((azimuth + 180) % 360)

  const SolarPosition({
    required this.time,
    required this.azimuth,
    required this.elevation,
    required this.zenith,
    this.shadowLength,
    required this.shadowAzimuth,
  });

  /// True when the sun is above the geometric horizon.
  bool get isDay => elevation > 0.0;
}

/// Calculate the instantaneous solar position and shadow geometry for any [moment].
SolarPosition getSolarPositionAt(DateTime moment, {double? lat, double? lng}) {
  // NREL SPA expects year, month, day, hour, min, sec passed in a DateTime
  // along with the timezone offset parameter. Construct a UTC DateTime with the local fields.
  DateTime localMoment = DateTime.utc(
    moment.year,
    moment.month,
    moment.day,
    moment.hour,
    moment.minute,
    moment.second,
  );
  double tz = moment.timeZoneOffset.inMinutes / 60.0;
  final oLat = lat ?? Prefs.lat;
  final oLng = lng ?? Prefs.lng;
  final result = getSpa(localMoment, oLat, oLng, tz);

  final double zenith = result.zenith;
  final double azimuth = result.azimuth;
  final double elevation = 90.0 - zenith;
  final double shadowAzimuth = (azimuth + 180.0) % 360.0;

  double? shadowLength;
  if (elevation > 4.0) {
    double rad = elevation * (math.pi / 180.0);
    shadowLength = 1.0 / math.tan(rad);
  }

  return SolarPosition(
    time: moment,
    azimuth: azimuth,
    elevation: elevation,
    zenith: zenith,
    shadowLength: shadowLength,
    shadowAzimuth: shadowAzimuth,
  );
}

/// Sample the diurnal trajectory curve for a given [date].
/// Returns [samples] points sampled evenly across the day.
List<SolarPosition> getDaySolarArc(DateTime date, {int samples = 72}) {
  final List<SolarPosition> arc = [];
  int intervalMinutes = (24 * 60) ~/ samples;
  DateTime dayStart = DateTime(date.year, date.month, date.day, 0, 0, 0);

  for (int i = 0; i <= samples; i++) {
    DateTime t = dayStart.add(Duration(minutes: i * intervalMinutes));
    arc.add(getSolarPositionAt(t));
  }
  return arc;
}
