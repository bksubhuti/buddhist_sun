import 'package:flutter/foundation.dart';

class SettingsProvider extends ChangeNotifier {
  double _offset = 0;
  int _safety = 0;
  String _dawnVal = "";
  double _lat = 0.0;
  double _lng = 0.0;

  double get offset => _offset;
  int get safety => _safety;
  String get dawnVal => _dawnVal;
  double get lat => _lat;
  double get lng => _lng;
  String _country = "";

  void setOffset(double newOffset) {
    _offset = newOffset;
    notifyListeners();
  }

  void setSafety(int newIndex) {
    _safety = newIndex;
    notifyListeners();
  }

  void setDawnVal(String newValue) {
    _dawnVal = newValue;
    notifyListeners();
  }

  void setLatLng(lat, lng) {
    _lat = lat;
    _lng = lng;
    notifyListeners();
  }

  void setSelectedUposatha(String country) {
    _country = country;
    notifyListeners();
  }
}
