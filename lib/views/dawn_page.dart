import 'package:buddhist_sun/src/services/solar_calc.dart';
import 'package:flutter/material.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:buddhist_sun/src/models/colored_text.dart';

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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 50.0, 0, 0),
        child: Column(children: <Widget>[
          Center(
            child: CircleAvatar(
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              backgroundImage: AssetImage("assets/buddhist_sun.png"),
              radius: 50.0,
            ),
          ),
          SizedBox(height: 30.0),
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
              style: TextStyle(fontSize: 20)),
          Divider(
            height: 20.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ColoredText(getDawnString(),
                  style: TextStyle(fontSize: 65, fontWeight: FontWeight.bold)),
              (Prefs.safety > 0)
                  ? //Text('\ud83d\udee1')
                  Icon(Icons.health_and_safety_outlined,
                      color: Theme.of(context).colorScheme.primary)
                  : Text(""),
            ],
          ),
          ColoredText(getDawnMethodString(context), //_dawnMethod,
              style: TextStyle(fontSize: 25, letterSpacing: 2)),
          Padding(
              padding: EdgeInsets.fromLTRB(30.0, 40.0, 30.0, 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ColoredText(
                      '${AppLocalizations.of(context)!.gps}: ${Prefs.lat}, ${Prefs.lng}',
                      style: TextStyle(fontSize: 12.8, letterSpacing: 2.0)),
                  SizedBox(height: 10.0),
                  ColoredText(
                      "${AppLocalizations.of(context)!.gmt_offset}: ${Prefs.offset} hours",
                      style: TextStyle(fontSize: 12.8, letterSpacing: 2.0)),
                ],
              )),
        ]),
      ),
    );
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
