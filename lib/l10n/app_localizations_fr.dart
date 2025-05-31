// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get buddhistSun => '佛教太阳';

  @override
  String get noon => 'Noon';

  @override
  String get dawn => 'Dawn';

  @override
  String get timer => 'Timer';

  @override
  String get gps => 'GPS';

  @override
  String get settings => 'Settings';

  @override
  String get help => 'Help';

  @override
  String get about => 'About';

  @override
  String get licenses => 'Licenses';

  @override
  String get not_set => 'Not Set';

  @override
  String get solar_noon => 'Solar Noon';

  @override
  String get gmt_offset => 'GMT Offset';

  @override
  String get hours => 'hours';

  @override
  String get astronomical_twilight => 'Astronomical Twilight';

  @override
  String get nautical_twilight => 'Nautical Twilight';

  @override
  String get civil_twilight => 'Civil Twilight';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get date => 'Date';

  @override
  String get current_time => 'Current TIme';

  @override
  String get late => 'Late';

  @override
  String get time_left => 'Time Left';

  @override
  String get speech_notify => 'Speech Notify';

  @override
  String get screen_always_on => 'Screen Always On';

  @override
  String get speech_in_background => 'Speech in backgroun';

  @override
  String get volume => 'Volume';

  @override
  String get press_wait => 'Press and wait for new GPS.';

  @override
  String get get_gps => 'Get GPS';

  @override
  String get save_gps => 'Save GPS';

  @override
  String get set_gps_city => 'Set GPS city name by Internet';

  @override
  String get previous_gps_is => 'Previous GPS is';

  @override
  String get decimal_number => 'Decimal Number';

  @override
  String get current_offset_is => 'Current offset is';

  @override
  String get safety => 'Safety';

  @override
  String get none => 'none';

  @override
  String get minute1 => '1 minute';

  @override
  String get minutes2 => '2 minutes';

  @override
  String get minutes3 => '3 minutes';

  @override
  String get minutes4 => '4 minutes';

  @override
  String get minutes5 => '5 minutes';

  @override
  String get minutes10 => '10 minutes';

  @override
  String get pa_auk => 'Pa-Auk';

  @override
  String get na_uyana => 'Na-Uyana';

  @override
  String get search_for_city => 'Search for city';

  @override
  String get gps_permission => 'GPS Permission';

  @override
  String get background_permission => 'Background Permission';

  @override
  String get error => 'Error';

  @override
  String get notification => 'Notification';

  @override
  String get running_in_background => 'Buddhist Sun Running In Background';

  @override
  String get background_initialized => 'Background Initialized';

  @override
  String get background_enabled => 'Background Enabled';

  @override
  String get background_not_set => 'Background not set';

  @override
  String get background_init_error => 'Background initialize error';

  @override
  String get background_disabled => 'Background disabled';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get cancel => 'Cancel';

  @override
  String get gps_not_available => 'GPS is not available';

  @override
  String get gps_recommend =>
      'GPS is recommended for best results.  Would you like to set GPS?';

  @override
  String get gps_internet_message =>
      'If the Internet is turned on, the City Name can be referenced by GPS';

  @override
  String get language => 'Locale';

  @override
  String get theme => 'Theme';

  @override
  String get help_content =>
      'Calculations:\n The calculations are based on equations from Astronomical Algorithms, by Jean Meeus. The sunrise and sunset results are theoretically accurate to within a minute for locations between +/- 72° of latitud. Please consider stopping well before the stated time. \n\nNOON:\nThe Noon screen displays the Solar Noon for the current day as selected by GPS or City in an easy to view manner. All times reflect the safety from settings.  (see below) \n\nDAWN:\nThe Dawn screen displays the selected Dawn formula from the settings and also various solar calculations. All times reflect the safety from settings.  \nPa-Auk = ( Sunrise - 40 Minutes).  \nNa-uyana = ( Sunrise - 30 minutes)  (see below) \n\nGPS:\nGPS will automatically set the city if the Internet is on and the checkbox is checked.  It is recommended that you use the GPS settings for your location because the Solar Noon will be most accurate this way.  This was not tested with \"Day Light Savings\" locations.\n\nSETTINGS:\nOffset:\n This is automatically set when using GPS.  If you use City Search in settings, you must select an offset (GMT +- your local time). \nSaftey:\nThis subtracts minutes from the Noon time to make it earlier and adds to Dawnrise to make it later.  The formula is accurate within one minute so the default safety is 1 minute. \nDawn:\nChoose your prefered Dawnrise.  Na-Uyana uses Sunrise -30 minutes, and Pa-Auk uses Sunrise -40 minutes.  Safety will add x-Minutes to this time. \nTimer:\nThe Timer screen allows for hands free audio notifications.  Speech means \"Text to Speech\".  The volume is controlled by the slider.  Under normal conditions the speech notifications only work while the screen is on.  To fix this, you can make the screen stay awake with the \"Screen Always On\" switch, or you can enable the \"TTS with screen off\" feature.  This will enable \"background\" operation while your screen is off and prevent the device from entering sleep mode. You should test this background feature a few times before relying on it.  Some phones may not allow it. We are not responsible for anything.  When you close the applicaton, a method is called to stop the background task.  You will know the app is running in the background by the sun icon displayed in the top of your phone\'s notification area (where the time and signal bars are).  If Buddhist Sun is not in \"background mode\", you will not see a sun icon. This feature is not available for iOS users.\n The speech announcements are in the following minute intervals: 50,40,30,20,15,10,8,6,5,4,3,2,1,0 \n\nPrivacy:\nA full privacy statement is located at:\n https://americanmonk.org/privacy-policy-for-buddhist-sun-app/\n\n We do not collect information.';

  @override
  String get about_content =>
      'Buddhist Sun is a small app for Buddhist monks and nuns to display the Solar Noon time specific to Buddhist monastic needs. Because I usually eat with my hands, I needed to have a \"hands free\" way to know when the Noon was approaching. The timer with voice notifications turned on helps me know the time left for eating.  I enjoy using the app, and I hope that you do too.\n\nWhy is this important?\nThose who follow Buddhist monastic rules are not allowed to eat after Noon.  The rule is according to the sun at its zenith in the sky rather than a clock. They did not have clocks in the Buddha\'s time.  Others who follow 8 or 10 precepts may find this app useful too.\n\nI recommend https://TimeandDate.com to verify this app\'s accuracy.This application is meant for \"present moment/location\" use.  \n\nMay this help you to reach Nibbāna quickly and safely!';

  @override
  String get gps_permission_content =>
      'Permission will be requested for GPS use. This allows for Buddhist Sun to know the GPS Location Data to calculate the sun\'s position. GPS is only collected once for each time the GPS button is pressed.  Data is not sent outside this app.';

  @override
  String get background_permission_content =>
      'Permission will be requested for background use.  This permission is needed to enable speech notifications to run properly the screen on.  Buddhist Sun will turn off this Background process when the switch is turned off or the app is closed.  Permission will be requested only one time if accepted.';

  @override
  String get dstSavingsNotice =>
      'Warning, this app does not calculate for Daylight Savings Time (DST).  Please be aware of the changes.  When DST happens you need to reset the GPS or the offset found in the Settings Tab.';

  @override
  String get dstNoticeTitle => 'Daylight Savings Notice';

  @override
  String get verify => 'Verify Noon';

  @override
  String get rateThisApp => 'Rate This App';

  @override
  String get prev => 'Prev';

  @override
  String get next => 'Next';

  @override
  String get moonPhase => 'Moon Phase:';

  @override
  String get selectDate => 'Select Date';

  @override
  String get selectedDate => 'Selected Date:';

  @override
  String get moon => 'moon';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get color => 'Color';

  @override
  String get material3 => 'Material 3';

  @override
  String get uposathaCountry => 'Uposatha Country';

  @override
  String get autoUpdateGps => 'Auto update GPS';

  @override
  String get refreshingGps => 'Refreshing GPS';

  @override
  String get command => 'flutter gen-l10n';
}
