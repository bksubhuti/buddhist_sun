import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';

import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/solar_time.dart';
import 'package:buddhist_sun/src/services/notification_service.dart';

class CountdownAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();

  CountdownAudioHandler() {
    // Continually broadcast our forced single "Stop" control whenever player state changes
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.stop
        ],
        systemActions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.stop,
        },
        androidCompactActionIndices: const [0, 1],
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

  @override
  Future<void> stop() async {
    _aodTimer?.cancel();
    await _player.stop();
    _currentTarget = null;
    _originalTitle = null;
    playbackState.add(playbackState.value.copyWith(
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
        title: "⏸ PAUSED - $_originalTitle",
      ));
    }
    await _player.pause();
  }

  @override
  Future<void> play() async {
    // Restore the title immediately if we're resuming
    if (mediaItem.value != null && _originalTitle != null) {
      mediaItem.add(mediaItem.value!.copyWith(
        title: _originalTitle!,
      ));
    }
    // When resumed, NEVER just blindly play (which screws up timing).
    // Instead, recalculate EXACTLY where the playhead should be!
    if (_currentTarget != null) {
      final now = DateTime.now();
      final secondsUntilTarget = _currentTarget!.difference(now).inSeconds;

      Duration seekPos = Duration.zero;
      if (secondsUntilTarget <= 0) {
        seekPos = const Duration(minutes: 60);
      } else if (secondsUntilTarget > 3600) {
        seekPos = Duration.zero;
      } else {
        final secondsElapsed = 3600 - secondsUntilTarget;
        seekPos = Duration(seconds: secondsElapsed);
      }

      await _player.seek(seekPos);
    }
    await _player.play();
  }

  Future<void> startForTarget({
    required DateTime target,
    required String title,
    required String artist,
    required String album,
    Uri? albumArtUri,
  }) async {
    await _player.stop();
    _currentTarget = target;
    _originalTitle = title;
    final now = DateTime.now();
    final secondsUntilTarget = target.difference(now).inSeconds;

    Duration seekPos = Duration.zero;
    if (secondsUntilTarget <= 0) {
      seekPos = const Duration(minutes: 60);
    } else if (secondsUntilTarget > 3600) {
      seekPos = Duration.zero;
    } else {
      final secondsElapsed = 3600 - secondsUntilTarget;
      seekPos = Duration(seconds: secondsElapsed);
    }

    final item = MediaItem(
      id: 'timer_countdown_m4av2',
      title: title,
      artist: _getRemainingTimeString(),
      album: album,
      artUri:
          albumArtUri ?? Uri.parse('asset:///assets/buddhist_sun_app_logo.png'),
    );

    mediaItem.add(item);

    _aodTimer?.cancel();
    _aodTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final currentItem = mediaItem.value;
      if (currentItem == null || _currentTarget == null) return;

      final remaining = _currentTarget!.difference(DateTime.now());

      if (remaining.isNegative) {
        timer.cancel();
        mediaItem.add(currentItem.copyWith(artist: 'Time Reached'));
        return;
      }

      mediaItem.add(currentItem.copyWith(
        artist: _getRemainingTimeString(),
      ));
    });

    await _player.setAudioSource(
      AudioSource.asset('assets/audio/timer_countdownv2.m4a'),
    );
    await _player.seek(seekPos);
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
  static Uri? _albumArtUri;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      // Copy asset to local file so Android's MediaSession can read it
      final byteData =
          await rootBundle.load('assets/buddhist_sun_app_logo.png');
      final file = File(
          '${(await getApplicationDocumentsDirectory()).path}/buddhist_sun_app_logo.png');
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      _albumArtUri = file.uri;
    } catch (e) {
      debugPrint("Failed to load album art: $e");
    }

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
      albumArtUri: _albumArtUri,
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
