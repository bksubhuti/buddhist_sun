// import to copy////////////////////
//import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';

// Shared prefs package import
import 'package:shared_preferences/shared_preferences.dart';

// preference names
const String CITYNAME = "cityName";
const String LAT = "lat";
const String LNG = "lng";
const String OFFSET = "offset";
const String SPEAKISON = "speakIsOn";
const String SCREEN_ALWAYS_ON = "screenAlwaysOn";
const String BACKGROUND_ON = "backgroundOn";
const String VOLUME = "volume";
const String SAFETY = "safety";
const String DAWNVAL = "dawnVal";
const String RETRIEVE_CITYNAME = "retrieveCityName";
const String LOCALEVAL = "localeVal";
const String THEME_INDEX = "themeIndex";
const String LIGHT_THEME_ON = "lightThemeOn";
const String useM3Pref = 'useM3';
const String darkThemeOnPref = "darkThemeOn";
const String UPOSATHACOUNTRY = "uposathaCountry";
const String LASTDOWNLOAD = "lastDownload";

// default pref values
const String DEFAULT_CITYNAME = "Not Set";
const double DEFAULT_LAT = 1.1;
const double DEFAULT_LNG = 1.1;
const double DEFAULT_OFFSET = 6.5;
const bool DEFAULT_SPEAKISON = false;
const bool DEFAULT_SCREEN_ALWAYS_ON = false;
const bool DEFAULT_BACKGROUND_ON = false;
const double DEFAULT_VOLUME = 0.5;
const int DEFAULT_SAFETY = 1;
const int DEFAULT_DAWNVAL = 1;
const bool DEFAULT_RETRIEVE_CITYNAME = true;
const int DEFAULT_LOCALEVAL = 0;
const int DEFAULT_THEME_INDEX = 24;
const bool DEFAULT_LIGHT_THEME_ON = true;
const bool defaultUseM3 = true;
const bool defaultDarkThemeOn = false;
int defaultSelectedPageColor = 0;
const String selectedPageColorPref = "selectedPageColor";
const String themeNamePref = "themeNamePref";
const String defaultThemeName = '';
DateTime defaultLastDownload = DateTime(2000);

enum UposathaCountry { Myanmar, Sinhala, Thailand }

const defaultSelectedUposatha = UposathaCountry.Myanmar;

class Prefs {
  static late final SharedPreferences instance;

  static Future<SharedPreferences> init() async =>
      instance = await SharedPreferences.getInstance();

  // get and set the default member values if null
  static String get cityName =>
      instance.getString(CITYNAME) ?? DEFAULT_CITYNAME;
  static set cityName(String value) => instance.setString(CITYNAME, value);

  static double get lat => instance.getDouble(LAT) ?? DEFAULT_LAT;
  static set lat(double value) => instance.setDouble(LAT, value);

  static double get lng => instance.getDouble(LNG) ?? DEFAULT_LNG;
  static set lng(double value) => instance.setDouble(LNG, value);

  static double get offset => instance.getDouble(OFFSET) ?? DEFAULT_OFFSET;
  static set offset(double value) => instance.setDouble(OFFSET, value);

  static bool get speakIsOn => instance.getBool(SPEAKISON) ?? DEFAULT_SPEAKISON;
  static set speakIsOn(bool value) => instance.setBool(SPEAKISON, value);

  static bool get screenAlwaysOn =>
      instance.getBool(SCREEN_ALWAYS_ON) ?? DEFAULT_SCREEN_ALWAYS_ON;
  static set screenAlwaysOn(bool value) =>
      instance.setBool(SCREEN_ALWAYS_ON, value);

  static bool get backgroundOn =>
      instance.getBool(BACKGROUND_ON) ?? DEFAULT_BACKGROUND_ON;
  static set backgroundOn(bool value) => instance.setBool(BACKGROUND_ON, value);

  static bool get retrieveCityName =>
      instance.getBool(RETRIEVE_CITYNAME) ?? DEFAULT_RETRIEVE_CITYNAME;
  static set retrieveCityName(bool value) =>
      instance.setBool(RETRIEVE_CITYNAME, value);

  static double get volume => instance.getDouble(VOLUME) ?? DEFAULT_VOLUME;
  static set volume(double value) => instance.setDouble(VOLUME, value);

  static int get safety => instance.getInt(SAFETY) ?? DEFAULT_SAFETY;
  static set safety(int value) => instance.setInt(SAFETY, value);

  static int get dawnVal => instance.getInt(DAWNVAL) ?? DEFAULT_DAWNVAL;
  static set dawnVal(int value) => instance.setInt(DAWNVAL, value);

  static int get localeVal => instance.getInt(LOCALEVAL) ?? DEFAULT_LOCALEVAL;
  static set localeVal(int value) => instance.setInt(LOCALEVAL, value);

  static int get themeIndex =>
      instance.getInt(THEME_INDEX) ?? DEFAULT_THEME_INDEX;
  static set themeIndex(int value) => instance.setInt(THEME_INDEX, value);

  static bool get lightThemeOn =>
      instance.getBool(LIGHT_THEME_ON) ?? DEFAULT_LIGHT_THEME_ON;
  static set lightThemeOn(bool value) =>
      instance.setBool(LIGHT_THEME_ON, value);
  static String get themeName =>
      instance.getString(themeNamePref) ?? defaultThemeName;
  static set themeName(String value) =>
      instance.setString(themeNamePref, value);

  static bool get useM3 => instance.getBool(useM3Pref) ?? defaultUseM3;
  static set useM3(bool value) => instance.setBool(useM3Pref, value);
  static bool get darkThemeOn =>
      instance.getBool(darkThemeOnPref) ?? defaultDarkThemeOn;
  static set darkThemeOn(bool value) =>
      instance.setBool(darkThemeOnPref, value);

  static int get selectedPageColor =>
      instance.getInt(selectedPageColorPref) ?? defaultSelectedPageColor;
  static set selectedPageColor(int value) =>
      instance.setInt(selectedPageColorPref, value);

  static UposathaCountry get selectedUposatha =>
      EnumToString.fromString(
          UposathaCountry.values, instance.getString(UPOSATHACOUNTRY) ?? "",
          camelCase: true) ??
      UposathaCountry.Myanmar;
  static set selectedUposatha(UposathaCountry value) => instance.setString(
      UPOSATHACOUNTRY, EnumToString.convertToString(value, camelCase: true));

  static DateTime get lastDownload =>
      DateTime.tryParse(instance.getString(LASTDOWNLOAD) ?? "") ??
      defaultLastDownload;
  static set lastDownload(DateTime value) =>
      instance.setString(LASTDOWNLOAD, value.toString());

  static Color getChosenColor(BuildContext context) {
    switch (Prefs.selectedPageColor) {
      case 0:
        return (Color(Colors.white.value));
      case 1:
        return Theme.of(context)
            .colorScheme
            .surfaceContainerHighest; // ?? (const Color(seypia));
      case 2:
        return (Color(Colors.black.value));
      default:
        return Color(Colors.white.value);
    }
  }
}
