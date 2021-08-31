import 'package:flutter/cupertino.dart';
import 'package:solar_calculator/solar_calculator.dart';
import 'package:solar_calculator/src/instant.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:one_context/one_context.dart';

String getNowString() {
  DateTime now = DateTime.now();
  Instant instant = Instant(
      year: now.year,
      month: now.month,
      day: now.day,
      hour: now.hour,
      timeZoneOffset: Prefs.offset);

  String nowString = 'Date: ${instant.day}.${instant.month}.${instant.year}';
  return nowString;
}

String getDawnString() {
  String sDawn = "";
  switch (Prefs.dawnVal) {
    case "Nauticle Twilight":
      sDawn = getNauticalTwilightString();
      break;
    case "Pa-Auk":
      sDawn = getSunrise40String();
      break;
    case "Na-Uyana":
      sDawn = getSunrise30String();
      break;
    case "Civil Twilight":
      sDawn = getCivilTwilightString();
      break;
    case "Sunrise":
      sDawn = getSunriseString();
      break;
  }
  return sDawn;
}

int getSafetyOffset() {
  int safetyOffset = 1;
  switch (Prefs.safety) {
    case "none":
      safetyOffset = 0;
      break;
    case "1 minute":
      safetyOffset = 1;
      break;
    case "2 minutes":
      safetyOffset = 2;
      break;
    case "3 minutes":
      safetyOffset = 3;
      break;
    case "4 minutes":
      safetyOffset = 4;
      break;
    case "5 minutes":
      safetyOffset = 5;
      break;
    case "10 minutes":
      safetyOffset = 10;
      break;
  }
  return safetyOffset;
}

SolarCalculator getSolarCalcInstant() {
  DateTime now = DateTime.now();
  var timezoneOffset = now.timeZoneOffset;

  Instant instant = Instant(
      year: now.year,
      month: now.month,
      day: now.day,
      hour: now.hour,
      timeZoneOffset: Prefs.offset);
  SolarCalculator calc = SolarCalculator(instant, Prefs.lat, Prefs.lng);
  return calc;
}

Instant getNauticalTwilight() {
  SolarCalculator calc = getSolarCalcInstant();
  return addSafety(calc.morningNauticalTwilight.begining);
}

String getNauticalTwilightString() {
  Instant inst = getNauticalTwilight();
  return '${inst.hour}:${inst.minute.toString().padLeft(2, '0')}';
}

Instant getCivilTwilight() {
  SolarCalculator calc = getSolarCalcInstant();
  return addSafety(calc.morningCivilTwilight.begining);
}

String getCivilTwilightString() {
  Instant inst = getCivilTwilight();
  return '${inst.hour}:${inst.minute.toString().padLeft(2, '0')}';
}

Instant getAstronomicalTwilight() {
  SolarCalculator calc = getSolarCalcInstant();
  return addSafety(calc.morningAstronomicalTwilight.begining);
}

String getAstronomicalTwilightString() {
  Instant inst = getAstronomicalTwilight();
  return '${inst.hour}:${inst.minute.toString().padLeft(2, '0')}';
}

Instant getSunrise30() {
  SolarCalculator calc = getSolarCalcInstant();
  Instant inst = calc.sunriseTime;
  Duration dur = Duration(minutes: 30);
  Instant instNew = inst.subtract(dur);

  return addSafety(instNew);
}

String getSunrise30String() {
  Instant inst = getSunrise30();
  return '${inst.hour}:${inst.minute.toString().padLeft(2, '0')}';
}

Instant getSunrise40() {
  SolarCalculator calc = getSolarCalcInstant();
  Instant inst = calc.sunriseTime;
  Duration dur = Duration(minutes: 40);
  Instant instNew = inst.subtract(dur);

  return addSafety(instNew);
}

String getSunrise40String() {
  Instant inst = getSunrise40();
  return '${inst.hour}:${inst.minute.toString().padLeft(2, '0')}';
}

Instant getSunrise() {
  SolarCalculator calc = getSolarCalcInstant();
  Instant inst = calc.sunriseTime;
  return addSafety(inst);
}

String getSunriseString() {
  Instant inst = getSunrise();
  return '${inst.hour}:${inst.minute.toString().padLeft(2, '0')}';
}

String getSolarNoonTimeString() {
  Instant inst = getSolarNoon();
  String s = '${inst.hour}:${inst.minute.toString().padLeft(2, '0')}';
  return s;
}

Instant getSolarNoon() {
  SolarCalculator calc = getSolarCalcInstant();
  return subtractSafety(calc.sunTransitTime);
}

Instant subtractSafety(Instant inst) {
  int safetyOffset = getSafetyOffset();
  Duration dur = Duration(minutes: safetyOffset);
  Instant instNew = inst.subtract(dur);
  return instNew;
}

// for dawnrise we want to add minutes to make it later = safer
// for noon, we subtract to finish eating later.
Instant addSafety(Instant inst) {
  int safetyOffset = getSafetyOffset();
  Duration dur = Duration(minutes: safetyOffset);
  Instant instNew = inst.add(dur);
  return instNew;
}
