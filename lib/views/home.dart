import 'package:flutter/material.dart';
import 'package:solar_calculator/solar_calculator.dart';
import 'package:solar_calculator/src/instant.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
//    data = ModalRoute.of(context)!.settings.arguments as Map;
    //  print(data);
    Color? bgColor = Colors.indigo[700];
    late double latitude = 22.0392;
    late double longitude = 96.4717;

    DateTime now = DateTime.now();

    late String solarNoon = 'not set';

    Instant instant = Instant(
        year: now.year,
        month: now.month,
        day: now.day,
        hour: now.hour,
        timeZoneOffset: 6.5);
    SolarCalculator calc = SolarCalculator(instant, lat, lng);
    print('time of noon: ${calc.sunTransitTime}');
    Instant inst2 = calc.sunTransitTime;
    print('${inst2}');
    DateTime dt =
        DateTime(inst2.year, inst2.month, inst2.day, inst2.hour, inst2.minute);

    print('adjusted time');
    print(dt);

    return Scaffold(
        appBar: AppBar(title: Text("Buddhist Sun")),
        backgroundColor: bgColor,
        body: SafeArea(
            child: Container(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 120.0, 0, 0),
            child: Column(children: <Widget>[
              TextButton.icon(
                  label: Text('Choose Location',
                      style: TextStyle(color: Colors.grey[200])),
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/location');
                    getPrefsData();
                  },
                  icon: Icon(Icons.edit_location, color: Colors.grey[200])),
              SizedBox(height: 50.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('$cityName \nSolar Noon',
                      style: TextStyle(
                          color: Colors.white, fontSize: 28, letterSpacing: 2)),
                ],
              ),
              SizedBox(height: 20),
              Text('${dt}',
                  style: TextStyle(color: Colors.white, fontSize: 40)),
            ]),
          ),
        )));
  }
}
