import 'package:buddhist_sun/src/services/get_world_cities.dart';
import 'package:buddhist_sun/src/services/notification_service.dart';
import 'package:buddhist_sun/views/theme_settings_view.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:buddhist_sun/src/models/select_language_widget.dart';
import 'package:buddhist_sun/src/models/colored_text.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
  // You can toggle this based on user interactions or other
  bool showCityAndOffset = false;
  late TextEditingController _customDawnController;

  @override
  void initState() {
    // debug mode to reset
    //Prefs.instance.clear();
    dbService.initDatabase();
    _customDawnController =
        TextEditingController(text: Prefs.customDawnAngle.toString());
    super.initState();
  }

  @override
  void dispose() {
    dbService.dispose();
    _customDawnController.dispose();
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
      _dawnMethodItems.add(AppLocalizations.of(context)!.pa_auk_angle);
      _dawnMethodItems.add(AppLocalizations.of(context)!.na_uyana_angle);
      _dawnMethodItems.add(AppLocalizations.of(context)!.custom_dawn);
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
                              settingsProvider.setSafety(Prefs.safety);
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
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ColoredText("${AppLocalizations.of(context)!.dawn}:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          )),
                      SizedBox(height: 6.0),
                      DropdownButton<String>(
                          value: _dawnMethodItems[Prefs.dawnVal],
                          style: TextStyle(
                            color: (!Prefs.darkThemeOn)
                                ? Theme.of(context).primaryColor
                                : Colors.white,
                          ),
                          isExpanded: true,
                          isDense: true,
                          onChanged: (newValue) {
                            setState(() {
                              Prefs.dawnVal =
                                  _dawnMethodItems.indexOf(newValue!);
                              settingsProvider.setDawnVal(newValue);
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ).toList()),
                    ],
                  ),
                ),
              ),
              if (Prefs.dawnVal == 5) SizedBox(height: 15),
              if (Prefs.dawnVal == 5)
                Card(
                  margin: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: Row(
                      children: [
                        SizedBox(height: 6.0),
                        ColoredText("Angle (Degrees):",
                            style: TextStyle(
                              fontSize: 16,
                            )),
                        SizedBox(
                          width: 10.0,
                          height: 20,
                        ),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.numberWithOptions(
                                decimal: true, signed: true),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 10.0),
                            ),
                            controller: _customDawnController,
                            style: TextStyle(
                              color: (!Prefs.darkThemeOn)
                                  ? Theme.of(context).primaryColor
                                  : Colors.white,
                            ),
                            onChanged: (value) {
                              double? angle = double.tryParse(value);
                              if (angle != null) {
                                Prefs.customDawnAngle = angle;
                                // Need to notify listeners if they depend on this to redraw immediately
                                // We can use settingsProvider.setDawnVal with current to trigger update
                                settingsProvider.setDawnVal(
                                    _dawnMethodItems[Prefs.dawnVal]);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 15),
              Card(
                margin: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ColoredText(
                          "${AppLocalizations.of(context)!.uposathaCountry}:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          )),
                      SizedBox(height: 6.0),
                      DropdownButton<String>(
                          value: EnumToString.convertToString(
                              Prefs.selectedUposatha,
                              camelCase: true),
                          style: TextStyle(
                            color: (!Prefs.darkThemeOn)
                                ? Theme.of(context).primaryColor
                                : Colors.white,
                          ),
                          isExpanded: true,
                          isDense: true,
                          onChanged: (newValue) {
                            setState(() {
                              Prefs.selectedUposatha = EnumToString.fromString(
                                      UposathaCountry.values, newValue!,
                                      camelCase: true) ??
                                  UposathaCountry.Myanmar;
                              settingsProvider.setSelectedUposatha(newValue);
                            });
                          },
                          items: EnumToString.toList(UposathaCountry.values,
                                  camelCase: true)
                              .map<DropdownMenuItem<String>>(
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
              Card(
                margin: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: ColoredText(
                          AppLocalizations.of(context)!.autoStartDawnTimer,
                          style: TextStyle(fontSize: 16),
                        ),
                        value: Prefs.autoStartDawnTimer,
                        onChanged: (bool value) {
                          setState(() {
                            Prefs.autoStartDawnTimer = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        title: ColoredText(
                          AppLocalizations.of(context)!.autoStartNoonTimer,
                          style: TextStyle(fontSize: 16),
                        ),
                        value: Prefs.autoStartNoonTimer,
                        onChanged: (bool value) {
                          setState(() {
                            Prefs.autoStartNoonTimer = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 15),
              NotificationSettingsWidget(),
              getDeathContemplationSettings(settingsProvider),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

// removed this from the regular build.. not called
  Widget getOffsetCard(BuildContext context) {
    return Card(
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
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                        color: (!Prefs.darkThemeOn)
                            ? Theme.of(context).primaryColor
                            : Colors.white,
                        fontSize: 15),
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.decimal_number,
                        border: OutlineInputBorder()),
                    onChanged: (String data) async {
                      _offset = double.parse(data);
                      //settingsProvider
                      //  .setOffset(double.tryParse(data) ?? 0);
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
    );
  }

  Widget NotificationSettingsWidget() {
    return Card(
      // 🟢 NEW
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 10),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColoredText(
              AppLocalizations.of(context)!.uposathaNotifications,
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(
              height: 12,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ColoredText(
                  AppLocalizations.of(context)!.daysBefore,
                  style: TextStyle(fontSize: 16),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          final current = Prefs.beforeUposathaNotificationDays;
                          if (current > 0) {
                            Prefs.beforeUposathaNotificationDays = current - 1;
                          }
                        });
                        rescheduleUposathaNotifications();
                      },
                    ),
                    Text(
                      '${Prefs.beforeUposathaNotificationDays}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          Prefs.beforeUposathaNotificationDays =
                              Prefs.beforeUposathaNotificationDays + 1;
                        });
                        rescheduleUposathaNotifications();
                      },
                    ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ColoredText(
                  AppLocalizations.of(context)!.notificationTime,
                  style: TextStyle(fontSize: 16),
                ),
                TextButton(
                  onPressed: () async {
                    final initialTime = Prefs.uposathaNotificationTime;
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: initialTime,
                    );
                    if (picked != null) {
                      setState(() {
                        Prefs.uposathaNotificationTime = picked;
                      });
                      rescheduleUposathaNotifications();
                    }
                  },
                  child: Text(
                    Prefs.uposathaNotificationTime.format(context),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget getDeathContemplationSettings(SettingsProvider settingsProvider) {
    if (!showDeath) return const SizedBox.shrink();
    final birthDate = Prefs.deathContemplationBirthDate;
    final birthDateFormatted = birthDate != null
        ? DateFormat('yyyy-MM-dd').format(birthDate)
        : AppLocalizations.of(context)!.not_set;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 15),
        Card(
          margin: const EdgeInsets.fromLTRB(15, 0, 15, 10),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.hourglass_bottom,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ColoredText(
                        AppLocalizations.of(context)!.deathContemplation,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.maranasatiQuote,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Divider(height: 20),
                // Birthday
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ColoredText(
                        AppLocalizations.of(context)!.birthday,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            birthDateFormatted,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () async {
                            final initial = birthDate ?? DateTime(1990, 1, 1);
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: initial,
                              firstDate: DateTime(1900, 1, 1),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                Prefs.deathContemplationBirthDate = picked;
                              });
                              settingsProvider
                                  .updateDeathContemplationSettings();
                            }
                          },
                        ),
                        if (birthDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            tooltip: 'Clear',
                            onPressed: () {
                              setState(() {
                                Prefs.deathContemplationBirthDate = null;
                              });
                              settingsProvider
                                  .updateDeathContemplationSettings();
                            },
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Expected Life Expectancy Age
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ColoredText(
                        AppLocalizations.of(context)!.lifeExpectancy,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            final current =
                                Prefs.deathContemplationLifeExpectancy;
                            if (current > 1) {
                              setState(() {
                                Prefs.deathContemplationLifeExpectancy =
                                    current - 1;
                              });
                              settingsProvider
                                  .updateDeathContemplationSettings();
                            }
                          },
                        ),
                        InkWell(
                          onTap: () async {
                            final controller = TextEditingController(
                              text: Prefs.deathContemplationLifeExpectancy
                                  .toString(),
                            );
                            final result = await showDialog<int>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(AppLocalizations.of(context)!
                                    .lifeExpectancy),
                                content: TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Age (Years)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(
                                        AppLocalizations.of(context)!.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      final val = int.tryParse(controller.text);
                                      if (val != null &&
                                          val > 0 &&
                                          val <= 130) {
                                        Navigator.pop(ctx, val);
                                      }
                                    },
                                    child:
                                        Text(AppLocalizations.of(context)!.ok),
                                  ),
                                ],
                              ),
                            );
                            if (result != null) {
                              setState(() {
                                Prefs.deathContemplationLifeExpectancy = result;
                              });
                              settingsProvider
                                  .updateDeathContemplationSettings();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Text(
                              '${Prefs.deathContemplationLifeExpectancy}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            final current =
                                Prefs.deathContemplationLifeExpectancy;
                            if (current < 130) {
                              setState(() {
                                Prefs.deathContemplationLifeExpectancy =
                                    current + 1;
                              });
                              settingsProvider
                                  .updateDeathContemplationSettings();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
