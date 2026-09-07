import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nrel_spa/nrel_spa.dart';
import 'package:buddhist_sun/src/models/prefs.dart';

// ── helpers ──────────────────────────────────────────────────────────

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
SpaResult _getNrelResult() {
  DateTime now = DateTime.now();
  double tz = now.timeZoneOffset.inMinutes / 60.0;
  DateTime utcNoon = DateTime.utc(now.year, now.month, now.day, 12, 0, 0);

  double customZenith = 90.0 - Prefs.customDawnAngle;

  return getSpa(
    utcNoon,
    Prefs.lat,
    Prefs.lng,
    tz,
    customAngles: [96.0, customZenith, 102.0, 108.0, 99.8, 97.7],
  );
}

/// Convert NREL SPA fractional local-hours to a DateTime today.
DateTime _fractionalHoursToDateTime(double hours) {
  DateTime now = DateTime.now();
  int totalSeconds = (hours * 3600.0).round();
  int h = totalSeconds ~/ 3600;
  int m = (totalSeconds % 3600) ~/ 60;
  int s = totalSeconds % 60;
  return DateTime(now.year, now.month, now.day, h, m, s);
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

DateTime getAstronomicalTwilight() {
  final result = _getNrelResult();
  return _addSafety(_fractionalHoursToDateTime(result.angles[3].sunrise));
}

String getAstronomicalTwilightString() => _formatHM(getAstronomicalTwilight());

// ── Nautical Twilight (-12°, zenith 102°) ────────────────────────────

DateTime getNauticalTwilight() {
  final result = _getNrelResult();
  return _addSafety(_fractionalHoursToDateTime(result.angles[2].sunrise));
}

String getNauticalTwilightString() => _formatHM(getNauticalTwilight());

// ── Custom Dawn ─────────────────────────────────────────

DateTime getCustomDawn() {
  final result = _getNrelResult();
  return _addSafety(_fractionalHoursToDateTime(result.angles[1].sunrise));
}

String getCustomDawnString() => _formatHM(getCustomDawn());

// ── Pa-Auk Angle Dawn (-9.8°, zenith 99.8°) ─────────────────────

DateTime getPaAukAngleDawn() {
  final result = _getNrelResult();
  return _addSafety(_fractionalHoursToDateTime(result.angles[4].sunrise));
}

String getPaAukAngleDawnString() => _formatHM(getPaAukAngleDawn());

// ── Na-Uyana Angle Dawn (-7.7°, zenith 97.7°) ─────────────────

DateTime getNaUyanaAngleDawn() {
  final result = _getNrelResult();
  return _addSafety(_fractionalHoursToDateTime(result.angles[5].sunrise));
}

String getNaUyanaAngleDawnString() => _formatHM(getNaUyanaAngleDawn());

// ── Civil Twilight (-6°, zenith 96°) ────────────────────────────────

DateTime getCivilTwilight() {
  final result = _getNrelResult();
  return _addSafety(_fractionalHoursToDateTime(result.angles[0].sunrise));
}

String getCivilTwilightString() => _formatHM(getCivilTwilight());

// ── Sunrise ──────────────────────────────────────────────────────────

DateTime getSunrise() {
  final result = _getNrelResult();
  return _addSafety(_fractionalHoursToDateTime(result.sunrise));
}

String getSunriseString() => _formatHM(getSunrise());

// ── Pa-Auk: Sunrise − 40 min ────────────────────────────────────────

DateTime getSunrise40() {
  final result = _getNrelResult();
  DateTime sr = _fractionalHoursToDateTime(result.sunrise);
  return _addSafety(sr.subtract(Duration(minutes: 40)));
}

String getSunrise40String() => _formatHM(getSunrise40());

// ── Na-Uyana: Sunrise − 30 min ──────────────────────────────────────

DateTime getSunrise30() {
  final result = _getNrelResult();
  DateTime sr = _fractionalHoursToDateTime(result.sunrise);
  return _addSafety(sr.subtract(Duration(minutes: 30)));
}

String getSunrise30String() => _formatHM(getSunrise30());

// ── Selected Aruṇa (Dawn based on Settings) ─────────────────────────

/// Returns the Aruṇa (Dawn) DateTime corresponding to the user-selected
/// method in Settings (Prefs.dawnVal).
DateTime getSelectedDawn() {
  switch (Prefs.dawnVal) {
    case 0:
      return getNauticalTwilight();
    case 1:
      return getSunrise40();
    case 2:
      return getSunrise30();
    case 3:
      return getPaAukAngleDawn();
    case 4:
      return getNaUyanaAngleDawn();
    case 5:
      return getCustomDawn();
    case 6:
      return getCivilTwilight();
    case 7:
      return getSunrise();
    default:
      return getNauticalTwilight();
  }
}

/// Formatted Aruṇa string based on user's dawn setting.
String getSelectedDawnString() => _formatHM(getSelectedDawn());

// ── Solar Noon ───────────────────────────────────────────────────────

/// Raw solar noon (no safety) — used by countdown timer internally.
DateTime getSolarNoonRaw() {
  final result = _getNrelResult();
  return _fractionalHoursToDateTime(result.solarNoon);
}

/// Solar noon with safety subtracted.
DateTime getSolarNoonDateTime() {
  return _subtractSafety(getSolarNoonRaw());
}

/// Formatted solar noon string with seconds precision.
String getSolarNoonTimeString() => _formatHMS(getSolarNoonDateTime());

// ── Sunset ───────────────────────────────────────────────────────────

DateTime getSunset() {
  final result = _getNrelResult();
  return _subtractSafety(_fractionalHoursToDateTime(result.sunset));
}

String getSunsetString() => _formatHM(getSunset());

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
SolarPosition getSolarPositionAt(DateTime moment) {
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
  final result = getSpa(localMoment, Prefs.lat, Prefs.lng, tz);

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
