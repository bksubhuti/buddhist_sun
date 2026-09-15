//import 'package:buddhist_sun/src/services/solar_timer_service.dart';

import 'package:buddhist_sun/src/services/solar_calc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/background_time_player.dart';

//import 'package:logging/logging.dart';
//import 'package:intl/intl.dart' show DateFormat;

enum TtsState { playing, stopped, paused, continued }

mixin SolarTimerDelegate {
  void update();
  void setCountdownString(_countdownString);
  void setSpeakIsOn(_speakIsOn);
  void setNowString(_nowString);
}

class SolarTimerService {
  static final SolarTimerService _singleton = SolarTimerService._internal();
  DateTime get countdownTarget => _dtSolar;
  bool get isDawnMode => _isDawnMode();

  factory SolarTimerService() {
    return _singleton;
  }
  SolarTimerService._internal();

  SolarTimerDelegate? delegate;
  bool textToSpeech = true;

  DateTime _now = DateTime.now();
  String _voiceMessage = "Starting TTS";
  //bool _switchTTSValue = false;
  bool initialVoicing = false;
  String _nowString = "";
  String _countdownString = "";
  static const String LATE = "Late";

  DateTime _dtSolar = DateTime.now();
  Duration _duration = Duration(seconds: 1);

  /////////////////////////////////////////////////////////////////
  late FlutterTts flutterTts;

  String? language;
  String? engine;
  double pitch = 1.0;
  double rate = 0.5;
  bool isCurrentLanguageInstalled = false;

  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;
  get isPaused => ttsState == TtsState.paused;
  get isContinued => ttsState == TtsState.continued;
  TtsState ttsState = TtsState.stopped;

/////////////////////////////////////////////////////////////////
  late Timer _timer;
  bool _speakIsOn = false;
  bool _bLate = false;

  //int? _inputLength;

  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWeb => kIsWeb;
///////////////////////////////////////////////////////////////////////

  bool _isDoingTimerStuff = false;

  bool get speakIsOn => _speakIsOn;

  void doTimerStuff() async {
    // timer gets set one time.
    // use the preferences to understand what is controlling the speach.
    // always update the screen.. if the screen is alive, it will update
    // never cancel the timer.  Timer gets canceled when the app closes.
    //
    initTts();

    if (!_isDoingTimerStuff) {
      _bLate = false;
      _isDoingTimerStuff = true;
      timerCallback(); // Run immediately for synchronous initial state
      _timer = Timer.periodic(_duration, (timer) {
        timerCallback();
      });
    } // is doing timer stuff
  }

  Future _speak() async {
    if (!_bLate) {
      try {
        await initTts();
        await flutterTts.setSpeechRate(rate);
        await flutterTts.speak(_voiceMessage);
      } catch (e) {
        print("TTS speak error: $e");
      }
    }
  }

  /// Speaks the current remaining time via TTS when voice is first toggled ON.
  Future<void> speakInitialCountdown(DateTime target) async {
    await initTts();
    final now = DateTime.now();
    final diff = target.difference(now);
    if (diff.isNegative) return;
    final min = diff.inMinutes;
    final seconds = diff.inSeconds % 60;
    if (min == 0) {
      _voiceMessage = "$seconds seconds remaining";
    } else if (seconds == 0) {
      _voiceMessage = "$min minutes remaining";
    } else {
      _voiceMessage = "$min minutes and $seconds seconds remaining";
    }
    await _speak();
  }

  timerCallback() {
    // cannot debug without putting code outside of timer

    // if speak is on.. we speak..
    _speakIsOn = Prefs.speakIsOn;

    _now = DateTime.now();
    _dtSolar = _getCountdownTarget();
    _nowString =
        "${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}";
    // print("speak on is $_speakIsOn");
    // print(_nowString);

    // tell the window to show the new now time
    delegate?.setNowString(_nowString);

    final diff = _dtSolar.difference(_now);

    if (diff.isNegative) {
      doLateTime();
    } else {
      int min = diff.inMinutes;
      int seconds = diff.inSeconds % 60;

      // countdown string prep and send
      _countdownString =
          "${min.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
      delegate?.setCountdownString(_countdownString);
      delegate?.update(); // full set state if possible

      // if the speech toggle is on, starting message
      if (_speakIsOn && !initialVoicing) {
        initialVoicing = true;
        _voiceMessage =
            "${min.toString()} minutes and ${seconds.toString()} seconds remaining";
        _speak();
      }
    }
  }

  doLateTime() {
    _countdownString = LATE;
    delegate?.setCountdownString(_countdownString);
    delegate?.update(); // full set state if possible
    _bLate = true;

    _speakIsOn = false;
    Prefs.speakIsOn = false;
    delegate?.setSpeakIsOn(_speakIsOn);
    unawaited(BackgroundTimePlayer.stop());
  }

  bool _ttsInitialized = false;

  Future<void> initTts() async {
    if (_ttsInitialized) return;
    flutterTts = FlutterTts();
    _ttsInitialized = true;

    try {
      if (isAndroid) {
        await _getDefaultEngine();
      }
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(rate);
      await flutterTts.setPitch(pitch);
    } catch (_) {}

    flutterTts.setStartHandler(() {
      print("Playing");
      ttsState = TtsState.playing;
    });

    flutterTts.setCompletionHandler(() {
      print("Complete");
      ttsState = TtsState.stopped;
    });

    flutterTts.setCancelHandler(() {
      print("Cancel");
      ttsState = TtsState.stopped;
    });

    if (isWeb || isIOS) {
      flutterTts.setPauseHandler(() {
        print("Paused");
        ttsState = TtsState.paused;
      });

      flutterTts.setContinueHandler(() {
        print("Continued");
        ttsState = TtsState.continued;
      });
    }

    flutterTts.setErrorHandler((msg) {
      ttsState = TtsState.stopped;
    });
  }

  Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      print(engine);
    }
  }

  // ------------------------------------------------------------
// Determine whether dawn mode should be used
// ------------------------------------------------------------
  bool _isDawnMode() {
    final now = DateTime.now();

    // 2 AM boundary
    final twoAm = DateTime(now.year, now.month, now.day, 2, 0);

    // Get selected dawn DateTime
    late final DateTime dawnDT;
    switch (Prefs.dawnVal) {
      case 0:
        dawnDT = getNauticalTwilight();
        break;
      case 1:
        dawnDT = getSunrise40();
        break;
      case 2:
        dawnDT = getSunrise30();
        break;
      case 3:
        dawnDT = getPaAukAngleDawn();
        break;
      case 4:
        dawnDT = getNaUyanaAngleDawn();
        break;
      case 5:
        dawnDT = getCustomDawn();
        break;
      case 6:
        dawnDT = getCivilTwilight();
        break;
      case 7:
        dawnDT = getSunrise();
        break;
      default:
        dawnDT = getNauticalTwilight();
        break;
    }

    // Dawn + 1 hour
    final dawnPlus1h = dawnDT.add(const Duration(hours: 1));

    // Dawn must be before solar noon (normal case)
    final solarNoon = getSolarNoonDateTime();

    return now.isAfter(twoAm) &&
        now.isBefore(dawnPlus1h) &&
        dawnDT.isBefore(solarNoon);
  }

// ------------------------------------------------------------
// Get the correct countdown target (dawn or solar noon)
// ------------------------------------------------------------
  DateTime _getCountdownTarget() {
    final now = DateTime.now();

    // Compute solar noon with safety
    final solarNoon = getSolarNoonDateTime();

    // If dawn mode → countdown to dawn
    if (_isDawnMode()) {
      late final DateTime dawnDT;
      switch (Prefs.dawnVal) {
        case 0:
          dawnDT = getNauticalTwilight();
          break;
        case 1:
          dawnDT = getSunrise40();
          break;
        case 2:
          dawnDT = getSunrise30();
          break;
        case 3:
          dawnDT = getPaAukAngleDawn();
          break;
        case 4:
          dawnDT = getNaUyanaAngleDawn();
          break;
        case 5:
          dawnDT = getCustomDawn();
          break;
        case 6:
          dawnDT = getCivilTwilight();
          break;
        case 7:
          dawnDT = getSunrise();
          break;
        default:
          dawnDT = getNauticalTwilight();
          break;
      }

      return DateTime(now.year, now.month, now.day, dawnDT.hour, dawnDT.minute);
    }

    // Else → solar noon
    return solarNoon;
  }
}
