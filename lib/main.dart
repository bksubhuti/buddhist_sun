import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:buddhist_sun/views/base_home_page.dart';
import 'dart:io' show File, Platform;
// #docregion LocalizationDelegatesImport
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:buddhist_sun/src/models/prefs.dart';

// theme stuff
import 'package:buddhist_sun/src/provider/locale_change_notifier.dart';
import 'package:buddhist_sun/src/provider/theme_change_notifier.dart';
import 'package:buddhist_sun/src/provider/settings_provider.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'src/services/plugin.dart';
import 'package:buddhist_sun/src/services/notification_service.dart';
import 'package:buddhist_sun/src/services/example_includes.dart';

// ----------------------------------------------------------
//  MAIN
// ----------------------------------------------------------
Future<void> main() async {
  // Needed for async work in main
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop DB init
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // SharedPrefs
  await Prefs.init();

  // Ensure Uposatha JSON is in app-support dir
  await initJsonFile();

  // Timezone for tz-based scheduling
  await configureLocalTimeZone();
  await createUposathaChannel(); // NEW — needed BEFORE initialize()

  // ---------------- ANDROID / iOS / macOS INIT ----------------

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');

  final List<DarwinNotificationCategory> darwinNotificationCategories =
      <DarwinNotificationCategory>[
    DarwinNotificationCategory(
      darwinNotificationCategoryText,
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.text(
          'text_1',
          'Action 1',
          buttonTitle: 'Send',
          placeholder: 'Placeholder',
        ),
      ],
    ),
    DarwinNotificationCategory(
      darwinNotificationCategoryPlain,
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain('id_1', 'Action 1'),
        DarwinNotificationAction.plain(
          'id_2',
          'Action 2 (destructive)',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.destructive,
          },
        ),
        DarwinNotificationAction.plain(
          navigationActionId,
          'Action 3 (foreground)',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.foreground,
          },
        ),
        DarwinNotificationAction.plain(
          'id_4',
          'Action 4 (auth required)',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.authenticationRequired,
          },
        ),
      ],
      options: <DarwinNotificationCategoryOption>{
        DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
      },
    ),
  ];

  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    notificationCategories: darwinNotificationCategories,
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
  );

  // Single initialize call
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: selectNotificationStream.add,
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  // ---------------- PLATFORM PERMISSIONS / CHANNELS ----------------
  if (!kIsWeb && Platform.isAndroid) {
    final androidImpl =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // POST_NOTIFICATIONS (Android 13+)
    await androidImpl?.requestNotificationsPermission();

    // Exact alarms (for prev-day 6am exactAllowWhileIdle)
    // This may return false on devices that restrict exact alarms.
    await androidImpl?.requestExactAlarmsPermission();
  }

  // ---------------- SCHEDULE UPOSATHA NOTIFICATIONS ----------------
  if (Prefs.uposathaNotificationsEnabled) {
    await cancelAllNotifications(); // prevents duplicates
    await scheduleUpcomingUposathaNotifications();
  }

  runApp(MyApp());
}

// ----------------------------------------------------------
//  Uposatha JSON SETUP
// ----------------------------------------------------------
Future<void> initJsonFile() async {
  final directory = await getApplicationSupportDirectory();
  final jsonFile = File('${directory.path}/uposatha.json');

  // Always copy from assets (overwrites old if needed)
  final content = await rootBundle.loadString('assets/uposatha.json');
  await jsonFile.writeAsString(content);

  // Set default last download time
  Prefs.lastDownload = DateTime(2025, 12, 1);
}

// ----------------------------------------------------------
//  APP WIDGET
// ----------------------------------------------------------
class MyApp extends StatelessWidget {
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
          final font = _fontForLocale(localChangeNotifier.localeString);

          return MaterialApp(
            title: "Buddhist Sun",
            themeMode: themeChangeNotifier.themeMode,
            theme: themeChangeNotifier.themeData.copyWith(
              textTheme: themeChangeNotifier.themeData.textTheme.apply(
                fontFamily: font,
              ),
            ),
            darkTheme: themeChangeNotifier.darkTheme,
            locale: Locale(localChangeNotifier.localeString, ''),
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
              Locale('my', ''),
              Locale('si', ''),
              Locale('th', ''),
              Locale('km', ''),
              Locale('zh', ''),
              Locale('vi', ''),
              Locale('hi', ''),
            ],
            home: HomePageContainer(),
          );
        },
      );

  String? _fontForLocale(String locale) {
    switch (locale) {
      case 'my':
        return 'NotoSansMyanmar';
      case 'si':
        return 'NotoSansSinhala';
      default:
        return null; // system default
    }
  }
}
