import 'dart:math';

import 'package:buddhist_sun/src/models/colored_text.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/moon_calc.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:buddhist_sun/src/models/moon_phase/moon_phase.dart';
import 'package:buddhist_sun/src/services/astronomy.dart';
import 'package:timezone/timezone.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

class MoonPage extends StatefulWidget {
  const MoonPage({Key? key}) : super(key: key);

  @override
  _MoonPageState createState() => _MoonPageState();
}

class _MoonPageState extends State<MoonPage> {
  DateTime _nextUposatha = DateTime.now();
  DateTime selectedDate = DateTime.now();
  String _nextFullOrNewmoon = "";
  double moonPhasePercentage =
      0.0; // Dummy value, you need to calculate this based on the selected date

  void _calculateMoonPhase() {
    useMeeus();
    final moonCalc = MoonCalc();
    MoonPhase m = MoonPhase();
    double result = m.getPhaseAngle(selectedDate);
    double simple = moonCalc.calculateMoonPhaseSimple(
        selectedDate.year, selectedDate.month, selectedDate.day);
    result = makePercentageFromPhase(result);
    debugPrint("getPhaseAngle:  ${result.toString()}");
    debugPrint("getPhaseAngle MoonCalcSimple:  $simple  ");

    // Add your moon phase calculation logic here
    // Update moonPhasePercentage based on the selectedDate
    setState(() {
      moonPhasePercentage = result;
      //50.0; // Update this with the actual calculated value
    });
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _calculateMoonPhase();
      _calculateNextUposatha();
    }
  }

  void _goToNextDay() {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: 1));
    });
    _calculateMoonPhase();
    _calculateNextUposatha();
  }

  void _goToPreviousDay() {
    setState(() {
      selectedDate = selectedDate.subtract(Duration(days: 1));
    });
    _calculateMoonPhase();
    _calculateNextUposatha();
  }

  @override
  void initState() {
    super.initState();
    _calculateMoonPhase();
    _calculateNextUposatha();
  }

  @override
  Widget build(BuildContext context) {
    final mmDate = MyanmarDateConverter.fromDateTime(selectedDate);
    String fullOrNewmoon = mmDate.getMoonPhase();
    String fortnightDay = mmDate.getFortnightDay();
    String buddhistEra = "Buddhit Era: ${mmDate.getBuddhistEra()}";

    String parts = ("$fullOrNewmoon $fortnightDay");
    return SingleChildScrollView(
      child: Container(
        color: Prefs.getChosenColor(context),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
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
                  height: 40,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    SizedBox(
                      width: 150, // Fixed width
                      height: 35, // Fixed height
                      child: ElevatedButton(
                        style: _m3ButtonStyle(context),
                        onPressed: _goToPreviousDay,
                        child: Text('Previous Day'),
                      ),
                    ),
                    _getColoredOrRegularText(parts, fullOrNewmoon),
                    SizedBox(
                      width: 150, // Fixed width
                      height: 35, // Fixed height
                      child: ElevatedButton(
                        style: _m3ButtonStyle(context),
                        onPressed: _goToNextDay,
                        child: Text('Next Day'),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  padding:
                      const EdgeInsets.all(8.0), // Add padding to avoid overlap
                  child: MoonWidget(
                    size: 100, // Adjust the size as needed
                    resolution: 200,
                    backgroundImageAsset:
                        'assets/moon_free2.png', // Example image.

                    moonColor: const Color.fromARGB(97, 63, 57, 57),
                    date: selectedDate,
                  ),
                ),
                _getColoredOrRegularText(
                    'Moon Phase: ${moonPhasePercentage.toStringAsFixed(2)}%',
                    fullOrNewmoon),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: _m3ButtonStyle(context),
                  onPressed: () => _selectDate(context),
                  child: Text('Select Date'),
                ),
                SizedBox(height: 20),
                _getSelectedDateWidget(fullOrNewmoon),
                SizedBox(height: 10),
                ColoredText(
                  "Next Uposatha ($_nextFullOrNewmoon): ${_nextUposatha.year.toString()}-${_nextUposatha.month.toString()}-${_nextUposatha.day.toString()}",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String getMoonText() {
    var moon = MoonCalc();
    DateTime dt = DateTime.now();
//    Map<String, dynamic> result =
    //      moon.calculateMoonPhase(dt.year, dt.month, dt.day);
    int result = moon.calculateMoonPhaseWikipedia(dt.year, dt.month, dt.day);

    debugPrint(result.toString());
    return (result
        .toString()); // Example: {illumination: 0.507, description: 'Waxing Crescent', phaseAngle: 61.456}
  }

  double makePercentageFromPhase(double phaseAngle) {
    if (phaseAngle < 0) {
      phaseAngle += 2 * pi;
    }
    return 100 - (1 - phaseAngle / (2 * pi)) * 100;
  }

  void useMeeus() {
    TZDateTime datetimeUTC = TZDateTime.now(UTC);
    // Adjust the time for Sri Lanka's timezone, which is UTC+5:30
    TZDateTime datetimeSL = datetimeUTC.add(Duration(hours: 5, minutes: 30));

    double latitude = 7.4854; // Latitude for Kurunegala, Sri Lanka
    double longitude = 80.3622; // Longitude for Kurunegala, Sri Lanka
    double JD = datetimeToJD(datetimeSL);
    double lunarPhase = calculateLunarPhaseWithLatLong(JD, latitude, longitude);
    double illumination = calculateLunarIllumination(lunarPhase);

    String formattedDate =
        '${datetimeSL.year}-${datetimeSL.month.toString().padLeft(2, '0')}-${datetimeSL.day.toString().padLeft(2, '0')} ${datetimeSL.hour.toString().padLeft(2, '0')}:${datetimeSL.minute.toString().padLeft(2, '0')}:${datetimeSL.second.toString().padLeft(2, '0')} UTC+5:30';
    print('Current Local Time (Sri Lanka): $formattedDate');
    print('Latitude: $latitude, Longitude: $longitude');
    print('Lunar Phase Angle: $lunarPhase°');
    print('Lunar Illumination: $illumination%');
  }

  ButtonStyle _m3ButtonStyle(BuildContext context) {
    // Check if the Material 3 switch is enabled
    // Fetch the primary light color from the theme
    final primaryLightColor = Theme.of(context).colorScheme.primaryContainer;
    final primaryColor = Theme.of(context).colorScheme.inverseSurface;
    return ElevatedButton.styleFrom(
      foregroundColor: primaryColor,
      backgroundColor: primaryLightColor, // Background color
    );
  }

  _calculateNextUposatha() {
    DateTime upoDate = selectedDate;

    for (int x = 0; x < 16; x++) {
      upoDate = upoDate.add(Duration(days: 1));
      MyanmarDate mmDate1 = MyanmarDateConverter.fromDateTime(upoDate,
          calendarType: CalendarType.english);
      _nextFullOrNewmoon = mmDate1.getMoonPhase();
      if (_nextFullOrNewmoon.contains("new") ||
          _nextFullOrNewmoon.contains("full")) {
        _nextUposatha = upoDate;

        break;
      }
    }
  }

  Widget _getSelectedDateWidget(String moon) {
    if (moon.contains("new") || moon.contains("full")) {
      return ColoredText(
        'Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      );
    } else {
      return Text(
        'Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      );
    }
  }

  Widget _getColoredOrRegularText(String t, String m) {
    if (m.toLowerCase().contains("new") || m.toLowerCase().contains("full")) {
      return ColoredText(t,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
    } else {
      return Text(t,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
    }
  }
}
