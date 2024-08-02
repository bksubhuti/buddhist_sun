import 'package:buddhist_sun/src/models/world_cities.dart';
import 'package:buddhist_sun/src/services/get_world_cities.dart';
import 'package:buddhist_sun/views/theme_settings_view.dart';
import 'package:flutter/material.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:buddhist_sun/src/models/select_language_widget.dart';
import 'package:buddhist_sun/src/models/colored_text.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:buddhist_sun/src/provider/settings_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final dbService = DatabaseService();
  String searchKey = "Mand";
  late double _offset = 0;
  List<String> _safetyItems = <String>[];

  List<String> _dawnMethodItems = <String>[];

  @override
  void initState() {
    // debug mode to reset
    //Prefs.instance.clear();
    super.initState();
  }

  @override
  void dispose() {
    dbService.dispose();
    super.dispose();
  }

  _addSafetyItemsToMemberList() {
    if (_safetyItems.isEmpty) {
      _safetyItems.add(AppLocalizations.of(context)!.none);
      _safetyItems.add(AppLocalizations.of(context)!.minute1);
      _safetyItems.add(AppLocalizations.of(context)!.minutes2);
      _safetyItems.add(AppLocalizations.of(context)!.minutes3);
      _safetyItems.add(AppLocalizations.of(context)!.minutes4);
      _safetyItems.add(AppLocalizations.of(context)!.minutes5);
      _safetyItems.add(AppLocalizations.of(context)!.minutes10);
    }
  }

  _addDawnMethodItemsToMemberList() {
    if (_dawnMethodItems.isEmpty) {
      _dawnMethodItems.add(AppLocalizations.of(context)!.nautical_twilight);
      _dawnMethodItems.add(AppLocalizations.of(context)!.pa_auk);
      _dawnMethodItems.add(AppLocalizations.of(context)!.na_uyana);
      _dawnMethodItems.add(AppLocalizations.of(context)!.civil_twilight);
      _dawnMethodItems.add(AppLocalizations.of(context)!.sunrise);
    }
  }

  var controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
// here we must add the localized values to the menu buttons.
// when we have an active context.
    _addSafetyItemsToMemberList();
    _addDawnMethodItemsToMemberList();

    return Scaffold(
      appBar: AppBar(title: Text('settings')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Card(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 5),
                elevation: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 50, width: 50.0),
                    ColoredText(AppLocalizations.of(context)!.language + ":",
                        style: TextStyle(
                          fontSize: 18,
                        )),
                    SizedBox(width: 40.0),
                    SelectLanguageWidget(),
                  ],
                ),
              ),
              ThemeSettingView(),
              Card(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 5),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: TextField(
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              style: TextStyle(
                                  color: (!Prefs.darkThemeOn)
                                      ? Theme.of(context).primaryColor
                                      : Colors.white,
                                  fontSize: 15),
                              decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!
                                      .decimal_number,
                                  border: OutlineInputBorder()),
                              onChanged: (String data) async {
                                _offset = double.parse(data);
                                settingsProvider
                                    .setOffset(double.tryParse(data) ?? 0);
                              },
                            ),
                          ),
                          SizedBox(height: 6.0),
                          IconButton(
                            icon: Icon(Icons.save),
                            onPressed: () async {
                              setState(() {
                                Prefs.offset = _offset;
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 6.0),
                      ColoredText(
                          "${AppLocalizations.of(context)!.current_offset_is} ${Prefs.offset}"),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 25),
              Card(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Row(
                    children: [
                      SizedBox(height: 6.0),
                      ColoredText(AppLocalizations.of(context)!.safety,
                          style: TextStyle(
                            fontSize: 15,
                          )),
                      SizedBox(width: 10.0),
                      DropdownButton<String>(
                          value: _safetyItems[Prefs.safety],
                          style: TextStyle(
                            color: (!Prefs.darkThemeOn)
                                ? Theme.of(context).primaryColor
                                : Colors.white,
                          ),
                          isDense: false,
                          onChanged: (newValue) {
                            setState(() {
                              Prefs.safety = _safetyItems.indexOf(newValue!);
                            });
                          },
                          items: _safetyItems.map<DropdownMenuItem<String>>(
                            (String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: TextStyle(
                                      color: (!Prefs.darkThemeOn)
                                          ? Theme.of(context).primaryColor
                                          : Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ).toList()),
                      SizedBox(
                        width: 12,
                      ),
                      (Prefs.safety > 0)
                          ? //Text('\ud83d\udee1')
                          Icon(Icons.health_and_safety_outlined,
                              color: Theme.of(context).colorScheme.primary)
                          : Text(""),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Card(
                margin: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Row(
                    children: [
                      SizedBox(height: 6.0),
                      ColoredText("${AppLocalizations.of(context)!.dawn}:",
                          style: TextStyle(
                            fontSize: 16,
                          )),
                      SizedBox(
                        width: 10.0,
                        height: 20,
                      ),
                      DropdownButton<String>(
                          value: _dawnMethodItems[Prefs.dawnVal],
                          style: TextStyle(
                            color: (!Prefs.darkThemeOn)
                                ? Theme.of(context).primaryColor
                                : Colors.white,
                          ),
                          isDense: true,
                          onChanged: (newValue) {
                            setState(() {
                              Prefs.dawnVal =
                                  _dawnMethodItems.indexOf(newValue!);
                            });
                          },
                          items: _dawnMethodItems.map<DropdownMenuItem<String>>(
                            (String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: ColoredText(
                                  value,
                                  style: TextStyle(
                                      color: (Prefs.lightThemeOn)
                                          ? Theme.of(context).primaryColor
                                          : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ).toList()),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                style: TextStyle(
                    color: (!Prefs.darkThemeOn)
                        ? Theme.of(context).primaryColor
                        : null,
                    fontSize: 20),
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.search_for_city,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)))),
                controller: controller,
                onChanged: (String data) {
                  setState(() {
                    searchKey = data;
                  });
                  print(data);
                },
              ),
              FutureBuilder<List<WorldCities>>(
                  future: dbService.getWorldCities(searchKey),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    return ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return Card(
                            child: ListTile(
                              onTap: () async {
                                Prefs.cityName =
                                    snapshot.data![index].cityAscii;
                                Prefs.lat = snapshot.data![index].lat;
                                Prefs.lng = snapshot.data![index].lng;
                                settingsProvider.setLatLng(
                                    Prefs.lat, Prefs.lng);
                              },
                              title: ColoredText(
                                  "${snapshot.data![index].cityAscii}, ${snapshot.data![index].country} ",
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: (Prefs.lightThemeOn)
                                        ? Theme.of(context).primaryColor
                                        : Colors.white,
                                  )),
                              subtitle: ColoredText(
                                  snapshot.data![index].lat.toString() +
                                      "," +
                                      snapshot.data![index].lng.toString()),
                            ),
                          );
                        });
                  })
            ],
          ),
        ),
      ),
    );
  }
}
