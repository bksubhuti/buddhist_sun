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
    '2000': '2000-05-17',
    '2001': '2001-05-07',
    '2002': '2002-05-27',
    '2003': '2003-05-15',
    '2004': '2004-06-02',
    '2005': '2005-05-22',
    '2006': '2006-05-12',
    '2007': '2007-05-31',
    '2008': '2008-05-19',
    '2009': '2009-05-08',
    '2010': '2010-05-28',
    '2011': '2011-05-17',
    '2012': '2012-06-04',
    '2013': '2013-05-24',
    '2014': '2014-05-13',
    '2015': '2015-06-01',
    '2016': '2016-05-20',
    '2017': '2017-05-10',
    '2018': '2018-05-29',
    '2019': '2019-05-18',
    '2020': '2020-05-06',
    '2021': '2021-05-26',
    '2022': '2022-05-15',
    '2023': '2023-06-03',
    '2024': '2024-05-22',
    '2025': '2025-05-12',
    '2026': '2026-05-31',
    '2027': '2027-05-20',
    '2028': '2028-05-08',
    '2029': '2029-05-27',
    '2030': '2030-05-16',
    '2031': '2031-06-04',
    '2032': '2032-05-23',
    '2033': '2033-05-13',
    '2034': '2034-06-01',
    '2035': '2035-05-21',
    '2036': '2036-05-10',
    '2037': '2037-05-29',
    '2038': '2038-05-18',
    '2039': '2039-05-07',
    '2040': '2040-05-25',
    '2041': '2041-05-14',
    '2042': '2042-06-02',
    '2043': '2043-05-22',
    '2044': '2044-05-11',
    '2045': '2045-05-30',
    '2046': '2046-05-19',
    '2047': '2047-05-10',
    '2048': '2048-05-27',
    '2049': '2049-05-17',
    '2050': '2050-06-04',
    '2051': '2051-05-24',
    '2052': '2052-05-12',
    '2053': '2053-06-01',
    '2054': '2054-05-21',
    '2055': '2055-05-11',
    '2056': '2056-05-28',
    '2057': '2057-05-18',
    '2058': '2058-05-07',
    '2059': '2059-05-26',
    '2060': '2060-05-15',
    '2061': '2061-05-04',
    '2062': '2062-05-23',
    '2063': '2063-05-13',
    '2064': '2064-05-30',
    '2065': '2065-05-19',
    '2066': '2066-05-09',
    '2067': '2067-05-28',
    '2068': '2068-05-17',
    '2069': '2069-05-05',
    '2070': '2070-05-24',
    '2071': '2071-05-13',
    '2072': '2072-06-01',
    '2073': '2073-05-21',
    '2074': '2074-05-10',
    '2075': '2075-05-30',
    '2076': '2076-05-18',
    '2077': '2077-05-07',
    '2078': '2078-05-26',
    '2079': '2079-05-15',
    '2080': '2080-05-03',
    '2081': '2081-05-22',
    '2082': '2082-05-11',
    '2083': '2083-05-30',
    '2084': '2084-05-19',
    '2085': '2085-05-09',
    '2086': '2086-05-27',
    '2087': '2087-05-17',
    '2088': '2088-05-05',
    '2089': '2089-05-24',
    '2090': '2090-05-13',
    '2091': '2091-05-02',
    '2092': '2092-05-21',
    '2093': '2093-05-10',
    '2094': '2094-05-29',
    '2095': '2095-05-19',
    '2096': '2096-05-07',
    '2097': '2097-05-26',
    '2098': '2098-05-15',
    '2099': '2099-05-04',
    '2100': '2100-05-23',
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
