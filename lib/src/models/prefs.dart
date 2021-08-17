import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  bool _gotPrefs = false;
  double lat = 1.1;
  double lng = 1.1;
  double offset = 6.5;
  //DateTime solarNoon;
  String cityName = "Not Set";
  late SharedPreferences _prefs;
  Prefs() {}
  GetSetValues() async {
    if (_gotPrefs == false) {
      _prefs = await SharedPreferences.getInstance();
      _gotPrefs = true;
    }
    // get and set the default member values if null
    cityName = _prefs.getString("cityName") ?? "not set2";
    lat = _prefs.getDouble("lat") ?? 1.1;
    lng = _prefs.getDouble("lng") ?? 1.1;
    offset = _prefs.getDouble("offset") ?? 6.5;

    // set the values
    _prefs.setString("cityName", cityName);
    _prefs.setDouble("lat", lat);
    _prefs.setDouble("lng", lng);
    _prefs.setDouble("offset", offset);
  }
}
