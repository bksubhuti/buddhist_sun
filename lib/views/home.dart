import 'package:flutter/material.dart';
import 'package:solar_calculator/solar_calculator.dart';
import 'package:solar_calculator/src/instant.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:buddhist_sun/views/gps_location.dart';
//import 'package:convex_bottom_bar/convex_bottom_bar.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Map data = {};
  String cityName = "Not Set";
  double lat = 1.1;
  double lng = 1.1;
  double _offset = 6.5;

  @override
  void initState() {
    getPrefsData();
    super.initState();
  }

  getPrefsData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cityName = prefs.getString("cityName") ?? "not set2";
      lat = prefs.getDouble("lat") ?? 1.1;
      lng = prefs.getDouble("lng") ?? 1.1;

      if (prefs.getDouble("offset") == null) {
        prefs.setDouble("offset", 6.5);
      }
      _offset = prefs.getDouble("offset") ?? 6.5;
    });
  }

  @override
  Widget build(BuildContext context) {
//    data = ModalRoute.of(context)!.settings.arguments as Map;
    //  print(data);

    DateTime now = DateTime.now();
    var timezoneOffset = now.timeZoneOffset;

    print(timezoneOffset);

    late String solarNoon = 'not set';

    Instant instant = Instant(
        year: now.year,
        month: now.month,
        day: now.day,
        hour: now.hour,
        timeZoneOffset: _offset);
    SolarCalculator calc = SolarCalculator(instant, lat, lng);
    print('time of noon: ${calc.sunTransitTime}');
    Instant inst2 = calc.sunTransitTime;
    print('${inst2}');
    //DateTime dt =
    //  DateTime(inst2.year, inst2.month, inst2.day, inst2.hour, inst2.minute);

    //print('adjusted time');
    //print(dt);

    return Container(
        child: Container(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 120.0, 0, 0),
        child: Column(children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('$cityName \nSolar Noon',
                  style: TextStyle(
                      color: Colors.white, fontSize: 28, letterSpacing: 2)),
            ],
          ),
          SizedBox(height: 20),
          Text('${inst2}', style: TextStyle(color: Colors.white, fontSize: 40)),
        ]),
      ),
    ));
  }
}
