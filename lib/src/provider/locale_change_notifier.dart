import 'package:flutter/material.dart';
import 'package:buddhist_sun/src/models/prefs.dart';

class LocaleChangeNotifier extends ChangeNotifier {
  int _localeVal = Prefs.localeVal;

  String get localeString {
    String localeString = "en";
    switch (_localeVal) {
      case 0:
        localeString = "en";
        break;
      case 1:
        localeString = "my";
        break;
      case 2:
        localeString = "si";
        break;
      case 3:
        localeString = "th";
        break;
      case 4:
        localeString = "km";
        break;
      case 5:
        localeString = "zh";
        break;
      case 6:
        localeString = "vi";
        break;
    }

    return localeString;
  }

  set localeVal(int val) {
    _localeVal = Prefs.localeVal = val;
    notifyListeners();
  }
}
