import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';

import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/solar_time.dart';
import 'package:buddhist_sun/src/services/notification_service.dart';
import 'package:buddhist_sun/src/services/meditation_audio_service.dart';

class BackgroundTimePlayer {
  // Single persistent player – never disposed/recreated.
  // This matches the pattern used by MeditationAudioService which works on iOS.
  // Destroying and recreating AudioPlayer breaks just_audio_background on iOS.
  static final AudioPlayer _player = AudioPlayer();
  static DateTime? _target;
  static bool _initialized = false;
  static Uri? _logoUri;
  static StreamSubscription<bool>? _playingSub;
  static bool _isStopping = false;

  /// Whether the countdown timer audio is currently playing.
  static bool get isPlaying {
    try {
      return _player.playing;
    } catch (_) {
      return false;
    }
  }

  static Future<void> init() async {
    if (_initialized) return;
    await _configureAudioSession();
    await _getLogoUri();

    // Enforce time synchronization when the user resumes playback from the lock screen.
    // just_audio_background handles the play/pause natively, so we just react to it.
    _playingSub = _player.playingStream.listen((playing) {
      if (playing && _target != null) {
        final now = DateTime.now();
        final secondsUntilTarget = _target!.difference(now).inSeconds;

        if (secondsUntilTarget <= 7200 && secondsUntilTarget > 0) {
          final secondsElapsed = 7200 - secondsUntilTarget;
          final targetDuration = Duration(seconds: secondsElapsed);
          // Only seek if out of sync by more than 2 seconds (e.g. after lock screen pause)
          // to avoid audio hiccups/stutter on screen on or app resume.
          if ((_player.position - targetDuration).abs().inSeconds > 2) {
            _player.seek(targetDuration);
          }
        } else if (secondsUntilTarget <= 0) {
          _player.seek(const Duration(minutes: 120));
        } else {
          _player.seek(Duration.zero);
        }
      }
    });

    _initialized = true;
  }

  static Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers |
          AVAudioSessionCategoryOptions.mixWithOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        usage: AndroidAudioUsage.media,
      ),
      androidWillPauseWhenDucked: true,
    ));
    await session.setActive(true);
    await _player.setAndroidAudioAttributes(
      const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        usage: AndroidAudioUsage.media,
      ),
    );
  }

  static Future<Uri> _getLogoUri() async {
    if (_logoUri != null) return _logoUri!;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/notification_logo.png');
    final byteData = await rootBundle.load('assets/notification_logo.png');
    if (!await file.exists() ||
        (await file.length()) != byteData.lengthInBytes) {
      await file.writeAsBytes(
        byteData.buffer
            .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        flush: true,
      );
    }
    _logoUri = file.uri;
    return _logoUri!;
  }

  static String _getAudioAssetPath() {
    switch (Prefs.localeVal) {
      case 0:
        return 'assets/audio/timer_countdown_120_en.m4a';
      case 1:
        return 'assets/audio/timer_countdown_120_my.m4a';
      case 2:
        return 'assets/audio/timer_countdown_120_si.m4a';
      case 3:
        return 'assets/audio/timer_countdown_120_th.m4a';
      case 4:
        return 'assets/audio/timer_countdown_120_km.m4a';
      case 5:
        return 'assets/audio/timer_countdown_120_zh.m4a';
      case 6:
        return 'assets/audio/timer_countdown_120_vi.m4a';
      case 7:
        return 'assets/audio/timer_countdown_120_hi.m4a';
      case 8:
        return 'assets/audio/timer_countdown_120_bn.m4a';
      default:
        return 'assets/audio/timer_countdown_120_en.m4a';
    }
  }

  /// Safely stops the player with a timeout to avoid deadlocking
  /// on Android when the player is in ProcessingState.completed.
  static Future<void> _safeStop() async {
    try {
      await _player.stop().timeout(
            const Duration(milliseconds: 500),
            onTimeout: () {},
          );
    } catch (_) {}
  }

  static Future<void> startForTarget({
    required DateTime target,
    required String title,
    required String artist,
    required String album,
  }) async {
    print('BTP: startForTarget called, target=$target');
    _target = target;
    await init();
    print('BTP: init done');
    await _configureAudioSession();
    print('BTP: audio session configured');

    final logoUri = await _getLogoUri();
    final audioAsset = _getAudioAssetPath();
    print('BTP: audioAsset=$audioAsset');

    final now = DateTime.now();
    final secondsUntilTarget = target.difference(now).inSeconds;
    print('BTP: secondsUntilTarget=$secondsUntilTarget');

    final mediaItem = MediaItem(
      id: 'timer_countdown_m4av2',
      album: album,
      title: title,
      artist: artist,
      artUri: logoUri,
      duration: const Duration(minutes: 120),
    );

    // Stop any current playback safely (timeout protects against Android deadlock)
    await _safeStop();
    print('BTP: player stopped, processingState=${_player.processingState}');

    // Use AudioSource.asset (same approach that works in MeditationAudioService)
    try {
      final source = AudioSource.asset(
        audioAsset,
        tag: mediaItem,
      );
      print('BTP: setting audio source...');
      await _player.setAudioSource(source);
      print('BTP: audio source set, duration=${_player.duration}');
    } catch (e, st) {
      print('BTP: ERROR setting audio source: $e');
      print('BTP: stacktrace: $st');
      return;
    }

    try {
      if (secondsUntilTarget <= 7200 && secondsUntilTarget > 0) {
        final secondsElapsed = 7200 - secondsUntilTarget;
        print('BTP: seeking to ${secondsElapsed}s');
        await _player.seek(Duration(seconds: secondsElapsed));
      } else if (secondsUntilTarget <= 0) {
        print('BTP: seeking to end (120min)');
        await _player.seek(const Duration(minutes: 120));
      } else {
        print('BTP: seeking to start');
        await _player.seek(Duration.zero);
      }
      print('BTP: seek done, position=${_player.position}');
    } catch (e) {
      print('BTP: ERROR seeking: $e');
    }

    try {
      print('BTP: calling play...');
      await _player.play();
      print(
          'BTP: play returned, playing=${_player.playing}, state=${_player.processingState}');
    } catch (e) {
      print('BTP: ERROR playing: $e');
    }
  }

  static Future<void> stop() async {
    if (_isStopping) return;
    _isStopping = true;
    try {
      _target = null;
      await _safeStop();

      // Only deactivate audio session if meditation is not using it
      if (!MeditationAudioService().isSessionActive &&
          !MeditationAudioService().isPlaying) {
        try {
          final session = await AudioSession.instance;
          await session.setActive(false);
        } catch (_) {}
      }

      // Cleanup notifications
      await cancelAllTimerNotifications();
      Prefs.speakIsOn = false;
      Prefs.instance.setBool(SPEAKISON, false);

      // Keep TTS compatible
      final solarService = SolarTimerService();
      solarService.initialVoicing = false;
      solarService.delegate?.setSpeakIsOn(false);
    } finally {
      _isStopping = false;
    }
  }

  static Future<void> updateTarget({
    required DateTime newTarget,
    required String title,
    required String artist,
    required String album,
  }) async {
    if (_target == newTarget) return;
    await startForTarget(
      target: newTarget,
      title: title,
      artist: artist,
      album: album,
    );
  }
}
