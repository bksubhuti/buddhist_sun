import 'package:flutter/material.dart';


class LocaleChangeNotifier extends ChangeNotifier {
  String _local = "en";

  String get locale => _local;
  set locale(String val) {
    _local = val;
    notifyListeners();
  }

  set localeVal(int val) {
    switch (val) {
      case 0:
        _local = "en";
        break;
      case 1:
        _local = "my";
        break;
      case 0:
        _local = "si";
        break;
      case 0:
        _local = "zh";
        break;
    }
  }

  notifyListeners();
}
