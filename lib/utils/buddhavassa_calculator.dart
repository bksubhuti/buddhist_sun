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
  final String Function(String a, String s, String m, String p, String t, String w) paliTemplate;
  final String poyaSuffix;
  final String pakshaSukka;
  final String pakshaKanha;
  final List<String> animals;
  final Map<String, String> seasons;
  final List<String> weekDays;
  final String Function(int days, String poyaName) daysToPoya;

  BuddhavassaLocalization({
    required this.paliTemplate,
    required this.poyaSuffix,
    required this.pakshaSukka,
    required this.pakshaKanha,
    required this.animals,
    required this.seasons,
    required this.weekDays,
    required this.daysToPoya,
  });
}

class BuddhavassaCalculator {
  static BuddhavassaCalculation calculate(DateTime d, String lang, BuddhavassaLocalization loc) {
    // Normalize input date to midnight
    d = DateTime(d.year, d.month, d.day);
    final String ds = DateFormat('yyyy-MM-dd').format(d);
    final int time = d.millisecondsSinceEpoch;
    final int y = d.year;

    final String vDString = BuddhavassaData.vesakDates[y.toString()] ?? '$y-05-01';
    final DateTime vesakDate = DateTime.parse(vDString);
    final int vD = vesakDate.millisecondsSinceEpoch;

    final int bY = (time <= vD) ? (y + 543) : (y + 544);

    // Find past full moons
    final pastFullMoons = BuddhavassaData.poyaList.where((p) {
      return p.t == "පසළොස්වක" && DateTime.parse(p.d).millisecondsSinceEpoch < time;
    }).toList();
    
    final PoyaDay? lastFullMoon = pastFullMoons.isNotEmpty ? pastFullMoons.last : null;
    
    int tithi = 1;
    if (lastFullMoon != null) {
      final int lastFmTime = DateTime.parse(lastFullMoon.d).millisecondsSinceEpoch;
      tithi = ((time - lastFmTime) / 86400000).round();
    }
    if (tithi == 0) tithi = 1;

    // Find next Amavaka & Full Moon for Paksha
    final nextAmavakas = BuddhavassaData.poyaList.where((p) => p.t == "අමාවක" && DateTime.parse(p.d).millisecondsSinceEpoch >= time).toList();
    final nextFullMoons = BuddhavassaData.poyaList.where((p) => p.t == "පසළොස්වක" && DateTime.parse(p.d).millisecondsSinceEpoch >= time).toList();
    
    final nextA = nextAmavakas.isNotEmpty ? nextAmavakas.first : null;
    final nextF = nextFullMoons.isNotEmpty ? nextFullMoons.first : null;
    
    String paksha = loc.pakshaSukka;
    if (nextA != null && (nextF == null || DateTime.parse(nextA.d).millisecondsSinceEpoch <= DateTime.parse(nextF.d).millisecondsSinceEpoch)) {
      paksha = loc.pakshaKanha;
    }

    final int lastV = time <= vD ? y - 1 : y;
    final String lastVString = BuddhavassaData.vesakDates[lastV.toString()] ?? '$lastV-05-01';
    final String nextVString = BuddhavassaData.vesakDates[(lastV + 1).toString()] ?? '${lastV+1}-05-01';
    
    final int lastVD = DateTime.parse(lastVString).millisecondsSinceEpoch;
    final int nextVD = DateTime.parse(nextVString).millisecondsSinceEpoch;
    
    final int totM = ((nextVD - lastVD) / 2551442400).round();

    int bM = 1;
    if (nextF != null) {
      bM = ((DateTime.parse(nextF.d).millisecondsSinceEpoch - lastVD) / 2551442400).round();
    }
    bM = (bM <= 0) ? totM : (bM > totM ? totM : bM);

    final nextPoyas = BuddhavassaData.poyaList.where((p) => DateTime.parse(p.d).millisecondsSinceEpoch >= time).toList();
    final PoyaDay? nextP = nextPoyas.isNotEmpty ? nextPoyas.first : null;

    final todayPoyas = BuddhavassaData.poyaList.where((p) => p.d == ds).toList();
    final PoyaDay? todayP = todayPoyas.isNotEmpty ? todayPoyas.first : null;
    
    String poyaName = "";
    if (todayP != null) {
      if (lang == 'en') {
        poyaName = (todayP.t == "පසළොස්වක") ? "Full Moon" : "Amāvaka";
      } else {
        poyaName = todayP.t;
      }
    }
    
    final String poyaStatus = poyaName.isNotEmpty ? poyaName + loc.poyaSuffix : "";

    final Map<String, String> monthMap = {
      "මාඝ": "Māgha", "ඵග්ගුන": "Phagguna", "චිත්ත": "Citta",
      "අධිවේසාඛ": "Adhivesākha", "වේසාඛ": "Vesākha", "ජෙට්ඨ": "Jeṭṭha",
      "ආසාළ්හ": "Āsāḷha", "සාවන": "Sāvana", "පොට්ඨපාද": "Poṭṭhapāda",
      "අස්සයුජ": "Assayuja", "කත්තික": "Kattika", "මාඝසිර": "Māghasira", "ඵුස්ස": "Phussa"
    };

    final pastPoyas = BuddhavassaData.poyaList.where((p) => DateTime.parse(p.d).millisecondsSinceEpoch <= time).toList();
    final PoyaDay? seasonEntry = pastPoyas.isNotEmpty ? pastPoyas.last : null;
    final String rawS = seasonEntry != null ? seasonEntry.r : "හේමන්ත";

    String seasonKey = 'Hemanta';
    if (rawS == "ගිම්හාන") {
      seasonKey = "Gimhana";
    } else if (rawS == "වස්සාන") {
      seasonKey = "Vassana";
    } else if (rawS == "නැවත හේමන්ත") {
      seasonKey = "ReHemanta";
    }

    final String displayS = loc.seasons[seasonKey] ?? seasonKey;
    
    final String animal = loc.animals[bY % 12];

    final String sMonth = nextP != null ? nextP.m : "වේසාඛ";
    final String displayMonth = (lang == 'en') ? (monthMap[sMonth] ?? sMonth) : sMonth;

    int paliIndex = tithi;
    String finalPaksha = paksha;

    final currentAmavakas = BuddhavassaData.poyaList.where((p) {
      final pDate = DateTime.parse(p.d);
      return p.t == "අමාවක" && pDate.month == d.month && pDate.year == d.year;
    }).toList();
    
    final PoyaDay? currentAmavaka = currentAmavakas.isNotEmpty ? currentAmavakas.first : null;

    if (currentAmavaka != null) {
      final DateTime amavakaDate = DateTime.parse(currentAmavaka.d);
      if (d.isAfter(amavakaDate)) {
        finalPaksha = loc.pakshaSukka;
        final int diffTime = d.millisecondsSinceEpoch - amavakaDate.millisecondsSinceEpoch;
        paliIndex = (diffTime / (1000 * 60 * 60 * 24)).round();
      } else {
        finalPaksha = loc.pakshaKanha;
        paliIndex = tithi;
      }
    }

    if (paliIndex < 0 || paliIndex > 15) {
      paliIndex = 15; // default to 15 if out of bounds somehow
    }

    final String tithiWord = (lang == 'si') 
      ? BuddhavassaData.tithiPaliS[paliIndex] 
      : BuddhavassaData.tithiPaliE[paliIndex];

    final List<String> weekDays = loc.weekDays;
    final String weekDay = weekDays[d.weekday % 7]; 

    final String paliString = loc.paliTemplate(animal, displayS, displayMonth, finalPaksha, tithiWord, weekDay);

    int currentAvasitthaD = 0;
    String poyaMessage = "";
    bool isPoyaDay = false;
    int statusAvasitthaD = 0;

    if (nextP != null) {
      final DateTime targetD = DateTime.parse(nextP.d);
      statusAvasitthaD = ((targetD.millisecondsSinceEpoch - d.millisecondsSinceEpoch) / (1000 * 60 * 60 * 24)).round();

      if (statusAvasitthaD == 0) {
        isPoyaDay = true;
        poyaMessage = (lang == 'si') 
          ? nextP.t 
          : nextP.t.replaceAll("පසළොස්වක", "Full Moon").replaceAll("අමාවක", "New Moon");
      } else {
        final String poyaNameEN = (lang == 'si') 
          ? nextP.t 
          : nextP.t.replaceAll("පසළොස්වක", "Full Moon").replaceAll("අමාවක", "New Moon");
        poyaMessage = loc.daysToPoya(statusAvasitthaD, poyaNameEN);
      }
    }

    if (nextF != null) {
      final DateTime fullMoonD = DateTime.parse(nextF.d);
      currentAvasitthaD = ((fullMoonD.millisecondsSinceEpoch - d.millisecondsSinceEpoch) / (1000 * 60 * 60 * 24)).round();
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
