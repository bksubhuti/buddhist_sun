import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:buddhist_sun/src/models/meditation_timer_state.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/meditation_audio_service.dart';
import 'package:buddhist_sun/src/services/notification_service.dart';

class MeditationTimerProvider extends ChangeNotifier {
  final MeditationAudioService _audioService = MeditationAudioService();

  MeditationTimerMode _mode = MeditationTimerMode.timed;
  MeditationTimerStatus _status = MeditationTimerStatus.idle;

  int _durationMinutes = 30;
  int _endAtHour = 0;
  int _endAtMinute = 0;

  int _elapsedSeconds = 0;
  int _remainingSeconds = 0;
  int _totalDurationSeconds = 0;

  DateTime? _startTime;
  DateTime? _endTime;
  DateTime? _pauseStartTime;
  int _totalPauseDurationSeconds = 0;

  MeditationSoundItem _startSound = MeditationSoundItem.fromId('Bowl');
  MeditationSoundItem _intervalSound = MeditationSoundItem.fromId('Bowl');
  MeditationSoundItem _endSound = MeditationSoundItem.fromId('Bowl');
  int _intervalMinutes = 0;
  bool _keepScreenOn = true;
  int _volume = 80;

  int _lastIntervalMinute = -1;
  Timer? _tickTimer;

  // Getters
  MeditationTimerMode get mode => _mode;
  MeditationTimerStatus get status => _status;
  int get durationMinutes => _durationMinutes;
  int get endAtHour => _endAtHour;
  int get endAtMinute => _endAtMinute;
  int get elapsedSeconds => _elapsedSeconds;
  int get remainingSeconds => _remainingSeconds;
  int get totalDurationSeconds => _totalDurationSeconds;
  MeditationSoundItem get startSound => _startSound;
  MeditationSoundItem get intervalSound => _intervalSound;
  MeditationSoundItem get endSound => _endSound;
  int get intervalMinutes => _intervalMinutes;
  bool get keepScreenOn => _keepScreenOn;
  int get volume => _volume;
  double get volumeNormalized => (_volume / 100.0).clamp(0.0, 1.0);

  double get progress {
    if (_status == MeditationTimerStatus.completed) return 1.0;
    if (_mode == MeditationTimerMode.unlimited) return 0.0;
    if (_totalDurationSeconds <= 0) return 0.0;
    final p = 1.0 - (_remainingSeconds / _totalDurationSeconds);
    return p.clamp(0.0, 1.0);
  }

  String get formattedDisplayTime {
    if (_status == MeditationTimerStatus.idle) {
      if (_mode == MeditationTimerMode.timed) {
        final hours = _durationMinutes ~/ 60;
        final mins = _durationMinutes % 60;
        if (hours > 0) {
          return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:00';
        }
        return '${mins.toString().padLeft(2, '0')}:00';
      } else if (_mode == MeditationTimerMode.endAt) {
        final h = _endAtHour == 0
            ? 12
            : (_endAtHour > 12 ? _endAtHour - 12 : _endAtHour);
        final amPm = _endAtHour >= 12 ? 'PM' : 'AM';
        return '$h:${_endAtMinute.toString().padLeft(2, '0')} $amPm';
      }
      return '00:00';
    }

    if (_mode == MeditationTimerMode.unlimited) {
      final hours = _elapsedSeconds ~/ 3600;
      final minutes = (_elapsedSeconds % 3600) ~/ 60;
      final seconds = _elapsedSeconds % 60;
      if (hours > 0) {
        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    // timed or endAt: show remaining countdown
    final hours = _remainingSeconds ~/ 3600;
    final minutes = (_remainingSeconds % 3600) ~/ 60;
    final seconds = _remainingSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedElapsedTime {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  MeditationTimerProvider() {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    _durationMinutes = Prefs.meditationDurationMinutes;
    final modeStr = Prefs.meditationTimerMode;
    if (modeStr == 'endAt') {
      _mode = MeditationTimerMode.endAt;
    } else if (modeStr == 'unlimited') {
      _mode = MeditationTimerMode.unlimited;
    } else {
      _mode = MeditationTimerMode.timed;
    }

    _startSound = MeditationSoundItem.fromId(Prefs.meditationStartSound);
    _intervalSound = MeditationSoundItem.fromId(Prefs.meditationIntervalSound);
    _endSound = MeditationSoundItem.fromId(Prefs.meditationEndSound);
    _intervalMinutes = Prefs.meditationIntervalMinutes;
    _keepScreenOn = Prefs.meditationKeepScreenOn;
    _volume = Prefs.meditationVolume;

    final now = DateTime.now().add(Duration(minutes: _durationMinutes));
    _endAtHour = now.hour;
    _endAtMinute = now.minute;
  }

  void setMode(MeditationTimerMode newMode) {
    _mode = newMode;
    Prefs.meditationTimerMode = newMode.name;
    notifyListeners();
  }

  void setDurationMinutes(int minutes) {
    if (minutes <= 0) minutes = 1;
    _durationMinutes = minutes;
    Prefs.meditationDurationMinutes = minutes;
    notifyListeners();
  }

  void setEndAtTime(int hour, int minute) {
    _endAtHour = hour;
    _endAtMinute = minute;
    notifyListeners();
  }

  void setStartSound(MeditationSoundItem sound) {
    _startSound = sound;
    Prefs.meditationStartSound = sound.id;
    notifyListeners();
  }

  void setIntervalSound(MeditationSoundItem sound) {
    _intervalSound = sound;
    Prefs.meditationIntervalSound = sound.id;
    notifyListeners();
  }

  void setEndSound(MeditationSoundItem sound) {
    _endSound = sound;
    Prefs.meditationEndSound = sound.id;
    notifyListeners();
  }

  void setIntervalMinutes(int minutes) {
    _intervalMinutes = minutes;
    Prefs.meditationIntervalMinutes = minutes;
    notifyListeners();
  }

  void setVolume(int value) {
    _volume = value.clamp(0, 100);
    Prefs.meditationVolume = _volume;
    notifyListeners();
  }

  Future<void> previewSound(MeditationSoundItem sound) async {
    await _audioService.playSound(sound, volume: volumeNormalized);
  }

  void setKeepScreenOn(bool value) {
    _keepScreenOn = value;
    Prefs.meditationKeepScreenOn = value;
    if (_status == MeditationTimerStatus.running) {
      if (value) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    }
    notifyListeners();
  }

  Future<void> startSession() async {
    _elapsedSeconds = 0;
    _totalPauseDurationSeconds = 0;
    _lastIntervalMinute = -1;

    await _beginRunning();
  }

  Future<void> _beginRunning() async {
    _status = MeditationTimerStatus.running;
    _startTime = DateTime.now();

    switch (_mode) {
      case MeditationTimerMode.timed:
        _totalDurationSeconds = _durationMinutes * 60;
        _remainingSeconds = _totalDurationSeconds;
        _endTime = _startTime!.add(Duration(seconds: _totalDurationSeconds));
        break;
      case MeditationTimerMode.endAt:
        final now = _startTime!;
        var target = DateTime(
          now.year,
          now.month,
          now.day,
          _endAtHour,
          _endAtMinute,
        );
        if (target.isBefore(now)) {
          target = target.add(const Duration(days: 1));
        }
        _endTime = target;
        _totalDurationSeconds = _endTime!.difference(now).inSeconds;
        _remainingSeconds = _totalDurationSeconds;
        break;
      case MeditationTimerMode.unlimited:
        _totalDurationSeconds = 0;
        _remainingSeconds = 0;
        _endTime = null;
        break;
    }

    if (_keepScreenOn) {
      try {
        await WakelockPlus.enable();
      } catch (_) {}
    }

    _startTick();
    notifyListeners();

    // Play starting bell asynchronously without delaying timer
    _audioService.playSound(_startSound, volume: volumeNormalized);

    // Schedule background completion notification if timed / endAt
    if (_endTime != null) {
      scheduleMeditationEndNotification(
        targetTime: _endTime!,
        title: 'Meditation Complete',
        body:
            'Your ${_mode == MeditationTimerMode.timed ? "$_durationMinutes minute " : ""}meditation session has ended.',
      );
    }
  }

  void _startTick() {
    _tickTimer?.cancel();
    _tickTimer =
        Timer.periodic(const Duration(milliseconds: 250), (_) => _onTick());
  }

  void _stopTick() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  void _onTick() {
    if (_status != MeditationTimerStatus.running) return;

    final now = DateTime.now();
    final totalSeconds =
        now.difference(_startTime!).inSeconds - _totalPauseDurationSeconds;
    _elapsedSeconds = totalSeconds >= 0 ? totalSeconds : 0;

    // Check interval bell
    if (_intervalMinutes > 0 && _elapsedSeconds > 0) {
      final currentMinute = _elapsedSeconds ~/ 60;
      if (currentMinute > 0 &&
          currentMinute % _intervalMinutes == 0 &&
          currentMinute != _lastIntervalMinute) {
        _lastIntervalMinute = currentMinute;
        _audioService.playSound(_intervalSound, volume: volumeNormalized);
      }
    }

    if (_mode == MeditationTimerMode.timed ||
        _mode == MeditationTimerMode.endAt) {
      if (_endTime != null) {
        final remaining = _totalDurationSeconds - _elapsedSeconds;
        _remainingSeconds = remaining >= 0 ? remaining : 0;

        if (now.isAfter(_endTime!) || _elapsedSeconds > _totalDurationSeconds) {
          _remainingSeconds = 0;
          _completeSession();
          return;
        }
      }
    }

    notifyListeners();
  }

  Future<void> pauseSession() async {
    if (_status != MeditationTimerStatus.running) return;
    _status = MeditationTimerStatus.paused;
    _pauseStartTime = DateTime.now();
    _stopTick();
    await cancelMeditationNotifications();
    notifyListeners();
  }

  Future<void> resumeSession() async {
    if (_status != MeditationTimerStatus.paused) return;
    final pauseDuration = DateTime.now().difference(_pauseStartTime!);
    _totalPauseDurationSeconds += pauseDuration.inSeconds;

    if (_endTime != null) {
      _endTime = _endTime!.add(pauseDuration);
      await scheduleMeditationEndNotification(
        targetTime: _endTime!,
        title: 'Meditation Complete',
        body: 'Your meditation session has ended.',
      );
    }

    _status = MeditationTimerStatus.running;
    _startTick();
    notifyListeners();
  }

  Future<void> _completeSession() async {
    _stopTick();
    await cancelMeditationNotifications();
    try {
      await WakelockPlus.disable();
    } catch (_) {}

    _status = MeditationTimerStatus.completed;
    _remainingSeconds = 0;
    if (_mode == MeditationTimerMode.timed && _totalDurationSeconds > 0) {
      _elapsedSeconds = _totalDurationSeconds;
    }

    await _audioService.playSound(_endSound, volume: volumeNormalized);
    notifyListeners();
  }

  Future<void> stopSession({bool completed = false}) async {
    _stopTick();
    await cancelMeditationNotifications();
    try {
      await WakelockPlus.disable();
    } catch (_) {}

    if (completed) {
      _status = MeditationTimerStatus.completed;
      await _audioService.playSound(_endSound, volume: volumeNormalized);
    } else {
      _status = MeditationTimerStatus.idle;
    }
    notifyListeners();
  }

  void resetToIdle() {
    _stopTick();
    _status = MeditationTimerStatus.idle;
    _elapsedSeconds = 0;
    _remainingSeconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
