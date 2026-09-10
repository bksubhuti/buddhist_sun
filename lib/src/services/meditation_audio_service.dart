import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
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
  bool _isSessionActive = false;
  bool _isLoopingSilence = false;

  bool get isSessionActive => _isSessionActive;

  bool get _requiresSilenceKeepAlive =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final session = await AudioSession.instance;
      // Configure with duckOthers (matching BackgroundTimePlayer) so iOS treats
      // this as a primary playback session rather than mixable transient effects.
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
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
          if (_isSessionActive && !_isLoopingSilence) {
            if (_requiresSilenceKeepAlive) {
              // Bell finished while meditation session is active on iOS:
              // Immediately transition back to looping silence to maintain iOS background execution.
              _playSilenceLoop();
            } else {
              _player.stop();
            }
          } else if (!_isSessionActive) {
            _player.stop();
            session.setActive(false).catchError((_) => true);
          }
        }
      });
    } catch (e) {
      debugPrint("MeditationAudioService init error: $e");
    }
  }

  Future<AudioSource> _getAudioSource(String assetPath,
      {required MediaItem tag}) async {
    if (!kIsWeb) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = assetPath.split('/').last;
        final file = File('${dir.path}/$fileName');
        final byteData = await rootBundle.load(assetPath);
        if (!await file.exists() ||
            (await file.length()) != byteData.lengthInBytes) {
          await file.writeAsBytes(byteData.buffer
              .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        }
        return AudioSource.uri(Uri.file(file.path), tag: tag);
      } catch (e) {
        debugPrint("Error writing physical audio file for $assetPath: $e");
      }
    }
    return AudioSource.asset(assetPath, tag: tag);
  }

  Future<void> _playSilenceLoop() async {
    if (!_isSessionActive || !_requiresSilenceKeepAlive) return;
    try {
      _isLoopingSilence = true;
      await _player.stop();
      await _player.setLoopMode(LoopMode.one);
      // When just_audio_background is active, tag MUST be a valid MediaItem
      // otherwise just_audio_background throws a cast error.
      final source = await _getAudioSource(
        'assets/audio/silence.m4a',
        tag: const MediaItem(
          id: 'meditation_silence',
          title: 'Meditation',
          album: 'Buddhist Sun',
          duration: Duration(hours: 3),
        ),
      );
      await _player.setAudioSource(source);
      await _player.setVolume(0.05);
      _player.play();
    } catch (e) {
      debugPrint("MeditationAudioService _playSilenceLoop error: $e");
    }
  }

  Future<void> _playBell(MeditationSoundItem sound,
      {double volume = 1.0, String title = 'Meditation Bell'}) async {
    if (sound.assetPath == null || sound.id == 'none') return;
    try {
      _isLoopingSilence = false;
      await init();
      final session = await AudioSession.instance;
      await session.setActive(true);

      await _player.stop();
      await _player.setLoopMode(LoopMode.off);
      final source = await _getAudioSource(
        sound.assetPath!,
        tag: MediaItem(
          id: sound.id,
          title: sound.displayName,
          album: 'Buddhist Sun',
        ),
      );
      await _player.setAudioSource(source);
      await _player.setVolume(volume.clamp(0.0, 1.0));
      _player.play();
    } catch (e) {
      debugPrint("MeditationAudioService _playBell error: $e");
    }
  }

  /// Starts a meditation session: activates audio session and plays starting bell,
  /// or directly begins background silence loop if no bell is selected.
  Future<void> startSession({
    required MeditationSoundItem startSound,
    double volume = 1.0,
  }) async {
    try {
      _isSessionActive = true;
      await init();
      final session = await AudioSession.instance;
      await session.setActive(true);

      if (startSound.assetPath != null && startSound.id != 'none') {
        await _playBell(startSound, volume: volume, title: 'Starting Bell');
      } else {
        await _playSilenceLoop();
      }
    } catch (e) {
      debugPrint("MeditationAudioService startSession error: $e");
    }
  }

  /// Plays an interval bell during an active session, then resumes background silence.
  Future<void> playIntervalSound(
    MeditationSoundItem sound, {
    double volume = 1.0,
  }) async {
    if (!_isSessionActive || sound.assetPath == null || sound.id == 'none') {
      return;
    }
    await _playBell(sound, volume: volume, title: 'Interval Bell');
  }

  /// Plays the session ending bell and concludes background audio session.
  Future<void> playEndSound(
    MeditationSoundItem sound, {
    double volume = 1.0,
  }) async {
    _isSessionActive = false;
    _isLoopingSilence = false;
    if (sound.assetPath != null && sound.id != 'none') {
      await _playBell(sound, volume: volume, title: 'Meditation Complete');
    } else {
      await stop();
    }
  }

  /// Pauses active session audio and deactivates audio session to conserve battery.
  Future<void> pauseSession() async {
    _isSessionActive = false;
    _isLoopingSilence = false;
    try {
      await _player.stop();
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (e) {
      debugPrint("MeditationAudioService pauseSession error: $e");
    }
  }

  /// Resumes session audio with background silence loop.
  Future<void> resumeSession() async {
    _isSessionActive = true;
    try {
      if (_requiresSilenceKeepAlive) {
        await init();
        final session = await AudioSession.instance;
        await session.setActive(true);
        await _playSilenceLoop();
      }
    } catch (e) {
      debugPrint("MeditationAudioService resumeSession error: $e");
    }
  }

  /// Ends session without ending bell (e.g. user stops or resets timer).
  Future<void> endSession() async {
    _isSessionActive = false;
    _isLoopingSilence = false;
    await stop();
  }

  /// Standalone preview of bell sounds from the settings screen.
  Future<void> previewSound(
    MeditationSoundItem sound, {
    double volume = 1.0,
  }) async {
    _isSessionActive = false;
    await _playBell(sound, volume: volume, title: 'Preview Bell');
  }

  /// Backward-compatible alias for previewSound.
  Future<void> playSound(
    MeditationSoundItem sound, {
    double volume = 1.0,
  }) async {
    await previewSound(sound, volume: volume);
  }

  Future<void> stop() async {
    try {
      _isLoopingSilence = false;
      await _player.stop();
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (e) {
      debugPrint("MeditationAudioService stop error: $e");
    }
  }

  Future<void> dispose() async {
    try {
      _isSessionActive = false;
      _isLoopingSilence = false;
      await _player.dispose();
      _isInitialized = false;
    } catch (e) {
      debugPrint("MeditationAudioService dispose error: $e");
    }
  }
}
