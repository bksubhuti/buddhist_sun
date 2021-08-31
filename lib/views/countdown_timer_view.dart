import 'dart:async';
import 'dart:io' show Platform;

import 'package:buddhist_sun/src/services/solar_calc.dart';
import 'package:buddhist_sun/src/services/solar_time.dart';
import 'package:buddhist_sun/src/models/prefs.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:motion_toast/resources/arrays.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CountdownTimerView extends StatefulWidget {
  const CountdownTimerView({Key? key, required this.goToHome})
      : super(key: key);
  final VoidCallback goToHome;

  @override
  _CountdownTimerViewState createState() => _CountdownTimerViewState();
}

class _CountdownTimerViewState extends State<CountdownTimerView>
    with SolarTimerDelegate {
  //Duration _duration = Duration(seconds: 1);
  String _solarTime = "";
  String _nowString = "";
  String _countdownString = "";
  bool _speakIsOn = false;
  bool _wakeOn = false;
  bool _backgroundOn = false;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool _disposed = false;

  /////////////////////////////////////////////////////////////////
  double _volume = Prefs.volume;
  SolarTimerService service =
      SolarTimerService(); // always return singleton instance anywhere, also you can set delegate to null
  @override
  void update() {
    if (!_disposed) {
      setState(() {});
    } // from mixin delegate
  }

  @override
  setCountdownString(countdownString) {
    if (!_disposed) {
      setState(() {
        this._countdownString = countdownString;
      });
    }
  }

  @override
  void setSpeakIsOn(speakIsOn) {
    if (!_disposed) {
      setState(() {
        _speakIsOn = speakIsOn;
      });
    }
  }

  @override
  void setNowString(nowString) {
    if (!_disposed) {
      setState(() {
        _nowString = nowString;
        print(nowString);
      });
    }
  }

  @override
  void initState() {
    _disposed = false;
    service.delegate = this;
    _backgroundOn = Prefs.backgroundOn;
    _wakeOn = Prefs.screenAlwaysOn;

    _speakIsOn = Prefs.instance.getBool(SPEAKISON) ?? false;
    service.doTimerStuff();

    super.initState();
  }

  Future<bool> setupBackground() async {
    bool success =
        await FlutterBackground.initialize(androidConfig: androidConfig);
    print("result from setup backgroud is $success");
    return success;
  }

  final androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "Buddhist Sun Running In Background",
    notificationText: "Buddhist Sun is running in the background",
    notificationImportance: AndroidNotificationImportance.Default,
    notificationIcon: AndroidResource(
        name: 'background_icon',
        defType: 'drawable'), // Default is ic_launcher from folder mipmap
  );

  @override
  void dispose() {
    _disposed = true;
    //_timer.cancel();
    //flutterTts.stop();
    //Wakelock.disable();
    super.dispose();
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
    Prefs.backgroundOn = bSwitch;
    setState(() {
      _backgroundOn = bSwitch;
    });
  }

  _displayMotionToast(BuildContext context, String message) {
    MotionToast(
      title: "Notification",
      titleStyle: TextStyle(
          color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
      description: message,
      descriptionStyle:
          TextStyle(color: Theme.of(context).primaryColor, fontSize: 14),
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
      titleStyle: TextStyle(
          color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
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
          Text(getSolarNoonTimeString(),
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 42,
                  fontWeight: FontWeight.normal)),
          Text("${AppLocalizations.of(context)!.solar_noon}:",
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Divider(
            height: 15.0,
          ),
          Text(_nowString,
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 42,
                  fontWeight: FontWeight.normal)),
          Text("${AppLocalizations.of(context)!.current_time}",
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Divider(
            height: 15.0,
          ),
          Text(_countdownString,
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 45,
                  fontWeight: FontWeight.bold)),
          Text("${AppLocalizations.of(context)!.time_left}",
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Card(
            margin: const EdgeInsets.fromLTRB(15, 0, 25, 10),
            elevation: 1,
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 12),
              child: Column(
                children: [
                  SizedBox(
                    width: 0,
                    height: 15,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text("${AppLocalizations.of(context)!.speech_notify}",
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .appBarTheme
                                      .backgroundColor,
                                  fontSize: 15)),
                          SizedBox(
                            width: 0,
                            height: 25,
                          ),
                          Text(
                              "${AppLocalizations.of(context)!.screen_always_on}",
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .appBarTheme
                                      .backgroundColor,
                                  fontSize: 15)),
                          SizedBox(
                            width: 0,
                            height: 25,
                          ),
                          Text(
                              "${AppLocalizations.of(context)!.speech_in_background} ",
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .appBarTheme
                                      .backgroundColor,
                                  fontSize: 15)),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
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
                                      Prefs.instance.setBool(SPEAKISON, bValue);
                                      _speakIsOn = bValue;
                                      if (_speakIsOn)
                                        Prefs.speakIsOn = _speakIsOn;
                                      else {
                                        service.initialVoicing = false;
                                      }
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
                                      Prefs.screenAlwaysOn = bValue;
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
                      onChanged: (newVolume) {
                        setState(() => _volume = newVolume);
                        Prefs.volume = _volume;
                      },
                      min: 0.0,
                      max: 1.0,
                      divisions: 100,
                      label:
                          "${AppLocalizations.of(context)!.volume}: $_volume"),
                  Text("${AppLocalizations.of(context)!.volume}",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 15,
                      )),
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
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 16,
            )),
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
