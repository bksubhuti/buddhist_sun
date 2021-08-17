import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_calculator/solar_calculator.dart';
import 'package:solar_calculator/src/instant.dart';
import 'package:flutter_tts/flutter_tts.dart';

class CountdownTimerView extends StatefulWidget {
  const CountdownTimerView({Key? key, required this.goToHome})
      : super(key: key);
  final VoidCallback goToHome;

  @override
  _CountdownTimerViewState createState() => _CountdownTimerViewState();
}

enum TtsState { playing, stopped, paused, continued }

class _CountdownTimerViewState extends State<CountdownTimerView> {
  Duration _duration = Duration(seconds: 1);
  late Timer _timer;
  String _solarTime = "";
  String _nowString = "";
  String _countdownString = "";
  DateTime _now = DateTime.now();
  DateTime _dtSolar = DateTime.now();
  bool _speakIsOn = false;
  bool _initialVoicing = false;

  /////////////////////////////////////////////////////////////////
  late FlutterTts flutterTts;
  String? language;
  String? engine;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  bool isCurrentLanguageInstalled = false;

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

  @override
  void initState() {
    _timer = Timer.periodic(_duration, (timer) {
      _now = DateTime.now();
      _nowString =
          "${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}";

      int min = _dtSolar.difference(_now).inMinutes;
      int seconds = (_dtSolar.difference(_now).inSeconds) % 60;

      _countdownString =
          "${min.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

      if (_speakIsOn) {
        if (_initialVoicing == false) {
          _initialVoicing = true;
          _speak();
        }
        if ((min == 30) && (seconds == 0)) {
          _speak();
        }
        if ((min == 20) && (seconds == 0)) {
          _speak();
        }
        if ((min == 15) && (seconds == 0)) {
          _speak();
        }
        if ((min == 10) && (seconds == 0)) {
          _speak();
        }
        if ((min == 8) && (seconds == 0)) {
          _speak();
        }
        if ((min == 6) && (seconds == 0)) {
          _speak();
        }
        if ((min == 5) && (seconds == 0)) {
          _speak();
        }
        if ((min == 4) && (seconds == 0)) {
          _speak();
        }
        if ((min == 3) && (seconds == 0)) {
          _speak();
        }
        if ((min == 2) && (seconds == 0)) {
          _speak();
        }
        if ((min == 1) && (seconds == 0)) {
          _speak();
        }
        if ((min == 0) && (seconds == 0)) {
          _speak(true);
          _timer.cancel();
          _speakIsOn = false;
        }
      }

      setState(() {
//        if (_counter > 0) {
        //        _counter--;
        //    }
      });
    });

    GetSolarTime();
    initTts();
    super.initState();
  }

  void GetSolarTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    double lat = prefs.getDouble("lat") ?? 1.1;
    double lng = prefs.getDouble("lng") ?? 1.1;
    double offset = prefs.getDouble("offset") ?? 1.1;

    DateTime nw = DateTime.now();
    Instant instant = Instant(
        year: nw.year,
        month: nw.month,
        day: nw.day,
        hour: nw.hour,
        timeZoneOffset: offset);
    SolarCalculator calc = SolarCalculator(instant, lat, lng);
    Instant inst2 = calc.sunTransitTime;

    _dtSolar = DateTime(
        nw.year, nw.month, nw.day, inst2.hour, inst2.minute, inst2.second);

    _solarTime =
        "${inst2.hour.toString().padLeft(2, "0")}:${inst2.minute.toString().padLeft(2, "0")}";
  }

  @override
  void dispose() {
    _timer.cancel();
    flutterTts.stop();
    super.dispose();
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

  Future _speak([bool? finished]) async {
    if (_countdownString != "") {
      if (_countdownString.isNotEmpty) {
        await flutterTts.awaitSpeakCompletion(true);
        if (finished != null) {
          await flutterTts.speak("Your Time has passed");
        } else {
          await flutterTts.speak(_countdownString);
        }
      }
    }
  }

  //Future<dynamic> _getLanguages() => flutterTts.getLanguages;

  //Future<dynamic> _getEngines() => flutterTts.getEngines;

/*
  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  Future _pause() async {
    var result = await flutterTts.pause();
    if (result == 1) setState(() => ttsState = TtsState.paused);
  }

  List<DropdownMenuItem<String>> getEnginesDropDownMenuItems(dynamic engines) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in engines) {
      items.add(DropdownMenuItem(
          value: type as String?, child: Text(type as String)));
    }
    return items;
  }

  void changedEnginesDropDownItem(String? selectedEngine) {
    flutterTts.setEngine(selectedEngine!);
    language = null;
    setState(() {
      engine = selectedEngine;
    });
  }

  List<DropdownMenuItem<String>> getLanguageDropDownMenuItems(
      dynamic languages) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in languages) {
      items.add(DropdownMenuItem(
          value: type as String?, child: Text(type as String)));
    }
    return items;
  }

  void changedLanguageDropDownItem(String? selectedType) {
    setState(() {
      language = selectedType;
      flutterTts.setLanguage(language!);
      if (isAndroid) {
        flutterTts
            .isLanguageInstalled(language!)
            .then((value) => isCurrentLanguageInstalled = (value as bool));
      }
    });
  }
  void _onChange(String text) {
    setState(() {
      //_newVoiceText = text;
    });
  }
*/

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Container(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 30,
            ),
            Text(_solarTime,
                style: TextStyle(
                    color: Colors.orange[600],
                    fontSize: 55,
                    fontWeight: FontWeight.bold)),
            Text("Solar Noon:",
                style: TextStyle(
                    color: Colors.orange[600],
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Divider(
              height: 30.0,
              color: Colors.grey,
            ),
            Text(_nowString,
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 48,
                    fontWeight: FontWeight.bold)),
            Text("Current Time",
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Divider(
              height: 30.0,
              color: Colors.grey,
            ),
            Text(_countdownString,
                style: TextStyle(
                    color: Colors.green,
                    fontSize: 60,
                    fontWeight: FontWeight.bold)),
            Text("Time Left",
                style: TextStyle(
                    color: Colors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            SizedBox(
              height: 30,
            ),
            ElevatedButton.icon(
                label: Text("Start TTS"),
                icon: Icon(Icons.timelapse),
                onPressed: () {
                  _speakIsOn = true;
                  _speak();
                }),
          ]),
        ),
      ),
    );
  }
}
