import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';

import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/solar_time.dart';
import 'package:buddhist_sun/src/services/notification_service.dart';

class CountdownAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();

  CountdownAudioHandler() {
    // Continually broadcast our forced single "Stop" control whenever player state changes
// Continually broadcast our forced single "Stop" control whenever player state changes
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          playing ? MediaControl.pause : MediaControl.play, // Index 0
          MediaControl.stop // Index 1
        ],
        systemActions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.stop,
          MediaAction.seek
        },

        // THE FIX: Only put Play/Pause in the compact view
        // Stop will safely live in the expanded view.
        androidCompactActionIndices: const [0],

        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        stop();
      }
    });

    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace st) {
      debugPrint("BackgroundTimePlayer Pipeline Error: $e");
    });
  }

  DateTime? _currentTarget;
  String? _originalTitle;
  Timer? _aodTimer;
  StreamSubscription? _playlistIndexSub;
  Uri? _logoUri;

  Future<Uri> _getLogoUri() async {
    if (_logoUri != null) return _logoUri!;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/buddhist_sun_app_logo.png');
    if (!await file.exists()) {
      final byteData = await rootBundle.load('assets/buddhist_sun_app_logo.png');
      await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    _logoUri = file.uri;
    return _logoUri!;
  }

  String _getAudioAssetPath() {
    switch (Prefs.localeVal) {
      case 0: // English
        return 'assets/audio/timer_countdown_120_en.m4a';
      case 1: // Myanmar
        return 'assets/audio/timer_countdown_120_my.m4a';
      case 2: // Sinhala
        return 'assets/audio/timer_countdown_120_si.m4a';
      case 3: // Thai
        return 'assets/audio/timer_countdown_120_th.m4a';
      case 4: // Khmer
        return 'assets/audio/timer_countdown_120_km.m4a';
      case 5: // Chinese
        return 'assets/audio/timer_countdown_120_zh.m4a';
      case 6: // Vietnamese
        return 'assets/audio/timer_countdown_120_vi.m4a';
      case 7: // Hindi
        return 'assets/audio/timer_countdown_120_hi.m4a';
      case 8: // Bengali
        return 'assets/audio/timer_countdown_120_bn.m4a';
      default:
        return 'assets/audio/timer_countdown_120_en.m4a';
    }
  }

  Future<String> _getPhysicalAudioFile(String assetPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = assetPath.split('/').last;
    final file = File('${dir.path}/$fileName');

    if (!await file.exists()) {
      debugPrint(
          "Copying $assetPath to ${file.path} for iOS background playback compatibility");
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }

  @override
  Future<void> stop() async {
    _aodTimer?.cancel();
    _playlistIndexSub?.cancel();
    _currentTarget = null;
    _originalTitle = null;

    await _player.stop();

    // Explicitly broadcast idle and clear controls to force notification dismissal
    playbackState.add(playbackState.value.copyWith(
      controls: [],
      systemActions: const {},
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
    await super.stop();

    // Turn off Speech Notify globally and sync with active UI
    Prefs.instance.setBool(SPEAKISON, false);
    Prefs.speakIsOn = false;

    final solarService = SolarTimerService();
    solarService.initialVoicing = false;
    solarService.delegate?.setSpeakIsOn(false);

    await cancelAllTimerNotifications();
  }

  @override
  Future<void> onTaskRemoved() async {
    // When the app is swiped away / killed manually by the user
    await stop();
  }

  @override
  Future<void> pause() async {
    // Allows the user to temporarily silence it if they want.
    if (mediaItem.value != null && _originalTitle != null) {
      mediaItem.add(mediaItem.value!.copyWith(
        title: "🔴 PAUSED - $_originalTitle",
        artUri: await _getLogoUri(),
      ));
    }
    await _player.pause();
  }

  @override
  Future<void> play() async {
    // Restore the title immediately if we're resuming
    if (mediaItem.value != null && _originalTitle != null) {
      // Revert the title back from 🔴 PAUSED
      mediaItem.add(mediaItem.value!.copyWith(
        title: _originalTitle!,
        artUri: await _getLogoUri(),
      ));
    }

    // When resumed, we MUST recalculate exact position!
    if (_currentTarget != null) {
      final now = DateTime.now();
      final secondsUntilTarget = _currentTarget!.difference(now).inSeconds;
      final audioAsset = _getAudioAssetPath();
      final physicalPath = await _getPhysicalAudioFile(audioAsset);

      if (secondsUntilTarget > 7200) {
        await _player.setAudioSource(
          AudioSource.file(physicalPath),
        );
        await _player.seek(Duration.zero);
      } else {
        await _player.setAudioSource(
          AudioSource.file(physicalPath),
        );
        Duration seekPos = Duration.zero;
        if (secondsUntilTarget <= 0) {
          seekPos = const Duration(minutes: 120);
        } else {
          final secondsElapsed = 7200 - secondsUntilTarget;
          seekPos = Duration(seconds: secondsElapsed);
        }
        await _player.seek(seekPos);
      }
    }
    await _player.play();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> startForTarget({
    required DateTime target,
    required String title,
    required String artist,
    required String album,
  }) async {
    await _player.stop();
    _currentTarget = target;
    _originalTitle = title;

    final logoUri = await _getLogoUri();

    final item = MediaItem(
      id: 'timer_countdown_m4av2',
      title: title,
      artist: _getRemainingTimeString(),
      album: album,
      duration: const Duration(minutes: 120),
      artUri: logoUri,
    );

    mediaItem.add(item);

    _aodTimer?.cancel();
    _aodTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final currentItem = mediaItem.value;
      if (currentItem == null || _currentTarget == null) return;

      final remaining = _currentTarget!.difference(DateTime.now());

      if (remaining.isNegative) {
        timer.cancel();
        mediaItem.add(currentItem.copyWith(
          artist: 'Time Reached',
          artUri: _logoUri,
        ));
        return;
      }

      mediaItem.add(currentItem.copyWith(
        artist: _getRemainingTimeString(),
        artUri: _logoUri,
      ));
    });

    final now2 = DateTime.now();
    final secondsUntilTarget = target.difference(now2).inSeconds;
    final audioAsset = _getAudioAssetPath();
    final physicalPath = await _getPhysicalAudioFile(audioAsset);

    if (secondsUntilTarget > 7200) {
      await _player.setAudioSource(
        AudioSource.file(physicalPath),
      );
      await _player.seek(Duration.zero);
    } else {
      await _player.setAudioSource(
        AudioSource.file(physicalPath),
      );
      Duration seekPos = Duration.zero;
      if (secondsUntilTarget <= 0) {
        seekPos = const Duration(minutes: 120);
      } else {
        final secondsElapsed = 7200 - secondsUntilTarget;
        seekPos = Duration(seconds: secondsElapsed);
      }
      await _player.seek(seekPos);
    }

    await _player.setVolume(1.0);
    await _player.play();
  }

  String _getRemainingTimeString() {
    if (_currentTarget == null) return '';
    final remaining = _currentTarget!.difference(DateTime.now());
    if (remaining.isNegative) return 'Time Reached';
    final minutes = remaining.inMinutes;
    return 'Remaining: $minutes min${minutes == 1 ? '' : 's'}';
  }
}

class BackgroundTimePlayer {
  static CountdownAudioHandler? _handler;
  static DateTime? _target;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    await session.setActive(true);

    _handler = await AudioService.init(
      builder: () => CountdownAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'dawn_audio_channel',
        androidNotificationChannelName: 'Dawn Audio',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true, // Fixes sticky notification on stop
        androidNotificationIcon:
            'drawable/buddhist_sun_silo_app_icon', // Usually a transparent silhouette
      ),
    );
    _initialized = true;
  }

  static Future<void> startForTarget({
    required DateTime target,
    required String title,
    required String artist,
    required String album,
  }) async {
    _target = target;
    await _handler?.startForTarget(
      target: target,
      title: title,
      artist: artist,
      album: album,
    );
  }

  static Future<void> stop() async {
    await _handler?.stop();
    _target = null;
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
