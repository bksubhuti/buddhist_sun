import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/solar_calc.dart';
import 'package:buddhist_sun/widgets/home_target_display_widget.dart';
import 'package:buddhist_sun/widgets/home_noon_timer_widget.dart';
import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:buddhist_sun/views/buddhavassa_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs.init();
    // Use Kandy coordinates
    Prefs.lat = 7.2906;
    Prefs.lng = 80.6337;
    Prefs.offset = 5.5;
  });

  group('Countdown Target Mode Tests', () {
    test('Within 6 hours before dawn is in Dawn Mode and not late', () {
      final now = DateTime.now();
      final todayDawn = getSelectedDawn(now);

      // 3 hours before dawn
      final testTime = todayDawn.subtract(const Duration(hours: 3));
      final info = getCountdownTargetInfo(testTime);

      expect(info.mode, CountdownTargetMode.dawn);
      expect(info.isDawnMode, isTrue);
      expect(info.isLate, isFalse);
      expect(info.targetDateTime, todayDawn);
    });

    test('Between dawn and dawn + 2 hours is in Dawn Mode and isLate is true',
        () {
      final now = DateTime.now();
      final todayDawn = getSelectedDawn(now);

      // 1 hour after dawn
      final testTime = todayDawn.add(const Duration(hours: 1));
      final info = getCountdownTargetInfo(testTime);

      expect(info.mode, CountdownTargetMode.dawn);
      expect(info.isDawnMode, isTrue);
      expect(info.isLate, isTrue);
      expect(info.targetDateTime, todayDawn);
    });

    test(
        'Just before 2 hours after dawn (dawn + 1h59m) remains in Dawn Mode (Late)',
        () {
      final now = DateTime.now();
      final todayDawn = getSelectedDawn(now);

      final testTime = todayDawn.add(const Duration(hours: 1, minutes: 59));
      final info = getCountdownTargetInfo(testTime);

      expect(info.mode, CountdownTargetMode.dawn);
      expect(info.isLate, isTrue);
    });

    test('At dawn + 2 hours + 1 minute switches to Noon Mode', () {
      final now = DateTime.now();
      final todayDawn = getSelectedDawn(now);
      final todayNoon = getSolarNoonDateTime(now);

      // 2 hours and 1 minute after dawn
      final testTime = todayDawn.add(const Duration(hours: 2, minutes: 1));
      final info = getCountdownTargetInfo(testTime);

      expect(info.mode, CountdownTargetMode.noon);
      expect(info.isDawnMode, isFalse);
      expect(info.isLate, isFalse);
      expect(info.targetDateTime, todayNoon);
    });

    test('After solar noon remains in Noon Mode and isLate is true', () {
      final now = DateTime.now();
      final todayNoon = getSolarNoonDateTime(now);

      // 1 hour after noon
      final testTime = todayNoon.add(const Duration(hours: 1));
      final info = getCountdownTargetInfo(testTime);

      expect(info.mode, CountdownTargetMode.noon);
      expect(info.isDawnMode, isFalse);
      expect(info.isLate, isTrue);
      expect(info.targetDateTime, todayNoon);
    });

    test(
        'Within 6 hours before tomorrow dawn (e.g. late evening) enters Dawn Mode for tomorrow dawn',
        () {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowDawn = getSelectedDawn(tomorrow);

      // 4 hours before tomorrow dawn
      final testTime = tomorrowDawn.subtract(const Duration(hours: 4));
      final info = getCountdownTargetInfo(testTime);

      expect(info.mode, CountdownTargetMode.dawn);
      expect(info.isDawnMode, isTrue);
      expect(info.isLate, isFalse);
      expect(info.targetDateTime, tomorrowDawn);
      expect(info.upcomingDawn, tomorrowDawn);
    });
  });

  group('HomeTargetDisplayWidget & HomeNoonTimerWidget Widget Tests', () {
    testWidgets('HomeTargetDisplayWidget in Noon Mode renders only Solar Noon',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final todayDawn = getSelectedDawn(now);
      // 3 hours after dawn is Noon Mode
      final noonModeTime = todayDawn.add(const Duration(hours: 3));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
          ],
          home: Scaffold(
            body: HomeTargetDisplayWidget(currentTime: noonModeTime),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(HomeTargetDisplayWidget), findsOneWidget);
      expect(find.text('Solar Noon', findRichText: true), findsOneWidget);
      // In Noon Mode, Dawn label should NOT be present
      expect(find.textContaining('Dawn', findRichText: true), findsNothing);
    });

    testWidgets(
        'HomeTargetDisplayWidget in Dawn Mode renders Solar Noon and upcoming Dawn',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final todayDawn = getSelectedDawn(now);
      // 2 hours before dawn is Dawn Mode
      final dawnModeTime = todayDawn.subtract(const Duration(hours: 2));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
          ],
          home: Scaffold(
            body: HomeTargetDisplayWidget(currentTime: dawnModeTime),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(HomeTargetDisplayWidget), findsOneWidget);
      // Both Solar Noon and Dawn should be present
      expect(find.text('Solar Noon', findRichText: true), findsOneWidget);
      expect(find.textContaining('Dawn', findRichText: true), findsOneWidget);
    });

    testWidgets('HomeNoonTimerWidget in Dawn Mode displays countdown to dawn',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final todayDawn = getSelectedDawn(now);
      // 2 hours before dawn
      final dawnModeTime = todayDawn.subtract(const Duration(hours: 2));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
          ],
          home: Scaffold(
            body: HomeNoonTimerWidget(currentTime: dawnModeTime),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(HomeNoonTimerWidget), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_bottom_rounded), findsOneWidget);
      // Should show countdown ~02:00:00 or 01:59:59
      expect(find.textContaining('02:00', findRichText: true), findsOneWidget);
    });

    testWidgets('HomeNoonTimerWidget within 2 hours after dawn displays Late',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final todayDawn = getSelectedDawn(now);
      // 1 hour after dawn
      final lateDawnTime = todayDawn.add(const Duration(hours: 1));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
          ],
          home: Scaffold(
            body: HomeNoonTimerWidget(currentTime: lateDawnTime),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(HomeNoonTimerWidget), findsOneWidget);
      expect(find.text('Late'), findsOneWidget);
    });

    testWidgets(
        'HomeNoonTimerWidget switches to Solar Noon countdown 2 hours after dawn',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final todayDawn = getSelectedDawn(now);
      // 2 hours and 5 minutes after dawn
      final noonModeTime = todayDawn.add(const Duration(hours: 2, minutes: 5));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
          ],
          home: Scaffold(
            body: HomeNoonTimerWidget(currentTime: noonModeTime),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(HomeNoonTimerWidget), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_bottom_rounded), findsOneWidget);
    });
  });

  group('Buddhavassa Page & Help Dialog Tests', () {
    testWidgets(
        'BuddhavassaPage displays selected country prefix before Pakkha Days',
        (WidgetTester tester) async {
      // Test Sri Lanka
      Prefs.selectedUposatha = UposathaCountry.Sinhala;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
          ],
          home: const BuddhavassaPage(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('Sri Lanka Pakkha Days', findRichText: true),
          findsOneWidget);

      // Test Thailand
      Prefs.selectedUposatha = UposathaCountry.Thailand;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
          ],
          home: const BuddhavassaPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Thailand Pakkha Days', findRichText: true),
          findsOneWidget);

      // Test Myanmar
      Prefs.selectedUposatha = UposathaCountry.Myanmar;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
          ],
          home: const BuddhavassaPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Myanmar Pakkha Days', findRichText: true),
          findsOneWidget);
    });
  });
}
