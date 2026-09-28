import 'package:flutter_test/flutter_test.dart';
import 'package:buddhist_sun/utils/buddhavassa_data.dart';
import 'package:buddhist_sun/utils/buddhavassa_calculator.dart';
import 'package:buddhist_sun/widgets/poya_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await BuddhavassaData.init();
  });

  test('8th day calculation generates valid 8th days for all traditions', () {
    for (final tradition in CalendarTradition.values) {
      final baseList =
          BuddhavassaData.getPoyaList(tradition, includeEighthDays: false);
      final listWith8th =
          BuddhavassaData.getPoyaList(tradition, includeEighthDays: true);

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
          orElse: () => throw Exception(
              'Missing 8th day for $eighthDateStr in $tradition'),
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

  test(
      'BuddhavassaCalculator recognizes 8th day when includeEighthDays is true',
      () {
    final listWith8th = BuddhavassaData.getPoyaList(CalendarTradition.thai,
        includeEighthDays: true);
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
      seasons: {
        'Hemanta': 'Hemanta',
        'Gimhana': 'Gimhana',
        'Vassana': 'Vassana'
      },
      weekDays: List.filled(7, 'Ravivaram'),
      months: {'Magha': 'Magha', 'Phussa': 'Phussa', 'Phagguna': 'Phagguna'},
      tithis: List.generate(15, (i) => 'Tithi ${i + 1}'),
      daysToPoya: (d, p) => '$d days to $p',
    );

    // 2026-01-11 is a Waning 8th day (between FullMoon 2026-01-03 and NewMoon 2026-01-18)
    final d = DateTime(2026, 1, 11);

    // Without 8th days: isPoyaDay should be false
    final calcWithout8th = BuddhavassaCalculator.calculate(d, loc, listWith8th,
        includeEighthDays: false);
    expect(calcWithout8th.isPoyaDay, isFalse);
    expect(calcWithout8th.statusAvasitthaD, equals(7)); // 7 days to New Moon

    // With 8th days: isPoyaDay should be true and status should reflect Waning 8th
    final calcWith8th = BuddhavassaCalculator.calculate(d, loc, listWith8th,
        includeEighthDays: true);
    expect(calcWith8th.isPoyaDay, isTrue);
    expect(calcWith8th.poyaStatus, contains('Waning 8th'));
  });

  test(
      'PoyaBottomSheet.calculateSeasonProgress counts pakkhas correctly and identically with attha ON or OFF',
      () {
    for (final tradition in CalendarTradition.values) {
      final canonicalList =
          BuddhavassaData.getPoyaList(tradition, includeEighthDays: false);
      final listWith8th =
          BuddhavassaData.getPoyaList(tradition, includeEighthDays: true);

      final datesToTest = [
        '2026-07-30', // special day (entry to Vassa)
        '2026-08-13', // 1st major Uposatha of Vassana (New Moon)
        '2026-09-26', // 4th major Uposatha of Vassana (Full Moon)
        '2026-09-27', // day after Full Moon (in 5th Pakkha)
        '2026-10-04', // 8th day (Waning 8th in 5th Pakkha)
        '2026-10-05', // day after 8th day (in 5th Pakkha)
        '2026-10-11', // 5th major Uposatha of Vassana (New Moon)
        '2026-10-12', // day after New Moon (in 6th Pakkha)
        '2026-10-19', // Waxing 8th (in 6th Pakkha)
        '2026-10-26', // 6th major Uposatha of Vassana (Full Moon)
        '2026-11-24', // 8th major Uposatha of Vassana (Full Moon)
        '2026-12-09', // 1st major Uposatha of Hemanta
        '2026-12-24', // 2nd major Uposatha of Hemanta
        '2027-01-07', // 3rd major Uposatha of Hemanta across year boundary
        '2027-01-22', // 4th major Uposatha of Hemanta
      ];

      for (final dateStr in datesToTest) {
        final yr = dateStr.substring(0, 4);

        // Calculate progress without 8th days
        final poyasOff =
            canonicalList.where((p) => p.date.startsWith(yr)).toList();
        int hlOff = poyasOff.indexWhere((p) => p.date == dateStr);
        if (hlOff < 0) {
          hlOff = poyasOff.indexWhere((p) => p.date.compareTo(dateStr) > 0);
        }
        expect(hlOff, greaterThanOrEqualTo(0),
            reason: 'Highlight index for $dateStr with 8th off in $tradition');
        final progressOff = PoyaBottomSheet.calculateSeasonProgress(
          highlightedPoya: poyasOff[hlOff],
          canonicalList: canonicalList,
        );
        expect(progressOff, isNotNull);

        // Calculate progress with 8th days
        final poyasOn =
            listWith8th.where((p) => p.date.startsWith(yr)).toList();
        int hlOn = poyasOn.indexWhere((p) => p.date == dateStr);
        if (hlOn < 0) {
          hlOn = poyasOn.indexWhere((p) => p.date.compareTo(dateStr) > 0);
        }
        expect(hlOn, greaterThanOrEqualTo(0),
            reason: 'Highlight index for $dateStr with 8th on in $tradition');
        final progressOn = PoyaBottomSheet.calculateSeasonProgress(
          highlightedPoya: poyasOn[hlOn],
          canonicalList: canonicalList,
        );
        expect(progressOn, isNotNull);

        // Pakkha counting must match identically whether attha is on or off
        expect(progressOn!.seasonName, equals(progressOff!.seasonName),
            reason: 'Season name mismatch for $dateStr in $tradition');
        expect(progressOn.pakkhaToday, equals(progressOff.pakkhaToday),
            reason:
                'pakkhaToday changed when attha turned on for $dateStr in $tradition');
        expect(progressOn.pakkhaPast, equals(progressOff.pakkhaPast),
            reason:
                'pakkhaPast changed when attha turned on for $dateStr in $tradition');
        expect(progressOn.pakkhaRemaining, equals(progressOff.pakkhaRemaining),
            reason:
                'pakkhaRemaining changed when attha turned on for $dateStr in $tradition');
        expect(progressOn.pakkhaTotal, equals(progressOff.pakkhaTotal),
            reason:
                'pakkhaTotal changed when attha turned on for $dateStr in $tradition');

        // Verify invariant: past + 1 (today) + remaining == total
        expect(progressOn.pakkhaPast + 1 + progressOn.pakkhaRemaining,
            equals(progressOn.pakkhaTotal),
            reason: 'Sum invariant violated for $dateStr in $tradition');
      }
    }
  });
}
