// helper for tts
//import 'package:buddhist_sun/src/services/solar_timer_service.dart';
/*
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

//import 'package:logging/logging.dart';
import 'package:intl/intl.dart' show DateFormat;

enum TtsState { playing, stopped, paused, continued }

////////////////////////////////
// callback defined i want to pass inside
void somecallback(){}

///////////////////////////////////////////////////////////////
// I want to call this...like this with a function parameter.
SolarTimerService mySTS = SolarTimerService();


class SolarTimerService {
  static late SolarTimerService? _instance = null;
  
  ////////////////////////////////
  ///  i need this member to be initialized.. or set somehow
  /// 
  //final VoidCallback mycallback;
  /////////////////////////////////////////
  SolarTimerService._internal() {
    _instance = this;
  }
  
  // i prefer this notation.. this notation  works
  // but i don't know why i need the bang operator to make this work.
  //////////////////////////////

  factory SolarTimerService() {
    if (_instance == null) {
      _instance = SolarTimerService._internal();
    }
  
    return _instance!;
  }

// example from article you sent me 
// i don't understand this type of stuff notation
///////////////////////
//factory SolarTimerService() => _instance ?? SolarTimerService._internal();

}



  //late void Function(int) callback;
//  void setPageState(Null Function() param0) {}


  factory SolarTimerService() {
    if (_instance == null) {
      _instance = SolarTimerService._internal();
    }
  
    return _instance;
  }

  SolarTimerService._internal() {
    _instance = this;
  }
}






  DateTime _now = DateTime.now();
  String _voiceMessage = "Starting TTS";
  bool _switchTTSValue = false;
  bool _initialVoicing = false;
  String _solarTime = "";
  String _nowString = "";
  String _countdownString = "";

  DateTime _dtSolar = DateTime.now();
  Duration _duration = Duration(seconds: 1);

  /////////////////////////////////////////////////////////////////
  late FlutterTts flutterTts;

  String? language;
  String? engine;
  double _volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  bool isCurrentLanguageInstalled = false;
  late Timer _timer;
  bool _speakIsOn = false;

  //int? _inputLength;

  TtsState ttsState = TtsState.stopped;

  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;
  get isPaused => ttsState == TtsState.paused;
  get isContinued => ttsState == TtsState.continued;

  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWeb => kIsWeb;
///////////////////////////////////////////////////////////////////////

  void doTimerStuff() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    _speakIsOn = prefs.getBool("speakIsOn") ?? _speakIsOn;

    _timer = Timer.periodic(_duration, (timer) {
      _now = DateTime.now();
      _nowString =
          "${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}";

      int min = _dtSolar.difference(_now).inMinutes;
      int seconds = (_dtSolar.difference(_now).inSeconds) % 60;

      if (min >= 0) {
        _countdownString =
            "${min.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
        _voiceMessage = "${min.toString()} minutes remaining";
      } else {
        _countdownString = "Late";
        _voiceMessage = "I'm sorry, but the time has passed.";
      }
      if (_speakIsOn) {
        if (_initialVoicing == false) {
          _initialVoicing = true;
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
              _speak();
            }
            break;
        }
        if ((min == 0) && (seconds == 0)) {
          _speak(true);
          _timer.cancel();
          _speakIsOn = false;
        }
        if (min < 0) {
          _speak(true);
          _timer.cancel();
          setPageState(() {
            _speakIsOn = false;
          });
        }
      }
//      getTogglesFromPrefs();
//      setPageState();
    });
  }

  Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      print(engine);
    }
  }

  initTts() {
    flutterTts = FlutterTts();

    if (isAndroid) {
      _getDefaultEngine();
    }

    flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
      });
    });

    if (isWeb || isIOS) {
      flutterTts.setPauseHandler(() {
        setState(() {
          print("Paused");
          ttsState = TtsState.paused;
        });
      });

      flutterTts.setContinueHandler(() {
        setState(() {
          print("Continued");
          ttsState = TtsState.continued;
        });
      });
    }

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
  }
  

  }

  Future _speak([bool? finished]) async {
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setVolume(_volume);
    if (_countdownString != "") {
      if (_countdownString.isNotEmpty) {
        await flutterTts.awaitSpeakCompletion(true);
        if (finished != null) {
          await flutterTts.speak("Your Time has passed");
        } else {
          await flutterTts.speak(_voiceMessage);
        }
      }
    }
  }
}
*/