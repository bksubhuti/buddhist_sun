import 'dart:math';
import 'package:timezone/timezone.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/solar_calc.dart';

/// Converts a [TZDateTime] in UTC to the corresponding Julian Date.
double datetimeToJD(TZDateTime datetime) {
  int Y = datetime.year;
  int M = datetime.month;
  final double D = datetime.day +
      (datetime.hour + (datetime.minute + datetime.second / 60) / 60) / 24;
  if (M < 3) {
    Y -= 1;
    M += 12;
  }
  final int A = (Y / 100).floor();
  int B = 0;
  final TZDateTime gregorianCutoff = TZDateTime.utc(1582, 10, 15, 12, 0, 0);
  if (datetime.isAfter(gregorianCutoff)) {
    B = 2 - A + (A / 4).floor();
  }
  return (365.25 * (Y + 4716)).floor() +
      (30.6001 * (M + 1)).floor() +
      D +
      B -
      1524.5;
}

/// Converts a Julian Date to the corresponding [TZDateTime] in UTC.
TZDateTime JDToDatetime(double JD) {
  JD += 0.5;
  final int Z = JD.floor();
  final double F = JD - Z;
  int A = Z;
  if (Z >= 2299161) {
    final int alpha = ((Z - 1867216.25) / 36524.25).floor();
    A += 1 + alpha - (alpha / 4).floor();
  }
  final int B = A + 1524;
  final int C = ((B - 122.1) / 365.25).floor();
  final int D = (365.25 * C).floor();
  final int E = ((B - D) / 30.6001).floor();
  final double fracDay = B - D - (30.6001 * E).floor() + F;
  final int day = fracDay.floor();
  final int hour = ((fracDay - day) * 24).floor();
  final int minute = (((fracDay - day) * 24 - hour) * 60).floor();
  final int second =
      ((((fracDay - day) * 24 - hour) * 60 - minute) * 60).floor();
  int month = E - 1;
  if (E > 13) {
    month -= 12;
  }
  int year = C - 4715;
  if (month > 2) {
    year -= 1;
  }
  return TZDateTime.utc(year, month, day, hour, minute, second);
}

/// Converts a Julian date to the number of Julian centuries since
/// 2000-01-01T12:00:00Z.
double JDToT(double JD) {
  return (JD - 2451545) / 36525;
}

/// Converts a [TZDateTime] in UTC to the number of Julian centuries since
/// 2000-01-01T12:00:00Z.
double datetimeToT(TZDateTime datetime) {
  return JDToT(datetimeToJD(datetime));
}

// Define your polynomial function and DeltaT function in Dart here...

/// Calculates an approximate value for k (the fractional number of new moons
/// since 2000-01-06).
double approxK(TZDateTime datetime) {
  final double year =
      datetime.year + (datetime.month / 12) + datetime.day / 365.25;
  return (year - 2000) * 12.3685;
}

/// Calculates T from k.
double kToT(double k) {
  return k / 1236.85;
}

// Add the rest of your functions here...
// Function to calculate Julian Date from a DateTime object
double calculateJulianDate(DateTime date) {
  int year = date.year;
  int month = date.month;
  double day =
      date.day + (date.hour + (date.minute + date.second / 60.0) / 60.0) / 24.0;

  if (month <= 2) {
    year -= 1;
    month += 12;
  }
  int A = (year / 100).floor();
  int B = 2 - A + (A / 4).floor();

  return ((365.25 * (year + 4716)).floor()) +
      (30.6001 * (month + 1)).floor() +
      day +
      B -
      1524.5;
}

// Function to calculate Julian Centuries from Julian Date
double calculateJulianCenturies(double julianDate) {
  return (julianDate - 2451545.0) / 36525.0;
}

// Function to find the time of the new moon nearest to a given Julian Date
double findNewMoon(double julianDate) {
  // Implementation of Meeus algorithm to find the Julian Date of new moon
  // This is a simplified example and might require more terms and corrections for high precision
  double k = (julianDate - 2451550.09766) / 29.53058867;
  k = k.roundToDouble(); // Round to the nearest new moon
  double JDE = 2451550.09766 + 29.53058867 * k;
  return JDE;
}

double calculateLunarIllumination(double phaseAngle) {
  return (1 - cos(rad(phaseAngle))) / 2 * 100;
}

double rad(double degree) {
  return degree * pi / 180;
}

// Function to calculate observer's sidereal time
double calculateSiderealTime(TZDateTime datetime, double longitude) {
  double JD = datetimeToJD(datetime);
  double T = JDToT(JD);
  double GMST = 280.46061837 +
      360.98564736629 * (JD - 2451545) +
      T * T * (0.000387933 - T / 38710000);
  GMST = GMST % 360.0; // Normalize to [0, 360)
  double LST = GMST + longitude;
  LST = LST % 360.0; // Normalize to [0, 360)
  return LST;
}

// Function to apply topocentric corrections to lunar phase angle
double applyTopocentricCorrections(
    double lunarPhase, double latitude, double siderealTime) {
  // This is a simplified example, and for a real application, you would need to calculate the
  // topocentric corrections based on the observer's latitude, lunar parallax, and sidereal time.
  double correction =
      latitude / 10.0 + siderealTime / 100.0; // Simplified correction formula
  double correctedPhase = lunarPhase + correction;
  correctedPhase = correctedPhase % 360.0; // Ensure the result is in [0, 360)
  return correctedPhase;
}

// Function to calculate lunar phase based on Julian Date, latitude, and longitude
double calculateLunarPhaseWithLatLong(
    double julianDate, double latitude, double longitude) {
  TZDateTime datetime = JDToDatetime(julianDate);
  double lunarPhase = calculateLunarPhase(
      julianDate); // Calculate lunar phase without corrections
  double siderealTime = calculateSiderealTime(
      datetime, longitude); // Calculate observer's sidereal time
  double correctedPhase = applyTopocentricCorrections(
      lunarPhase, latitude, siderealTime); // Apply topocentric corrections
  return correctedPhase;
}

// Function to calculate lunar phase based on Julian Date
double calculateLunarPhase(double julianDate) {
  double newMoonJDE = findNewMoon(julianDate);
  double daysSinceNewMoon = julianDate - newMoonJDE;
  double lunarPhase =
      (daysSinceNewMoon / 29.53058867) * 360.0; // Convert to degrees
  lunarPhase = lunarPhase % 360.0; // Ensure the result is in [0, 360)
  return lunarPhase;
}

// ══════════════════════════════════════════════════════════════════════════
// REAL-TIME MOON POSITION & 3D CELESTIAL DOME MODELING
// ══════════════════════════════════════════════════════════════════════════

class MoonPosition {
  final DateTime time;
  final double
      azimuth; // Degrees clockwise from North (0°=N, 90°=E, 180°=S, 270°=W)
  final double elevation; // Degrees above horizon (-90° to +90°)
  final double zenith; // Degrees from zenith (90° - elevation)
  final double?
      shadowLength; // Gnomon shadow length ratio (null if below horizon)
  final double shadowAzimuth; // Azimuth pointing away from the moon
  final double illumination; // 0% to 100%
  final double phase; // 0.0 to 1.0 (0=New, 0.5=Full, 1.0=New)
  final double distance; // Distance in kilometers
  final double parallacticAngle;

  const MoonPosition({
    required this.time,
    required this.azimuth,
    required this.elevation,
    required this.zenith,
    this.shadowLength,
    required this.shadowAzimuth,
    required this.illumination,
    required this.phase,
    required this.distance,
    required this.parallacticAngle,
  });

  bool get isAboveHorizon => elevation > 0.0;
  double get distanceKm => distance;
  double get fraction => illumination / 100.0;
  double get phaseAngle => phase * 2 * pi;
}

class MoonMilestones {
  final DateTime? moonrise;
  final DateTime? transit; // Culmination / Zenith point
  final DateTime? moonset;
  final double maxElevation;

  const MoonMilestones({
    this.moonrise,
    this.transit,
    this.moonset,
    required this.maxElevation,
  });
}

/// Categories of naked-eye lunar visibility.
enum MoonVisibilityCategory {
  belowHorizon,
  lostInSolarGlare,
  newMoonInvisible,
  faintInDaylight,
  visibleDaytime,
  visibleTwilight,
  visibleNight,
}

/// Information describing whether the Moon can be discerned by the naked human eye.
class MoonVisibility {
  final MoonVisibilityCategory category;
  final bool isVisibleToNakedEye;
  final double angularSeparationDeg;
  final String statusText;
  final String shortBadge;
  final String detailExplanation;

  const MoonVisibility({
    required this.category,
    required this.isVisibleToNakedEye,
    required this.angularSeparationDeg,
    required this.statusText,
    required this.shortBadge,
    required this.detailExplanation,
  });
}

const double _degToRad = pi / 180.0;
const double _msInDay = 1000.0 * 60 * 60 * 24;
const double _epochJ1970 = 2440588.0;
const double _epochJ2000 = 2451545.0;
const double _earthObliquity = _degToRad * 23.4397;

double _calcDaysSinceJ2000(DateTime date) {
  final jd = date.toUtc().millisecondsSinceEpoch / _msInDay - 0.5 + _epochJ1970;
  return jd - _epochJ2000;
}

double _calcRightAscension(double l, double b) {
  return atan2(
    sin(l) * cos(_earthObliquity) - tan(b) * sin(_earthObliquity),
    cos(l),
  );
}

double _calcDeclination(double l, double b) {
  return asin(
    sin(b) * cos(_earthObliquity) + cos(b) * sin(_earthObliquity) * sin(l),
  );
}

double _calcAzimuth(double H, double phi, double dec) {
  return atan2(
    sin(H),
    cos(H) * sin(phi) - tan(dec) * cos(phi),
  );
}

double _calcAltitude(double H, double phi, double dec) {
  return asin(
    sin(phi) * sin(dec) + cos(phi) * cos(dec) * cos(H),
  );
}

double _calcSiderealTime(double d, double lw) {
  return _degToRad * (280.16 + 360.9856235 * d) - lw;
}

double _calcAstroRefraction(double h) {
  if (h < 0) h = 0;
  return 0.0002967 / tan(h + 0.00312536 / (h + 0.08901179));
}

Map<String, double> _calcMoonCoords(double d) {
  final L = _degToRad * (218.316 + 13.176396 * d);
  final M = _degToRad * (134.963 + 13.064993 * d);
  final F = _degToRad * (93.272 + 13.229350 * d);

  final l = L + _degToRad * 6.289 * sin(M);
  final b = _degToRad * 5.128 * sin(F);
  final dt = 385001.0 - 20905.0 * cos(M);

  return {
    'ra': _calcRightAscension(l, b),
    'dec': _calcDeclination(l, b),
    'dist': dt,
  };
}

/// Calculate instantaneous lunar coordinates and shadow for any [time] and location.
MoonPosition getMoonPositionAt(DateTime time, {double? lat, double? lng}) {
  final observerLat = lat ?? ((Prefs.lat != 1.1) ? Prefs.lat : 0.0);
  final observerLng = lng ?? ((Prefs.lng != 1.1) ? Prefs.lng : 0.0);

  final lw = _degToRad * -observerLng;
  final phi = _degToRad * observerLat;
  final d = _calcDaysSinceJ2000(time);

  final c = _calcMoonCoords(d);
  final H = _calcSiderealTime(d, lw) - c['ra']!;
  var h = _calcAltitude(H, phi, c['dec']!);
  final pa = atan2(
    sin(H),
    tan(phi) * cos(c['dec']!) - sin(c['dec']!) * cos(H),
  );

  h = h + _calcAstroRefraction(h);

  final azRad = _calcAzimuth(H, phi, c['dec']!);
  var compassAz = (azRad * 180.0 / pi + 180.0) % 360.0;
  if (compassAz < 0) compassAz += 360.0;

  final elevationDeg = h * 180.0 / pi;
  final zenithDeg = 90.0 - elevationDeg;
  final double? shadowLen = elevationDeg > 0.5 ? 1.0 / tan(h) : null;
  final shadowAz = (compassAz + 180.0) % 360.0;

  // Illumination calculation
  final mSun = _degToRad * (357.5291 + 0.98560028 * d);
  final lSun = mSun +
      _degToRad *
          (1.9148 * sin(mSun) + 0.02 * sin(2 * mSun) + 0.0003 * sin(3 * mSun)) +
      _degToRad * 102.9372 +
      pi;
  final sunDec = _calcDeclination(lSun, 0);
  final sunRa = _calcRightAscension(lSun, 0);

  const double sdist = 149598000.0;
  final moonDec = c['dec']!;
  final moonRa = c['ra']!;
  final moonDist = c['dist']!;

  final phiMoon = acos(
    (sin(sunDec) * sin(moonDec) +
            cos(sunDec) * cos(moonDec) * cos(sunRa - moonRa))
        .clamp(-1.0, 1.0),
  );
  final inc = atan2(sdist * sin(phiMoon), moonDist - sdist * cos(phiMoon));
  final angle = atan2(
    cos(sunDec) * sin(sunRa - moonRa),
    sin(sunDec) * cos(moonDec) -
        cos(sunDec) * sin(moonDec) * cos(sunRa - moonRa),
  );
  final fraction = (1.0 + cos(inc)) / 2.0;
  final phase = 0.5 + 0.5 * inc * (angle < 0 ? -1 : 1) / pi;

  return MoonPosition(
    time: time,
    azimuth: compassAz,
    elevation: elevationDeg,
    zenith: zenithDeg,
    shadowLength: shadowLen,
    shadowAzimuth: shadowAz,
    illumination: fraction * 100.0,
    phase: phase,
    distance: c['dist']!,
    parallacticAngle: pa * 180.0 / pi,
  );
}

/// Computes the 24-hour diurnal lunar path curve sampled every [samples] times across [date].
List<MoonPosition> getDayMoonArc(DateTime date,
    {int samples = 48, double? lat, double? lng}) {
  final startOfDay = DateTime(date.year, date.month, date.day);
  final stepMinutes = (24.0 * 60.0 / samples).round();
  final List<MoonPosition> arc = [];

  for (int i = 0; i <= samples; i++) {
    final t = startOfDay.add(Duration(minutes: i * stepMinutes));
    arc.add(getMoonPositionAt(t, lat: lat, lng: lng));
  }
  return arc;
}

/// Calculates approximate moonrise, moon transit (highest culmination), and moonset for [date].
MoonMilestones getMoonMilestones(DateTime date, {double? lat, double? lng}) {
  DateTime? rise;
  DateTime? set;
  DateTime? maxTransit;
  double maxEl = -999.0;

  final startOfDay = DateTime(date.year, date.month, date.day);
  MoonPosition? prevPos;

  // Sample every 5 minutes across the 24-hour day
  for (int m = 0; m <= 24 * 60; m += 5) {
    final t = startOfDay.add(Duration(minutes: m));
    final pos = getMoonPositionAt(t, lat: lat, lng: lng);

    if (pos.elevation > maxEl) {
      maxEl = pos.elevation;
      maxTransit = t;
    }

    if (prevPos != null) {
      if (prevPos.elevation <= 0.0 && pos.elevation > 0.0 && rise == null) {
        rise = t;
      } else if (prevPos.elevation > 0.0 &&
          pos.elevation <= 0.0 &&
          set == null) {
        set = t;
      }
    }
    prevPos = pos;
  }

  return MoonMilestones(
    moonrise: rise,
    transit: maxTransit,
    moonset: set,
    maxElevation: maxEl,
  );
}

/// Computes whether the Moon can be observed by the naked human eye at [time].
///
/// Accounts for:
/// 1. Topocentric Moon elevation relative to the horizon.
/// 2. Solar elevation (daylight, twilight, or night sky background).
/// 3. Angular separation between Sun and Moon (solar glare / forward aureole).
/// 4. Illuminated fraction (crescent, quarter, gibbous, full, or new moon).
MoonVisibility getMoonVisibility(DateTime time, {double? lat, double? lng}) {
  final mPos = getMoonPositionAt(time, lat: lat, lng: lng);
  final sPos = getSolarPositionAt(time, lat: lat, lng: lng);

  final elMRad = mPos.elevation * (pi / 180.0);
  final elSRad = sPos.elevation * (pi / 180.0);
  final azDiffRad = (sPos.azimuth - mPos.azimuth) * (pi / 180.0);
  final cosSep =
      (sin(elSRad) * sin(elMRad) + cos(elSRad) * cos(elMRad) * cos(azDiffRad))
          .clamp(-1.0, 1.0);
  final sepDeg = acos(cosSep) * (180.0 / pi);

  final f = mPos.fraction; // 0.0 to 1.0

  if (mPos.elevation <= 0.0) {
    return MoonVisibility(
      category: MoonVisibilityCategory.belowHorizon,
      isVisibleToNakedEye: false,
      angularSeparationDeg: sepDeg,
      statusText: 'Below Horizon (Not Visible)',
      shortBadge: 'Under Horizon',
      detailExplanation: 'The Moon is beneath the horizon and not in the sky.',
    );
  }

  // Moon is above horizon: check sky lighting conditions
  final isDaytime = sPos.elevation > 0.0;
  final isCivilTwilight = sPos.elevation <= 0.0 && sPos.elevation > -6.0;

  if (isDaytime) {
    // Under daylight, human eye can only discern the Moon if illuminated enough
    // and far enough from the Sun's forward glare disk.
    if (f < 0.05 || sepDeg < 15.0) {
      final reason = f < 0.05 && sepDeg < 15.0
          ? 'Near New Moon (${(f * 100).toStringAsFixed(1)}% lit) and within ${sepDeg.toStringAsFixed(0)}° of the Sun.'
          : (sepDeg < 15.0
              ? 'Washed out by intense solar glare (${sepDeg.toStringAsFixed(0)}° from Sun).'
              : 'Thin crescent (${(f * 100).toStringAsFixed(1)}% lit) washed out by daylight sky brightness.');
      return MoonVisibility(
        category: MoonVisibilityCategory.lostInSolarGlare,
        isVisibleToNakedEye: false,
        angularSeparationDeg: sepDeg,
        statusText: 'Not Visible (Lost in Solar Glare)',
        shortBadge: 'Invisible to Eye',
        detailExplanation: reason,
      );
    } else if (f < 0.15 || sepDeg < 25.0) {
      final isMorning = time.hour < 12;
      final timeOfDay = isMorning ? 'Morning' : 'Afternoon';
      return MoonVisibility(
        category: MoonVisibilityCategory.faintInDaylight,
        isVisibleToNakedEye: true,
        angularSeparationDeg: sepDeg,
        statusText: 'Faint in $timeOfDay Sky',
        shortBadge: 'Faint in Daylight',
        detailExplanation:
            'Can be spotted in clear skies away from glare ($timeOfDay sky, ${(f * 100).toStringAsFixed(0)}% lit).',
      );
    } else {
      // Clear daytime visibility!
      final isMorning = time.hour < 12;
      final period = isMorning ? 'Morning' : 'Afternoon';
      return MoonVisibility(
        category: MoonVisibilityCategory.visibleDaytime,
        isVisibleToNakedEye: true,
        angularSeparationDeg: sepDeg,
        statusText: 'Visible in $period Sky',
        shortBadge: 'Visible in $period',
        detailExplanation:
            'Sufficiently illuminated (${(f * 100).toStringAsFixed(0)}%) and separated from Sun (${sepDeg.toStringAsFixed(0)}°) to be seen by naked eye in daylight.',
      );
    }
  } else if (isCivilTwilight) {
    if (f < 0.02 || sepDeg < 8.0) {
      return MoonVisibility(
        category: MoonVisibilityCategory.newMoonInvisible,
        isVisibleToNakedEye: false,
        angularSeparationDeg: sepDeg,
        statusText: 'Not Visible (New Moon in Twilight)',
        shortBadge: 'Invisible to Eye',
        detailExplanation:
            'Too close to New Moon phase to be discerned against the twilight glow.',
      );
    } else {
      return MoonVisibility(
        category: MoonVisibilityCategory.visibleTwilight,
        isVisibleToNakedEye: true,
        angularSeparationDeg: sepDeg,
        statusText: 'Visible in Twilight Sky',
        shortBadge: 'Visible to Eye',
        detailExplanation:
            'Visible in the twilight sky before sunrise / after sunset.',
      );
    }
  } else {
    // Night sky (Sun <= -6°)
    if (f < 0.015) {
      return MoonVisibility(
        category: MoonVisibilityCategory.newMoonInvisible,
        isVisibleToNakedEye: false,
        angularSeparationDeg: sepDeg,
        statusText: 'Not Visible (New Moon)',
        shortBadge: 'Invisible (New Moon)',
        detailExplanation:
            'Moon is in New Moon phase (unlit disk facing Earth).',
      );
    } else {
      return MoonVisibility(
        category: MoonVisibilityCategory.visibleNight,
        isVisibleToNakedEye: true,
        angularSeparationDeg: sepDeg,
        statusText: 'Visible in Night Sky',
        shortBadge: 'Visible to Eye',
        detailExplanation:
            'Clearly visible in the dark night sky (${(f * 100).toStringAsFixed(0)}% lit).',
      );
    }
  }
}
