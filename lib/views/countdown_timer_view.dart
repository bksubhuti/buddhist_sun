import 'dart:io' show Platform;

import 'package:buddhist_sun/src/provider/settings_provider.dart';
import 'package:buddhist_sun/src/services/background_time_player.dart';
import 'package:buddhist_sun/src/services/solar_calc.dart';
import 'package:buddhist_sun/src/services/solar_time.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/models/colored_text.dart';
import 'package:buddhist_sun/src/services/notification_service.dart';

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

class CountdownTimerView extends StatefulWidget {
  const CountdownTimerView({Key? key, required this.goToHome})
      : super(key: key);
  final VoidCallback goToHome;

  @override
  _CountdownTimerViewState createState() => _CountdownTimerViewState();
}

class _CountdownTimerViewState extends State<CountdownTimerView>
    with SolarTimerDelegate {
  String _nowString = "";
  String _countdownString = "";
  bool _speakIsOn = false;
  bool _wakeOn = false;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool _disposed = false;

  /////////////////////////////////////////////////////////////////
  double _volume = 0.5;
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
        // for localization.. sometimes the countdown string is
        // the word "Late" instead of a time
        // this needs localization done with a context.
        if (countdownString == SolarTimerService.LATE) {
          this._countdownString = AppLocalizations.of(context)!.late;
        } else {
          this._countdownString = countdownString;
        }
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
    _wakeOn = Prefs.screenAlwaysOn;

    _speakIsOn = Prefs.instance.getBool(SPEAKISON) ?? false;
    service.doTimerStuff();
    
    _initSystemVolume();

    super.initState();
  }

  Future<void> _initSystemVolume() async {
    if (kIsWeb) return;
    try {
      await FlutterVolumeController.updateShowSystemUI(false);
      final systemVolume = await FlutterVolumeController.getVolume();
      if (systemVolume != null && mounted) {
        setState(() {
          _volume = systemVolume;
        });
      }
      FlutterVolumeController.addListener((newVolume) {
        if (mounted && newVolume != _volume) {
          setState(() {
            _volume = newVolume;
          });
        }
      });
    } catch (e) {
      print("Error binding to system volume: $e");
    }
  }

  @override
  void dispose() {
    _disposed = true;
    if (!kIsWeb) {
      FlutterVolumeController.removeListener();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
      return Container(
        color: Prefs.getChosenColor(context),
        child: SingleChildScrollView(
          child: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(
                height: 12,
                width: 30,
              ),
              getTargetSection(),
              Divider(
                height: 15.0,
              ),
              ColoredText(_nowString,
                  style:
                      TextStyle(fontSize: 35, fontWeight: FontWeight.normal)),
              ColoredText(AppLocalizations.of(context)!.current_time,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Divider(
                height: 15.0,
              ),
              ColoredText(_countdownString,
                  style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold)),
              ColoredText(
                  "${AppLocalizations.of(context)!.time_left} (${_isDawnMode() ? _getSelectedDawnLabel(context) : AppLocalizations.of(context)!.solar_noon})",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Container(
                margin: const EdgeInsets.fromLTRB(15, 0, 25, 5),
                color: Prefs.getChosenColor(context),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 0,
                        height: 10,
                      ),
                      ListTile(
                        leading: ColoredText(
                            AppLocalizations.of(context)!.speech_notify,
                            style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 15)),
                        trailing: Transform.scale(
                          scale: 1.7,
                          child: Switch(
                            value: _speakIsOn,
                            onChanged: (bValue) async {
                              // 1. Update UI first
                              setState(() {
                                _speakIsOn = bValue;
                                Prefs.instance.setBool(SPEAKISON, bValue);
                                Prefs.speakIsOn = bValue;
                              });

                              // 2. Now do async work AFTER setState
                              if (bValue) {
                                await BackgroundTimePlayer.startForTarget(
                                  target: service.countdownTarget,
                                  title:
                                      "${AppLocalizations.of(context)!.buddhistSunCountdown} - ${_isDawnMode() ? _getSelectedDawnLabel(context) : AppLocalizations.of(context)!.solar_noon}",
                                  artist:
                                      AppLocalizations.of(context)!.buddhistSun,
                                  album: AppLocalizations.of(context)!.timer,
                                );
                                // Background voice ON
                                //await scheduleAllTimerNotifications(
                                //targetTime: service.countdownTarget,
                                //);
                              } else {
                                // Background voice OFF
                                await BackgroundTimePlayer.stop();
                                service.initialVoicing = false;
                                await cancelAllTimerNotifications();
                              }
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 0,
                        height: 10,
                      ),
                      ListTile(
                        leading: ColoredText(
                            AppLocalizations.of(context)!.screen_always_on,
                            style: TextStyle(fontSize: 15)),
                        trailing: Transform.scale(
                          scale: 1.7,
                          child: Switch(
                              value: _wakeOn,
                              onChanged: (bValue) {
                                setState(() {
                                  Prefs.screenAlwaysOn = bValue;
                                  _wakeOn = bValue;
                                  WakelockPlus.toggle(enable: bValue);
                                });
                              }),
                        ),
                      ),
                      SizedBox(
                        width: 0,
                        height: 10,
                      ),
                      Slider(
                          value: _volume,
                          onChanged: (newVolume) {
                            setState(() => _volume = newVolume);
                            if (!kIsWeb) {
                              FlutterVolumeController.setVolume(newVolume);
                            }
                          },
                          min: 0.0,
                          max: 1.0,
                          divisions: 100,
                          label:
                              "${AppLocalizations.of(context)!.volume}: ${_volume.toStringAsFixed(2)}"),
                      ColoredText(AppLocalizations.of(context)!.volume,
                          style: TextStyle(
                            fontSize: 15,
                          )),
                      SizedBox(
                        width: 30,
                        height: 15,
                      ),
                      // Only show test buttons in debug builds
                      if (kDebugMode) ...[
                        GetNotificationDebugButtons(),
                        SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
    });
  }

  Widget GetNotificationDebugButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () async {
            // Test background audio by setting a fake target 2m 10s in the future
            final testTarget =
                DateTime.now().add(const Duration(minutes: 2, seconds: 10));
            await BackgroundTimePlayer.startForTarget(
              target: testTarget,
              title:
                  "${AppLocalizations.of(context)!.buddhistSunCountdown} - ${_isDawnMode() ? _getSelectedDawnLabel(context) : AppLocalizations.of(context)!.solar_noon}",
              artist: AppLocalizations.of(context)!.buddhistSun,
              album: AppLocalizations.of(context)!.timer,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
          ),
          child: const Text(
            "Test Audio (2:10)",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            await BackgroundTimePlayer.stop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
          ),
          child: const Text(
            "Stop Audio",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // 🟢 NEW: selected dawn time string based on Prefs.dawnVal
  String _getSelectedDawnTimeString() {
    switch (Prefs.dawnVal) {
      case 0:
        return getNauticalTwilightString();
      case 1:
        return getSunrise40String();
      case 2:
        return getSunrise30String();
      case 3:
        return getCivilTwilightString();
      case 4:
        return getSunriseString();
      default:
        return getNauticalTwilightString();
    }
  }

  // 🟢 NEW: label for the selected dawn method
  String _getSelectedDawnLabel(BuildContext context) {
    switch (Prefs.dawnVal) {
      case 0:
        return AppLocalizations.of(context)!.nautical_twilight;
      case 1:
        return AppLocalizations.of(context)!.pa_auk;
      case 2:
        return AppLocalizations.of(context)!.na_uyana;
      case 3:
        return AppLocalizations.of(context)!.civil_twilight;
      case 4:
        return AppLocalizations.of(context)!.sunrise;
      default:
        return AppLocalizations.of(context)!.nautical_twilight;
    }
  }

  bool _isDawnMode() {
    // Get selected dawn today as DateTime
    final dawnInst = () {
      switch (Prefs.dawnVal) {
        case 0:
          return getNauticalTwilight();
        case 1:
          return getSunrise40();
        case 2:
          return getSunrise30();
        case 3:
          return getCivilTwilight();
        case 4:
          return getSunrise();
        default:
          return getNauticalTwilight();
      }
    }();

    final dawnDT = DateTime(
      dawnInst.year,
      dawnInst.month,
      dawnInst.day,
      dawnInst.hour,
      dawnInst.minute,
    );

    return service.countdownTarget.hour == dawnDT.hour &&
        service.countdownTarget.minute == dawnDT.minute;
  }

// ---------------------------------------------------------
//  Combined Target Section (Option A - Best UX)
//  Always show Dawn + Solar Noon; highlight active target
// ---------------------------------------------------------
  Widget getTargetSection() {
    final isDawn = _isDawnMode();

    return Column(
      children: [
        // ===== Solar Noon Row =====
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ColoredText(
              getSolarNoonTimeString(),
              style: TextStyle(
                fontSize: isDawn ? 18 : 22, // inactive vs active
                fontWeight: isDawn
                    ? FontWeight.w500 // inactive
                    : FontWeight.w900, // active
              ),
            ),
            if (Prefs.safety > 0)
              Icon(
                Icons.health_and_safety_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: isDawn ? 18 : 24,
              ),
          ],
        ),

        ColoredText(
          AppLocalizations.of(context)!.solar_noon,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isDawn ? FontWeight.w400 : FontWeight.bold,
          ),
        ),

        const Divider(height: 15),

        // ===== Dawn Row =====
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ColoredText(
              _getSelectedDawnTimeString(),
              style: TextStyle(
                fontSize: isDawn ? 22 : 18, // active vs inactive
                fontWeight: isDawn
                    ? FontWeight.w900 // active
                    : FontWeight.w500, // inactive
              ),
            ),
            if (Prefs.safety > 0)
              Icon(
                Icons.health_and_safety_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: isDawn ? 24 : 18,
              ),
          ],
        ),

        ColoredText(
          _getSelectedDawnLabel(context),
          style: TextStyle(
            fontSize: 16,
            fontWeight: isDawn ? FontWeight.bold : FontWeight.w400,
          ),
        ),

        const Divider(height: 15),
      ],
    );
  }
}
