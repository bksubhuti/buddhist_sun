import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/models/vitd_body_size_chart.dart';
import 'package:buddhist_sun/src/provider/vitamin_d_provider.dart';
import 'package:buddhist_sun/src/services/vitamin_d_calc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs.init();
  });

  setUp(() async {
    await Prefs.instance.clear();
    Prefs.lat = 6.9271;
    Prefs.lng = 79.8612;
    Prefs.countryCode = 'LK';
  });

  group('vitamin D model', () {
    test('UV index is ~12.5 overhead and 0 at night', () {
      expect(estimateUvIndex(90), closeTo(12.5, 0.01));
      expect(estimateUvIndex(0), 0);
      expect(estimateUvIndex(-10), 0);
      expect(estimateUvIndex(90, skyFactor: 0.3), closeTo(3.75, 0.01));
    });

    test('efficiency is full above 45°, zero below 15°', () {
      expect(vitaminDElevationEfficiency(60), 1.0);
      expect(vitaminDElevationEfficiency(45), 1.0);
      expect(vitaminDElevationEfficiency(30), closeTo(0.5, 1e-9));
      expect(vitaminDElevationEfficiency(15), 0.0);
    });

    test('standard daily target is for an average adult', () {
      expect(vitDStandardDailyIu, 1400);
    });

    // Body size is not an input. These tests only check the static chart
    // shown in Sun Settings, using the published body surface area formula
    // (Livingston & Lee) which exists here in the test, not in the app.
    double bsa(double kg) => 0.1173 * math.pow(kg, 0.6466);
    const double avgBsa = 1.8; // average adult, about 68 kg
    String pct(double ratio) {
      final p = ((ratio - 1) * 100).round();
      if (p == 0) return '—';
      return p > 0 ? '+$p%' : '−${-p}%';
    }

    test('body size chart matches the formula for each weight', () {
      for (final (kg, lb, made, need, time) in vitDBodySizeChart) {
        expect(lb, (kg * 2.20462).round(), reason: '$kg kg in lb');
        expect(need, (kg * 20 / 100).round() * 100, reason: '$kg kg need');
        final rate = bsa(kg.toDouble()) / avgBsa;
        expect(made, pct(rate), reason: '$kg kg made');
        final timeRatio = (need / vitDStandardDailyIu) / rate;
        expect(time, pct(timeRatio), reason: '$kg kg time');
      }
    });

    test('example weights: sun time changes little, burn time not at all',
        () {
      // Lying down, light skin (type 2), upper body bare, high sun.
      final r = computeVitDRate(
        elevationDeg: 75,
        skin: VitDSkinType.type2,
        coverage: VitDCoverage.upperBare,
        sky: VitDSky.clear,
        posture: VitDPosture.lying,
      );
      final avgMinutes = vitDStandardDailyIu / r.iuPerMinute;
      for (final kg in [45.0, 50.0, 60.0, 68.3, 75.0, 90.0, 110.0]) {
        // What a weight-based model would have said for this person.
        final personalRate = r.iuPerMinute * bsa(kg) / avgBsa;
        final personalNeed = (kg * 20 / 100).round() * 100;
        final personalMinutes = personalNeed / personalRate;
        // The standard (no body size) time is within 20% for 45–110 kg.
        expect(personalMinutes / avgMinutes, inInclusiveRange(0.8, 1.2),
            reason: '$kg kg');
      }
      // Burn time is the same for everyone with this skin and sun.
      expect(r.minutesToBurn, isNotNull);
    });

    test('noon dose is plausible for skin type 4, one shoulder bare', () {
      final r = computeVitDRate(
        elevationDeg: 80,
        skin: VitDSkinType.type4,
        coverage: VitDCoverage.oneShoulder,
        sky: VitDSky.clear,
      );
      // ~12 UVI → burn in roughly 25 minutes.
      expect(r.minutesToBurn!, inInclusiveRange(20, 35));
      // 15 minutes should give several hundred IU, not tens of thousands.
      final iu15 = r.iuPerMinute * 15;
      expect(iu15, inInclusiveRange(500, 2000));
    });

    test('noon gives more vitamin D per burn dose than afternoon', () {
      VitDRate at(double el) => computeVitDRate(
            elevationDeg: el,
            skin: VitDSkinType.type4,
            coverage: VitDCoverage.oneShoulder,
            sky: VitDSky.clear,
              );
      final noon = at(80);
      final afternoon = at(30);
      expect(noon.iuPerMinute / noon.medPerMinute,
          greaterThan(afternoon.iuPerMinute / afternoon.medPerMinute));
    });

    test('more skin uncovered makes more vitamin D', () {
      double iu(VitDCoverage c) => computeVitDRate(
            elevationDeg: 70,
            skin: VitDSkinType.type3,
            coverage: c,
            sky: VitDSky.clear,
              ).iuPerMinute;
      expect(iu(VitDCoverage.fullRobe), lessThan(iu(VitDCoverage.oneShoulder)));
      expect(iu(VitDCoverage.oneShoulder), lessThan(iu(VitDCoverage.upperBare)));
      expect(iu(VitDCoverage.upperBare), lessThan(iu(VitDCoverage.bathingCloth)));
    });

    test('lay options are grouped and ordered by exposure', () {
      expect(VitDCoverageInfo.monastic, hasLength(5));
      expect(VitDCoverage.angsa.isLay, isFalse);
      expect(VitDCoverageInfo.lay, hasLength(4));
      expect(VitDCoverageInfo.lay.every((c) => c.isLay), isTrue);
      expect(VitDCoverageInfo.female, hasLength(4));
      expect(VitDCoverageInfo.female.every((c) => c.isLay && c.isFemale),
          isTrue);
      expect(VitDCoverage.femaleSwimwear.maleEquivalent,
          VitDCoverage.laySwimwear);
      expect(VitDCoverage.femaleSwimwear.exposedFraction,
          lessThan(VitDCoverage.laySwimwear.exposedFraction));
      final fractions =
          VitDCoverageInfo.lay.map((c) => c.exposedFraction).toList();
      expect(fractions, orderedEquals([...fractions]..sort()));
    });

    test('lying down beats standing at noon but not with low sun', () {
      expect(postureFactor(VitDPosture.standing, 75), 1.0);
      expect(postureFactor(VitDPosture.lying, 75), closeTo(1.65, 0.1));
      expect(postureFactor(VitDPosture.lying, 25), lessThan(1.0));
      final sit = postureFactor(VitDPosture.sitting, 75);
      expect(sit, greaterThan(1.0));
      expect(sit, lessThan(postureFactor(VitDPosture.lying, 75)));
    });

    test('shaved scalp adds exposure for monks only, fading with hair', () {
      expect(exposedFractionFor(VitDCoverage.fullRobe, 0), closeTo(0.12, 1e-9));
      expect(exposedFractionFor(VitDCoverage.fullRobe, 14),
          lessThan(exposedFractionFor(VitDCoverage.fullRobe, 3)));
      expect(exposedFractionFor(VitDCoverage.layFaceHands, 0),
          VitDCoverage.layFaceHands.exposedFraction);
    });

    test('minutesToProduce matches a constant rate and fails when low', () {
      final r = computeVitDRate(
        elevationDeg: 70,
        skin: VitDSkinType.type5,
        coverage: VitDCoverage.oneShoulder,
        sky: VitDSky.clear,
      );
      final m = minutesToProduce(
          targetIu: 500,
          start: DateTime(2026, 10, 2, 12),
          medSoFar: 0,
          rateAt: (_) => r)!;
      // Below half a burn dose production is linear.
      expect(m, closeTo(500 / r.iuPerMinute, 0.05));
      final low = computeVitDRate(
        elevationDeg: 10,
        skin: VitDSkinType.type5,
        coverage: VitDCoverage.oneShoulder,
        sky: VitDSky.clear,
      );
      expect(
          minutesToProduce(
              targetIu: 500,
              start: DateTime(2026, 10, 2, 17),
              medSoFar: 0,
              rateAt: (_) => low),
          isNull);
    });

    test('linear to half a burn dose, then tapering', () {
      final r = computeVitDRate(
        elevationDeg: 80,
        skin: VitDSkinType.type2,
        coverage: VitDCoverage.upperBare,
        sky: VitDSky.clear,
      );
      final secsToHalf = 0.5 / r.medPerMinute * 60;
      final first = integrateExposure(r, secsToHalf, 0);
      expect(first.iu, closeTo(r.iuPerMinute * secsToHalf / 60, 1e-6));
      // Next equal span (0.5 → 1.0 MED) yields half as much.
      final second = integrateExposure(r, secsToHalf, 0.5);
      expect(second.iu, closeTo(first.iu / 2, 1e-6));
    });

    test('user scenario: 50% in 4 min leaves about 4 min', () {
      // Type 2, noon: 4 minutes reaches 50% of target, well under ½ MED.
      final r = computeVitDRate(
        elevationDeg: 75,
        skin: VitDSkinType.type2,
        coverage: VitDCoverage.oneShoulder,
        sky: VitDSky.clear,
      );
      final four = integrateExposure(r, 240, 0);
      final left = minutesToProduce(
          targetIu: four.iu,
          start: DateTime(2026, 10, 2, 12),
          medSoFar: four.med,
          rateAt: (_) => r)!;
      expect(left, closeTo(4, 0.5));
    });

    test('session duration formats as m:ss', () {
      expect(formatSessionDuration(300.4), '5:00');
      expect(formatSessionDuration(299.6), '5:00');
      expect(formatSessionDuration(330), '5:30');
      expect(formatSessionDuration(45), '0:45');
      expect(formatSessionDuration(3725), '62:05');
    });

    test('production saturates at one burn dose', () {
      final r = computeVitDRate(
        elevationDeg: 80,
        skin: VitDSkinType.type2,
        coverage: VitDCoverage.upperBare,
        sky: VitDSky.clear,
      );
      final inc = integrateExposure(r, 600, 1.0);
      expect(inc.iu, 0);
      expect(inc.med, greaterThan(0));
    });
  });

  group('VitaminDController sessions', () {
    late DateTime clock;

    VitaminDController make({double elevation = 70}) =>
        VitaminDController(
            elevationAt: (_) => elevation, now: () => clock, alerts: false);

    test('a session is saved and counted in the day total', () {
      clock = DateTime(2026, 10, 2, 12, 0);
      final c = make();
      c.start();
      clock = clock.add(const Duration(seconds: 30));
      c.refresh();
      clock = clock.add(const Duration(seconds: 30));
      c.stop();

      expect(c.isRunning, isFalse);
      expect(c.todaySessions, hasLength(1));
      final s = c.todaySessions.first;
      expect(s.seconds, closeTo(60, 0.01));
      expect(s.iu, greaterThan(0));
      expect(c.todayIu, closeTo(s.iu, 1e-9));
      c.dispose();
    });

    test('sessions with different coverage are kept separately', () {
      clock = DateTime(2026, 10, 2, 11, 0);
      final c = make();
      c.setCoverage(VitDCoverage.fullRobe);
      c.start();
      clock = clock.add(const Duration(seconds: 60));
      c.stop();

      c.setCoverage(VitDCoverage.upperBare);
      c.setSky(VitDSky.overcast);
      clock = clock.add(const Duration(minutes: 30));
      c.start();
      clock = clock.add(const Duration(seconds: 60));
      c.stop();

      final list = c.todaySessions;
      expect(list, hasLength(2));
      expect(list.map((s) => s.coverage).toSet(),
          {VitDCoverage.fullRobe, VitDCoverage.upperBare});
      expect(c.todayIu, closeTo(list[0].iu + list[1].iu, 1e-9));
      c.dispose();
    });

    test('sessions persist and running session resumes after restart', () {
      clock = DateTime(2026, 10, 2, 12, 0);
      final c1 = make();
      c1.start();
      clock = clock.add(const Duration(seconds: 60));
      c1.stop();
      c1.start();
      clock = clock.add(const Duration(seconds: 10));
      c1.refresh();
      c1.dispose();

      // App killed and reopened 5 minutes later.
      clock = clock.add(const Duration(minutes: 5));
      final c2 = make();
      expect(c2.todaySessions, hasLength(1));
      expect(c2.isRunning, isTrue);
      expect(c2.activeElapsed.inSeconds, closeTo(310, 1));
      c2.stop();
      expect(c2.todaySessions, hasLength(2));
      c2.dispose();
    });

    test('yesterday does not count toward today', () {
      clock = DateTime(2026, 10, 1, 12, 0);
      final c = make();
      c.start();
      clock = clock.add(const Duration(seconds: 60));
      c.stop();
      clock = DateTime(2026, 10, 2, 9, 0);
      expect(c.todaySessions, isEmpty);
      expect(c.todayIu, 0);
      c.dispose();
    });

    test('target time is the whole need first, then the remainder', () {
      clock = DateTime(2026, 10, 2, 12, 0);
      final c = make();
      c.setSkin(VitDSkinType.type5);
      c.setCustomTarget(1000);
      final full = c.targetMinutes!;
      expect(full, greaterThan(0));
      c.start();
      clock = clock.add(Duration(seconds: (full * 60 / 2).round()));
      c.refresh();
      c.stop();
      final rest = c.targetMinutes!;
      expect(rest, lessThan(full));
      expect(rest, greaterThan(full * 0.3));
      expect(c.remainingIu, closeTo(1000 - c.todayIu, 1e-6));
      c.dispose();
    });

    test('custom target overrides the standard, 0 returns to standard', () {
      clock = DateTime(2026, 10, 2, 12, 0);
      final c = make();
      expect(c.dailyGoalIu, 1400);
      c.setCustomTarget(2000);
      expect(c.dailyGoalIu, 2000);
      c.setCustomTarget(0);
      expect(c.dailyGoalIu, 1400);
      c.dispose();
    });

    test('posture and hair are saved with the session', () {
      clock = DateTime(2026, 10, 2, 12, 0);
      final c = make();
      c.setPosture(VitDPosture.lying);
      c.setHairDays(5);
      c.start();
      clock = clock.add(const Duration(seconds: 60));
      c.stop();
      c.dispose();
      final c2 = make();
      expect(c2.todaySessions.first.posture, VitDPosture.lying);
      expect(c2.todaySessions.first.hairDays, 5);
      expect(c2.posture, VitDPosture.lying);
      c2.dispose();
    });

    test('hair days count up automatically from the shave date', () {
      clock = DateTime(2026, 10, 2, 9, 0);
      final c = make();
      c.setHairDays(2);
      expect(c.hairDays, 2);
      c.dispose();
      clock = DateTime(2026, 10, 5, 9, 0); // three days later
      final c2 = make();
      expect(c2.hairDays, 5);
      c2.setHairDays(0); // shaved again today
      expect(c2.hairDays, 0);
      clock = DateTime(2026, 10, 30, 9, 0);
      expect(c2.hairDays, vitDMaxHairDays);
      c2.dispose();
    });

    test('legacy hair days migrate to a shave date', () async {
      await Prefs.instance.setInt('vitDHairDays', 4);
      clock = DateTime(2026, 10, 2, 9, 0);
      final c = make();
      expect(c.hairDays, 4);
      c.dispose();
    });

    test('each tab remembers its own clothing and the tab persists', () {
      clock = DateTime(2026, 10, 2, 12, 0);
      final c = make();
      c.setCoverage(VitDCoverage.angsa); // monk tab
      c.setCoverTab(1);
      c.setCoverage(VitDCoverage.laySwimwear);
      c.setCoverTab(2);
      expect(c.coverage.isFemale, isTrue);
      c.setCoverage(VitDCoverage.femaleShorts);
      c.setCoverTab(0);
      expect(c.coverage, VitDCoverage.angsa);
      c.setCoverTab(1);
      expect(c.coverage, VitDCoverage.laySwimwear);
      c.dispose();
      final c2 = make();
      expect(c2.coverTab, 1);
      expect(c2.coverage, VitDCoverage.laySwimwear);
      c2.setCoverTab(2);
      expect(c2.coverage, VitDCoverage.femaleShorts);
      c2.dispose();
    });

    /// Saves one completed session of [iu] on [day] directly.
    Future<void> seed(List<List<dynamic>> days) async {
      final list = days.map((d) {
        final start = d[0] as DateTime;
        return {
          'start': start.millisecondsSinceEpoch,
          'end': start.add(const Duration(minutes: 5)).millisecondsSinceEpoch,
          'seconds': 300,
          'iu': d[1],
          'med': 0.2,
          'coverage': 1,
          'sky': 0,
          'skin': 3,
        };
      }).toList();
      await Prefs.instance.setString('vitDSessions', jsonEncode(list));
    }

    test('week is prorated from first use', () async {
      await seed([
        [DateTime(2026, 10, 1, 12), 1000.0],
      ]);
      clock = DateTime(2026, 10, 2, 9, 0);
      final c = make();
      c.setCustomTarget(1000);
      expect(c.weekDaysCounted, 2); // first session was yesterday
      expect(c.weekTarget, 2000);
      expect(c.weekTotal, 1000);
      c.dispose();
    });

    test('catch-up: surplus covers today, deficit raises target', () async {
      await Prefs.instance.setInt(
          'vitDFirstUse', DateTime(2026, 9, 1).millisecondsSinceEpoch);
      await seed([
        [DateTime(2026, 10, 1, 12), 3000.0], // big day yesterday
      ]);
      clock = DateTime(2026, 10, 2, 9, 0);
      final c = make();
      c.setCustomTarget(1000);
      expect(c.weekDaysCounted, 7);
      // Off: plain daily target.
      expect(c.todayTargetIu, 1000);
      c.setCatchUp(true);
      // Week needs 7000; previous 6 days gave 3000 → 4000, capped at 3×.
      expect(c.todayTargetIu, 3000);
      c.dispose();
    });

    test('catch-up drops to 0 when the week is covered', () async {
      await Prefs.instance.setInt(
          'vitDFirstUse', DateTime(2026, 9, 1).millisecondsSinceEpoch);
      await seed([
        for (int d = 1; d <= 6; d++)
          [DateTime(2026, 10, 2 - d, 12), 1200.0],
      ]);
      clock = DateTime(2026, 10, 2, 9, 0);
      final c = make();
      c.setCustomTarget(1000);
      c.setCatchUp(true);
      expect(c.todayTargetIu, 0);
      expect(c.remainingIu, 0);
      expect(c.todayPercentOfGoal, 100);
      expect(c.weekShortfall, lessThan(0));
      c.dispose();
    });

    test('one day counts for at most 3 days and drops out after 7', () async {
      await Prefs.instance.setInt(
          'vitDFirstUse', DateTime(2026, 9, 1).millisecondsSinceEpoch);
      await seed([
        [DateTime(2026, 9, 26, 12), 9000.0],
      ]);
      clock = DateTime(2026, 10, 2, 9, 0); // 6 days later: still in window
      final c = make();
      c.setCustomTarget(1000);
      expect(c.weekTotal, 3000);
      c.dispose();
      clock = DateTime(2026, 10, 3, 9, 0); // 7 days later: dropped out
      final c2 = make();
      expect(c2.weekTotal, 0);
      c2.dispose();
    });

    test('a 5-minute session records 5:00, not 6', () {
      clock = DateTime(2026, 10, 2, 12, 0);
      final c = make();
      c.start();
      // Ticks every second, then Stop pressed a fraction over 5:00.
      for (int i = 0; i < 300; i++) {
        clock = clock.add(const Duration(seconds: 1));
        c.refresh();
      }
      clock = clock.add(const Duration(milliseconds: 400));
      c.stop();
      final s = c.todaySessions.single;
      expect(s.seconds, closeTo(300.4, 0.01));
      expect(formatSessionDuration(s.seconds), '5:00');
      c.dispose();
    });

    test('no vitamin D when the sun is low', () {
      clock = DateTime(2026, 10, 2, 17, 30);
      final c = make(elevation: 10);
      c.start();
      clock = clock.add(const Duration(minutes: 1));
      c.stop();
      expect(c.todayIu, 0);
      c.dispose();
    });

    test('USA mode zeros out IU and activates safe sun timer', () {
      Prefs.countryCode = 'US';
      expect(Prefs.isUsaLocation, isTrue);
      clock = DateTime(2026, 10, 2, 12, 0);
      final c = make();
      expect(c.isUsa, isTrue);
      expect(c.rate.iuPerMinute, 0.0);
      expect(c.rate.medPerMinute, greaterThan(0));
      c.start();
      clock = clock.add(const Duration(minutes: 5));
      c.refresh();
      expect(c.activeIu, 0.0);
      expect(c.activeMed, greaterThan(0));
      c.stop();
      expect(c.todayIu, 0.0);
      expect(c.todaySessions.first.iu, 0.0);
      expect(c.todaySessions.first.med, greaterThan(0));
      c.dispose();
    });

    test('US territories are detected as USA location', () {
      for (final code in ['PR', 'GU', 'VI', 'AS', 'MP', 'USA']) {
        Prefs.countryCode = code;
        expect(Prefs.isUsaLocation, isTrue, reason: 'Failed for $code');
      }
    });

    test('fail-closed behavior when location is completely unknown', () {
      Prefs.countryCode = '';
      Prefs.lat = 1.1;
      Prefs.lng = 1.1;
      // Fails closed to USA mode
      expect(Prefs.isUsaLocation, isTrue);
    });

    test('traveling outside USA unlocks once GPS and country agree', () {
      // User was in USA
      Prefs.countryCode = 'US';
      Prefs.lat = 40.7128; // New York
      Prefs.lng = -74.0060;
      expect(Prefs.isUsaLocation, isTrue);

      // New GPS fix in Colombo, country code not yet refreshed: still USA
      Prefs.lat = 6.9271;
      Prefs.lng = 79.8612;
      expect(Prefs.isUsaLocation, isTrue);

      // Reverse geocoding / IP lookup updates the country: unlocked
      Prefs.countryCode = 'LK';
      expect(Prefs.isUsaLocation, isFalse);

      // Thailand (Bangkok)
      Prefs.lat = 13.7563;
      Prefs.lng = 100.5018;
      Prefs.countryCode = 'TH';
      expect(Prefs.isUsaLocation, isFalse);

      // Back to California: GPS alone is enough, even with a stale code
      Prefs.lat = 37.7749;
      Prefs.lng = -122.4194;
      expect(Prefs.isUsaLocation, isTrue);
    });

    test('declined GPS marker is not treated as a real location', () {
      Prefs.lat = 1.2; // set when the user cancels the GPS prompt
      Prefs.lng = 1.1;
      expect(Prefs.hasValidLocation, isFalse);
      Prefs.countryCode = '';
      expect(Prefs.isUsaLocation, isTrue);
      Prefs.countryCode = 'US';
      expect(Prefs.isUsaLocation, isTrue);
      Prefs.countryCode = 'LK';
      expect(Prefs.isUsaLocation, isFalse);
    });

    test('US country code wins over a non-US GPS fix', () {
      Prefs.lat = 6.9271; // stale Colombo fix
      Prefs.lng = 79.8612;
      Prefs.countryCode = 'US';
      expect(Prefs.isUsaLocation, isTrue);
    });

    test('outlying US islands are inside the US bounds', () {
      const points = {
        'Rose Atoll': [-14.55, -168.15],
        'Swains Island': [-11.05, -171.08],
        'Wake Island': [19.28, 166.65],
        'Johnston Atoll': [16.73, -169.53],
        'Palmyra Atoll': [5.88, -162.08],
        'Navassa Island': [18.40, -75.01],
        'Attu, Alaska': [52.93, 173.0],
        'Key West': [24.55, -81.78],
      };
      points.forEach((name, p) {
        expect(Prefs.inUsaBounds(p[0], p[1]), isTrue, reason: name);
      });
      expect(Prefs.inUsaBounds(6.9271, 79.8612), isFalse); // Colombo
      expect(Prefs.inUsaBounds(13.7563, 100.5018), isFalse); // Bangkok
    });
  });
}
