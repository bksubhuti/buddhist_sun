import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class BackgroundTimePlayer {
  static AudioPlayer? _player;
  static DateTime? _target;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  static Future<void> startForTarget({
    required DateTime target,
    required String title,
    required String artist,
    required String album,
  }) async {
    await stop();
    _target = target;
    _player = AudioPlayer();

    // Listen to player state to see if it stalls or buffers indefinitely
    _player!.playerStateStream.listen((state) {
      debugPrint(
          "BackgroundTimePlayer State -- Processing: ${state.processingState}, Playing: ${state.playing}");
    });

    // Listen to errors from the underlying audio pipeline
    _player!.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace st) {
      debugPrint("BackgroundTimePlayer Pipeline Error: $e");
    });

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

    debugPrint(
        "BackgroundTimePlayer: Loading timer_countdownv2.m4a audio source...");
    await _player!.setAudioSource(
      AudioSource.asset(
        'assets/audio/timer_countdownv2.m4a',
        tag: MediaItem(
          id: 'timer_countdown_m4av2',
          title: title,
          artist: artist,
          album: album,
        ),
      ),
    );

    debugPrint(
        "BackgroundTimePlayer: Audio source loaded! Seeking to $seekPos...");
    await _player!.seek(seekPos);

    debugPrint(
        "BackgroundTimePlayer: Seek completed! Setting volume to max...");
    await _player!.setVolume(1.0);

    debugPrint("BackgroundTimePlayer: Telling player to play()...");
    await _player!.play();

    debugPrint(
        "Background timer started — playing from ${seekPos.inSeconds} sec (approx ${seekPos.inMinutes} min)");
  }

  static Future<void> stop() async {
    await _player?.stop();
    await _player?.dispose();
    _player = null;
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
