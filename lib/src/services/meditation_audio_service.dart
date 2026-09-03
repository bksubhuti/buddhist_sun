import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:buddhist_sun/src/models/meditation_timer_state.dart';

class MeditationAudioService {
  static final MeditationAudioService _instance =
      MeditationAudioService._internal();
  factory MeditationAudioService() => _instance;
  MeditationAudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidWillPauseWhenDucked: true,
      ));
      _isInitialized = true;
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _player.stop();
        }
      });
    } catch (e) {
      debugPrint("MeditationAudioService init error: $e");
    }
  }

  Future<void> playSound(MeditationSoundItem sound,
      {double volume = 1.0}) async {
    if (sound.assetPath == null || sound.id == 'none') return;
    try {
      await init();
      await _player.stop();
      await _player.setAudioSource(
        AudioSource.asset(
          sound.assetPath!,
          tag: MediaItem(
            id: sound.id,
            title: sound.displayName,
            album: 'Meditation Bell',
          ),
        ),
      );
      await _player.setVolume(volume.clamp(0.0, 1.0));
      _player.play(); // Play asynchronously without blocking timer execution
    } catch (e) {
      debugPrint("MeditationAudioService playSound error: $e");
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint("MeditationAudioService stop error: $e");
    }
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
      _isInitialized = false;
    } catch (e) {
      debugPrint("MeditationAudioService dispose error: $e");
    }
  }
}
