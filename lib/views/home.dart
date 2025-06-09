import 'package:buddhist_sun/src/provider/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/solar_calc.dart';
import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:buddhist_sun/src/models/colored_text.dart';
import 'package:provider/provider.dart';
import 'package:buddhist_sun/src/services/gps_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
      // make sure there are no lingering keyboards when this page is shown
      FocusScope.of(context).unfocus();

      return Container(
        color: Prefs.getChosenColor(context),
        child: RefreshIndicator(
          onRefresh: _refreshGps,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 35.0, 0, 0),
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
