import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:buddhist_sun/views/base_home_page.dart';
import 'dart:io' show Platform;
// #docregion LocalizationDelegatesImport
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:buddhist_sun/src/models/prefs.dart';

// #enddocregion LocalizationDelegatesImport
// #docregion AppLocalizationsImport
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// #enddocregion AppLocalizationsImport

// theme stuff
import 'package:buddhist_sun/src/models/theme_data.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

// for one context
//import 'package:one_context/one_context.dart';

void main() async {
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();

    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  }

  // Required for async calls in `main`
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize SharedPrefs instance.
  await Prefs.init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Buddhist Sun",
      themeMode: ThemeMode.light,
      //theme: ThemeData(brightness: Brightness.light, accentColor: Colors.blue),
      //darkTheme: ThemeData(
      //  brightness: Brightness.dark, accentColor: Colors.amber[700]),
      theme: FlexColorScheme.light(colors: myScheme1Light).toTheme,
      darkTheme: FlexColorScheme.dark(colors: myScheme1Dark).toTheme,

      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        AppLocalizations.delegate, // Add this line
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', ''), // English, no country code
        Locale('es', ''), // Spanish, no country code
        Locale('my', ''), // Myanmar, no country code
        Locale('si', ''), // Myanmar, no country code
        Locale('zh', ''), // Myanmar, no country code
      ],
      home: HomePageContainer(),
    );
  }
}
