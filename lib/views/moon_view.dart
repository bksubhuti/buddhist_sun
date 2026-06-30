import 'dart:convert';
import 'dart:math';

import 'package:buddhist_sun/src/models/colored_text.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/provider/settings_provider.dart';
import 'package:buddhist_sun/src/services/moon_calc.dart';
import 'package:buddhist_sun/src/services/notification_service.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:buddhist_sun/src/models/moon_phase/moon_phase.dart';
import 'package:buddhist_sun/src/services/astronomy.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:buddhist_sun/utils/buddhavassa_data.dart';
import 'package:buddhist_sun/widgets/poya_bottom_sheet.dart';

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
  bool _noNextUposathaData = false;
  PoyaDay? _todayPoya;
  bool _isTodayUposatha = false;

  CalendarTradition get _tradition {
    switch (Prefs.selectedUposatha) {
      case UposathaCountry.Thailand:
        return CalendarTradition.thai;
      case UposathaCountry.Myanmar:
        return CalendarTradition.myanmar;
      case UposathaCountry.Sinhala:
        return CalendarTradition.sriLanka;
    }
  }

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
    final mmCalendar = MmCalendar(
      config: const MmCalendarConfig(
        calendarType: CalendarType.english,
        language: Language.english,
      ),
    );

    final mmDate = mmCalendar.fromDateTime(selectedDate);
    String fullOrNewmoon = mmDate.getMoonPhase();
    String fortnightDay = mmDate.getFortnightDay();
    //String buddhistEra = "Buddhit Era: ${mmDate.getBuddhistEra()}";

    String parts = ("\n\n$fullOrNewmoon $fortnightDay");

    return Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
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
                    height: 20,
                  ),
                  buildUposathaSwitch(context),
                  ColoredText(
                    "${EnumToString.convertToString(Prefs.selectedUposatha, camelCase: true)} Calendar",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: ColoredText(
                          _isTodayUposatha
                              ? "${AppLocalizations.of(context)!.today_is} ${_todayPoya!.moonPhase.replaceAll('FullMoon', AppLocalizations.of(context)!.beFullMoon).replaceAll('NewMoon', AppLocalizations.of(context)!.beNewMoon)}"
                              : (_noNextUposathaData
                                  ? "No Data"
                                  : "${AppLocalizations.of(context)!.next}  ${_nextFullOrNewmoon.replaceAll('FullMoon', AppLocalizations.of(context)!.beFullMoon).replaceAll('NewMoon', AppLocalizations.of(context)!.beNewMoon)}: ${_nextUposatha.year}-${_nextUposatha.month}-${_nextUposatha.day}"),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(40, 40),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          PoyaBottomSheet.show(context, selectedDate, _tradition, AppLocalizations.of(context)!);
                        },
                        child: const Icon(Icons.event_note),
                      ),
                    ],
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
                    padding: const EdgeInsets.all(
                        8.0), // Add padding to avoid overlap
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
    });
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
    final poyaList = BuddhavassaData.getPoyaList(_tradition);
    String currentDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    
    _todayPoya = null;
    _isTodayUposatha = false;
    for (var poya in poyaList) {
      if (poya.date == currentDateStr && (poya.moonPhase == "FullMoon" || poya.moonPhase == "NewMoon")) {
        _todayPoya = poya;
        _isTodayUposatha = true;
        break;
      }
    }

    PoyaDay? nextPoya;
    for (var poya in poyaList) {
      if (poya.date.compareTo(currentDateStr) > 0 && (poya.moonPhase == "FullMoon" || poya.moonPhase == "NewMoon")) {
        nextPoya = poya;
        break;
      }
    }

    if (nextPoya != null) {
      _nextUposatha = DateTime.parse(nextPoya.date);
      // We don't have context in initState, so we can't use AppLocalizations here easily if we want to replace FullMoon/NewMoon string here. 
      // We will just store it directly for now, or use English as a fallback if context isn't ready. 
      // Wait, _calculateNextUposatha is called in initState, so we can't use AppLocalizations.of(context) safely.
      // So let's store the raw string, but it seems before it was just "fullmoon", "newmoon", etc.
      // We can just set it to the raw moonPhase text from the CSV.
      _nextFullOrNewmoon = nextPoya.moonPhase;
      _noNextUposathaData = false;
    } else {
      _noNextUposathaData = true;
    }
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

  Widget buildUposathaSwitch(BuildContext context) {
    return Center(
      child: IntrinsicWidth(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: ColoredText(
                  "Uposatha Notifications",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Switch(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                value: Prefs.uposathaNotificationsEnabled,
                onChanged: (bool value) async {
                  Prefs.uposathaNotificationsEnabled = value;
                  if (value) {
                    ///////////TESTING STUFF //////////////////
                    //await thirtySecondsNotification();
                    //scheduleUpcomingUposathaNotificationsTest();
                    ////////////////////////////////////
                    //await showRealWorldTestWarning(context);
                    await requestPermissions();
                    await scheduleUpcomingUposathaNotifications();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("✅ Uposatha reminders scheduled")),
                    );
                  } else {
                    await cancelAllUposathaNotifications();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("🔕 Uposatha reminders turned off")),
                    );
                  }
                  (context as Element).markNeedsBuild();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showRealWorldTestWarning(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Notice"),
        content: const Text(
          "Real-world device testing has not been verified yet.",
        ),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
