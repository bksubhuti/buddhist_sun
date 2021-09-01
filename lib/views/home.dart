import 'package:flutter/material.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/solar_calc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

//import 'package:buddhist_sun/views/gps_location.dart';
//import 'package:convex_bottom_bar/convex_bottom_bar.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Map data = {};
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // make sure there are no lingering keyboards when this page is shown
    FocusScope.of(context).unfocus();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 50.0, 0, 0),
        child: Column(children: <Widget>[
          Text(Prefs.cityName,
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 23,
                  letterSpacing: 2)),
          Divider(
            height: 50.0,
          ),
          Text(AppLocalizations.of(context)!.date + ":  " + getNowString(),
              style: TextStyle(
                  color: Theme.of(context).primaryColor, fontSize: 22)),
          Divider(
            height: 50.0,
          ),
          Text(getSolarNoonTimeString(),
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 60,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 10.0),
          Text('${AppLocalizations.of(context)!.solar_noon}',
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 30,
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
