import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_km.dart';
import 'app_localizations_my.dart';
import 'app_localizations_si.dart';
import 'app_localizations_th.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('km'),
    Locale('my'),
    Locale('si'),
    Locale('th'),
    Locale('vi'),
    Locale('zh')
  ];

  /// No description provided for @buddhistSun.
  ///
  /// In en, this message translates to:
  /// **'Buddhist Sun'**
  String get buddhistSun;

  /// No description provided for @noon.
  ///
  /// In en, this message translates to:
  /// **'Noon'**
  String get noon;

  /// No description provided for @dawn.
  ///
  /// In en, this message translates to:
  /// **'Dawn'**
  String get dawn;

  /// No description provided for @timer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get timer;

  /// No description provided for @gps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get gps;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @not_set.
  ///
  /// In en, this message translates to:
  /// **'Not Set'**
  String get not_set;

  /// No description provided for @solar_noon.
  ///
  /// In en, this message translates to:
  /// **'Solar Noon'**
  String get solar_noon;

  /// No description provided for @gmt_offset.
  ///
  /// In en, this message translates to:
  /// **'GMT Offset'**
  String get gmt_offset;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @astronomical_twilight.
  ///
  /// In en, this message translates to:
  /// **'Astronomical Twilight'**
  String get astronomical_twilight;

  /// No description provided for @nautical_twilight.
  ///
  /// In en, this message translates to:
  /// **'Nautical Twilight'**
  String get nautical_twilight;

  /// No description provided for @civil_twilight.
  ///
  /// In en, this message translates to:
  /// **'Civil Twilight'**
  String get civil_twilight;

  /// No description provided for @sunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @current_time.
  ///
  /// In en, this message translates to:
  /// **'Current Time'**
  String get current_time;

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get late;

  /// No description provided for @time_left.
  ///
  /// In en, this message translates to:
  /// **'Time Left'**
  String get time_left;

  /// No description provided for @speech_notify.
  ///
  /// In en, this message translates to:
  /// **'Speech Notify'**
  String get speech_notify;

  /// No description provided for @screen_always_on.
  ///
  /// In en, this message translates to:
  /// **'Screen Always On'**
  String get screen_always_on;

  /// No description provided for @speech_in_background.
  ///
  /// In en, this message translates to:
  /// **'Speech in background'**
  String get speech_in_background;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @press_wait.
  ///
  /// In en, this message translates to:
  /// **'Press and wait for new GPS.'**
  String get press_wait;

  /// No description provided for @get_gps.
  ///
  /// In en, this message translates to:
  /// **'Get GPS'**
  String get get_gps;

  /// No description provided for @save_gps.
  ///
  /// In en, this message translates to:
  /// **'Save GPS'**
  String get save_gps;

  /// No description provided for @set_gps_city.
  ///
  /// In en, this message translates to:
  /// **'Set GPS city name by Internet'**
  String get set_gps_city;

  /// No description provided for @previous_gps_is.
  ///
  /// In en, this message translates to:
  /// **'Previous GPS is'**
  String get previous_gps_is;

  /// No description provided for @decimal_number.
  ///
  /// In en, this message translates to:
  /// **'Decimal Number'**
  String get decimal_number;

  /// No description provided for @current_offset_is.
  ///
  /// In en, this message translates to:
  /// **'Current offset is'**
  String get current_offset_is;

  /// No description provided for @safety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safety;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get none;

  /// No description provided for @minute1.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get minute1;

  /// No description provided for @minutes2.
  ///
  /// In en, this message translates to:
  /// **'2 minutes'**
  String get minutes2;

  /// No description provided for @minutes3.
  ///
  /// In en, this message translates to:
  /// **'3 minutes'**
  String get minutes3;

  /// No description provided for @minutes4.
  ///
  /// In en, this message translates to:
  /// **'4 minutes'**
  String get minutes4;

  /// No description provided for @minutes5.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get minutes5;

  /// No description provided for @minutes10.
  ///
  /// In en, this message translates to:
  /// **'10 minutes'**
  String get minutes10;

  /// No description provided for @pa_auk.
  ///
  /// In en, this message translates to:
  /// **'Pa-Auk'**
  String get pa_auk;

  /// No description provided for @na_uyana.
  ///
  /// In en, this message translates to:
  /// **'Na-Uyana'**
  String get na_uyana;

  /// No description provided for @search_for_city.
  ///
  /// In en, this message translates to:
  /// **'Search for city'**
  String get search_for_city;

  /// No description provided for @gps_permission.
  ///
  /// In en, this message translates to:
  /// **'GPS Permission'**
  String get gps_permission;

  /// No description provided for @background_permission.
  ///
  /// In en, this message translates to:
  /// **'Background Permission'**
  String get background_permission;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @running_in_background.
  ///
  /// In en, this message translates to:
  /// **'Buddhist Sun Running In Background'**
  String get running_in_background;

  /// No description provided for @background_initialized.
  ///
  /// In en, this message translates to:
  /// **'Background Initialized'**
  String get background_initialized;

  /// No description provided for @background_enabled.
  ///
  /// In en, this message translates to:
  /// **'Background Enabled'**
  String get background_enabled;

  /// No description provided for @background_not_set.
  ///
  /// In en, this message translates to:
  /// **'Background not set'**
  String get background_not_set;

  /// No description provided for @background_init_error.
  ///
  /// In en, this message translates to:
  /// **'Background initialize error'**
  String get background_init_error;

  /// No description provided for @background_disabled.
  ///
  /// In en, this message translates to:
  /// **'Background disabled'**
  String get background_disabled;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @gps_not_available.
  ///
  /// In en, this message translates to:
  /// **'GPS is not available'**
  String get gps_not_available;

  /// No description provided for @gps_recommend.
  ///
  /// In en, this message translates to:
  /// **'GPS is recommended for best results.  Would you like to set GPS?'**
  String get gps_recommend;

  /// No description provided for @gps_internet_message.
  ///
  /// In en, this message translates to:
  /// **'If the Internet is turned on, the City Name can be referenced by GPS'**
  String get gps_internet_message;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Locale'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @help_content.
  ///
  /// In en, this message translates to:
  /// **'Calculations:\n The calculations are based on equations from Astronomical Algorithms, by Jean Meeus. The sunrise and sunset results are theoretically accurate to within a minute for locations between +/- 72° of latitud. Please consider stopping well before the stated time. \n\nNOON:\nThe Noon screen displays the Solar Noon for the current day as selected by GPS or City in an easy to view manner. All times reflect the safety from settings.  (see below) \n\nDAWN:\nThe Dawn screen displays the selected Dawn formula from the settings and also various solar calculations. All times reflect the safety from settings.  \nPa-Auk = ( Sunrise - 40 Minutes).  \nNa-uyana = ( Sunrise - 30 minutes)  (see below) \n\nGPS:\nGPS will automatically set the city if the Internet is on and the checkbox is checked.  It is recommended that you use the GPS settings for your location because the Solar Noon will be most accurate this way.  This was not tested with \"Day Light Savings\" locations.\n\nSETTINGS:\nOffset:\n This is automatically set when using GPS.  If you use City Search in settings, you must select an offset (GMT +- your local time). \nSaftey:\nThis subtracts minutes from the Noon time to make it earlier and adds to Dawnrise to make it later.  The formula is accurate within one minute so the default safety is 1 minute. \nDawn:\nChoose your prefered Dawnrise.  Na-Uyana uses Sunrise -30 minutes, and Pa-Auk uses Sunrise -40 minutes.  Safety will add x-Minutes to this time. \nTimer:\nThe Timer screen allows for hands free audio notifications.  Speech means \"Text to Speech\".  The volume is controlled by the slider.  Under normal conditions the speech notifications only work while the screen is on.  To fix this, you can make the screen stay awake with the \"Screen Always On\" switch, or you can enable the \"TTS with screen off\" feature.  This will enable \"background\" operation while your screen is off and prevent the device from entering sleep mode. You should test this background feature a few times before relying on it.  Some phones may not allow it. We are not responsible for anything.  When you close the applicaton, a method is called to stop the background task.  You will know the app is running in the background by the sun icon displayed in the top of your phone\'s notification area (where the time and signal bars are).  If Buddhist Sun is not in \"background mode\", you will not see a sun icon. This feature is not available for iOS users.\n The speech announcements are in the following minute intervals: 50,40,30,20,15,10,8,6,5,4,3,2,1,0 \n\nPrivacy:\nA full privacy statement is located at:\n https://americanmonk.org/privacy-policy-for-buddhist-sun-app/\n\n We do not collect information.'**
  String get help_content;

  /// No description provided for @about_content.
  ///
  /// In en, this message translates to:
  /// **'Buddhist Sun is a small app for Buddhist monks and nuns to display the Solar Noon time specific to Buddhist monastic needs. Because I usually eat with my hands, I needed to have a \"hands free\" way to know when the Noon was approaching. The timer with voice notifications turned on helps me know the time left for eating.  I enjoy using the app, and I hope that you do too.\n\nWhy is this important?\nThose who follow Buddhist monastic rules are not allowed to eat after Noon.  The rule is according to the sun at its zenith in the sky rather than a clock. They did not have clocks in the Buddha\'s time.  Others who follow 8 or 10 precepts may find this app useful too.\n\nI recommend https://TimeandDate.com to verify this app\'s accuracy.This application is meant for \"present moment/location\" use.  \n\nMay this help you to reach Nibbāna quickly and safely!'**
  String get about_content;

  /// No description provided for @gps_permission_content.
  ///
  /// In en, this message translates to:
  /// **'Permission will be requested for GPS use. This allows for Buddhist Sun to know the GPS Location Data to calculate the sun\'s position. GPS is only collected once for each time the GPS button is pressed.  Data is not sent outside this app.'**
  String get gps_permission_content;

  /// No description provided for @background_permission_content.
  ///
  /// In en, this message translates to:
  /// **'Permission will be requested for background use.  This permission is needed to enable speech notifications to run properly the screen on.  Buddhist Sun will turn off this Background process when the switch is turned off or the app is closed.  Permission will be requested only one time if accepted.'**
  String get background_permission_content;

  /// No description provided for @dstSavingsNotice.
  ///
  /// In en, this message translates to:
  /// **'Warning, this app does not calculate for Daylight Savings Time (DST).  Please be aware of the changes.  When DST happens you need to reset the GPS or the offset found in the Settings Tab.'**
  String get dstSavingsNotice;

  /// No description provided for @dstNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Daylight Savings Notice'**
  String get dstNoticeTitle;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify Noon'**
  String get verify;

  /// No description provided for @rateThisApp.
  ///
  /// In en, this message translates to:
  /// **'Rate This App'**
  String get rateThisApp;

  /// No description provided for @prev.
  ///
  /// In en, this message translates to:
  /// **'Prev'**
  String get prev;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @moonPhase.
  ///
  /// In en, this message translates to:
  /// **'Moon Phase:'**
  String get moonPhase;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectedDate.
  ///
  /// In en, this message translates to:
  /// **'Selected Date:'**
  String get selectedDate;

  /// No description provided for @moon.
  ///
  /// In en, this message translates to:
  /// **'moon'**
  String get moon;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @material3.
  ///
  /// In en, this message translates to:
  /// **'Material 3'**
  String get material3;

  /// No description provided for @uposathaCountry.
  ///
  /// In en, this message translates to:
  /// **'Uposatha Country'**
  String get uposathaCountry;

  /// No description provided for @autoUpdateGps.
  ///
  /// In en, this message translates to:
  /// **'Auto update GPS'**
  String get autoUpdateGps;

  /// No description provided for @refreshingGps.
  ///
  /// In en, this message translates to:
  /// **'Refreshing GPS'**
  String get refreshingGps;

  /// No description provided for @command.
  ///
  /// In en, this message translates to:
  /// **'flutter gen-l10n'**
  String get command;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'en',
        'es',
        'fr',
        'km',
        'my',
        'si',
        'th',
        'vi',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'km':
      return AppLocalizationsKm();
    case 'my':
      return AppLocalizationsMy();
    case 'si':
      return AppLocalizationsSi();
    case 'th':
      return AppLocalizationsTh();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
