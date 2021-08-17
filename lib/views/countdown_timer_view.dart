import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_calculator/solar_calculator.dart';
import 'package:solar_calculator/src/instant.dart';

class CountdownTimerView extends StatefulWidget {
  const CountdownTimerView({Key? key, required this.goToHome})
      : super(key: key);
  final VoidCallback goToHome;

  @override
  _CountdownTimerViewState createState() => _CountdownTimerViewState();
}

class _CountdownTimerViewState extends State<CountdownTimerView> {
  Duration _duration = Duration(seconds: 1);
  late Timer _timer;
  String _solarTime = "";
  String _nowString = "";
  String _countdownString = "";
  DateTime _now = DateTime.now();
  DateTime _dtSolar = DateTime.now();

  void _startTTS() {}

  @override
  void initState() {
    _timer = Timer.periodic(_duration, (timer) {
      _now = DateTime.now();
      _nowString =
          "${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}";

      int min = _dtSolar.difference(_now).inMinutes;
      int seconds = (_dtSolar.difference(_now).inSeconds) % 60;

      _countdownString =
          "${min.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

      setState(() {
//        if (_counter > 0) {
        //        _counter--;
        //    }
      });
    });

    GetSolarTime();
    super.initState();
  }

  void GetSolarTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    double lat = prefs.getDouble("lat") ?? 1.1;
    double lng = prefs.getDouble("lng") ?? 1.1;
    double offset = prefs.getDouble("offset") ?? 1.1;

    DateTime nw = DateTime.now();
    Instant instant = Instant(
        year: nw.year,
        month: nw.month,
        day: nw.day,
        hour: nw.hour,
        timeZoneOffset: offset);
    SolarCalculator calc = SolarCalculator(instant, lat, lng);
    Instant inst2 = calc.sunTransitTime;

    _dtSolar = DateTime(
        nw.year, nw.month, nw.day, inst2.hour, inst2.minute, inst2.second);

    _solarTime =
        "${inst2.hour.toString().padLeft(2, "0")}:${inst2.minute.toString().padLeft(2, "0")}";
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Container(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 30,
            ),
            Text(_solarTime,
                style: TextStyle(
                    color: Colors.orange[600],
                    fontSize: 55,
                    fontWeight: FontWeight.bold)),
            Text("Solar Noon:",
                style: TextStyle(
                    color: Colors.orange[600],
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Divider(
              height: 30.0,
              color: Colors.grey,
            ),
            Text(_nowString,
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 48,
                    fontWeight: FontWeight.bold)),
            Text("Current Time",
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Divider(
              height: 30.0,
              color: Colors.grey,
            ),
            Text(_countdownString,
                style: TextStyle(
                    color: Colors.green,
                    fontSize: 60,
                    fontWeight: FontWeight.bold)),
            Text("Time Left",
                style: TextStyle(
                    color: Colors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            SizedBox(
              height: 30,
            ),
            ElevatedButton.icon(
                label: Text("Start TTS"),
                icon: Icon(Icons.timelapse),
                onPressed: _startTTS)
          ]),
        ),
      ),
    );
  }
}
