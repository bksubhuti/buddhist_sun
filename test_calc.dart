import 'lib/utils/buddhavassa_calculator.dart';
import 'lib/utils/buddhavassa_data.dart';
import 'dart:io';

void main() async {
  // We need a dummy loc
  final loc = BuddhavassaLocalization(
    paliTemplate: (a, s, m, p, t, w) => '$a $s $m $p $t $w',
    poyaSuffix: ' Poya',
    fullMoon: 'Full Moon',
    newMoon: 'New Moon',
    pakshaSukka: 'Sukka',
    pakshaKanha: 'Kanha',
    animals: ['A0','A1','A2','A3','A4','A5','A6','A7','A8','A9','A10','A11'],
    seasons: {'Hemanta':'Hemanta', 'Gimhana':'Gimhana', 'Vassana':'Vassana'},
    weekDays: ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'],
    months: {},
    tithis: ['T0','T1','T2','T3','T4','T5','T6','T7','T8','T9','T10','T11','T12','T13','T14','T15'],
    daysToPoya: (d, p) => '$d to $p',
  );

  final poyaList = [
    PoyaDay(date: '2026-04-16', moonPhase: 'NewMoon', season: 'Gimhana', month: 'Adhivesakha', poyaName: 'Adhivesākha'),
    PoyaDay(date: '2026-05-01', moonPhase: 'FullMoon', season: 'Gimhana', month: 'Adhivesakha', poyaName: 'Adhivesākha'),
    PoyaDay(date: '2026-05-16', moonPhase: 'NewMoon', season: 'Gimhana', month: 'Vesakha', poyaName: 'Vesākha'),
    PoyaDay(date: '2026-05-31', moonPhase: 'FullMoon', season: 'Gimhana', month: 'Vesakha', poyaName: 'Vesākha'),
    PoyaDay(date: '2026-06-14', moonPhase: 'NewMoon', season: 'Gimhana', month: 'Jettha', poyaName: 'Jeṭṭha'),
  ];

  final d1 = DateTime(2026, 5, 1);
  final d2 = DateTime(2026, 5, 2);
  final d3 = DateTime(2026, 5, 16);
  final d4 = DateTime(2026, 5, 17);

  final c1 = BuddhavassaCalculator.calculate(d1, loc, poyaList);
  final c2 = BuddhavassaCalculator.calculate(d2, loc, poyaList);
  final c3 = BuddhavassaCalculator.calculate(d3, loc, poyaList);
  final c4 = BuddhavassaCalculator.calculate(d4, loc, poyaList);

  print('2026-05-01 (Full Moon): \${c1.paliString}');
  print('2026-05-02 (Day After): \${c2.paliString}');
  print('2026-05-16 (New Moon): \${c3.paliString}');
  print('2026-05-17 (Day After): \${c4.paliString}');
}
