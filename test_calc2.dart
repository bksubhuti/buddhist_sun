import 'package:intl/intl.dart';

class PoyaDay {
  final String date;
  final String moonPhase;
  final String season;
  final String month;
  final String poyaName;

  PoyaDay({
    required this.date,
    required this.moonPhase,
    required this.season,
    required this.month,
    required this.poyaName,
  });
}

void main() {
  final poyaList = [
    PoyaDay(date: '2026-04-16', moonPhase: 'NewMoon', season: 'Gimhana', month: 'Adhivesakha', poyaName: 'Adhivesākha'),
    PoyaDay(date: '2026-05-01', moonPhase: 'FullMoon', season: 'Gimhana', month: 'Adhivesakha', poyaName: 'Adhivesākha'),
    PoyaDay(date: '2026-05-16', moonPhase: 'NewMoon', season: 'Gimhana', month: 'Vesakha', poyaName: 'Vesākha'),
    PoyaDay(date: '2026-05-31', moonPhase: 'FullMoon', season: 'Gimhana', month: 'Vesakha', poyaName: 'Vesākha'),
    PoyaDay(date: '2026-06-14', moonPhase: 'NewMoon', season: 'Gimhana', month: 'Jettha', poyaName: 'Jeṭṭha'),
  ];

  void calc(DateTime d) {
    d = DateTime(d.year, d.month, d.day);
    final int time = d.millisecondsSinceEpoch;

    final nextPoyas = poyaList.where((p) => DateTime.parse(p.date).millisecondsSinceEpoch >= time).toList();
    final PoyaDay? nextP = nextPoyas.isNotEmpty ? nextPoyas.first : null;

    final nextSeasonEntry = nextPoyas.isNotEmpty ? nextPoyas.first : null;
    final String rawS = nextSeasonEntry != null ? nextSeasonEntry.season : "Hemanta";
    final String sMonth = nextP != null ? nextP.month : "Vesakha";

    print('${DateFormat('yyyy-MM-dd').format(d)}: Month: $sMonth, Season: $rawS');
  }

  calc(DateTime(2026, 5, 1));
  calc(DateTime(2026, 5, 2));
  calc(DateTime(2026, 5, 16));
  calc(DateTime(2026, 5, 17));
}
