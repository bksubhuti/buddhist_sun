import 'package:buddhist_sun/src/services/solar_calc.dart';
import 'package:flutter/material.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 50.0, 0, 0),
        child: Column(children: <Widget>[
          Text('${AppLocalizations.of(context)!.astronomical_twilight}: ${getAstronomicalTwilightString()}',
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 15,
                  letterSpacing: 2)),
          Divider(
            height: 15.0,
          ),
          Text('${AppLocalizations.of(context)!.nautical_twilight}: ${getNauticalTwilightString()}',
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 15,
                  letterSpacing: 2)),
          Divider(
            height: 15.0,
          ),
          Text('${AppLocalizations.of(context)!.civil_twilight}: ${getCivilTwilightString()}',
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 15,
                  letterSpacing: 2)),
          Divider(
            height: 15.0,
          ),
          Text('${AppLocalizations.of(context)!.sunrise}: ${getSunriseString()}',
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 15,
                  letterSpacing: 2)),
          Divider(
            height: 15.0,
          ),
          Text(getNowString(),
              style: TextStyle(
                  color: Theme.of(context).primaryColor, fontSize: 20)),
          Divider(
            height: 20.0,
          ),
          Text(getDawnString(),
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 55,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 10.0),
          Text(Prefs.dawnVal, //_dawnMethod,
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 20,
                  letterSpacing: 2)),
          Padding(
              padding: EdgeInsets.fromLTRB(30.0, 40.0, 30.0, 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).appBarTheme.backgroundColor,
                      backgroundImage: AssetImage("assets/buddhist_sun.png"),
                      radius: 40.0,
                    ),
                  ),
                  SizedBox(height: 30.0),
                  Text('${AppLocalizations.of(context)!.gps}: ${Prefs.lat}, ${Prefs.lng}',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12.8,
                          letterSpacing: 2.0)),
                  SizedBox(height: 10.0),
                  Text("${AppLocalizations.of(context)!.gmt_offset}: ${Prefs.offset} hours",
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12.8,
                          letterSpacing: 2.0)),
                ],
              )),
        ]),
      ),
    );
  }
}
