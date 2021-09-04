//import 'package:buddhist_sun/src/services/solar_timer_service.dart';

import 'package:buddhist_sun/src/services/solar_calc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:buddhist_sun/src/models/prefs.dart';

//import 'package:logging/logging.dart';
//import 'package:intl/intl.dart' show DateFormat;
import 'package:solar_calculator/solar_calculator.dart';

enum TtsState { playing, stopped, paused, continued }

mixin SolarTimerDelegate {
  void update();
  void setCountdownString(_countdownString);
  void setSpeakIsOn(_speakIsOn);
  void setNowString(_nowString);
}

class SolarTimerService {
  static final SolarTimerService _singleton = SolarTimerService._internal();

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
      // only set the time once.. this gets called
      _isDoingTimerStuff =
          true; // "initinstance" which gets called each page flip
      _timer = Timer.periodic(_duration, (timer) {
        timerCallback();
      });
    } // is doing timer stuff
  }

  Future _speak() async {
    if (!_bLate) {
      await flutterTts.setSpeechRate(rate);
      await flutterTts.setVolume(Prefs.volume);
      await flutterTts.awaitSpeakCompletion(true);
      await flutterTts.speak(_voiceMessage);
    }
  }

  timerCallback() {
    // cannot debug without putting code outside of timer

    // if speak is on.. we speak..
    _speakIsOn = Prefs.speakIsOn;

    _now = DateTime.now();
    Instant inst = getSolarNoon();
    _dtSolar =
        DateTime(inst.year, inst.month, inst.day, inst.hour, inst.minute);
    _nowString =
        "${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}";
    print("speak on is $_speakIsOn");
    print(_nowString);

    // tell the window to show the new now time
    delegate!.setNowString(_nowString);

    // setup the countdown time remaining..
    int min = _dtSolar.difference(_now).inMinutes;
    int seconds = (_dtSolar.difference(_now).inSeconds) % 60;

    // this section prepares the message to speak and display
    // for the view.. if the view is alive it will refresh the build.
    // if it is not alive , it will ignore.

    // minutes at zero can also mean 59 seconds left..
    if (min >= 0) {
      // countdown string prep and send
      _countdownString =
          "${min.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
      // send countdown string for display
      if (!_bLate) {
        delegate!.setCountdownString(_countdownString);
        delegate!.update(); // full set state if possible
      } else {
        _countdownString = LATE;
        delegate!.setCountdownString(_countdownString);
        delegate!.update(); // full set state if possible
      }
    }
    if (min < 0) {
      doLateTime();
      /*Prefs.speakIsOn = false;
      _countdownString = "Late";
      delegate!.setCountdownString(_countdownString);
      delegate!.setSpeakIsOn(_speakIsOn);

      delegate!.update(); // full set state if possible
      */
    }
    print(min);
    print("countdown is:  $_countdownString");
    print(_countdownString);

    // if the speech toggle is on..
    if (_speakIsOn) {
      // starting message
      if (initialVoicing == false) {
        initialVoicing = true;
        _voiceMessage =
            "${min.toString()} minutes and ${seconds.toString()} seconds remaining";
        _speak();
      }

      switch (min) {
        case 50:
        case 40:
        case 30:
        case 20:
        case 15:
        case 10:
        case 8:
        case 6:
        case 5:
        case 4:
        case 3:
        case 2:
        case 1:
          if (seconds == 0) {
            // prepare voice message  at "new" minute change
            _voiceMessage = "${min.toString()} minutes remaining";
            _speak();
          }
          break;
        case 0:
          if (!_bLate) {
            if (seconds == 0) {
              // countdown finished
              // flick the switch on parent
              doLateTime();
            }
          }
          break;
      } // switch

    }
  }

  doLateTime() {
    if (Prefs.speakIsOn) {
      _speakIsOn = false;
      Prefs.speakIsOn = false;
      delegate!.setSpeakIsOn(_speakIsOn);

      // set final tts message and speak
      _voiceMessage = "Your time has passed";
      _speak(); // speaking has finished.
    }
    _countdownString = LATE;
    delegate!.setCountdownString(_countdownString);
    delegate!.update(); // full set state if possible
    _bLate = true;
  }

  initTts() {
    flutterTts = FlutterTts();

    if (isAndroid) {
      _getDefaultEngine();
    }

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
}
