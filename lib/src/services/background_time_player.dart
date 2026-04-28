import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';

import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/solar_time.dart';
import 'package:buddhist_sun/src/services/notification_service.dart';

class BackgroundTimePlayer {
  static final AudioPlayer _player = AudioPlayer();
  static DateTime? _target;
  static bool _initialized = false;
  static Uri? _logoUri;
  static StreamSubscription<bool>? _playingSub;

  static Future<void> init() async {
    if (_initialized) return;

    await _configureAudioSession();

    // Enforce time synchronization when the user resumes playback from the lock screen.
    // just_audio_background handles the play/pause natively, so we just react to it.
    _playingSub = _player.playingStream.listen((playing) {
      if (playing && _target != null) {
        final now = DateTime.now();
        final secondsUntilTarget = _target!.difference(now).inSeconds;

        if (secondsUntilTarget <= 7200 && secondsUntilTarget > 0) {
          final secondsElapsed = 7200 - secondsUntilTarget;
          _player.seek(Duration(seconds: secondsElapsed));
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
    await session.configure(const AudioSessionConfiguration.speech());
    await session.setActive(true);
  }

  static Future<Uri> _getLogoUri() async {
    if (_logoUri != null) return _logoUri!;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/buddhist_sun_app_logo.png');
    if (!await file.exists()) {
      final byteData =
          await rootBundle.load('assets/buddhist_sun_app_logo.png');
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
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

  static Future<String> _getPhysicalAudioFile(String assetPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = assetPath.split('/').last;
    final file = File('${dir.path}/$fileName');

    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }

  static Future<void> startForTarget({
    required DateTime target,
    required String title,
    required String artist,
    required String album,
  }) async {
    _target = target;
    await init();
    await _configureAudioSession();

    final logoUri = await _getLogoUri();
    final audioAsset = _getAudioAssetPath();

    // --> EXTRACT THE PHYSICAL FILE <--
    final physicalPath = await _getPhysicalAudioFile(audioAsset);

    final now = DateTime.now();
    final secondsUntilTarget = target.difference(now).inSeconds;

    final mediaItem = MediaItem(
      id: 'timer_countdown_m4av2',
      album: album,
      title: title,
      artist: artist,
      artUri: logoUri,
      duration: const Duration(minutes: 120),
    );

    await _player.stop();

    // --> USE AudioSource.uri INSTEAD OF AudioSource.asset <--
    await _player.setAudioSource(
      AudioSource.uri(
        Uri.file(physicalPath),
        tag: mediaItem,
      ),
    );
    if (secondsUntilTarget <= 7200 && secondsUntilTarget > 0) {
      final secondsElapsed = 7200 - secondsUntilTarget;
      await _player.seek(Duration(seconds: secondsElapsed));
    } else if (secondsUntilTarget <= 0) {
      await _player.seek(const Duration(minutes: 120));
    } else {
      await _player.seek(Duration.zero);
    }

    await _player.play();
  }

  static Future<void> stop() async {
    await _player.stop();
    final session = await AudioSession.instance;
    await session.setActive(false);
    _target = null;

    // Cleanup notifications
    await cancelAllTimerNotifications();
    Prefs.speakIsOn = false;

    // Keep TTS compatible
    final solarService = SolarTimerService();
    solarService.initialVoicing = false;
    solarService.delegate?.setSpeakIsOn(false);
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
