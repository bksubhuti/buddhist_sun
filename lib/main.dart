import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:buddhist_sun/src/services/background_time_player.dart';
import 'package:buddhist_sun/utils/buddhavassa_data.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:buddhist_sun/views/base_home_page.dart';
// #docregion LocalizationDelegatesImport
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:buddhist_sun/src/models/prefs.dart';

// theme stuff
import 'package:buddhist_sun/src/provider/locale_change_notifier.dart';
import 'package:buddhist_sun/src/provider/theme_change_notifier.dart';
import 'package:buddhist_sun/src/provider/settings_provider.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'src/services/plugin.dart';
import 'package:buddhist_sun/src/services/notification_service.dart';
import 'package:buddhist_sun/src/services/example_includes.dart';

// ----------------------------------------------------------
//  MAIN
// ----------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'dawn_audio_channel',
    androidNotificationChannelName: 'Dawn Audio',
    androidNotificationOngoing: true,
    preloadArtwork: true,
  );

  // 1. Timezone FIRST
  await configureLocalTimeZone();

  // 2. Notification initialization SECOND (exactly like the working example)
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

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: selectNotificationStream.add,
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  await Prefs.init();
  await createUposathaChannel(); // ← moved AFTER initialize (harmless on iOS)
  await createTimerChannelsOnce(); // ← moved AFTER initialize (harmless on iOS)
  await BackgroundTimePlayer.init();

  // Finally schedule
  if (Prefs.uposathaNotificationsEnabled) {
    await cancelAllUposathaNotifications();
    await scheduleUpcomingUposathaNotifications();
  }

  await BuddhavassaData.init();

  runApp(MyApp());
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
              Locale('bn', ''),
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
