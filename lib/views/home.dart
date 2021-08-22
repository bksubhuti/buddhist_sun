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
  double _lat = 1.1;
  double _lng = 1.1;
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
      _lat = prefs.getDouble("lat") ?? 1.1;
      _lng = prefs.getDouble("lng") ?? 1.1;

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

    //late String solarNoon = 'not set';

    Instant instant = Instant(
        year: now.year,
        month: now.month,
        day: now.day,
        hour: now.hour,
        timeZoneOffset: _offset);
    SolarCalculator calc = SolarCalculator(instant, _lat, _lng);
    print('time of noon: ${calc.sunTransitTime}');
    Instant inst2 = calc.sunTransitTime;
    print('${inst2}');
    String inst2Minute = (inst2.minute < 10)
        ? "0" + inst2.minute.toString()
        : inst2.minute.toString();
    //DateTime dt =
    //  DateTime(inst2.year, inst2.month, inst2.day, inst2.hour, inst2.minute);

    //print('adjusted time');
    //print(dt);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 50.0, 0, 0),
        child: Column(children: <Widget>[
          Text('City: $cityName',
              style: TextStyle(
                  color: Colors.white, fontSize: 28, letterSpacing: 2)),
          Divider(
            height: 50.0,
            color: Colors.grey,
          ),
          Text('Date: ${inst2.day}.${inst2.month}.${inst2.year}',
              style: TextStyle(color: Colors.white, fontSize: 22)),
          Divider(
            height: 50.0,
            color: Colors.grey,
          ),
          Text('${inst2.hour}:$inst2Minute',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 60,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 10.0),
          Text('Solar Noon',
              style: TextStyle(
                  color: Colors.white, fontSize: 30, letterSpacing: 2)),
          Padding(
              padding: EdgeInsets.fromLTRB(30.0, 40.0, 30.0, 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: CircleAvatar(
                      backgroundImage: AssetImage("assets/buddhist_sun.png"),
                      radius: 40.0,
                    ),
                  ),
                  SizedBox(height: 30.0),
                  Text('Gps: $_lat, $_lng',
                      style: TextStyle(
                          fontSize: 12.8,
                          color: Colors.grey,
                          letterSpacing: 2.0)),
                  SizedBox(height: 10.0),
                  Text("GMT Offset: $_offset hours",
                      style: TextStyle(
                          fontSize: 12.8,
                          color: Colors.grey,
                          letterSpacing: 2.0)),
                ],
              )),
        ]),
      ),
    );
  }
}
