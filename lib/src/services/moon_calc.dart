import 'dart:math';

class MoonCalc {
  // Calculate Julian Day
  double _getJulianDay(int year, int month, int day) {
    if (month < 3) {
      year--;
      month += 12;
    }
    int a = (year / 100).floor();
    int b = 2 - a + (a / 4).floor();
    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524.5;
  }

  // Normalize angle to be within 0 and 360 degrees
  double _normalizeDegrees(double angle) {
    while (angle < 0) angle += 360;
    while (angle > 360) angle -= 360;
    return angle;
  }

  // Calculate moon phase and illumination
  Map<String, dynamic> calculateMoonPhase(int year, int month, int day) {
    double jd = _getJulianDay(year, month, day);
    double d = jd - 2451550.1;
    double cycles = d / 29.53058867;
    double phase = _normalizeDegrees((cycles - cycles.floor()) * 360);

    // Calculate illumination (0 = New Moon, 1 = Full Moon)
    double illumination = (1 - cos(phase * pi / 180)) / 2;

    // Determine phase description
    String description;
    if (phase < 1 || phase > 359) {
      description = 'New Moon';
    } else if (phase < 50) {
      description = 'Waxing Crescent';
    } else if (phase < 101) {
      description = 'First Quarter';
    } else if (phase < 150) {
      description = 'Waxing Gibbous';
    } else if (phase < 201) {
      description = 'Full Moon';
    } else if (phase < 250) {
      description = 'Waning Gibbous';
    } else if (phase < 301) {
      description = 'Last Quarter';
    } else if (phase < 350) {
      description = 'Waning Crescent';
    } else {
      description = 'New Moon';
    }

    return {
      'illumination': illumination,
      'description': description,
      'phaseAngle': phase,
    };
  }

  double calculateMoonPhaseSimple(int year, int month, int day) {
    // long-term avg duration 29.530587981 days (coverted to seconds)
    double lp = 2551442.8015584;
    DateTime date = new DateTime(year, month, day, 20, 35, 0);
    // reference point new moon, the new moon at Jan 7th, 1970, 20:35.
    DateTime newMoon = new DateTime(1970, 1, 7, 20, 35, 0);
    double phase =
        ((date.millisecondsSinceEpoch - newMoon.millisecondsSinceEpoch) /
                1000) %
            lp;
    return (phase / (24 * 3600)).floor() + 1;
  }

  int calculateMoonPhaseWikipedia(int year, int month, int day) {
    DateTime givenDate = DateTime(year, month, day);
    DateTime knownNewMoon = DateTime(1999, 8, 11);

    // Calculate difference in days
    int daysDifference = givenDate.difference(knownNewMoon).inDays;

    // Calculate age of the moon
    double moonAge = daysDifference % 29.53059;

    return moonAge.floor();
  }
}
