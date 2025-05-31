import 'package:buddhist_sun/src/services/solar_calc.dart';
import 'package:flutter/material.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import '../l10n/app_localizations.dart';
import 'package:buddhist_sun/src/models/colored_text.dart';
import 'package:buddhist_sun/src/provider/settings_provider.dart';
import 'package:provider/provider.dart';

//import 'package:buddhist_sun/views/gps_location.dart';
//import 'package:convex_bottom_bar/convex_bottom_bar.dart';

class DawnPage extends StatefulWidget {
  const DawnPage({Key? key}) : super(key: key);

  @override
  DawnPageState createState() => DawnPageState();
}

class DawnPageState extends State<DawnPage> {
  Map data = {};

  @override
  void initState() {
    super.initState();
  }

  String getDawnString() {
    String sDawn = "";
    switch (Prefs.dawnVal) {
      case 0:
        sDawn = getNauticalTwilightString();
        break;
      case 1:
        sDawn = getSunrise40String();
        break;
      case 2:
        sDawn = getSunrise30String();
        break;
      case 3:
        sDawn = getCivilTwilightString();
        break;
      case 4:
        sDawn = getSunriseString();
        break;
    }
    return sDawn;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
      return Container(
        color: Prefs.getChosenColor(context),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 35, 0, 0),
            child: Column(children: <Widget>[
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
              SizedBox(height: 20.0),
              ColoredText(
                  '${AppLocalizations.of(context)!.astronomical_twilight}: ${getAstronomicalTwilightString()}',
                  style: TextStyle(fontSize: 15, letterSpacing: 2)),
              Divider(
                height: 15.0,
              ),
              ColoredText(
                  '${AppLocalizations.of(context)!.nautical_twilight}: ${getNauticalTwilightString()}',
                  style: TextStyle(fontSize: 15, letterSpacing: 2)),
              Divider(
                height: 15.0,
              ),
              ColoredText(
                  '${AppLocalizations.of(context)!.civil_twilight}: ${getCivilTwilightString()}',
                  style: TextStyle(fontSize: 15, letterSpacing: 2)),
              Divider(
                height: 15.0,
              ),
              ColoredText(
                  '${AppLocalizations.of(context)!.sunrise}: ${getSunriseString()}',
                  style: TextStyle(fontSize: 15, letterSpacing: 2)),
              Divider(
                height: 15.0,
              ),
              ColoredText(
                  AppLocalizations.of(context)!.date + ":  " + getNowString(),
                  style: TextStyle(fontSize: 15)),
              Divider(
                height: 20.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ColoredText(getDawnString(),
                      style:
                          TextStyle(fontSize: 50, fontWeight: FontWeight.bold)),
                  (Prefs.safety > 0)
                      ? //Text('\ud83d\udee1')
                      Icon(Icons.health_and_safety_outlined,
                          color: Theme.of(context).colorScheme.primary)
                      : Text(""),
                ],
              ),
              ColoredText(getDawnMethodString(context), //_dawnMethod,
                  style: TextStyle(fontSize: 20, letterSpacing: 2)),
              Divider(
                height: 15.0,
              ),
              ColoredText('Sunset: ${getSunsetString()}',
                  style: TextStyle(fontSize: 15, letterSpacing: 2)),
              Divider(
                height: 15.0,
              ),
              ColoredText('Civil Dusk: ${getDuskCivilString()}',
                  style: TextStyle(fontSize: 15, letterSpacing: 2)),
              Divider(
                height: 15.0,
              ),
              ColoredText('Nauticle Dusk: ${getDuskNauticleString()}',
                  style: TextStyle(fontSize: 15, letterSpacing: 2)),
              Divider(
                height: 15.0,
              ),
            ]),
          ),
        ),
      );
    });
  }

  String getDawnMethodString(BuildContext context) {
    String dawnMethod = "";
    switch (Prefs.dawnVal) {
      case 0:
        dawnMethod = AppLocalizations.of(context)!.nautical_twilight;
        break;
      case 1:
        dawnMethod = AppLocalizations.of(context)!.pa_auk;
        break;
      case 2:
        dawnMethod = AppLocalizations.of(context)!.na_uyana;
        break;
      case 3:
        dawnMethod = AppLocalizations.of(context)!.civil_twilight;
        break;
      case 4:
        dawnMethod = AppLocalizations.of(context)!.sunrise;
        break;
    }
    return dawnMethod;
  }
}
