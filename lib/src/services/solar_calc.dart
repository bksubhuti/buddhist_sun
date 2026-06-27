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
    customAngles: [96.0, customZenith, 102.0, 108.0],
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
  return _subtractSafety(_fractionalHoursToDateTime(result.angles[1].sunset));
}

String getDuskNauticleString() => _formatHM(getNuaticleDusk());
