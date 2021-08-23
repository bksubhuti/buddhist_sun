import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_calculator/solar_calculator.dart';
import 'package:solar_calculator/src/instant.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock/wakelock.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:motion_toast/resources/arrays.dart';
//import 'package:volume/volume.dart';

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
  String _voiceMessage = "Starting TTS";
  bool _switchTTSValue = false;
  bool _wakeOn = false;
  bool _backgroundOn = false;

  /////////////////////////////////////////////////////////////////
  late FlutterTts flutterTts;
  String? language;
  String? engine;
  double _volume = 0.5;
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
          setState(() {
            _speakIsOn = false;
          });
        }
      }

      setState(() {});
    });

    GetSolarTime();
    initTts();
    super.initState();
  }

  Future<bool> setupBackground() async {
    bool success =
        await FlutterBackground.initialize(androidConfig: androidConfig);
    print("result from setup backgroud is $success");
    return success;
  }

  final androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "flutter_background example app",
    notificationText:
        "Background notification for keeping the example app running in the background",
    notificationImportance: AndroidNotificationImportance.Default,
    notificationIcon: AndroidResource(
        name: 'background_icon',
        defType: 'drawable'), // Default is ic_launcher from folder mipmap
  );

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
    Wakelock.disable();
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

  void _backgroundSwitchChange(bSwitch) async {
    bool successEnabled = false;
    bool bkrunning = false;
    bool successInit = false;
    bool hasPermissions = await FlutterBackground.hasPermissions;
    if (bSwitch) {
      if (!hasPermissions) {
        await showBackgroundInfoDialog(context);
      }
      successInit =
          await FlutterBackground.initialize(androidConfig: androidConfig);
      if (successInit) {
        _displayMotionToast(context, "Background Initialized");
        if (successInit) {
          bkrunning = FlutterBackground.isBackgroundExecutionEnabled;
          if (!bkrunning) {
            successEnabled =
                await FlutterBackground.enableBackgroundExecution();
          } // bkrunning
        } // has permission
        if (successEnabled || bkrunning) {
          _displayMotionToast(context, "Background Enabled");
        } // successEnabled || bkrunning
        else {
          _displayErrorMotionToast(context, "Background not set");

          bSwitch = false;
        }
      } else {
        _displayErrorMotionToast(context, "Background initialize error");

        bSwitch = false;
      }
    } // switch enabled
    else {
      if (FlutterBackground.isBackgroundExecutionEnabled) {
        await FlutterBackground.disableBackgroundExecution();
        _displayMotionToast(context, "Background disabled");
      }
    } // else no switch on
    setState(() {
      _backgroundOn = bSwitch;
    });
  }

  _displayMotionToast(BuildContext context, String message) {
    MotionToast(
      title: "Notification",
      titleStyle: TextStyle(fontWeight: FontWeight.bold),
      description: message,
      descriptionStyle: TextStyle(fontSize: 14),
      layoutOrientation: ORIENTATION.RTL,
      animationType: ANIMATION.FROM_RIGHT,
      width: 300,
//      height: 90,
      icon: Icons.battery_charging_full,
      color: Colors.blue,
    ).show(context);
  }

  _displayErrorMotionToast(BuildContext context, String message) {
    MotionToast.error(
      title: "Error",
      titleStyle: TextStyle(fontWeight: FontWeight.bold),
      description: message,
      animationType: ANIMATION.FROM_LEFT,
      position: MOTION_TOAST_POSITION.TOP,
      width: 300,
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            width: 30,
          ),
          Text(_solarTime,
              style: TextStyle(
                  color: Colors.blue,
                  fontSize: 42,
                  fontWeight: FontWeight.normal)),
          Text("Solar Noon:",
              style: TextStyle(
                  color: Colors.blue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Divider(
            height: 15.0,
            color: Colors.grey,
          ),
          Text(_nowString,
              style: TextStyle(
                  color: Colors.blue,
                  fontSize: 42,
                  fontWeight: FontWeight.normal)),
          Text("Current Time",
              style: TextStyle(
                  color: Colors.blue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Divider(
            height: 15.0,
            color: Colors.grey,
          ),
          Text(_countdownString,
              style: TextStyle(
                  color: Colors.blue,
                  fontSize: 45,
                  fontWeight: FontWeight.bold)),
          Text("Time Left",
              style: TextStyle(
                  color: Colors.blue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Card(
            margin: const EdgeInsets.fromLTRB(25, 0, 25, 10),
            color: Colors.grey[200],
            shadowColor: Colors.blue,
            elevation: 1,
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 12),
              child: Column(
                children: [
                  SizedBox(
                    width: 0,
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text("Text to Speech",
                              style:
                                  TextStyle(fontSize: 20, color: Colors.blue)),
                          SizedBox(
                            width: 0,
                            height: 25,
                          ),
                          Text("Screen Always On",
                              style:
                                  TextStyle(fontSize: 20, color: Colors.blue)),
                          SizedBox(
                            width: 0,
                            height: 25,
                          ),
                          Text("TTS with screen off ",
                              style:
                                  TextStyle(fontSize: 20, color: Colors.blue)),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 0,
                              height: 5,
                            ),
                            Transform.scale(
                              scale: 1.7,
                              child: Switch(
                                  value: _speakIsOn,
                                  onChanged: (bValue) {
                                    setState(() {
                                      _speakIsOn = bValue;
                                      if (_speakIsOn) _speak();
                                    });
                                  }),
                            ),
                            SizedBox(
                              width: 35,
                              height: 0,
                            ),
                            Transform.scale(
                              scale: 1.7,
                              child: Switch(
                                  value: _wakeOn,
                                  onChanged: (bValue) {
                                    setState(() {
                                      _wakeOn = bValue;
                                      Wakelock.toggle(enable: bValue);
                                    });
                                  }),
                            ),
                            SizedBox(
                              width: 30,
                              height: 0,
                            ),
                            Transform.scale(
                              scale: 1.7,
                              child: Switch(
                                  value: _backgroundOn,
                                  onChanged: (isAndroid)
                                      ? _backgroundSwitchChange
                                      : null),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Slider(
                      value: _volume,
                      onChanged: (newVolume) async {
                        //_volume = newVolume;

                        setState() {}
                        _volume = newVolume;

                        ;
                      },
                      min: 0.0,
                      max: 1.0,
                      divisions: 100,
                      label: "Volume: $_volume"),
                  Text("Volume",
                      style: TextStyle(fontSize: 15, color: Colors.blue)),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Future showBackgroundInfoDialog(BuildContext context) async {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog help = AlertDialog(
      title: Text("Background Permission"),
      content: SingleChildScrollView(
        child: Text(
            "Permission will be requested for background use.  This permission is needed to enable tts to run properly without "
            "the need to have the screen on.  Buddhist Sun will turn off this Background process when the switch is turned off or the app is closed.  "
            "Permission will be requested only one time if accepted.",
            style: TextStyle(fontSize: 16, color: Colors.blue)),
      ),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return help;
      },
    );
  }
}
