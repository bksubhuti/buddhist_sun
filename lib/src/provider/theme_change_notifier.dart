import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/models/theme_data.dart';

class ThemeChangeNotifier extends ChangeNotifier {
  ThemeMode themeMode = (Prefs.darkThemeOn) ? ThemeMode.dark : ThemeMode.light;
  // ignore: unused_field
  int _themeIndex = 1;
  bool _useM3 = true;
  final List<bool> _isSelected = [true, false, false];

  set useM3(bool val) {
    _useM3 = val;
    notifyListeners();
  }

  set themeIndex(int val) {
    _themeIndex = val;
    notifyListeners();
  }

  List<bool> get isSelected {
    Prefs.selectedPageColor;

    //make sure the list returned is the same as prefs given.
    for (int x = 0; x < _isSelected.length; x++) {
      _isSelected[x] = x == Prefs.selectedPageColor;
    }
    return _isSelected;
  }

  bool get isDarkMode => themeMode == ThemeMode.dark;

  toggleTheme(int index) {
    themeMode = ThemeMode.light;
    for (int buttonIndex = 0; buttonIndex < isSelected.length; buttonIndex++) {
      if (buttonIndex == index) {
        _isSelected[buttonIndex] = true;
      } else {
        _isSelected[buttonIndex] = false;
      }
    }

    switch (index) {
      case 0:
        Prefs.selectedPageColor = 0;
        themeMode = ThemeMode.light;
        Prefs.darkThemeOn = false;
        break;
      case 1:
        Prefs.selectedPageColor = 1;
        themeMode = ThemeMode.light;
        Prefs.darkThemeOn = false;
        break;
      case 2:
        Prefs.selectedPageColor = 2;
        themeMode = ThemeMode.dark;
        Prefs.darkThemeOn = true;
        break;
      default:
        Prefs.selectedPageColor = 0;
        themeMode = ThemeMode.light;
        Prefs.darkThemeOn = false;
        break;
    }

    notifyListeners();
  }

  void onChangeFontSize(double fontSize) {
    notifyListeners();
  }

  // Returns dark ThemeData made by FlexColorScheme
  ThemeData get darkTheme => FlexThemeData.dark(
        colors: myFlexSchemes[Prefs.themeIndex].dark,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 2,
        tabBarStyle: FlexTabBarStyle.forAppBar,
        transparentStatusBar: true,
        subThemesData: FlexSubThemesData(
          appBarScrolledUnderElevation: Prefs.useM3 ? 6 : 0,
          blendOnLevel: 15,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
          elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
          inputDecoratorSchemeColor: SchemeColor.primary,
          inputDecoratorBackgroundAlpha: 28,
          inputDecoratorRadius: 8.0,
          inputDecoratorUnfocusedHasBorder: false,
          fabUseShape: true,
          fabAlwaysCircular: true,
          fabSchemeColor: SchemeColor.secondary,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
          drawerWidth: 300,
          tabBarIndicatorSize: TabBarIndicatorSize.tab,
          cardElevation: Prefs.useM3 ? 2 : 4,
          interactionEffects: true,
        ),
        keyColors: Prefs.useM3
            ? const FlexKeyColors(
                useSecondary: true,
                useTertiary: true,
                keepPrimary: true,
                keepSecondary: true,
                keepTertiary: true,
              )
            : null,
        tones: FlexTones.candyPop(Brightness.dark),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: Prefs.useM3,
      ).copyWith(
        // Custom ExpansionTileTheme that removes the extra borders.
        expansionTileTheme: const ExpansionTileThemeData(
          shape: Border(),
          collapsedShape: Border(),
        ),
      );

  // Returns light ThemeData made by FlexColorScheme
  ThemeData get themeData => FlexThemeData.light(
        colors: myFlexSchemes[Prefs.themeIndex].light,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 1,
        appBarStyle: Prefs.useM3 ? FlexAppBarStyle.surface : null,
        tabBarStyle: FlexTabBarStyle.forAppBar,
        transparentStatusBar: true,
        appBarElevation: Prefs.useM3 ? 3 : 0,
        subThemesData: FlexSubThemesData(
          appBarScrolledUnderElevation: Prefs.useM3 ? 6 : 0,
          blendOnLevel: 8,
          blendOnColors: false,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
          elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
          inputDecoratorSchemeColor: SchemeColor.primary,
          inputDecoratorBackgroundAlpha: 23,
          inputDecoratorRadius: 8.0,
          inputDecoratorUnfocusedHasBorder: false,
          fabUseShape: true,
          fabAlwaysCircular: true,
          fabSchemeColor: SchemeColor.secondary,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
          drawerWidth: 300,
          chipSelectedSchemeColor:
              Prefs.useM3 ? SchemeColor.primaryContainer : null,
          tabBarIndicatorSize: TabBarIndicatorSize.tab,
          cardElevation: Prefs.useM3 ? 2 : 4,
          interactionEffects: true,
        ),
        keyColors: Prefs.useM3
            ? const FlexKeyColors(
                useSecondary: true,
                useTertiary: true,
                keepPrimary: true,
                keepSecondary: true,
                keepTertiary: true,
              )
            : null,
        tones: FlexTones.candyPop(Brightness.light),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: Prefs.useM3,
      ).copyWith(
        // Custom ExpansionTileTheme that removes the extra borders.
        expansionTileTheme: const ExpansionTileThemeData(
          shape: Border(),
          collapsedShape: Border(),
        ),
      );
}
