import 'dart:io';

void main() {
  final lines = File('assets/calendars/sri_lanka.csv').readAsLinesSync().skip(1);
  String? lastMonth;
  String? lastSeason;
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    final parts = line.split(',');
    final phase = parts[1];
    final season = parts[2];
    final month = parts[3];
    
    if (phase == 'NewMoon') {
      lastMonth = month;
      lastSeason = season;
    } else if (phase == 'FullMoon') {
      if (lastMonth != null && lastMonth != month) {
        print('Mismatch month: NewMoon had $lastMonth, FullMoon has $month');
      }
      if (lastSeason != null && lastSeason != season) {
        print('Mismatch season: NewMoon had $lastSeason, FullMoon has $season');
      }
    }
  }
  print('Done verifying.');
}
