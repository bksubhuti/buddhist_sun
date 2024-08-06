import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:buddhist_sun/src/models/colored_text.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/moon_calc.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:buddhist_sun/src/models/moon_phase/moon_phase.dart';
import 'package:buddhist_sun/src/services/astronomy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;

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
  Map<String, List<DateTime>> listUposatha = {};

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
    initUposatha().then((_) {
      _calculateMoonPhase();
      _calculateNextUposatha();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mmDate = MyanmarDateConverter.fromDateTime(selectedDate);
    String fullOrNewmoon = mmDate.getMoonPhase();
    String fortnightDay = mmDate.getFortnightDay();
    //String buddhistEra = "Buddhit Era: ${mmDate.getBuddhistEra()}";

    String parts = ("\n\n$fullOrNewmoon $fortnightDay");
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
                SizedBox(height: 10),
                ColoredText(
                  "${AppLocalizations.of(context)!.next} $_nextFullOrNewmoon: ${_nextUposatha.year.toString()}-${_nextUposatha.month.toString()}-${_nextUposatha.day.toString()}",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    SizedBox(
                      width: 110, // Fixed width
                      height: 35, // Fixed height
                      child: ElevatedButton(
                        onPressed: _goToPreviousDay,
                        child: Text(AppLocalizations.of(context)!.prev),
                      ),
                    ),
                    _getColoredOrRegularText(parts, fullOrNewmoon),
                    SizedBox(
                      width: 110, // Fixed width
                      height: 35, // Fixed height
                      child: ElevatedButton(
                        onPressed: _goToNextDay,
                        child: Text(AppLocalizations.of(context)!.next),
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
                    '${AppLocalizations.of(context)!.moonPhase} ${moonPhasePercentage.toStringAsFixed(2)}%',
                    fullOrNewmoon),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: Text(AppLocalizations.of(context)!.selectDate),
                ),
                SizedBox(height: 20),
                _getSelectedDateWidget(fullOrNewmoon),
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

  _calculateNextUposatha() {
    switch (Prefs.selectedUposatha) {
      case UposathaCountry.Myanmar:
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
        break;
      default:
        String selectedCountry = EnumToString.convertToString(
                Prefs.selectedUposatha,
                camelCase: true)
            .toLowerCase();
        if ((!listUposatha.containsKey(selectedCountry))) break;
        _nextUposatha = _CalculateNextUposatha(
            selectedDate, listUposatha[selectedCountry]!);
    }
  }

  DateTime _CalculateNextUposatha(
      DateTime? currentDate, List<DateTime> listUposatha) {
    if (currentDate == null) {
      currentDate = DateTime.now();
    }
    listUposatha.sort((a, b) => a.compareTo(b));

    DateTime nextUposatha = currentDate;
    //it should be null, but to match with orginal code,
    //set it as current date if couldn't find.

    //find the first day that greater than current day.
    for (DateTime item in listUposatha) {
      if (item.compareTo(currentDate) > 0) {
        nextUposatha = item;
        break;
      }
    }
    return nextUposatha;
  }

  Future initUposatha() async {
    final directory = await getApplicationDocumentsDirectory();
    File jsonFile = File('${directory.path}/uposatha.json');

    late String content;
    if (DateTime.now().difference(Prefs.lastDownload).inDays > 30) {
      try {
        final response = await http
            .get(Uri.parse('http://192.168.43.1:8080/files/uposatha.json'));
        content = response.body;
        listUposatha = _parseUposathaList_Json(content);
        if (listUposatha.length == 0) {
          return;
        }
        jsonFile.writeAsStringSync(content);
        Prefs.lastDownload = DateTime.now(); //mark as downloaded.
      } catch (e) {
        debugPrint("Error occurred: $e");
        return;
      }
    } else {
      content = jsonFile.readAsStringSync();
      listUposatha = _parseUposathaList_Json(content);
      if (listUposatha.length == 0) {
        //Failed to parse the json. Should reset the lastDownload time?
        debugPrint("Failed to parse upsatha json from local file");

        return;
      }
    }
  }

  Map<String, List<DateTime>> _parseUposathaList_Json(String content) {
    // input is string of json in following format. Return a map of year and List date.
    // {
    // "myanmar": [
    // 	"2024-01-01",
    // 	"2024-02-07"
    // ],
    // "srilanka": [
    // 	"2025-01-01"
    // }

    Map<String, dynamic> data = jsonDecode(content);
    Map<String, List<DateTime>> uposathaDays = {};

    for (String key in data.keys) {
      try {
        List<dynamic> listDaysOfYear = data[key] as List<dynamic>;
        uposathaDays[key] =
            listDaysOfYear.map((value) => DateTime.parse(value)).toList();
      } catch (e) {
        print("[Error]: Failed to parse data from json");
      }
    }
    return uposathaDays;
  }

  Widget _getSelectedDateWidget(String moon) {
    if (moon.contains("new") || moon.contains("full")) {
      return ColoredText(
        '${AppLocalizations.of(context)!.selectedDate} ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      );
    } else {
      return Text(
        '${AppLocalizations.of(context)!.selectedDate} ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
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
