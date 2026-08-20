import 'package:flutter_test/flutter_test.dart';
import 'package:buddhist_sun/utils/buddhavassa_data.dart';
import 'package:buddhist_sun/utils/buddhavassa_calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await BuddhavassaData.init();
  });

  test('8th day calculation generates valid 8th days for all traditions', () {
    for (final tradition in CalendarTradition.values) {
      final baseList = BuddhavassaData.getPoyaList(tradition, includeEighthDays: false);
      final listWith8th = BuddhavassaData.getPoyaList(tradition, includeEighthDays: true);

      // Verify that listWith8th has more elements than baseList
      expect(listWith8th.length, greaterThan(baseList.length));

      // Verify that all 8th days are +8 days from the previous moon phase
      final moonPhaseDays = baseList
          .where((p) => p.moonPhase == "FullMoon" || p.moonPhase == "NewMoon")
          .toList();

      for (int i = 0; i < moonPhaseDays.length - 1; i++) {
        final prev = moonPhaseDays[i];
        final curr = moonPhaseDays[i + 1];

        final prevDate = DateTime.parse(prev.date);
        final currDate = DateTime.parse(curr.date);
        final eighthDate = prevDate.add(const Duration(days: 8));
        final eighthDateStr =
            '${eighthDate.year.toString().padLeft(4, '0')}-${eighthDate.month.toString().padLeft(2, '0')}-${eighthDate.day.toString().padLeft(2, '0')}';

        final expectedPhase =
            (curr.moonPhase == "FullMoon") ? "Waxing8th" : "Waning8th";

        final eighthEntry = listWith8th.firstWhere(
          (p) => p.date == eighthDateStr,
          orElse: () => throw Exception('Missing 8th day for $eighthDateStr in $tradition'),
        );

        expect(eighthEntry.moonPhase, equals(expectedPhase));
        expect(eighthEntry.pakkhaType, equals("8"));
        expect(eighthEntry.month, equals(curr.month));
        expect(eighthEntry.season, equals(curr.season));

        // Check difference to ending moon phase
        final diffToEnd = currDate.difference(eighthDate).inDays;
        final totalDiff = currDate.difference(prevDate).inDays;
        if (totalDiff == 15) {
          expect(diffToEnd, equals(7));
        } else if (totalDiff == 14) {
          expect(diffToEnd, equals(6));
        }
      }
    }
  });

  test('BuddhavassaCalculator recognizes 8th day when includeEighthDays is true', () {
    final listWith8th = BuddhavassaData.getPoyaList(CalendarTradition.thai, includeEighthDays: true);
    final loc = BuddhavassaLocalization(
      paliTemplate: (a, s, m, p, t, w) => '$a $s $m $p $t $w',
      poyaSuffix: ' Poya',
      fullMoon: 'Full Moon',
      newMoon: 'New Moon',
      waxing8th: 'Waxing 8th',
      waning8th: 'Waning 8th',
      pakshaSukka: 'Sukka pakkhe',
      pakshaKanha: 'Kanha pakkhe',
      animals: List.filled(12, 'Naga'),
      seasons: {'Hemanta': 'Hemanta', 'Gimhana': 'Gimhana', 'Vassana': 'Vassana'},
      weekDays: List.filled(7, 'Ravivaram'),
      months: {'Magha': 'Magha', 'Phussa': 'Phussa', 'Phagguna': 'Phagguna'},
      tithis: List.generate(15, (i) => 'Tithi ${i + 1}'),
      daysToPoya: (d, p) => '$d days to $p',
    );

    // 2026-01-11 is a Waning 8th day (between FullMoon 2026-01-03 and NewMoon 2026-01-18)
    final d = DateTime(2026, 1, 11);

    // Without 8th days: isPoyaDay should be false
    final calcWithout8th = BuddhavassaCalculator.calculate(d, loc, listWith8th, includeEighthDays: false);
    expect(calcWithout8th.isPoyaDay, isFalse);
    expect(calcWithout8th.statusAvasitthaD, equals(7)); // 7 days to New Moon

    // With 8th days: isPoyaDay should be true and status should reflect Waning 8th
    final calcWith8th = BuddhavassaCalculator.calculate(d, loc, listWith8th, includeEighthDays: true);
    expect(calcWith8th.isPoyaDay, isTrue);
    expect(calcWith8th.poyaStatus, contains('Waning 8th'));
  });
}
