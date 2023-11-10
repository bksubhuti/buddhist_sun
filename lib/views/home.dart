import 'package:flutter/material.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/solar_calc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:buddhist_sun/src/models/colored_text.dart';

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

    return Container(
      color: Prefs.getChosenColor(context),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 50.0, 0, 0),
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
            SizedBox(
              height: 20,
            ),
            ColoredText(Prefs.cityName,
                style: TextStyle(fontSize: 15, letterSpacing: 2)),
            Divider(
              height: 50.0,
            ),
            ColoredText(
                AppLocalizations.of(context)!.date + ":  " + getNowString(),
                style: TextStyle(fontSize: 22)),
            Divider(
              height: 50.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ColoredText(getSolarNoonTimeString(),
                    style:
                        TextStyle(fontSize: 60, fontWeight: FontWeight.bold)),
                (Prefs.safety > 0)
                    ? //Text('\ud83d\udee1')
                    Icon(Icons.health_and_safety_outlined,
                        color: Theme.of(context).colorScheme.primary)
                    : Text(""),
              ],
            ),
            SizedBox(height: 10.0),
            ColoredText('${AppLocalizations.of(context)!.solar_noon}',
                style: TextStyle(fontSize: 30, letterSpacing: 2)),
            Padding(
                padding: EdgeInsets.fromLTRB(30.0, 40.0, 30.0, 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: 30.0),
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
      ),
    );
  }
}
