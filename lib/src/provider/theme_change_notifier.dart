import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/models/theme_data.dart';





class ThemeChangeNotifier extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark;
  int _themeIndex = 1;

  set themeIndex(int val) {
    _themeIndex = val;
    notifyListeners();
  }

  bool get isDarkMode => themeMode == ThemeMode.dark;
  toggleTheme(bool isOn) {
    themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  //returns // flexschemedata
  get darkTheme => FlexColorScheme.dark(
        // As scheme colors we use the one from our list
        // pointed to by the current themeIndex.
        colors: myFlexSchemes[Prefs.themeIndex].light,
        // Medium strength surface branding used in this example.
        surfaceStyle: FlexSurface.medium,
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
      ).toTheme;

  ThemeData get themeData =>
      //ThemeData get themeData=>  myFlexSchemes[Prefs.themeIndex].light().toTheme();
      FlexColorScheme.light(
        // As scheme colors we use the one from our list
        // pointed to by the current themeIndex.
        colors: myFlexSchemes[Prefs.themeIndex].light,
        // Medium strength surface branding used in this example.
        surfaceStyle: FlexSurface.medium,
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
      ).toTheme;
}
