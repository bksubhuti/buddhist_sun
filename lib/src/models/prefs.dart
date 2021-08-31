// import to copy////////////////////
//import 'package:buddhist_sun/src/models/prefs.dart';

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

// default pref values
const String DEFAULT_CITYNAME = "Not Set";
const double DEFAULT_LAT = 1.1;
const double DEFAULT_LNG = 1.1;
const double DEFAULT_OFFSET = 6.5;
const bool DEFAULT_SPEAKISON = false;
const bool DEFAULT_SCREEN_ALWAYS_ON = false;
const bool DEFAULT_BACKGROUND_ON = false;
const double DEFAULT_VOLUME = 0.5;
const String DEFAULT_SAFETY = "1 minute";
const String DEFAULT_DAWNVAL = "Nauticle Twilight";
const bool DEFAULT_RETRIEVE_CITYNAME = false;

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

  static String get safety => instance.getString(SAFETY) ?? DEFAULT_SAFETY;
  static set safety(String value) => instance.setString(SAFETY, value);

  static String get dawnVal => instance.getString(DAWNVAL) ?? DEFAULT_DAWNVAL;
  static set dawnVal(String value) => instance.setString(DAWNVAL, value);
}
