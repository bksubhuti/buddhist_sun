import 'dart:math';

import 'package:buddhist_sun/src/provider/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/solar_calc.dart';
import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:buddhist_sun/src/models/colored_text.dart';
import 'package:provider/provider.dart';
import 'package:buddhist_sun/src/services/gps_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:buddhist_sun/src/models/moon_phase/moon_phase.dart';

import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:buddhist_sun/utils/buddhavassa_data.dart';
import 'package:intl/intl.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:buddhist_sun/widgets/poya_bottom_sheet.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  static bool _initPerformed = false;

  Map data = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (Prefs.autoGpsEnabled && !_initPerformed) {
      Future.delayed(Duration.zero, () async {
        var (error, position, city) =
            await GpsService.initAndSaveGps(updateCity: Prefs.retrieveCityName);
        _initPerformed = true;
        if (error != null) {
          print("GPS error: $error");
          // optionally show a snackbar or toast here
        }
        if (mounted) {
          setState(
              () {}); // Only call setState if the widget is still in the tree
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      _refreshGps();
    }
  }

  // ── Dawn helpers (mirrored from DawnPage) ──────────────────────────

  String _getDawnString() {
    switch (Prefs.dawnVal) {
      case 0:
        return getNauticalTwilightString();
      case 1:
        return getSunrise40String();
      case 2:
        return getSunrise30String();
      case 3:
        return getPaAukAngleDawnString();
      case 4:
        return getNaUyanaAngleDawnString();
      case 5:
        return getCustomDawnString();
      case 6:
        return getCivilTwilightString();
      case 7:
        return getSunriseString();
      default:
        return getNauticalTwilightString();
    }
  }

  String _getDawnMethodString(BuildContext context) {
    switch (Prefs.dawnVal) {
      case 0:
        return AppLocalizations.of(context)!.nautical_twilight;
      case 1:
        return AppLocalizations.of(context)!.pa_auk;
      case 2:
        return AppLocalizations.of(context)!.na_uyana;
      case 3:
        return AppLocalizations.of(context)!.pa_auk_angle;
      case 4:
        return AppLocalizations.of(context)!.na_uyana_angle;
      case 5:
        return '${AppLocalizations.of(context)!.custom_dawn} (${Prefs.customDawnAngle}°)';
      case 6:
        return AppLocalizations.of(context)!.civil_twilight;
      case 7:
        return AppLocalizations.of(context)!.sunrise;
      default:
        return AppLocalizations.of(context)!.nautical_twilight;
    }
  }

  // ── Moon helpers ───────────────────────────────────────────────────

  CalendarTradition get _tradition {
    switch (Prefs.selectedUposatha) {
      case UposathaCountry.Thailand:
        return CalendarTradition.thai;
      case UposathaCountry.Myanmar:
        return CalendarTradition.myanmar;
      case UposathaCountry.Sinhala:
        return CalendarTradition.sriLanka;
    }
  }

  double _getMoonPhasePercentage(DateTime date) {
    MoonPhase m = MoonPhase();
    double result = m.getPhaseAngle(date);
    if (result < 0) {
      result += 2 * pi;
    }
    return 100 - (1 - result / (2 * pi)) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
      // make sure there are no lingering keyboards when this page is shown
      FocusScope.of(context).unfocus();

      // Pre-compute moon data for today
      final DateTime today = DateTime.now();
      final double moonPhase = _getMoonPhasePercentage(today);

      final mmCalendar = MmCalendar(
        config: const MmCalendarConfig(
          calendarType: CalendarType.english,
          language: Language.english,
        ),
      );
      final mmDate = mmCalendar.fromDateTime(today);
      final String fullOrNewmoon = mmDate.getMoonPhase();
      final String fortnightDay = mmDate.getFortnightDay();

      // Next uposatha
      final poyaList = BuddhavassaData.getPoyaList(_tradition);
      final String currentDateStr = DateFormat('yyyy-MM-dd').format(today);

      PoyaDay? todayPoya;
      bool isTodayUposatha = false;
      for (var poya in poyaList) {
        if (poya.date == currentDateStr &&
            (poya.moonPhase == "FullMoon" || poya.moonPhase == "NewMoon")) {
          todayPoya = poya;
          isTodayUposatha = true;
          break;
        }
      }

      PoyaDay? nextPoya;
      if (!isTodayUposatha) {
        for (var poya in poyaList) {
          if (poya.date.compareTo(currentDateStr) > 0 &&
              (poya.moonPhase == "FullMoon" || poya.moonPhase == "NewMoon")) {
            nextPoya = poya;
            break;
          }
        }
      }

      return Container(
        color: Prefs.getChosenColor(context),
        child: RefreshIndicator(
          onRefresh: _refreshGps,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 35.0, 0, 0),
              child: Column(children: <Widget>[
                // ════════════════════════════════════════════════════
                // NOON SECTION (existing)
                // ════════════════════════════════════════════════════
                Center(
                  child: ClipOval(
                    child: Image.asset(
                      "assets/buddhist_sun_app_logo.png",
                      fit: BoxFit.cover,
                      width: 100.0,
                      height: 100.0,
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                if (Prefs.autoGpsEnabled && !_initPerformed) ...[
                  SpinKitPulse(
                    color: Colors.blue,
                    size: 50.0,
                  ),
                  SizedBox(height: 10),
                  ColoredText(
                    AppLocalizations.of(context)!
                        .refreshingGps, // Add to your .arb files
                    style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                  ),
                  SizedBox(height: 10),
                ],
                ColoredText(Prefs.cityName,
                    style: TextStyle(fontSize: 15, letterSpacing: 2)),
                Divider(
                  height: 30.0,
                ),
                ColoredText(
                    AppLocalizations.of(context)!.date + ":  " + getNowString(),
                    style: TextStyle(fontSize: 22)),
                Divider(
                  height: 30.0,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ColoredText(getSolarNoonTimeString(),
                        style: TextStyle(
                            fontSize: 60, fontWeight: FontWeight.bold)),
                    (Prefs.safety > 0)
                        ? //Text('\ud83d\udee1')
                        Icon(Icons.health_and_safety_outlined,
                            color: Theme.of(context).colorScheme.primary)
                        : Text(""),
                  ],
                ),
                ColoredText(AppLocalizations.of(context)!.solar_noon,
                    style: TextStyle(fontSize: 30, letterSpacing: 2)),
                Padding(
                    padding: EdgeInsets.fromLTRB(30.0, 0.0, 30.0, 0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(height: 30.0),
                        ColoredText(
                            '${AppLocalizations.of(context)!.gps}: ${Prefs.lat}, ${Prefs.lng}',
                            style:
                                TextStyle(fontSize: 12.8, letterSpacing: 2.0)),
                        SizedBox(height: 10.0),
                        ColoredText(
                            "${AppLocalizations.of(context)!.gmt_offset}: ${Prefs.offset} hours",
                            style:
                                TextStyle(fontSize: 12.8, letterSpacing: 2.0)),
                      ],
                    )),

                // ════════════════════════════════════════════════════
                // DAWN SECTION
                // ════════════════════════════════════════════════════
                SizedBox(height: 20),
                Divider(thickness: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.brightness_4,
                          color: Theme.of(context).primaryColor),
                      SizedBox(width: 8),
                      ColoredText(
                        AppLocalizations.of(context)!.dawn,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2),
                      ),
                    ],
                  ),
                ),
                Divider(thickness: 3),
                SizedBox(height: 10),

                // Selected dawn method — large display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ColoredText(_getDawnString(),
                        style: TextStyle(
                            fontSize: 50, fontWeight: FontWeight.bold)),
                    (Prefs.safety > 0)
                        ? Icon(Icons.health_and_safety_outlined,
                            color: Theme.of(context).colorScheme.primary)
                        : Text(""),
                  ],
                ),
                ColoredText(_getDawnMethodString(context),
                    style: TextStyle(fontSize: 20, letterSpacing: 2)),
                Divider(height: 20.0),

                // All dawn/twilight times
                ColoredText(
                    '${AppLocalizations.of(context)!.astronomical_twilight}: ${getAstronomicalTwilightString()}',
                    style: TextStyle(fontSize: 15, letterSpacing: 2)),
                Divider(height: 15.0),
                ColoredText(
                    '${AppLocalizations.of(context)!.nautical_twilight}: ${getNauticalTwilightString()}',
                    style: TextStyle(fontSize: 15, letterSpacing: 2)),
                Divider(height: 15.0),
                ColoredText(
                    '${AppLocalizations.of(context)!.custom_dawn} (${Prefs.customDawnAngle}°): ${getCustomDawnString()}',
                    style: TextStyle(fontSize: 15, letterSpacing: 2)),
                Divider(height: 15.0),
                ColoredText(
                    '${AppLocalizations.of(context)!.civil_twilight}: ${getCivilTwilightString()}',
                    style: TextStyle(fontSize: 15, letterSpacing: 2)),
                Divider(height: 15.0),
                ColoredText(
                    '${AppLocalizations.of(context)!.sunrise}: ${getSunriseString()}',
                    style: TextStyle(fontSize: 15, letterSpacing: 2)),
                Divider(height: 15.0),
                ColoredText(
                    '${AppLocalizations.of(context)!.pa_auk}: ${getSunrise40String()}',
                    style: TextStyle(fontSize: 15, letterSpacing: 2)),
                Divider(height: 15.0),
                ColoredText(
                    '${AppLocalizations.of(context)!.na_uyana}: ${getSunrise30String()}',
                    style: TextStyle(fontSize: 15, letterSpacing: 2)),
                Divider(height: 15.0),
                ColoredText(
                    '${AppLocalizations.of(context)!.pa_auk_angle}: ${getPaAukAngleDawnString()}',
                    style: TextStyle(fontSize: 15, letterSpacing: 2)),
                Divider(height: 15.0),
                ColoredText(
                    '${AppLocalizations.of(context)!.na_uyana_angle}: ${getNaUyanaAngleDawnString()}',
                    style: TextStyle(fontSize: 15, letterSpacing: 2)),
                Divider(height: 15.0),

                // Sunset / Dusk times
                ColoredText('Sunset: ${getSunsetString()}',
                    style: TextStyle(fontSize: 15, letterSpacing: 2)),
                Divider(height: 15.0),
                ColoredText('Civil Dusk: ${getDuskCivilString()}',
                    style: TextStyle(fontSize: 15, letterSpacing: 2)),
                Divider(height: 15.0),
                ColoredText('Nauticle Dusk: ${getDuskNauticleString()}',
                    style: TextStyle(fontSize: 15, letterSpacing: 2)),

                // ════════════════════════════════════════════════════
                // MOON SECTION
                // ════════════════════════════════════════════════════
                SizedBox(height: 20),
                Divider(thickness: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.dark_mode,
                          color: Theme.of(context).primaryColor),
                      SizedBox(width: 8),
                      ColoredText(
                        AppLocalizations.of(context)!.moon,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2),
                      ),
                    ],
                  ),
                ),
                Divider(thickness: 3),
                SizedBox(height: 10),

                // Uposatha calendar tradition
                ColoredText(
                  "${EnumToString.convertToString(Prefs.selectedUposatha, camelCase: true)} Calendar",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),

                // Next uposatha / today is uposatha
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: ColoredText(
                          isTodayUposatha
                              ? "${AppLocalizations.of(context)!.today_is} ${todayPoya!.moonPhase.replaceAll('FullMoon', AppLocalizations.of(context)!.beFullMoon).replaceAll('NewMoon', AppLocalizations.of(context)!.beNewMoon)}"
                              : (nextPoya != null
                                  ? "${AppLocalizations.of(context)!.next}  ${nextPoya.moonPhase.replaceAll('FullMoon', AppLocalizations.of(context)!.beFullMoon).replaceAll('NewMoon', AppLocalizations.of(context)!.beNewMoon)}: ${nextPoya.date}"
                                  : "No Data"),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(40, 40),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          PoyaBottomSheet.show(context, today, _tradition, AppLocalizations.of(context)!);
                        },
                        child: const Icon(Icons.event_note),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),

                // Moon widget
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: MoonWidget(
                    size: 80,
                    resolution: 200,
                    backgroundImageAsset: 'assets/moon_free2.png',
                    moonColor: const Color.fromARGB(97, 63, 57, 57),
                    date: today,
                  ),
                ),

                // Moon phase info
                ColoredText(
                  '$fullOrNewmoon $fortnightDay',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                ColoredText(
                  '${AppLocalizations.of(context)!.moonPhase} ${moonPhase.toStringAsFixed(2)}%',
                  style: TextStyle(fontSize: 16),
                ),

                // ════════════════════════════════════════════════════
                // MAP SECTION
                // ════════════════════════════════════════════════════
                SizedBox(height: 20),
                Divider(thickness: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gps_fixed_rounded,
                          color: Theme.of(context).primaryColor),
                      SizedBox(width: 8),
                      ColoredText(
                        AppLocalizations.of(context)!.gps,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2),
                      ),
                    ],
                  ),
                ),
                Divider(thickness: 3),
                SizedBox(height: 10),
                Container(
                  width: 350,
                  height: 350,
                  child: GoogleMap(
                    markers: {
                      Marker(
                        markerId: MarkerId(Prefs.cityName),
                        position: LatLng(Prefs.lat, Prefs.lng),
                        infoWindow: InfoWindow(title: Prefs.cityName),
                      ),
                    },
                    mapType: MapType.satellite,
                    initialCameraPosition: CameraPosition(
                      zoom: 16,
                      target: LatLng(Prefs.lat, Prefs.lng),
                    ),
                  ),
                ),

                SizedBox(height: 40), // Bottom padding for scrolling
              ]),
            ),
          ),
        ),
      );
    });
  }

  Future<void> _refreshGps() async {
    if (mounted) {
      setState(() => _initPerformed = false);
    }
    var (error, position, city) =
        await GpsService.initAndSaveGps(updateCity: Prefs.retrieveCityName);
    if (mounted) {
      setState(() => _initPerformed = true);
    }
  }
}
