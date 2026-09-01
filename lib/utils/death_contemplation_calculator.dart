/// Calculator and model for Contemplation of Death (Maraṇassati)
class DeathCountdownResult {
  final bool isConfigured;
  final bool isElapsed;
  final int years;
  final int months;
  final int days;
  final int hours;
  final int minutes;
  final int seconds;
  final int totalDaysRemaining;
  final int totalDaysLived;
  final double progressFraction; // 0.0 to 1.0 (portion of life elapsed)
  final DateTime? birthDate;
  final DateTime? targetDate;
  final int lifeExpectancyYears;

  const DeathCountdownResult({
    required this.isConfigured,
    required this.isElapsed,
    required this.years,
    required this.months,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.totalDaysRemaining,
    required this.totalDaysLived,
    required this.progressFraction,
    this.birthDate,
    this.targetDate,
    required this.lifeExpectancyYears,
  });

  factory DeathCountdownResult.unconfigured() {
    return const DeathCountdownResult(
      isConfigured: false,
      isElapsed: false,
      years: 0,
      months: 0,
      days: 0,
      hours: 0,
      minutes: 0,
      seconds: 0,
      totalDaysRemaining: 0,
      totalDaysLived: 0,
      progressFraction: 0.0,
      birthDate: null,
      targetDate: null,
      lifeExpectancyYears: 80,
    );
  }
}

class DeathContemplationCalculator {
  /// Computes the precise breakdown of remaining life time from [now] until [birthDate] + [lifeExpectancyYears].
  static DeathCountdownResult calculate({
    required DateTime? birthDate,
    required int lifeExpectancyYears,
    DateTime? currentTime,
  }) {
    if (birthDate == null) {
      return DeathCountdownResult.unconfigured();
    }

    final now = currentTime ?? DateTime.now();
    final targetDate = DateTime(
      birthDate.year + lifeExpectancyYears,
      birthDate.month,
      birthDate.day,
      birthDate.hour,
      birthDate.minute,
      birthDate.second,
    );

    final totalLifespanDuration = targetDate.difference(birthDate);
    final livedDuration = now.difference(birthDate);

    final double progressFraction;
    if (totalLifespanDuration.inSeconds <= 0) {
      progressFraction = 1.0;
    } else {
      progressFraction =
          (livedDuration.inSeconds / totalLifespanDuration.inSeconds)
              .clamp(0.0, 1.0);
    }

    final totalDaysLived = livedDuration.inDays;

    if (!now.isBefore(targetDate)) {
      // Lifespan has been reached or exceeded
      return DeathCountdownResult(
        isConfigured: true,
        isElapsed: true,
        years: 0,
        months: 0,
        days: 0,
        hours: 0,
        minutes: 0,
        seconds: 0,
        totalDaysRemaining: 0,
        totalDaysLived: totalDaysLived,
        progressFraction: 1.0,
        birthDate: birthDate,
        targetDate: targetDate,
        lifeExpectancyYears: lifeExpectancyYears,
      );
    }

    final totalDaysRemaining = targetDate.difference(now).inDays;

    // Step 1: Calculate full years
    int years = targetDate.year - now.year;
    DateTime temp = _safeDate(
      now.year + years,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
    );
    if (temp.isAfter(targetDate)) {
      years--;
      temp = _safeDate(
        now.year + years,
        now.month,
        now.day,
        now.hour,
        now.minute,
        now.second,
      );
    }

    // Step 2: Calculate full months
    int months = 0;
    while (true) {
      int nextYear = temp.year + (temp.month == 12 ? 1 : 0);
      int nextMonth = temp.month == 12 ? 1 : temp.month + 1;
      DateTime nextDate = _safeDate(
        nextYear,
        nextMonth,
        temp.day,
        temp.hour,
        temp.minute,
        temp.second,
      );
      if (nextDate.isAfter(targetDate)) {
        break;
      }
      temp = nextDate;
      months++;
    }

    // Step 3: Calculate remaining days, hours, minutes, seconds
    final remainingFromTemp = targetDate.difference(temp);
    final days = remainingFromTemp.inDays;
    final remainingAfterDays = remainingFromTemp - Duration(days: days);

    final hours = remainingAfterDays.inHours;
    final remainingAfterHours = remainingAfterDays - Duration(hours: hours);

    final minutes = remainingAfterHours.inMinutes;
    final remainingAfterMins = remainingAfterHours - Duration(minutes: minutes);

    final seconds = remainingAfterMins.inSeconds;

    return DeathCountdownResult(
      isConfigured: true,
      isElapsed: false,
      years: years,
      months: months,
      days: days,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      totalDaysRemaining: totalDaysRemaining,
      totalDaysLived: totalDaysLived,
      progressFraction: progressFraction,
      birthDate: birthDate,
      targetDate: targetDate,
      lifeExpectancyYears: lifeExpectancyYears,
    );
  }

  /// Safely create a DateTime clamping invalid day numbers (e.g. Feb 30 -> Feb 28/29)
  static DateTime _safeDate(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    int second,
  ) {
    // Days in given month
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final safeDay = day > daysInMonth ? daysInMonth : (day < 1 ? 1 : day);
    return DateTime(year, month, safeDay, hour, minute, second);
  }
}
