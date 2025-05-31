// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sinhala Sinhalese (`si`).
class AppLocalizationsSi extends AppLocalizations {
  AppLocalizationsSi([String locale = 'si']) : super(locale);

  @override
  String get buddhistSun => 'විකාල දර්ශකය';

  @override
  String get noon => 'මධ්‍යාහ්නය';

  @override
  String get dawn => 'අරුණ';

  @override
  String get timer => 'timer';

  @override
  String get gps => 'GPS';

  @override
  String get settings => 'සැකසුම්';

  @override
  String get help => 'උදව්';

  @override
  String get about => 'පිළිබඳ';

  @override
  String get licenses => 'licenses';

  @override
  String get not_set => 'Set කර නැත';

  @override
  String get solar_noon => 'ඉරමුදුන';

  @override
  String get gmt_offset => 'GMT Offset';

  @override
  String get hours => 'පැය';

  @override
  String get astronomical_twilight => 'Astronomical Twilight';

  @override
  String get nautical_twilight => 'Nautical Twilight';

  @override
  String get civil_twilight => 'Civil Twilight';

  @override
  String get sunrise => 'හිරු උදාව';

  @override
  String get date => 'දිනය';

  @override
  String get current_time => 'දැන් වේලාව';

  @override
  String get late => 'ප්‍රමාදයි';

  @override
  String get time_left => 'ඉතිරි කාලය';

  @override
  String get speech_notify => 'කථනයෙන් හඟවන්න';

  @override
  String get screen_always_on => 'තිරය නොවසන්න';

  @override
  String get speech_in_background => 'පසුබිමේ කථාව';

  @override
  String get volume => 'ශබ්ද ප්‍රමාණය';

  @override
  String get press_wait => 'නව GPS සඳහා ඔබා රැඳී සිටින්න';

  @override
  String get get_gps => 'Get GPS';

  @override
  String get save_gps => 'Save GPS';

  @override
  String get set_gps_city => 'අන්තර්ජාලය තුලින් නගරයේ නම GPS මඟින් සොයන්න';

  @override
  String get previous_gps_is => 'පෙර GPS අංශක';

  @override
  String get decimal_number => 'දශම සංඛ්යාව';

  @override
  String get current_offset_is => 'Current GMT Offset';

  @override
  String get safety => 'Safety Buffer';

  @override
  String get none => 'none';

  @override
  String get minute1 => 'මිනිත්තු 1';

  @override
  String get minutes2 => 'මිනිත්තු 2';

  @override
  String get minutes3 => 'මිනිත්තු 3';

  @override
  String get minutes4 => 'මිනිත්තු 4';

  @override
  String get minutes5 => 'මිනිත්තු 5';

  @override
  String get minutes10 => 'මිනිත්තු 10';

  @override
  String get pa_auk => 'පා-අවුක්';

  @override
  String get na_uyana => 'නා-උයන';

  @override
  String get search_for_city => 'නගරය සොයන්න';

  @override
  String get gps_permission => 'GPS අවසර';

  @override
  String get background_permission => 'Background අවසර';

  @override
  String get error => 'වරදක් සිදුවිය';

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
  String get ok => 'හරි';

  @override
  String get yes => 'ඔව්';

  @override
  String get no => 'නැහැ';

  @override
  String get cancel => 'Cancel';

  @override
  String get gps_not_available => 'GPS සොයාගත නොහැකි විය';

  @override
  String get gps_recommend =>
      'නිවැරදිම වේලාවන් සඳහා GPS අවශ්‍යයි. GPS අනුකුලතාව ලබා දීමට ඔබ කැමතිද?';

  @override
  String get gps_internet_message =>
      'අන්තර්ජාල පහසුකම් තිබේනම් නගරයේ නම GPS හරහා සොයාගත හැක.';

  @override
  String get language => 'භාෂාව';

  @override
  String get theme => 'වර්ණමාලාව';

  @override
  String get help_content =>
      'Calculations:\n The calculations are based on equations from Astronomical Algorithms, by Jean Meeus. The sunrise and sunset results are theoretically accurate to within a minute for locations between +/- 72° of latitud. Please consider stopping well before the stated time. \n\nNOON:\nThe Noon screen displays the Solar Noon for the current day as selected by GPS or City in an easy to view manner. All times reflect the safety from settings.  (see below) \n\nDAWN:\nThe Dawn screen displays the selected Dawn formula from the settings and also various solar calculations. All times reflect the safety from settings.  \nPa-Auk = ( Sunrise - 40 Minutes).  \nNa-uyana = ( Sunrise - 30 minutes)  (see below) \n\nGPS:\nGPS will automatically set the city if the Internet is on and the checkbox is checked.  It is recommended that you use the GPS settings for your location because the Solar Noon will be most accurate this way.  This was not tested with \"Day Light Savings\" locations.\n\nSETTINGS:\nOffset:\n This is automatically set when using GPS.  If you use City Search in settings, you must select an offset (GMT +- your local time). \nSaftey:\nThis subtracts minutes from the Noon time to make it earlier and adds to Dawnrise to make it later.  The formula is accurate within one minute so the default safety is 1 minute. \nDawn:\nChoose your prefered Dawnrise.  Na-Uyana uses Sunrise -30 minutes, and Pa-Auk uses Sunrise -40 minutes.  Safety will add x-Minutes to this time. \nTimer:\nThe Timer screen allows for hands free audio notifications.  Speech means \"Text to Speech\".  The volume is controlled by the slider.  Under normal conditions the speech notifications only work while the screen is on.  To fix this, you can make the screen stay awake with the \"Screen Always On\" switch, or you can enable the \"TTS with screen off\" feature.  This will enable \"background\" operation while your screen is off and prevent the device from entering sleep mode. You should test this background feature a few times before relying on it.  Some phones may not allow it. We are not responsible for anything.  When you close the applicaton, a method is called to stop the background task.  You will know the app is running in the background by the sun icon displayed in the top of your phone\'s notification area (where the time and signal bars are).  If Buddhist Sun is not in \"background mode\", you will not see a sun icon. This feature is not available for iOS users.\n The speech announcements are in the following minute intervals: 50,40,30,20,15,10,8,6,5,4,3,2,1,0 \n\nPrivacy:\nA full privacy statement is located at:\n https://americanmonk.org/privacy-policy-for-buddhist-sun-app/\n\n We do not collect information.';

  @override
  String get about_content =>
      'Buddhist Sun යනු බෞද්ධ භික්ෂූන් වහන්සේලාට සහ භික්ෂුණීන්ගේ විනයට අදාළවූ ඒ ඒ ස්ථාන සඳහා මධ්‍යාහ්නය දැන ගැනීම සඳහා වූ කුඩා ඇප් එකකි. මම සාමාන්‍යයෙන් අතින් ආහාර ගන්නා නිසා, නිසි මධ්‍යාහ්නය දැන ගැනීමට මට \"hands free\" ක්‍රමයක් අවශ්‍ය විය. මේ ඇප් එකේ ටයිමරය  (timer) කෑමට ඉතිරිව ඇති කාලය දැන ගැනීමට මට උපකාරී වේ. මා මේ ඇප් එක භාවිතා කිරීමෙන් සතුටක් ලබන අතර ඔබටත් එසේ ලැබෙනු ඇතැයි මම බලාපොරොත්තු වෙමි. මෙය වැදගත් වන්නේ ඇයි? බෞද්ධ විනය පිළිපදින අයට මධ්‍යාහ්නයෙන් පසු ආහාර ගැනීමට අවසර නැත. මෙම විනය ක්‍රියාත්මකවන්නේ ඔරලෝසු වේලාවට වඩා හිරු මධ්‍යාහ්නගත වීමට අනුව ය. බුදුන් වහන්සේගේ කාලයේ ඔවුන්ට ඔරලෝසු නොතිබුණි. අට සිල් හෝ දශසිල් අනුගමනය කරන අයට ද  මෙම ඇප් එක ප්‍රයෝජනවත් විය හැකිය. මෙම යෙදුමේ නිරවද්‍යතාවය සත්‍යාපනය කිරීම සඳහා මෙම යොමුව (link) භාවිතා කරන්න. එමඟින් ඔබ ඉන්නා මොහොතත් ස්ථානයත් (\"present moment/location\") පෙන්නුම් කරයි. සඳහා අදහස් කෙරේ.  ';

  @override
  String get gps_permission_content =>
      'Permission will be requested for GPS use. This allows for Buddhist Sun to know the GPS Location Data to calculate the sun\'s position. GPS is only collected once for each time the GPS button is pressed.  Data is not sent outside this app.';

  @override
  String get background_permission_content =>
      'Permission will be requested for background use.  This permission is needed to enable speech notifications to run properly the screen on.  Buddhist Sun will turn off this Background process when the switch is turned off or the app is closed.  Permission will be requested only one time if accepted.';

  @override
  String get dstSavingsNotice =>
      'අවවාදයයි, මෙම යෙදුම දිවා ආලෝකය ඉතිරි කිරීමේ කාලය (DST) සඳහා ගණනය නොකරයි. කරුණාකර වෙනස්කම් පිළිබඳව දැනුවත් වන්න. DST සිදු වූ විට, ඔබට GPS හෝ සැකසීම් පටිත්තෙහි ඇති ඕෆ්සෙට් නැවත සැකසීමට අවශ්‍ය වේ.';

  @override
  String get dstNoticeTitle => 'දිවා ආලෝකය ඉතුරුම් දැන්වීම';

  @override
  String get verify => 'මධ්‍යහ්නය තහවුරු කරන්න.';

  @override
  String get rateThisApp => 'ශ්‍රේණිගත කරන්න.';

  @override
  String get prev => 'පිටුපසට';

  @override
  String get next => 'ඉදිරියට';

  @override
  String get moonPhase => 'සඳහි මුහුනත:';

  @override
  String get selectDate => 'දිනය තෝරන්න';

  @override
  String get selectedDate => ' තෝරපු දිනය:';

  @override
  String get moon => 'සඳ';

  @override
  String get darkMode => 'අඳුරු ප්‍රකාශය';

  @override
  String get color => 'වර්ණය';

  @override
  String get material3 => 'Material 3';

  @override
  String get uposathaCountry => 'උපෝසථ රට';

  @override
  String get autoUpdateGps => 'GPS ස්වයංක්‍රීයව යාවත්කාලීන කරන්න';

  @override
  String get refreshingGps => 'GPS නැවත تازه කිරීම';

  @override
  String get command => 'flutter gen-l10n';
}
