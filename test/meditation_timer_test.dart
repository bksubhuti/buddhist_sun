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
import 'package:buddhist_sun/src/services/meditation_audio_service.dart';

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
      expect(provider.startSound.id, equals('SingleBell'));
      expect(provider.startSound.displayName, equals('Suno Calm Bell'));
      expect(provider.endSound.id, equals('SingleBell'));
      expect(provider.endSound.displayName, equals('Suno Calm Bell'));
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

    test(
        'Bowl and Gong sounds use fade assets and slow variants are properly named',
        () {
      final bowl = MeditationSoundItem.fromId('Bowl');
      expect(bowl.assetPath,
          equals('assets/audio/meditation_sounds/Bowl-fade.wav'));
      expect(bowl.displayName, equals('Bowl'));

      final bowlSlow = MeditationSoundItem.fromId('BowlSlow');
      expect(bowlSlow.assetPath,
          equals('assets/audio/meditation_sounds/Bowl-slow-fade-.wav'));
      expect(bowlSlow.displayName, equals('Bowl (Slow)'));

      final gong = MeditationSoundItem.fromId('Gong');
      expect(gong.assetPath,
          equals('assets/audio/meditation_sounds/Gong-fade.wav'));
      expect(gong.displayName, equals('Gong'));

      final gongSlow = MeditationSoundItem.fromId('GongSlow');
      expect(gongSlow.assetPath,
          equals('assets/audio/meditation_sounds/Gong-slow-fade.wav'));
      expect(gongSlow.displayName, equals('Gong (Slow)'));

      // Ensure no sounds refer to deleted Bowl.wav or Gong.wav
      for (final sound in MeditationSoundItem.allSounds) {
        expect(sound.assetPath?.endsWith('/Bowl.wav') ?? false, isFalse);
        expect(sound.assetPath?.endsWith('/Gong.wav') ?? false, isFalse);
      }
    });

    test('MeditationSoundItem.fromId handles legacy sound aliases safely', () {
      expect(MeditationSoundItem.fromId('BowlFade').id, equals('Bowl'));
      expect(MeditationSoundItem.fromId('Bowl (Fade)').id, equals('Bowl'));
      expect(MeditationSoundItem.fromId('BowlSlowFade').id, equals('BowlSlow'));
      expect(MeditationSoundItem.fromId('Bowl (Slow Fade)').id,
          equals('BowlSlow'));

      expect(MeditationSoundItem.fromId('GongFade').id, equals('Gong'));
      expect(MeditationSoundItem.fromId('Gong (Fade)').id, equals('Gong'));
      expect(MeditationSoundItem.fromId('GongSlowFade').id, equals('GongSlow'));
      expect(MeditationSoundItem.fromId('Gong (Slow Fade)').id,
          equals('GongSlow'));
    });

    test('Prefs and migration handle legacy sound keys cleanly', () async {
      await Prefs.instance.setString('meditationStartSound', 'BowlSlowFade');
      await Prefs.instance.setString('meditationIntervalSound', 'GongFade');
      await Prefs.instance.setString('meditationEndSound', 'BowlFade');

      // Getters normalize immediately
      expect(Prefs.meditationStartSound, equals('BowlSlow'));
      expect(Prefs.meditationIntervalSound, equals('Gong'));
      expect(Prefs.meditationEndSound, equals('Bowl'));

      // Reset migration flag and run migration
      await Prefs.instance.remove('_meditationSoundsMigrated_v1');
      await Prefs.migrateMeditationSounds();

      // Check stored raw values in SharedPreferences
      expect(
          Prefs.instance.getString('meditationStartSound'), equals('BowlSlow'));
      expect(
          Prefs.instance.getString('meditationIntervalSound'), equals('Gong'));
      expect(Prefs.instance.getString('meditationEndSound'), equals('Bowl'));
      expect(Prefs.instance.getBool('_meditationSoundsMigrated_v1'), isTrue);

      // Restore defaults for subsequent tests
      Prefs.meditationStartSound = 'SingleBell';
      Prefs.meditationIntervalSound = 'ClearBell';
      Prefs.meditationEndSound = 'SingleBell';
    });

    test(
        'Vibration Only sound option is available, has correct properties, and persists in Prefs',
        () {
      final vibe = MeditationSoundItem.vibration;
      expect(vibe.id, equals('vibration'));
      expect(vibe.displayName, equals('Vibration Only'));
      expect(vibe.isVibration, isTrue);
      expect(vibe.isNone, isFalse);
      expect(vibe.assetPath, isNull);

      // Verify it is in allSounds list at index 1 (right after None)
      expect(MeditationSoundItem.allSounds[0].id, equals('none'));
      expect(MeditationSoundItem.allSounds[1].id, equals('vibration'));

      // Verify fromId aliases
      expect(MeditationSoundItem.fromId('vibration').id, equals('vibration'));
      expect(
          MeditationSoundItem.fromId('Vibration Only').id, equals('vibration'));
      expect(MeditationSoundItem.fromId('VIBRATE').id, equals('vibration'));

      // Test provider configuration and persistence
      final provider = MeditationTimerProvider();
      provider.setStartSound(vibe);
      provider.setIntervalSound(vibe);
      provider.setEndSound(vibe);

      expect(provider.startSound.id, equals('vibration'));
      expect(provider.intervalSound.id, equals('vibration'));
      expect(provider.endSound.id, equals('vibration'));

      expect(Prefs.meditationStartSound, equals('vibration'));
      expect(Prefs.meditationIntervalSound, equals('vibration'));
      expect(Prefs.meditationEndSound, equals('vibration'));

      // Restore defaults
      Prefs.meditationStartSound = 'SingleBell';
      Prefs.meditationIntervalSound = 'ClearBell';
      Prefs.meditationEndSound = 'SingleBell';
      provider.dispose();
    });

    testWidgets(
        'MeditationTimerPage displays Vibration Only and test vibration icon button when selected',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Prefs.meditationStartSound = 'vibration';
      Prefs.meditationIntervalMinutes = 10;
      Prefs.meditationIntervalSound = 'ClearBell';
      Prefs.meditationEndSound = 'vibration';

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

      // Expand Bells & Settings
      await tester.tap(find.text('Bells & Settings'));
      await tester.pumpAndSettle();

      // Subtitle reflects Vibration Only
      expect(find.textContaining('Start: Vibration Only'), findsOneWidget);
      expect(find.textContaining('End: Vibration Only'), findsOneWidget);

      // Verify Test vibration tooltip and icon appear for vibration selections
      expect(find.byTooltip('Test vibration'), findsNWidgets(2));
      expect(find.byIcon(Icons.vibration_rounded), findsNWidgets(2));

      // ClearBell has Preview sound tooltip
      expect(find.byTooltip('Preview sound'), findsOneWidget);

      // Tap test vibration button
      await tester.tap(find.byTooltip('Test vibration').first);
      await tester.pumpAndSettle();

      // Restore defaults
      Prefs.meditationStartSound = 'SingleBell';
      Prefs.meditationIntervalMinutes = 0;
      Prefs.meditationIntervalSound = 'ClearBell';
      Prefs.meditationEndSound = 'SingleBell';
      provider.dispose();
    });

    test('Session pause, resume, stop, and reset transitions work properly',
        () async {
      final provider = MeditationTimerProvider();
      provider.setMode(MeditationTimerMode.timed);
      provider.setDurationMinutes(5);

      await provider.startSession();
      expect(provider.status, equals(MeditationTimerStatus.running));

      await provider.pauseSession();
      expect(provider.status, equals(MeditationTimerStatus.paused));

      await provider.resumeSession();
      expect(provider.status, equals(MeditationTimerStatus.running));

      await provider.stopSession(completed: false);
      expect(provider.status, equals(MeditationTimerStatus.idle));

      await provider.startSession();
      expect(provider.status, equals(MeditationTimerStatus.running));

      await provider.stopSession(completed: true);
      expect(provider.status, equals(MeditationTimerStatus.completed));

      provider.resetToIdle();
      expect(provider.status, equals(MeditationTimerStatus.idle));
      expect(provider.elapsedSeconds, equals(0));
      expect(provider.remainingSeconds, equals(0));

      provider.dispose();
    });

    test(
        'Overtime counting past target duration tracks overflow and displays +M:SS',
        () async {
      final provider = MeditationTimerProvider();
      provider.setMode(MeditationTimerMode.timed);
      provider.setDurationMinutes(60); // 1 hour target

      expect(provider.isOvertime, isFalse);
      expect(provider.overtimeSeconds, equals(0));
      expect(provider.formattedOvertime, equals('+0:00'));
      expect(provider.formattedTargetDuration, equals('01:00:00'));

      await provider.startSession();
      expect(provider.status, equals(MeditationTimerStatus.running));
      expect(provider.hasCompletedTarget, isFalse);
      expect(provider.isOvertime, isFalse);

      await provider.stopSession(completed: false);
      expect(provider.status, equals(MeditationTimerStatus.idle));
      provider.dispose();
    });

    test(
        'MeditationAudioService lifecycle handles start, pause, resume, interval, and end safely',
        () async {
      final audioService = MeditationAudioService();

      // Ensure init executes without exception
      await audioService.init();

      // Start session with bell
      await audioService.startSession(
        startSound: MeditationSoundItem.fromId('Bowl'),
      );
      expect(audioService.isSessionActive, isTrue);

      // Play interval sound
      await audioService.playIntervalSound(
        MeditationSoundItem.fromId('ClearBell'),
      );
      expect(audioService.isSessionActive, isTrue);

      // Pause session
      await audioService.pauseSession();
      expect(audioService.isSessionActive, isFalse);

      // Resume session
      await audioService.resumeSession();
      expect(audioService.isSessionActive, isTrue);

      // Play end sound
      await audioService.playEndSound(
        MeditationSoundItem.fromId('Bowl'),
      );
      expect(audioService.isSessionActive, isFalse);

      // Start with none / vibration (direct silence loop)
      await audioService.startSession(
        startSound: MeditationSoundItem.none,
      );
      expect(audioService.isSessionActive, isTrue);

      // End session
      await audioService.endSession();
      expect(audioService.isSessionActive, isFalse);
    });

    test(
        'MeditationTimerProvider syncWithCurrentTime responds immediately to inactive, hidden, and resumed lifecycle states',
        () async {
      final provider = MeditationTimerProvider();
      await provider.startSessionWithDuration(30);

      expect(provider.status, equals(MeditationTimerStatus.running));

      // Test waking through hidden, inactive, and resumed states
      provider.didChangeAppLifecycleState(AppLifecycleState.hidden);
      expect(provider.status, equals(MeditationTimerStatus.running));

      provider.didChangeAppLifecycleState(AppLifecycleState.inactive);
      expect(provider.status, equals(MeditationTimerStatus.running));

      provider.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(provider.status, equals(MeditationTimerStatus.running));

      // Formatted display time evaluates dynamically
      expect(provider.formattedDisplayTime, isNotEmpty);
      expect(provider.formattedDisplayTime, contains(':'));

      await provider.stopSession(completed: false);
      provider.dispose();
    });
  });
}
