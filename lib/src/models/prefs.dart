// import to copy////////////////////
//import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';

// Shared prefs package import
import 'package:shared_preferences/shared_preferences.dart';

// preference names
const String CITYNAME = "cityName";
const String LAT = "lat";
const String LNG = "lng";
const String OFFSET = "offset";
const String SPEAKISON = "speakIsOn";
const String SCREEN_ALWAYS_ON = "screenAlwaysOn";
const String BACKGROUND_ON = "backgroundOn";
const String SAFETY = "safety";
const String DAWNVAL = "dawnVal";
const String RETRIEVE_CITYNAME = "retrieveCityName";
const String LOCALEVAL = "localeVal";
const String THEME_INDEX = "themeIndex";
const String LIGHT_THEME_ON = "lightThemeOn";
const String useM3Pref = 'useM3';
const String darkThemeOnPref = "darkThemeOn";
const String UPOSATHACOUNTRY = "uposathaCountry";
const String LASTDOWNLOAD = "lastDownload";
const String AUTO_GPS_ENABLED = "autoGpsEnabled";
const String UPOSATHA_NOTIFICATIONS_ENABLED = "uposathaNotificationsEnabled";
const String AUTO_START_DAWN_TIMER = "autoStartDawnTimer";
const String AUTO_START_NOON_TIMER = "autoStartNoonTimer";
const String CUSTOM_DAWN_ANGLE = "customDawnAngle";
// default pref values
const String DEFAULT_CITYNAME = "Not Set";
const double DEFAULT_CUSTOM_DAWN_ANGLE = -8.5;
const double DEFAULT_LAT = 1.1;
const double DEFAULT_LNG = 1.1;
const double DEFAULT_OFFSET = 6.5;
const bool DEFAULT_SPEAKISON = false;
const bool DEFAULT_SCREEN_ALWAYS_ON = true;
const bool DEFAULT_BACKGROUND_ON = false;
const int DEFAULT_SAFETY = 0;
const int DEFAULT_DAWNVAL = 1;
const bool DEFAULT_RETRIEVE_CITYNAME = true;
const int DEFAULT_LOCALEVAL = 0;
const int DEFAULT_THEME_INDEX = 24;
const bool DEFAULT_LIGHT_THEME_ON = true;
const bool defaultUseM3 = true;
const bool defaultDarkThemeOn = false;
const bool DEFAULT_AUTO_GPS_ENABLED = false;
const int defaultSelectedPageColor = 0;
const String selectedPageColorPref = "selectedPageColor";
const String themeNamePref = "themeNamePref";
const String defaultThemeName = '';
const bool DEFAULT_UPOSATHA_NOTIFICATIONS_ENABLED = false;
const bool DEFAULT_AUTO_START_DAWN_TIMER = false;
const bool DEFAULT_AUTO_START_NOON_TIMER = false;
const String BEFORE_UPOSATHA_NOTIFICATION_DAYS =
    "beforeUposathaNotificationDays";
const String UPOSATHA_NOTIFICATION_TIME = "uposathaNotificationTime";

const int DEFAULT_BEFORE_UPOSATHA_NOTIFICATION_DAYS = 1;
const String DEFAULT_UPOSATHA_NOTIFICATION_TIME = "06:00";
const String SHOW_EIGHTH_DAY_UPOSATHA = "showEighthDayUposatha";
const bool DEFAULT_SHOW_EIGHTH_DAY_UPOSATHA = true;

// Meditation Timer Prefs
const String MEDITATION_DURATION_MINUTES = "meditationDurationMinutes";
const int DEFAULT_MEDITATION_DURATION_MINUTES = 30;
const String MEDITATION_TIMER_MODE = "meditationTimerMode";
const String DEFAULT_MEDITATION_TIMER_MODE = "timed";
const String MEDITATION_START_SOUND = "meditationStartSound";
const String DEFAULT_MEDITATION_START_SOUND = "Bowl";
const String MEDITATION_END_SOUND = "meditationEndSound";
const String DEFAULT_MEDITATION_END_SOUND = "Bowl";
const String MEDITATION_INTERVAL_SOUND = "meditationIntervalSound";
const String DEFAULT_MEDITATION_INTERVAL_SOUND = "ClearBell";
const String MEDITATION_INTERVAL_MINUTES = "meditationIntervalMinutes";
const int DEFAULT_MEDITATION_INTERVAL_MINUTES = 0;
const String MEDITATION_PREP_DELAY_SECONDS = "meditationPrepDelaySeconds";
const int DEFAULT_MEDITATION_PREP_DELAY_SECONDS = 5;
const String MEDITATION_KEEP_SCREEN_ON = "meditationKeepScreenOn";
const bool DEFAULT_MEDITATION_KEEP_SCREEN_ON = true;
const String MEDITATION_VOLUME = "meditationVolume";
const int DEFAULT_MEDITATION_VOLUME = 80;
const String MEDITATION_PRESETS = "meditationPresets";
const List<String> DEFAULT_MEDITATION_PRESETS = [
  "5",
  "10",
  "15",
  "20",
  "25",
  "30",
  "45",
  "60",
  "90",
  "120"
];
const String MEDITATION_RING_STYLE = "meditationRingStyle";
const String DEFAULT_MEDITATION_RING_STYLE = "subtractive";
const String MEDITATION_RECENT_TIMES = "meditationRecentTimes";
const List<String> DEFAULT_MEDITATION_RECENT_TIMES = ["30", "15", "45", "60"];

// Death Contemplation (Maranasati) Feature Flag
bool showDeath = false;

// Death Contemplation (Maranasati) Prefs
const String DEATH_CONTEMPLATION_BIRTH_DATE = "deathContemplationBirthDate";
const String DEATH_CONTEMPLATION_LIFE_EXPECTANCY =
    "deathContemplationLifeExpectancy";
const int DEFAULT_DEATH_CONTEMPLATION_LIFE_EXPECTANCY = 80;
const String DEATH_CONTEMPLATION_SHOW_GAS_TANK =
    "deathContemplationShowGasTank";
const bool DEFAULT_DEATH_CONTEMPLATION_SHOW_GAS_TANK = true;
const String DEATH_CONTEMPLATION_GAUGE_SHOW_REMAINING =
    "deathContemplationGaugeShowRemaining";
const bool DEFAULT_DEATH_CONTEMPLATION_GAUGE_SHOW_REMAINING = false;

// Compass Prefs
const String targetNamePref = "targetName";
const String targetLatPref = "targetLat";
const String targetLongPref = "targetLong";
const String vibeOnPref = 'vibeOn';
const String compassShowMapPref = "compassShowMap";
const String userDest1Pref = "userDest1";
const String userDest1LatPref = "userDest1Lat";
const String userDest1LongPref = "userDest1Long";

const String defaultTargetName = "bodhGaya";
const double defaultTargetLat = 24.6951;
const double defaultTargetLong = 84.9913;
const bool defaultVibeOn = false;
const bool defaultCompassShowMap = false;
const String defaultUserDest1 = "";
const double defaultUserDest1Lat = 0.0;
const double defaultUserDest1Long = 0.0;

// set default to one month before the last known data point we ship with.
// it will download every 30 days thereafter.
DateTime defaultLastDownload = DateTime(2025, 12, 1);

enum UposathaCountry { Myanmar, Sinhala, Thailand }

const defaultSelectedUposatha = UposathaCountry.Myanmar;

class Prefs {
  static late final SharedPreferences instance;

  static Future<SharedPreferences> init() async =>
      instance = await SharedPreferences.getInstance();

  /// One-time migration: -6° dawn option inserted at index 3,
  /// so existing civil (3→4) and sunrise (4→5) must shift.
  static Future<void> migrateDawnVal() async {
    const key = '_dawnValMigrated_v2';
    if (instance.getBool(key) == true) return;
    final current = instance.getInt(DAWNVAL);
    if (current != null && current >= 3) {
      await instance.setInt(DAWNVAL, current + 1);
    }
    await instance.setBool(key, true);
  }

  /// V3 migration: Pa-Auk angle and Na-Uyana angle inserted at indices 3 & 4,
  /// so existing custom (3→5), civil (4→6), sunrise (5→7) must shift by +2.
  /// Note: v2 migration ran first, so if user had old index 3 it became 4, etc.
  /// After v2: 0=naut, 1=pa-auk-sr, 2=na-uyana-sr, 3=custom, 4=civil, 5=sunrise
  /// After v3: 0=naut, 1=pa-auk-sr, 2=na-uyana-sr, 3=pa-auk-angle, 4=na-uyana-angle, 5=custom, 6=civil, 7=sunrise
  static Future<void> migrateDawnValV3() async {
    const key = '_dawnValMigrated_v3';
    if (instance.getBool(key) == true) return;
    final current = instance.getInt(DAWNVAL);
    if (current != null && current >= 3) {
      await instance.setInt(DAWNVAL, current + 2);
    }
    await instance.setBool(key, true);
  }

  /// One-time migration: Bowl/Gong audio cleanup.
  /// BowlFade -> Bowl
  /// BowlSlowFade -> BowlSlow
  /// GongFade -> Gong
  /// GongSlowFade -> GongSlow
  static Future<void> migrateMeditationSounds() async {
    const key = '_meditationSoundsMigrated_v1';
    if (instance.getBool(key) == true) return;

    final start = instance.getString(MEDITATION_START_SOUND);
    if (start != null) {
      final normalized =
          _normalizeSoundId(start, DEFAULT_MEDITATION_START_SOUND);
      if (normalized != start) {
        await instance.setString(MEDITATION_START_SOUND, normalized);
      }
    }

    final end = instance.getString(MEDITATION_END_SOUND);
    if (end != null) {
      final normalized = _normalizeSoundId(end, DEFAULT_MEDITATION_END_SOUND);
      if (normalized != end) {
        await instance.setString(MEDITATION_END_SOUND, normalized);
      }
    }

    final interval = instance.getString(MEDITATION_INTERVAL_SOUND);
    if (interval != null) {
      final normalized =
          _normalizeSoundId(interval, DEFAULT_MEDITATION_INTERVAL_SOUND);
      if (normalized != interval) {
        await instance.setString(MEDITATION_INTERVAL_SOUND, normalized);
      }
    }

    await instance.setBool(key, true);
  }

  static String _normalizeSoundId(String? raw, String fallback) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final lower = raw.trim().toLowerCase();
    if (lower == 'vibration only' || lower == 'vibrate') return 'vibration';
    if (lower == 'bowlfade' || lower == 'bowl (fade)') return 'Bowl';
    if (lower == 'bowlslowfade' || lower == 'bowl (slow fade)')
      return 'BowlSlow';
    if (lower == 'gongfade' || lower == 'gong (fade)') return 'Gong';
    if (lower == 'gongslowfade' || lower == 'gong (slow fade)')
      return 'GongSlow';
    return raw;
  }

  // get and set the default member values if null
  static String get cityName =>
      instance.getString(CITYNAME) ?? DEFAULT_CITYNAME;
  static set cityName(String value) => instance.setString(CITYNAME, value);

  static double get lat => instance.getDouble(LAT) ?? DEFAULT_LAT;
  static set lat(double value) => instance.setDouble(LAT, value);

  static double get lng => instance.getDouble(LNG) ?? DEFAULT_LNG;
  static set lng(double value) => instance.setDouble(LNG, value);

  static double get offset => instance.getDouble(OFFSET) ?? DEFAULT_OFFSET;
  static set offset(double value) => instance.setDouble(OFFSET, value);

  static bool get speakIsOn => instance.getBool(SPEAKISON) ?? DEFAULT_SPEAKISON;
  static set speakIsOn(bool value) => instance.setBool(SPEAKISON, value);

  static bool get screenAlwaysOn =>
      instance.getBool(SCREEN_ALWAYS_ON) ?? DEFAULT_SCREEN_ALWAYS_ON;
  static set screenAlwaysOn(bool value) =>
      instance.setBool(SCREEN_ALWAYS_ON, value);

  static bool get backgroundOn =>
      instance.getBool(BACKGROUND_ON) ?? DEFAULT_BACKGROUND_ON;
  static set backgroundOn(bool value) => instance.setBool(BACKGROUND_ON, value);

  static bool get retrieveCityName =>
      instance.getBool(RETRIEVE_CITYNAME) ?? DEFAULT_RETRIEVE_CITYNAME;
  static set retrieveCityName(bool value) =>
      instance.setBool(RETRIEVE_CITYNAME, value);

  static int get safety => instance.getInt(SAFETY) ?? DEFAULT_SAFETY;
  static set safety(int value) => instance.setInt(SAFETY, value);

  static int get dawnVal => instance.getInt(DAWNVAL) ?? DEFAULT_DAWNVAL;
  static set dawnVal(int value) => instance.setInt(DAWNVAL, value);

  static int get localeVal => instance.getInt(LOCALEVAL) ?? DEFAULT_LOCALEVAL;
  static set localeVal(int value) => instance.setInt(LOCALEVAL, value);

  static int get themeIndex =>
      instance.getInt(THEME_INDEX) ?? DEFAULT_THEME_INDEX;
  static set themeIndex(int value) => instance.setInt(THEME_INDEX, value);

  static bool get lightThemeOn =>
      instance.getBool(LIGHT_THEME_ON) ?? DEFAULT_LIGHT_THEME_ON;
  static set lightThemeOn(bool value) =>
      instance.setBool(LIGHT_THEME_ON, value);
  static String get themeName =>
      instance.getString(themeNamePref) ?? defaultThemeName;
  static set themeName(String value) =>
      instance.setString(themeNamePref, value);

  static bool get useM3 => instance.getBool(useM3Pref) ?? defaultUseM3;
  static set useM3(bool value) => instance.setBool(useM3Pref, value);
  static bool get darkThemeOn =>
      instance.getBool(darkThemeOnPref) ?? defaultDarkThemeOn;
  static set darkThemeOn(bool value) =>
      instance.setBool(darkThemeOnPref, value);

  static int get selectedPageColor =>
      instance.getInt(selectedPageColorPref) ?? defaultSelectedPageColor;
  static set selectedPageColor(int value) =>
      instance.setInt(selectedPageColorPref, value);

  static UposathaCountry get selectedUposatha =>
      EnumToString.fromString(
          UposathaCountry.values, instance.getString(UPOSATHACOUNTRY) ?? "",
          camelCase: true) ??
      UposathaCountry.Myanmar;
  static set selectedUposatha(UposathaCountry value) => instance.setString(
      UPOSATHACOUNTRY, EnumToString.convertToString(value, camelCase: true));

  static DateTime get lastDownload =>
      DateTime.tryParse(instance.getString(LASTDOWNLOAD) ?? "") ??
      defaultLastDownload;
  static set lastDownload(DateTime value) =>
      instance.setString(LASTDOWNLOAD, value.toString());

  static bool get autoGpsEnabled =>
      instance.getBool(AUTO_GPS_ENABLED) ?? DEFAULT_AUTO_GPS_ENABLED;
  static set autoGpsEnabled(bool value) =>
      instance.setBool(AUTO_GPS_ENABLED, value);

  static bool get uposathaNotificationsEnabled =>
      instance.getBool(UPOSATHA_NOTIFICATIONS_ENABLED) ??
      DEFAULT_UPOSATHA_NOTIFICATIONS_ENABLED;

  static set uposathaNotificationsEnabled(bool value) =>
      instance.setBool(UPOSATHA_NOTIFICATIONS_ENABLED, value);

  static bool get autoStartDawnTimer =>
      instance.getBool(AUTO_START_DAWN_TIMER) ?? DEFAULT_AUTO_START_DAWN_TIMER;
  static set autoStartDawnTimer(bool value) =>
      instance.setBool(AUTO_START_DAWN_TIMER, value);

  static bool get autoStartNoonTimer =>
      instance.getBool(AUTO_START_NOON_TIMER) ?? DEFAULT_AUTO_START_NOON_TIMER;
  static set autoStartNoonTimer(bool value) =>
      instance.setBool(AUTO_START_NOON_TIMER, value);

  static double get customDawnAngle =>
      instance.getDouble(CUSTOM_DAWN_ANGLE) ?? DEFAULT_CUSTOM_DAWN_ANGLE;
  static set customDawnAngle(double value) =>
      instance.setDouble(CUSTOM_DAWN_ANGLE, value);

  static int get beforeUposathaNotificationDays =>
      instance.getInt(BEFORE_UPOSATHA_NOTIFICATION_DAYS) ??
      DEFAULT_BEFORE_UPOSATHA_NOTIFICATION_DAYS;
  static set beforeUposathaNotificationDays(int value) =>
      instance.setInt(BEFORE_UPOSATHA_NOTIFICATION_DAYS, value);

  static bool get showEighthDayUposatha =>
      instance.getBool(SHOW_EIGHTH_DAY_UPOSATHA) ??
      DEFAULT_SHOW_EIGHTH_DAY_UPOSATHA;
  static set showEighthDayUposatha(bool value) =>
      instance.setBool(SHOW_EIGHTH_DAY_UPOSATHA, value);

  static TimeOfDay get uposathaNotificationTime {
    final stored = instance.getString(UPOSATHA_NOTIFICATION_TIME) ??
        DEFAULT_UPOSATHA_NOTIFICATION_TIME;
    final parts = stored.split(':');
    if (parts.length != 2) {
      return const TimeOfDay(hour: 6, minute: 0);
    }
    final hour = int.tryParse(parts[0]) ?? 6;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static set uposathaNotificationTime(TimeOfDay value) => instance.setString(
        UPOSATHA_NOTIFICATION_TIME,
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
      );

  // Meditation Timer getters & setters
  static int get meditationDurationMinutes =>
      instance.getInt(MEDITATION_DURATION_MINUTES) ??
      DEFAULT_MEDITATION_DURATION_MINUTES;
  static set meditationDurationMinutes(int value) =>
      instance.setInt(MEDITATION_DURATION_MINUTES, value);

  static String get meditationTimerMode =>
      instance.getString(MEDITATION_TIMER_MODE) ??
      DEFAULT_MEDITATION_TIMER_MODE;
  static set meditationTimerMode(String value) =>
      instance.setString(MEDITATION_TIMER_MODE, value);

  static String get meditationStartSound => _normalizeSoundId(
      instance.getString(MEDITATION_START_SOUND),
      DEFAULT_MEDITATION_START_SOUND);
  static set meditationStartSound(String value) =>
      instance.setString(MEDITATION_START_SOUND, value);

  static String get meditationEndSound => _normalizeSoundId(
      instance.getString(MEDITATION_END_SOUND), DEFAULT_MEDITATION_END_SOUND);
  static set meditationEndSound(String value) =>
      instance.setString(MEDITATION_END_SOUND, value);

  static String get meditationIntervalSound => _normalizeSoundId(
      instance.getString(MEDITATION_INTERVAL_SOUND),
      DEFAULT_MEDITATION_INTERVAL_SOUND);
  static set meditationIntervalSound(String value) =>
      instance.setString(MEDITATION_INTERVAL_SOUND, value);

  static int get meditationIntervalMinutes =>
      instance.getInt(MEDITATION_INTERVAL_MINUTES) ??
      DEFAULT_MEDITATION_INTERVAL_MINUTES;
  static set meditationIntervalMinutes(int value) =>
      instance.setInt(MEDITATION_INTERVAL_MINUTES, value);

  static int get meditationPrepDelaySeconds =>
      instance.getInt(MEDITATION_PREP_DELAY_SECONDS) ??
      DEFAULT_MEDITATION_PREP_DELAY_SECONDS;
  static set meditationPrepDelaySeconds(int value) =>
      instance.setInt(MEDITATION_PREP_DELAY_SECONDS, value);

  static bool get meditationKeepScreenOn =>
      instance.getBool(MEDITATION_KEEP_SCREEN_ON) ??
      DEFAULT_MEDITATION_KEEP_SCREEN_ON;
  static set meditationKeepScreenOn(bool value) =>
      instance.setBool(MEDITATION_KEEP_SCREEN_ON, value);

  static int get meditationVolume =>
      instance.getInt(MEDITATION_VOLUME) ?? DEFAULT_MEDITATION_VOLUME;
  static set meditationVolume(int value) =>
      instance.setInt(MEDITATION_VOLUME, value);

  static List<int> get meditationPresets {
    final list = instance.getStringList(MEDITATION_PRESETS);
    if (list == null || list.isEmpty) {
      return [5, 10, 15, 20, 25, 30, 45, 60, 90, 120];
    }
    final ints = list
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .where((m) => m > 0 && m <= 720)
        .toList();
    if (ints.isEmpty) {
      return [5, 10, 15, 20, 25, 30, 45, 60, 90, 120];
    }
    ints.sort();
    return ints;
  }

  static set meditationPresets(List<int> values) {
    final sorted = List<int>.from(values)..sort();
    instance.setStringList(
      MEDITATION_PRESETS,
      sorted.map((e) => e.toString()).toList(),
    );
  }

  static String get meditationRingStyle =>
      instance.getString(MEDITATION_RING_STYLE) ??
      DEFAULT_MEDITATION_RING_STYLE;
  static set meditationRingStyle(String value) =>
      instance.setString(MEDITATION_RING_STYLE, value);

  static List<int> get meditationRecentTimes {
    final list = instance.getStringList(MEDITATION_RECENT_TIMES);
    if (list == null || list.isEmpty) {
      return [30, 15, 45, 60];
    }
    final ints = list
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .where((m) => m > 0 && m <= 720)
        .toList();
    if (ints.isEmpty) {
      return [30, 15, 45, 60];
    }
    final unique = <int>[];
    for (final val in ints) {
      if (!unique.contains(val)) {
        unique.add(val);
      }
      if (unique.length == 4) break;
    }
    for (final def in [30, 15, 45, 60]) {
      if (unique.length < 4 && !unique.contains(def)) {
        unique.add(def);
      }
    }
    return unique;
  }

  static set meditationRecentTimes(List<int> values) {
    final unique = <int>[];
    for (final val in values) {
      if (val > 0 && !unique.contains(val)) {
        unique.add(val);
      }
      if (unique.length == 4) break;
    }
    instance.setStringList(
      MEDITATION_RECENT_TIMES,
      unique.map((e) => e.toString()).toList(),
    );
  }

  static void addMeditationRecentTime(int minutes) {
    if (minutes <= 0) return;
    final current = List<int>.from(meditationRecentTimes);
    current.remove(minutes);
    current.insert(0, minutes);
    if (current.length > 4) {
      current.removeRange(4, current.length);
    }
    meditationRecentTimes = current;
  }

  // Death Contemplation getters & setters
  static DateTime? get deathContemplationBirthDate {
    final str = instance.getString(DEATH_CONTEMPLATION_BIRTH_DATE);
    if (str == null || str.isEmpty) return null;
    return DateTime.tryParse(str);
  }

  static set deathContemplationBirthDate(DateTime? value) {
    if (value == null) {
      instance.remove(DEATH_CONTEMPLATION_BIRTH_DATE);
    } else {
      instance.setString(
          DEATH_CONTEMPLATION_BIRTH_DATE, value.toIso8601String());
    }
  }

  static int get deathContemplationLifeExpectancy =>
      instance.getInt(DEATH_CONTEMPLATION_LIFE_EXPECTANCY) ??
      DEFAULT_DEATH_CONTEMPLATION_LIFE_EXPECTANCY;

  static set deathContemplationLifeExpectancy(int value) =>
      instance.setInt(DEATH_CONTEMPLATION_LIFE_EXPECTANCY, value);

  static bool get deathContemplationShowGasTank =>
      instance.getBool(DEATH_CONTEMPLATION_SHOW_GAS_TANK) ??
      DEFAULT_DEATH_CONTEMPLATION_SHOW_GAS_TANK;

  static set deathContemplationShowGasTank(bool value) =>
      instance.setBool(DEATH_CONTEMPLATION_SHOW_GAS_TANK, value);

  static bool get deathContemplationGaugeShowRemaining =>
      instance.getBool(DEATH_CONTEMPLATION_GAUGE_SHOW_REMAINING) ??
      DEFAULT_DEATH_CONTEMPLATION_GAUGE_SHOW_REMAINING;

  static set deathContemplationGaugeShowRemaining(bool value) =>
      instance.setBool(DEATH_CONTEMPLATION_GAUGE_SHOW_REMAINING, value);

  // Compass getters & setters
  static String get targetName =>
      instance.getString(targetNamePref) ?? defaultTargetName;
  static set targetName(String value) =>
      instance.setString(targetNamePref, value);

  static String get userDest1 =>
      instance.getString(userDest1Pref) ?? defaultUserDest1;
  static set userDest1(String value) =>
      instance.setString(userDest1Pref, value);

  static double get userDest1Lat =>
      instance.getDouble(userDest1LatPref) ?? defaultUserDest1Lat;
  static set userDest1Lat(double value) =>
      instance.setDouble(userDest1LatPref, value);

  static double get userDest1Long =>
      instance.getDouble(userDest1LongPref) ?? defaultUserDest1Long;
  static set userDest1Long(double value) =>
      instance.setDouble(userDest1LongPref, value);

  static double get targetLat =>
      instance.getDouble(targetLatPref) ?? defaultTargetLat;
  static set targetLat(double value) =>
      instance.setDouble(targetLatPref, value);

  static double get targetLong =>
      instance.getDouble(targetLongPref) ?? defaultTargetLong;
  static set targetLong(double value) =>
      instance.setDouble(targetLongPref, value);

  static bool get vibeOn => instance.getBool(vibeOnPref) ?? defaultVibeOn;
  static set vibeOn(bool value) => instance.setBool(vibeOnPref, value);

  static bool get compassShowMap =>
      instance.getBool(compassShowMapPref) ?? defaultCompassShowMap;
  static set compassShowMap(bool value) =>
      instance.setBool(compassShowMapPref, value);

  static Color getChosenColor(BuildContext context) {
    switch (Prefs.selectedPageColor) {
      case 0:
        return Colors.white;
      case 1:
        return Theme.of(context)
            .colorScheme
            .surfaceContainerHighest; // ?? (const Color(seypia));
      case 2:
        return Colors.black;
      default:
        return Colors.white;
    }
  }
}
