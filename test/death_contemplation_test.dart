import 'package:flutter_test/flutter_test.dart';
import 'package:buddhist_sun/utils/death_contemplation_calculator.dart';

void main() {
  group('DeathContemplationCalculator', () {
    test('returns unconfigured when birthDate is null', () {
      final result = DeathContemplationCalculator.calculate(
        birthDate: null,
        lifeExpectancyYears: 80,
      );

      expect(result.isConfigured, isFalse);
      expect(result.isElapsed, isFalse);
      expect(result.years, equals(0));
      expect(result.totalDaysRemaining, equals(0));
    });

    test('calculates correct remaining time components for known future target', () {
      final birthDate = DateTime(1990, 6, 15, 0, 0, 0);
      final lifeExpectancy = 80; // Target is 2070-06-15 00:00:00
      final currentTime = DateTime(2026, 8, 23, 14, 30, 15);

      final result = DeathContemplationCalculator.calculate(
        birthDate: birthDate,
        lifeExpectancyYears: lifeExpectancy,
        currentTime: currentTime,
      );

      expect(result.isConfigured, isTrue);
      expect(result.isElapsed, isFalse);
      expect(result.birthDate, equals(birthDate));
      expect(result.targetDate, equals(DateTime(2070, 6, 15, 0, 0, 0)));
      expect(result.lifeExpectancyYears, equals(80));

      // Check that adding the components to currentTime equals targetDate
      // 2026-08-23 14:30:15 + years, months, days, hours, mins, secs = 2070-06-15 00:00:00
      expect(result.years, equals(43)); // 2026 + 43 = 2069
      expect(result.months, equals(9)); // 2069-08-23 + 9 months = 2070-05-23
      expect(result.days, equals(22)); // 2070-05-23 to 2070-06-14 = 22 days
      expect(result.hours, equals(9)); // 14:30:15 to 00:00:00 next day = 9 hrs 29 mins 45 secs
      expect(result.minutes, equals(29));
      expect(result.seconds, equals(45));

      expect(result.totalDaysRemaining, greaterThan(0));
      expect(result.totalDaysLived, greaterThan(0));
      expect(result.progressFraction, inInclusiveRange(0.0, 1.0));
    });

    test('handles elapsed life expectancy correctly when current time > target', () {
      final birthDate = DateTime(1930, 1, 1, 0, 0, 0);
      final lifeExpectancy = 80; // Target was 2010-01-01 00:00:00
      final currentTime = DateTime(2026, 8, 23, 12, 0, 0);

      final result = DeathContemplationCalculator.calculate(
        birthDate: birthDate,
        lifeExpectancyYears: lifeExpectancy,
        currentTime: currentTime,
      );

      expect(result.isConfigured, isTrue);
      expect(result.isElapsed, isTrue);
      expect(result.years, equals(0));
      expect(result.months, equals(0));
      expect(result.days, equals(0));
      expect(result.hours, equals(0));
      expect(result.minutes, equals(0));
      expect(result.seconds, equals(0));
      expect(result.totalDaysRemaining, equals(0));
      expect(result.progressFraction, equals(1.0));
      expect(result.totalDaysLived, greaterThan(0));
    });

    test('handles leap day (Feb 29) birthdate safely', () {
      final birthDate = DateTime(2000, 2, 29, 0, 0, 0);
      final lifeExpectancy = 75; // 2075 is non-leap year (Feb 28)
      final currentTime = DateTime(2026, 3, 1, 0, 0, 0);

      final result = DeathContemplationCalculator.calculate(
        birthDate: birthDate,
        lifeExpectancyYears: lifeExpectancy,
        currentTime: currentTime,
      );

      expect(result.isConfigured, isTrue);
      expect(result.isElapsed, isFalse);
      expect(result.years, greaterThan(0));
    });
  });
}
