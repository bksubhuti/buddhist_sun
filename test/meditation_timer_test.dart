import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/models/meditation_timer_state.dart';
import 'package:buddhist_sun/src/provider/meditation_timer_provider.dart';

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
  });
}
