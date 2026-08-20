import 'buddhavassa_data.dart';
import 'package:intl/intl.dart';

class BuddhavassaCalculation {
  final int bYear;
  final int bMonth;
  final int bDay; // tithi
  final String paliString;
  final String poyaStatus;
  final bool isPoyaDay;
  final int statusAvasitthaD; // days to next poya

  final int atikkantaY;
  final int atikkantaM;
  final int atikkantaD;

  final int avasitthaY;
  final int avasitthaM;
  final int avasitthaD;

  final String poyaMessage;
  final PoyaDay? nextPoya;

  BuddhavassaCalculation({
    required this.bYear,
    required this.bMonth,
    required this.bDay,
    required this.paliString,
    required this.poyaStatus,
    required this.isPoyaDay,
    required this.statusAvasitthaD,
    required this.atikkantaY,
    required this.atikkantaM,
    required this.atikkantaD,
    required this.avasitthaY,
    required this.avasitthaM,
    required this.avasitthaD,
    required this.poyaMessage,
    this.nextPoya,
  });
}

class BuddhavassaLocalization {
  final String Function(String animal, String season, String month,
      String paksha, String tithi, String weekday) paliTemplate;
  final String poyaSuffix;
  final String fullMoon;
  final String newMoon;
  final String waxing8th;
  final String waning8th;
  final String pakshaSukka;
  final String pakshaKanha;
  final List<String> animals;
  final Map<String, String> seasons;
  final List<String> weekDays;
  final Map<String, String> months;
  final List<String> tithis;
  final String Function(int days, String poyaName) daysToPoya;

  BuddhavassaLocalization({
    required this.paliTemplate,
    required this.poyaSuffix,
    required this.fullMoon,
    required this.newMoon,
    required this.waxing8th,
    required this.waning8th,
    required this.pakshaSukka,
    required this.pakshaKanha,
    required this.animals,
    required this.seasons,
    required this.weekDays,
    required this.months,
    required this.tithis,
    required this.daysToPoya,
  });
}

class BuddhavassaCalculator {
  static bool _isValidMoonPhase(String phase, {bool include8th = false}) {
    if (phase == "FullMoon" || phase == "NewMoon") return true;
    if (include8th && (phase == "Waxing8th" || phase == "Waning8th")) return true;
    return false;
  }

  static BuddhavassaCalculation calculate(
      DateTime d, BuddhavassaLocalization loc, List<PoyaDay> poyaList,
      {bool includeEighthDays = false}) {
    // Normalize input date to midnight
    d = DateTime(d.year, d.month, d.day);
    final String ds = DateFormat('yyyy-MM-dd').format(d);
    final int time = d.millisecondsSinceEpoch;
    final int y = d.year;

    final String vDString =
        BuddhavassaData.vesakDates[y.toString()] ?? '$y-05-01';
    final DateTime vesakDate = DateTime.parse(vDString);
    final int vD = vesakDate.millisecondsSinceEpoch;

    final int bY = (time <= vD) ? (y + 543) : (y + 544);

    // Find past full moons
    final pastFullMoons = poyaList.where((p) {
      return p.moonPhase == "FullMoon" &&
          DateTime.parse(p.date).millisecondsSinceEpoch < time;
    }).toList();

    final PoyaDay? lastFullMoon =
        pastFullMoons.isNotEmpty ? pastFullMoons.last : null;

    int tithi = 1;
    if (lastFullMoon != null) {
      final DateTime lastFmDate = DateTime.parse(lastFullMoon.date);
      tithi = d.difference(lastFmDate).inDays;
    }
    if (tithi <= 0) tithi = 1;

    // Find next Amāvaka & Full Moon for Pakkha
    final nextAmavakas = poyaList
        .where((p) =>
            p.moonPhase == "NewMoon" &&
            DateTime.parse(p.date).millisecondsSinceEpoch >= time)
        .toList();
    final nextFullMoons = poyaList
        .where((p) =>
            p.moonPhase == "FullMoon" &&
            DateTime.parse(p.date).millisecondsSinceEpoch >= time)
        .toList();

    final nextA = nextAmavakas.isNotEmpty ? nextAmavakas.first : null;
    final nextF = nextFullMoons.isNotEmpty ? nextFullMoons.first : null;

    String paksha = loc.pakshaSukka;
    if (nextA != null &&
        (nextF == null ||
            DateTime.parse(nextA.date).millisecondsSinceEpoch <=
                DateTime.parse(nextF.date).millisecondsSinceEpoch)) {
      paksha = loc.pakshaKanha;
    }

    final int lastV = time <= vD ? y - 1 : y;
    final String lastVString =
        BuddhavassaData.vesakDates[lastV.toString()] ?? '$lastV-05-01';
    final String nextVString =
        BuddhavassaData.vesakDates[(lastV + 1).toString()] ??
            '${lastV + 1}-05-01';

    final int lastVD = DateTime.parse(lastVString).millisecondsSinceEpoch;
    final int nextVD = DateTime.parse(nextVString).millisecondsSinceEpoch;

    final int totM = ((nextVD - lastVD) / 2551442400).round();

    int bM = 1;
    if (nextF != null) {
      bM = ((DateTime.parse(nextF.date).millisecondsSinceEpoch - lastVD) /
              2551442400)
          .round();
    }
    bM = (bM <= 0) ? totM : (bM > totM ? totM : bM);

    // Only consider actual Full/New moons (or 8th days if enabled) for the "Next Poya" calculation
    final nextPoyas = poyaList
        .where((p) =>
            _isValidMoonPhase(p.moonPhase, include8th: includeEighthDays) &&
            DateTime.parse(p.date).millisecondsSinceEpoch >= time)
        .toList();
    final PoyaDay? nextP = nextPoyas.isNotEmpty ? nextPoyas.first : null;

    // Ensure today is only marked as Poya if it is an actual Full/New moon (or 8th day if enabled)
    final todayPoyas = poyaList
        .where((p) =>
            p.date == ds &&
            _isValidMoonPhase(p.moonPhase, include8th: includeEighthDays))
        .toList();
    final PoyaDay? todayP = todayPoyas.isNotEmpty ? todayPoyas.first : null;

    String poyaName = "";
    if (todayP != null) {
      if (todayP.moonPhase == "FullMoon") {
        poyaName = loc.fullMoon;
      } else if (todayP.moonPhase == "NewMoon") {
        poyaName = loc.newMoon;
      } else if (todayP.moonPhase == "Waxing8th") {
        poyaName = loc.waxing8th;
      } else if (todayP.moonPhase == "Waning8th") {
        poyaName = loc.waning8th;
      }
    }

    final String poyaStatus =
        poyaName.isNotEmpty ? poyaName + loc.poyaSuffix : "";

    // The new month and season start the day after the full moon,
    // so we determine the current month/season based on the Next Full Moon.
    final String rawS = nextF != null
        ? nextF.season
        : (nextP != null ? nextP.season : "Hemanta");

    String seasonKey = rawS;

    final String displayS = loc.seasons[seasonKey] ?? seasonKey;
    final String animal = loc.animals[bY % 12];

    final String sMonth =
        nextF != null ? nextF.month : (nextP != null ? nextP.month : "Vesakha");
    final String displayMonth = loc.months[sMonth] ?? sMonth;

    int paliIndex = tithi;
    String finalPaksha = paksha;

    // Corrected paliIndex: find past amavakas and adjust paliIndex when Sukka
    final pastAmavakas = poyaList
        .where((p) =>
            p.moonPhase == "NewMoon" &&
            DateTime.parse(p.date).millisecondsSinceEpoch < time)
        .toList();
    final PoyaDay? lastAmavaka =
        pastAmavakas.isNotEmpty ? pastAmavakas.last : null;

    if (finalPaksha == loc.pakshaSukka && lastAmavaka != null) {
      final DateTime amavakaDate = DateTime.parse(lastAmavaka.date);
      final DateTime amavakaNorm =
          DateTime(amavakaDate.year, amavakaDate.month, amavakaDate.day);
      paliIndex = d.difference(amavakaNorm).inDays;
    }

    if (paliIndex <= 0) paliIndex = 1;

    final String tithiWord = loc.tithis[(paliIndex - 1) % 15];

    final List<String> weekDays = loc.weekDays;
    final String weekDay = weekDays[d.weekday % 7];

    final String paliString = loc.paliTemplate(
        animal, displayS, displayMonth, finalPaksha, tithiWord, weekDay);

    int currentAvasitthaD = 0;
    String poyaMessage = "";
    bool isPoyaDay = false;
    int statusAvasitthaD = 0;

    if (nextP != null) {
      final DateTime targetD = DateTime.parse(nextP.date);
      statusAvasitthaD = targetD.difference(d).inDays;

      final String poyaNameLocalized = nextP.moonPhase
          .replaceAll("FullMoon", loc.fullMoon)
          .replaceAll("NewMoon", loc.newMoon)
          .replaceAll("Waxing8th", loc.waxing8th)
          .replaceAll("Waning8th", loc.waning8th);

      if (statusAvasitthaD == 0) {
        isPoyaDay = true;
        poyaMessage = poyaNameLocalized;
      } else {
        poyaMessage = loc.daysToPoya(statusAvasitthaD, poyaNameLocalized);
      }
    }

    if (nextF != null) {
      final DateTime fullMoonD = DateTime.parse(nextF.date);
      currentAvasitthaD = fullMoonD.difference(d).inDays;
    }

    return BuddhavassaCalculation(
      bYear: bY,
      bMonth: bM,
      bDay: tithi,
      paliString: paliString,
      poyaStatus: poyaStatus,
      isPoyaDay: isPoyaDay,
      statusAvasitthaD: statusAvasitthaD,
      atikkantaY: bY - 1,
      atikkantaM: bM - 1,
      atikkantaD: tithi - 1,
      avasitthaY: 5000 - bY,
      avasitthaM: totM - bM,
      avasitthaD: currentAvasitthaD,
      poyaMessage: poyaMessage,
      nextPoya: nextP,
    );
  }
}
