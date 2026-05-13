import 'package:flutter/services.dart' show rootBundle;

enum CalendarTradition { sriLanka, thai, myanmar }

class PoyaDay {
  final String date;
  final String moonPhase;
  final String season;
  final String month;
  final String poyaName;
  final String pakkhaType;
  final String special;

  const PoyaDay({
    required this.date,
    required this.moonPhase,
    required this.season,
    required this.month,
    required this.poyaName,
    required this.pakkhaType,
    required this.special,
  });
}

class BuddhavassaData {
  static final Map<CalendarTradition, List<PoyaDay>> _calendars = {
    CalendarTradition.sriLanka: [],
    CalendarTradition.thai: [],
    CalendarTradition.myanmar: [],
  };

  static String paliTemplate(String template, String a, String s, String m,
      String p, String t, String w) {
    return template
        .replaceAll('\$a', a)
        .replaceAll('\$s', s)
        .replaceAll('\$m', m)
        .replaceAll('\$p', p)
        .replaceAll('\$t', t)
        .replaceAll('\$w', w);
  }

  static const Map<String, String> vesakDates = {
    '2025': '2025-05-12',
    '2026': '2026-05-31',
    '2027': '2027-05-20',
    '2028': '2028-05-08',
    '2029': '2029-05-27',
    '2030': '2030-05-16',
    '2031': '2031-05-05',
    '2032': '2032-05-23',
    '2033': '2033-05-13',
    '2034': '2034-05-02',
    '2035': '2035-05-21',
    '2036': '2036-05-10',
    '2037': '2037-05-29',
    '2038': '2038-05-18',
    '2039': '2039-05-07',
    '2040': '2040-05-25'
  };

  static Future<void> init() async {
    _calendars[CalendarTradition.sriLanka] =
        await _loadCsv('assets/calendars/sri_lanka.csv');
    _calendars[CalendarTradition.thai] =
        await _loadCsv('assets/calendars/thai.csv');
    _calendars[CalendarTradition.myanmar] =
        await _loadCsv('assets/calendars/myanmar.csv');
  }

  static Future<List<PoyaDay>> _loadCsv(String path) async {
    final List<PoyaDay> list = [];
    try {
      final String data = await rootBundle.loadString(path);
      final List<String> lines = data.split('\n');
      for (int i = 1; i < lines.length; i++) {
        final String line = lines[i].trim();
        if (line.isEmpty) continue;
        final List<String> parts = line.split(',');
        if (parts.length >= 5) {
          list.add(PoyaDay(
            date: parts[0].trim(),
            moonPhase: parts[1].trim(),
            season: parts[2].trim(),
            month: parts[3].trim(),
            poyaName: parts[4].trim(),
            pakkhaType: parts.length > 5 ? parts[5].trim() : '',
            special: parts.length > 6 ? parts[6].trim() : '',
          ));
        }
      }
    } catch (e) {
      print('Error loading calendar data $path: $e');
    }
    return list;
  }

  static List<PoyaDay> getPoyaList(CalendarTradition tradition) {
    return _calendars[tradition] ?? _calendars[CalendarTradition.sriLanka]!;
  }
}
