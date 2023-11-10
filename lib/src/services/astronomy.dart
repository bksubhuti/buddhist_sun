import 'dart:math';
import 'package:timezone/timezone.dart';

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
  double T = calculateJulianCenturies(julianDate);
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
