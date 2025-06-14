import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:buddhist_sun/views/base_home_page.dart';
import 'dart:io' show Platform;
// #docregion LocalizationDelegatesImport
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:buddhist_sun/src/models/prefs.dart';

// theme stuff
import 'package:buddhist_sun/src/provider/locale_change_notifier.dart';
import 'package:buddhist_sun/src/provider/theme_change_notifier.dart';
import 'package:buddhist_sun/src/provider/settings_provider.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// for one context
//import 'package:one_context/one_context.dart';

void main() async {
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();
    // Initialize the timezone package

    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  }

  // Required for async calls in `main`
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize SharedPrefs instance.
  await Prefs.init();
  await initJsonFile(); // Ensure JSON file is ready before app runs

  runApp(MyApp());
}

Future<void> initJsonFile() async {
  final directory = await getApplicationSupportDirectory();
  File jsonFile = File('${directory.path}/uposatha.json');

  String content = await rootBundle.loadString('assets/uposatha.json');

  // Ensure the file is fully written before proceeding
  await jsonFile.writeAsString(content);

  // Set default last download time
  Prefs.lastDownload = DateTime(2025, 12, 1);
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeChangeNotifier>(
            create: (context) => ThemeChangeNotifier(),
          ),
          ChangeNotifierProvider<LocaleChangeNotifier>(
            create: (context) => LocaleChangeNotifier(),
          ),
          ChangeNotifierProvider<SettingsProvider>(
            create: (context) => SettingsProvider(),
          ),
        ],
        builder: (context, _) {
          final themeChangeNotifier = Provider.of<ThemeChangeNotifier>(context);
          final localChangeNotifier =
              Provider.of<LocaleChangeNotifier>(context);
          return MaterialApp(
            title: "Buddhist Sun",
            themeMode: themeChangeNotifier.themeMode,
            theme: themeChangeNotifier.themeData,
            darkTheme: themeChangeNotifier.darkTheme,
            locale: Locale(localChangeNotifier.localeString, ''),
            debugShowCheckedModeBanner: false,
            localizationsDelegates: [
              AppLocalizations.delegate, // Add this line
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              Locale('en', ''), // English, no country code
              Locale('my', ''), // Myanmar, no country code
              Locale('si', ''), // Myanmar, no country code
              Locale('th', ''), // thai, no country code
              Locale('km', ''), // khmer
              Locale('zh', ''), // Myanmar, no country code
              Locale('vi', ''), // vietnam, no country code
            ],
            home: HomePageContainer(),
          );
        }, // builder
      );
}
