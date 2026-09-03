import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/models/meditation_timer_state.dart';
import 'package:buddhist_sun/src/provider/meditation_timer_provider.dart';
import 'package:buddhist_sun/views/meditation_timer_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs.init();
  });

  group('Meditation Timer Model & Provider Tests', () {
    test('Initializes with default settings from Prefs', () {
      final provider = MeditationTimerProvider();

      expect(provider.mode, equals(MeditationTimerMode.timed));
      expect(provider.status, equals(MeditationTimerStatus.idle));
      expect(provider.durationMinutes, equals(30));
      expect(provider.formattedDisplayTime, equals('30:00'));
      expect(provider.startSound.id, equals('Bowl'));
      expect(provider.endSound.id, equals('Bowl'));
      expect(provider.intervalSound.id, equals('ClearBell'));
      expect(MeditationSoundItem.fromId('ding').id, equals('ClearBell'));
      expect(provider.volume, equals(80));
      expect(provider.volumeNormalized, equals(0.8));
    });

    test('Mode changes and persistence works', () {
      final provider = MeditationTimerProvider();

      provider.setMode(MeditationTimerMode.endAt);
      expect(provider.mode, equals(MeditationTimerMode.endAt));
      expect(Prefs.meditationTimerMode, equals('endAt'));

      provider.setMode(MeditationTimerMode.unlimited);
      expect(provider.mode, equals(MeditationTimerMode.unlimited));
      expect(Prefs.meditationTimerMode, equals('unlimited'));
    });

    test('Duration adjustments format correctly', () {
      final provider = MeditationTimerProvider();
      provider.setMode(MeditationTimerMode.timed);

      provider.setDurationMinutes(45);
      expect(provider.durationMinutes, equals(45));
      expect(provider.formattedDisplayTime, equals('45:00'));

      provider.setDurationMinutes(75);
      expect(provider.durationMinutes, equals(75));
      expect(provider.formattedDisplayTime, equals('01:15:00'));

      provider.setDurationMinutes(120);
      expect(provider.durationMinutes, equals(120));
      expect(provider.formattedDisplayTime, equals('02:00:00'));
    });

    test('Sound configurations and volume update properly', () {
      final provider = MeditationTimerProvider();

      final gong = MeditationSoundItem.fromId('Gong');
      provider.setStartSound(gong);
      expect(provider.startSound.id, equals('Gong'));
      expect(Prefs.meditationStartSound, equals('Gong'));

      final bowlStrong = MeditationSoundItem.fromId('BowlStrong');
      provider.setEndSound(bowlStrong);
      expect(provider.endSound.id, equals('BowlStrong'));
      expect(Prefs.meditationEndSound, equals('BowlStrong'));

      provider.setIntervalMinutes(15);
      expect(provider.intervalMinutes, equals(15));
      expect(Prefs.meditationIntervalMinutes, equals(15));

      final zenBell = MeditationSoundItem.fromId('ZenBell');
      provider.setIntervalSound(zenBell);
      expect(provider.intervalSound.id, equals('ZenBell'));
      expect(Prefs.meditationIntervalSound, equals('ZenBell'));

      provider.setVolume(60);
      expect(provider.volume, equals(60));
      expect(provider.volumeNormalized, equals(0.6));
      expect(Prefs.meditationVolume, equals(60));
    });

    test('Progress calculation behaves correctly for subtractive and additive',
        () {
      final provider = MeditationTimerProvider();
      provider.setMode(MeditationTimerMode.timed);
      provider.setDurationMinutes(30);

      // Default subtractive style in idle is 1.0 (full solid ring)
      expect(provider.ringStyle, equals('subtractive'));
      expect(provider.progress, equals(1.0));

      // Additive style in idle is 0.0 (empty ring)
      provider.setRingStyle('additive');
      expect(provider.ringStyle, equals('additive'));
      expect(provider.progress, equals(0.0));
    });

    test('Session start transitions immediately to running and ticks countdown',
        () async {
      final provider = MeditationTimerProvider();
      provider.setMode(MeditationTimerMode.timed);
      provider.setDurationMinutes(2); // 120 seconds

      await provider.startSession();

      expect(provider.status, equals(MeditationTimerStatus.running));
      expect(provider.formattedDisplayTime, equals('02:00'));
      expect(provider.remainingSeconds, equals(120));

      provider.dispose();
    });

    test('Meditation presets persist and sort properly', () {
      expect(Prefs.meditationPresets.length, equals(10));
      expect(Prefs.meditationPresets,
          equals([5, 10, 15, 20, 25, 30, 45, 60, 90, 120]));

      // Add a custom preset
      final list = List<int>.from(Prefs.meditationPresets);
      list.add(22);
      list.sort();
      Prefs.meditationPresets = list;

      expect(Prefs.meditationPresets.contains(22), isTrue);
      expect(Prefs.meditationPresets.length, equals(11));
      expect(Prefs.meditationPresets[4], equals(22)); // 5, 10, 15, 20, 22...

      // Delete a preset
      list.remove(22);
      Prefs.meditationPresets = list;
      expect(Prefs.meditationPresets.contains(22), isFalse);
    });

    test('Recent meditation times track 4 most recent durations properly', () {
      Prefs.meditationRecentTimes = [30, 15, 45, 60];
      expect(Prefs.meditationRecentTimes, equals([30, 15, 45, 60]));

      // Add a new duration
      Prefs.addMeditationRecentTime(25);
      expect(Prefs.meditationRecentTimes, equals([25, 30, 15, 45]));

      // Add an existing duration (moves to top)
      Prefs.addMeditationRecentTime(15);
      expect(Prefs.meditationRecentTimes, equals([15, 25, 30, 45]));

      // Add another new duration
      Prefs.addMeditationRecentTime(90);
      expect(Prefs.meditationRecentTimes, equals([90, 15, 25, 30]));

      final provider = MeditationTimerProvider();
      provider.setDurationMinutes(90);
      expect(provider.recentTimes, equals([90, 15, 25, 30]));
      expect(provider.alternateRecentTimes, equals([15, 25, 30]));
      provider.dispose();
    });

    testWidgets(
        'MeditationTimerPage displays 3 alternate recent duration buttons in timed mode',
        (WidgetTester tester) async {
      Prefs.meditationRecentTimes = [30, 15, 45, 60];
      Prefs.meditationTimerMode = 'timed';
      Prefs.meditationDurationMinutes = 30;

      final provider = MeditationTimerProvider();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: ChangeNotifierProvider<MeditationTimerProvider>.value(
            value: provider,
            child: const MeditationTimerPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the top set time card displays the current duration (30 min)
      expect(find.text('30 min'), findsOneWidget);

      // Verify the 3 buttons show the 2nd, 3rd, and 4th recent times (15 min, 45 min, 1 hr)
      expect(find.text('15 min'), findsOneWidget);
      expect(find.text('45 min'), findsOneWidget);
      expect(find.text('1 hr'), findsOneWidget);

      provider.dispose();
    });

    testWidgets(
        'MeditationTimerPage displays Volume below start button, and Interval Bell between Starting & Ending Bell in settings',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Prefs.meditationIntervalMinutes = 0;
      final provider = MeditationTimerProvider();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: ChangeNotifierProvider<MeditationTimerProvider>.value(
            value: provider,
            child: const MeditationTimerPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Volume is visible directly on the main screen below Start Meditation
      expect(find.text('Bell Volume', skipOffstage: false), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // Verify relative positions: Start Meditation is above Bell Volume, which is above Bells & Settings
      final startMeditationTop =
          tester.getTopLeft(find.text('Start Meditation')).dy;
      final volumeTop = tester.getTopLeft(find.text('Bell Volume')).dy;
      final settingsTop = tester.getTopLeft(find.text('Bells & Settings')).dy;
      expect(startMeditationTop < volumeTop, isTrue);
      expect(volumeTop < settingsTop, isTrue);

      // 2. Expand Bells & Settings
      await tester.tap(find.text('Bells & Settings'));
      await tester.pumpAndSettle();

      // Starting Bell, Interval Bell, and Ending Bell are visible
      expect(find.text('Starting Bell', skipOffstage: false), findsOneWidget);
      expect(find.text('Interval Bell', skipOffstage: false), findsOneWidget);
      expect(find.text('Ending Bell', skipOffstage: false), findsOneWidget);

      // Verify order: Starting Bell is above Interval Bell, which is above Ending Bell
      final startingBellTop = tester.getTopLeft(find.text('Starting Bell')).dy;
      final intervalBellTop = tester.getTopLeft(find.text('Interval Bell')).dy;
      final endingBellTop = tester.getTopLeft(find.text('Ending Bell')).dy;
      expect(startingBellTop < intervalBellTop, isTrue);
      expect(intervalBellTop < endingBellTop, isTrue);

      // When interval is Off, Interval Sound row is not shown
      expect(find.text('Interval Sound', skipOffstage: false), findsNothing);

      // Enable interval
      provider.setIntervalMinutes(15);
      await tester.pumpAndSettle();

      // Now Interval Sound row appears and is selectable
      expect(find.text('Interval Sound', skipOffstage: false), findsOneWidget);

      provider.dispose();
    });
  });
}
