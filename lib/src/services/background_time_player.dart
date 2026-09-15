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

class BackgroundTimePlayer {
  static AudioPlayer? _player;
  static DateTime? _target;
  static bool _initialized = false;
  static Uri? _logoUri;
  static StreamSubscription<bool>? _playingSub;
  static StreamSubscription<PlayerState>? _playerStateSub;
  static StreamSubscription<Duration>? _positionSub;
  static bool _isStopping = false;

  /// Whether the countdown timer audio is currently playing.
  static bool get isPlaying {
    final p = _player;
    if (p == null) return false;
    try {
      return p.playing;
    } catch (_) {
      return false;
    }
  }

  static Future<void> init() async {
    if (_initialized) return;
    await _configureAudioSession();
    await _getLogoUri();
    _initialized = true;
  }

  static void _setupPlayerListeners(AudioPlayer player) {
    _playingSub?.cancel();
    // Enforce time synchronization when the user resumes playback from the lock screen.
    // just_audio_background handles the play/pause natively, so we just react to it.
    _playingSub = player.playingStream.listen((playing) {
      if (playing && _target != null) {
        final now = DateTime.now();
        final secondsUntilTarget = _target!.difference(now).inSeconds;

        if (secondsUntilTarget <= 7200 && secondsUntilTarget > 0) {
          final secondsElapsed = 7200 - secondsUntilTarget;
          final targetDuration = Duration(seconds: secondsElapsed);
          // Only seek if out of sync by more than 2 seconds (e.g. after lock screen pause)
          // to avoid audio hiccups/stutter on screen on or app resume.
          if ((player.position - targetDuration).abs().inSeconds > 2) {
            player.seek(targetDuration);
          }
        } else if (secondsUntilTarget <= 0) {
          stop();
        } else {
          player.seek(Duration.zero);
        }
      }
    });

    _playerStateSub?.cancel();
    _playerStateSub = player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        stop();
      }
    });

    _positionSub?.cancel();
    _positionSub = player.positionStream.listen((pos) {
      final dur = player.duration;
      if (dur != null && pos >= dur) {
        stop();
      }
    });
  }

  static Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        usage: AndroidAudioUsage.media,
      ),
      androidWillPauseWhenDucked: true,
    ));
    await session.setActive(true);
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

  static Future<String> _getPhysicalAudioFile(String assetPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = assetPath.split('/').last;
    final file = File('${dir.path}/$fileName');

    final byteData = await rootBundle.load(assetPath);
    if (!await file.exists() ||
        (await file.length()) != byteData.lengthInBytes) {
      await file.writeAsBytes(
        byteData.buffer
            .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        flush: true,
      );
    }
    return file.path;
  }

  static Future<void> _destroyPlayer() async {
    await _playingSub?.cancel();
    _playingSub = null;

    await _playerStateSub?.cancel();
    _playerStateSub = null;

    await _positionSub?.cancel();
    _positionSub = null;

    final playerToDispose = _player;
    _player = null;

    if (playerToDispose != null) {
      try {
        unawaited(playerToDispose.stop());
      } catch (_) {}
      try {
        await playerToDispose.dispose().timeout(
              const Duration(milliseconds: 500),
              onTimeout: () {},
            );
      } catch (_) {}
    }
  }

  static Future<void> startForTarget({
    required DateTime target,
    required String title,
    required String artist,
    required String album,
  }) async {
    // Tear down any existing player instance cleanly
    await _destroyPlayer();

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

    final player = AudioPlayer();
    _player = player;
    _setupPlayerListeners(player);

    await player.setAndroidAudioAttributes(
      const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        usage: AndroidAudioUsage.media,
      ),
    );

    // --> USE AudioSource.uri INSTEAD OF AudioSource.asset <--
    await player.setAudioSource(
      AudioSource.uri(
        Uri.file(physicalPath),
        tag: mediaItem,
      ),
    );

    if (secondsUntilTarget <= 7200 && secondsUntilTarget > 0) {
      final secondsElapsed = 7200 - secondsUntilTarget;
      await player.seek(Duration(seconds: secondsElapsed));
    } else if (secondsUntilTarget <= 0) {
      await stop();
      return;
    } else {
      await player.seek(Duration.zero);
    }

    await player.play();
  }

  static Future<void> stop() async {
    if (_isStopping) return;
    _isStopping = true;
    try {
      _target = null;
      await _destroyPlayer();

      try {
        final session = await AudioSession.instance;
        await session.setActive(false);
      } catch (_) {}

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
