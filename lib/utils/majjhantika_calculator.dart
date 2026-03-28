import 'dart:math';

/// Exact Solar Noon Calculator for Majjhantika
/// Based on the NOAA Solar Calculator / Jean Meeus Astronomical Algorithms
class MajjhantikaCalculator {
  static double _degToRad(double deg) => deg * pi / 180.0;
  static double _radToDeg(double rad) => rad * 180.0 / pi;

  /// Returns the exact DateTime of solar noon (majjhantika) to the second.
  /// [date] The current local date.
  /// [longitude] The GPS longitude in decimal degrees (East is positive, West is negative).
  static DateTime getExactSolarNoon(DateTime date, double longitude) {
    // 1. Calculate Timezone Offset in hours automatically from the device
    double timeZoneOffset = date.timeZoneOffset.inMinutes / 60.0;

    // 2. Calculate Julian Day for the date (using 12:00 UTC as the daily anchor)
    DateTime utcDate = date.toUtc();
    int year = utcDate.year;
    int month = utcDate.month;
    int day = utcDate.day;

    if (month <= 2) {
      year -= 1;
      month += 12;
    }

    int A = year ~/ 100;
    int B = 2 - A + (A ~/ 4);

// Calculate the fractional day to capture the exact hour and minute
    double fractionalDay = utcDate.hour / 24.0 +
        utcDate.minute / 1440.0 +
        utcDate.second / 86400.0;

    double JD = (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        fractionalDay +
        B -
        1524.5;

    // 3. Calculate Julian Century
    double T = (JD - 2451545.0) / 36525.0;

    // 4. Geometric Mean Longitude of Sun (degrees)
    double L0 = (280.46646 + T * (36000.76983 + T * 0.0003032)) % 360.0;

    // 5. Geometric Mean Anomaly of Sun (degrees)
    double M = 357.52911 + T * (35999.05029 - 0.0001537 * T);

    // 6. Eccentricity of Earth Orbit
    double e = 0.016708634 - T * (0.000042037 + 0.0000001267 * T);

    // 7. Mean Obliquity of Ecliptic (degrees)
    double seconds = 21.448 - T * (46.815 + T * (0.00059 - T * 0.001813));
    double e0 = 23.0 + (26.0 + seconds / 60.0) / 60.0;

    // 8. Obliquity Correction (degrees)
    double omega = 125.04 - 1934.136 * T;
    double eCalc = e0 + 0.00256 * cos(_degToRad(omega));

    // 9. Calculate variable y
    double y = tan(_degToRad(eCalc) / 2.0);
    y *= y;

    // 10. Equation of Time (in radians, then converted to minutes)
    double sin2L0 = sin(2.0 * _degToRad(L0));
    double sinM = sin(_degToRad(M));
    double cos2L0 = cos(2.0 * _degToRad(L0));
    double sin4L0 = sin(4.0 * _degToRad(L0));
    double sin2M = sin(2.0 * _degToRad(M));

    double eotRad = y * sin2L0 -
        2.0 * e * sinM +
        4.0 * e * y * sinM * cos2L0 -
        0.5 * y * y * sin4L0 -
        1.25 * e * e * sin2M;

    double eotMinutes = _radToDeg(eotRad) * 4.0;

    // 11. Calculate Exact Solar Noon in minutes from midnight local time
    double solarNoonMinutes =
        720.0 - (4.0 * longitude) - eotMinutes + (timeZoneOffset * 60.0);

    // 12. Format into hours, minutes, seconds
    int noonHour = (solarNoonMinutes / 60.0).floor();
    int noonMinute = (solarNoonMinutes % 60.0).floor();
    int noonSecond = ((solarNoonMinutes * 60.0) % 60.0).round();

    // 13. Handle potential rounding edge cases at exactly 60 seconds
    if (noonSecond >= 60) {
      noonSecond = 0;
      noonMinute += 1;
    }
    if (noonMinute >= 60) {
      noonMinute = 0;
      noonHour += 1;
    }

    return DateTime(
        date.year, date.month, date.day, noonHour, noonMinute, noonSecond);
  }
}
