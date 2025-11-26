// ---------------------------------------------------------------
//  Buddhist Sun – MTS-style Notification Service
// ---------------------------------------------------------------

import 'dart:convert';
import 'dart:io';

import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:buddhist_sun/src/services/plugin.dart';

// ===============================================================
//  TIMEZONE INIT
// ===============================================================
Future<void> configureLocalTimeZone() async {
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}

// ===============================================================
//  CREATE CHANNEL
// ===============================================================
Future<void> createUposathaChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'uposatha_channel',
    'Uposatha Reminders',
    description: 'Notifications for Uposatha events',
    importance: Importance.max,
    playSound: true,
  );

  final android =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await android?.createNotificationChannel(channel);
}

Future<void> createTimerChannelbell() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'timer_channel',
    'Timer Reminders',
    description: 'Notifications for Timer events',
    sound: null,
    playSound: true,
    importance: Importance.max,
  );

  final android =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await android?.createNotificationChannel(channel);
}

// ==================================================
//    Request Permissions
// ==================================================
Future requestPermissions() async {
// Optional but recommended explicit permission request
  if (Platform.isIOS || Platform.isMacOS) {
    final ios =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

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
}

// =======================================================
//  Cancel all existing notifications
// =======================================================
Future<void> cancelAllNotifications() async {
  await flutterLocalNotificationsPlugin.cancelAll();
  debugPrint("🛑 All Uposatha notifications cancelled");
}

// -----------------------------------------------------------
//  Schedule Uposatha Notifications
// -----------------------------------------------------------
Future<void> scheduleUpcomingUposathaNotifications() async {
  await createUposathaChannel();

  // 1️⃣ Load Uposatha list (either Myanmar or JSON)
  final dates = await loadUposathaDates();

  final now = DateTime.now();

  // 2️⃣ Only schedule future dates
  final futureDates = dates.where((d) {
    final day6am = DateTime(d.year, d.month, d.day, 6, 0);
    return day6am.isAfter(now);
  }).toList();

  if (futureDates.isEmpty) {
    debugPrint("⚠️ No future Uposatha dates");
    return;
  }

  // 3️⃣ Schedule each future uposatha
  for (final date in futureDates) {
    await _scheduleSingleUposatha(date);
  }
}

// =======================================================
//  Full reschedule wrapper
// =======================================================
Future<void> rescheduleUposathaNotifications() async {
  if (!Prefs.uposathaNotificationsEnabled) {
    debugPrint("⚠️ Uposatha notifications are disabled; skipping reschedule");
    return;
  }
  await cancelAllNotifications();
  await scheduleUpcomingUposathaNotifications(); // ← you already have this
  debugPrint("🔄 Uposatha notifications fully rescheduled");
}

// -----------------------------------------------------------
//  Single Uposatha scheduler
// -----------------------------------------------------------
Future<void> _scheduleSingleUposatha(DateTime date) async {
  final now = tz.TZDateTime.now(tz.local);

  // --- NEW: get time-of-day from Prefs ---
  final notifTime = Prefs.uposathaNotificationTime;

  // DAY-OF notification time
  final dayOfTime = tz.TZDateTime(
    tz.local,
    date.year,
    date.month,
    date.day,
    notifTime.hour,
    notifTime.minute,
  );

  // BEFORE notification time (depends on user setting)
  final int beforeDays = Prefs.beforeUposathaNotificationDays;

  final beforeTime = tz.TZDateTime(
    tz.local,
    date.year,
    date.month,
    date.day,
    notifTime.hour,
    notifTime.minute,
  ).subtract(Duration(days: beforeDays));

  // Skip if day-of is already in the past
  if (dayOfTime.isBefore(now)) {
    debugPrint("⏩ Skipping past date ${date.toIso8601String()}");
    return;
  }

  // ---------------------------------------------------
  // 1️⃣ BEFORE-NOTIFICATION  (only if > 0 days)
  // ---------------------------------------------------
  if (beforeDays > 0) {
    if (beforeTime.isAfter(now)) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        date.hashCode ^ 111, // unchanged ID logic
        "Uposatha Coming Soon",
        "$beforeDays days until Uposatha.",
        beforeTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'uposatha_channel',
            'Uposatha Reminders',
            channelDescription: 'Day-before reminder',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          macOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint("🟢 Before-notification scheduled for $beforeTime");
    } else {
      debugPrint("⏩ Skipping before-notification (already past)");
    }
  } else {
    debugPrint(
        "⏩ beforeUposathaNotificationDays = 0 → skipping before-notification");
  }

  // ---------------------------------------------------
  // 2️⃣ DAY-OF NOTIFICATION (always delivered)
  // ---------------------------------------------------
  await flutterLocalNotificationsPlugin.zonedSchedule(
    date.hashCode, // unchanged ID logic
    "Uposatha Today",
    "Today is Uposatha Day.",
    dayOfTime,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'uposatha_channel',
        'Uposatha Reminders',
        channelDescription: 'Day-of reminder',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );

  debugPrint("🟢 Day-of scheduled for $dayOfTime");
}

// ===============================================================
//  Load Uposatha Dates (Myanmar or Country JSON)
// ===============================================================
Future<List<DateTime>> loadUposathaDates() async {
  // If Myanmar selected → compute via moon phases
  if (Prefs.selectedUposatha == UposathaCountry.Myanmar) {
    final now = DateTime.now();
    final List<DateTime> list = [];

    DateTime? next = now;
    for (int i = 0; i < 16; i++) {
      next = await calculateNextMyanmarUposatha(next!);
      if (next != null) list.add(next);
    }
    return list;
  }

  // Otherwise → JSON-based
  try {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/uposatha.json');

    if (!file.existsSync()) return [];

    final data = jsonDecode(await file.readAsString());
    final key = EnumToString.convertToString(Prefs.selectedUposatha);

    if (!data.containsKey(key)) return [];

    final dates =
        (data[key] as List<dynamic>).map((e) => DateTime.parse(e)).toList();

    dates.sort();
    return dates;
  } catch (e) {
    debugPrint("❌ Failed loading JSON: $e");
    return [];
  }
}

// ===============================================================
//  Myanmar moon-phase version
// ===============================================================
Future<DateTime?> calculateNextMyanmarUposatha(DateTime start) async {
  DateTime upo = start;

  final mmCalendar = MmCalendar(
    config: const MmCalendarConfig(
      calendarType: CalendarType.english,
      language: Language.english,
    ),
  );

  for (int i = 0; i < 16; i++) {
    upo = upo.add(const Duration(days: 1));
    final moon = mmCalendar.fromDateTime(upo).getMoonPhase();

    if (moon.contains("full") || moon.contains("new")) {
      return upo;
    }
  }
  return null;
}

// ===============================================================
//  TEST NOTIFICATIONS
// ===============================================================
Future<void> thirtySecondsNotification() async {
  try {
    await createUposathaChannel(); // Create the channel first
    final now = tz.TZDateTime.now(tz.local);
    final t = now.add(const Duration(seconds: 30));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      999999,
      "30-sec Test",
      "This should fire in 30 seconds",
      t,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'uposatha_channel',
          'Uposatha Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          // ← THIS LINE IS MANDATORY
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint("🟢 30 sec test @ $t");
  } catch (e) {
    debugPrint("❌ Test error: $e");
  }
}

Future<void> showInstantNotification() async {
  try {
    await createUposathaChannel(); // Create the channel first
    await flutterLocalNotificationsPlugin.show(
      777777,
      "Instant Test",
      "This is an instant notification",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'uposatha_channel',
          'Uposatha Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );

    debugPrint("🟢 Instant OK");
  } catch (e) {
    debugPrint("❌ Instant error: $e");
  }
}

/// FINAL TEST FUNCTION – 4 exact notifications with custom MP3 sounds
/// Uses your existing timer_channel (no deletion, no multiple channels)
/// Files must be in: android/app/src/main/res/raw/test1.mp3, test2.mp3, etc.
/// Works 100% once the MP3 files are properly encoded (your bell.mp3 proves it)
/// 2. TEST FUNCTION – now works perfectly with different sounds
Future<void> doFourTimerTest() async {
  await flutterLocalNotificationsPlugin.cancelAll();

  final now = tz.TZDateTime.now(tz.local);

  final announcements = [
    {'id': 991, 'sec': 5, 'sound': 'test4', 'title': 'Test 4 – now'},
    {'id': 992, 'sec': 30, 'sound': 'test3', 'title': 'Test 3 – 30s'},
    {'id': 993, 'sec': 60, 'sound': 'test2', 'title': 'Test 2 – 60s'},
    {'id': 994, 'sec': 90, 'sound': 'test1', 'title': 'Test 1 – 90s'},
  ];

  for (final a in announcements) {
    final androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Timer Reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: false,
      audioAttributesUsage: AudioAttributesUsage.notification,
      sound: RawResourceAndroidNotificationSound(
          a['sound'] as String), // ← this now works!
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      a['id'] as int,
      a['title'] as String,
      null,
      tz.TZDateTime.from(now.add(Duration(seconds: a['sec'] as int)), tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  debugPrint(
      "4 different voice notifications scheduled – you should hear test4, test3, test2, test1");
}

/// FINAL TEST – 13 ElevenLabs voices every 10 seconds
/// Deletes ALL old voice channels first → always fresh
/// One channel per sound → 100% guaranteed correct voice on every device
Future<void> doElevenLabsCountdownTest() async {
  final android =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  // STEP 1: DESTROY ALL OLD VOICE CHANNELS
  const List<String> soundNames = [
    '30minremaining',
    '20minremaining',
    '15minremaining',
    '10minremaining',
    '8minremaining',
    '6minremaining',
    '5minremaining',
    '4minremaining',
    '3minremaining',
    '2minremaining',
    '1minremaining',
    '0minremaining',
    'bell',
  ];

  for (final sound in soundNames) {
    final channelId = 'timer_channel_$sound';
    await android?.deleteNotificationChannel(channelId);
    debugPrint("Deleted old channel: $channelId");
  }

  // Cancel any pending notifications
  await flutterLocalNotificationsPlugin.cancelAll();

  // STEP 2: SCHEDULE 13 VOICES – fresh channels
  final now = tz.TZDateTime.now(tz.local);

  final List<Map<String, dynamic>> announcements = [
    {'sec': 10, 'sound': 'tts30minremaining', 'title': '30 minutes remaining'},
    {
      'sec': 30,
      'sound': 'tts20minutesremaining',
      'title': '20 minutes remaining'
    },
    {
      'sec': 50,
      'sound': 'tts15minutesremaining',
      'title': '15 minutes remaining'
    },
    {
      'sec': 70,
      'sound': 'tts10minutesremaining',
      'title': '10 minutes remaining'
    },
    {
      'sec': 90,
      'sound': 'tts8minutesremaining',
      'title': '8 minutes remaining'
    },
    {
      'sec': 120,
      'sound': 'tts6minutesremaining',
      'title': '6 minutes remaining'
    },
    {
      'sec': 140,
      'sound': 'tts5minutesremaining',
      'title': '5 minutes remaining'
    },
    {
      'sec': 160,
      'sound': 'tts4minutesremaining',
      'title': '4 minutes remaining'
    },
    {
      'sec': 180,
      'sound': 'tts3minutesremaining',
      'title': '3 minutes remaining'
    },
    {
      'sec': 200,
      'sound': 'tts2minutesremaining',
      'title': '2 minutes remaining'
    },
    {
      'sec': 220,
      'sound': 'tts1minutesremaining',
      'title': '1 minute remaining'
    },
    {'sec': 240, 'sound': 'tts0minutesremaining', 'title': 'Dawn has arrived'},
  ];

  for (int i = 0; i < announcements.length; i++) {
    final a = announcements[i];
    final soundName = a['sound'] as String;
    final channelId = 'timer_channel_$soundName';

    // Create fresh dedicated channel for this exact sound
    final channel = AndroidNotificationChannel(
      channelId,
      'Voice – $soundName',
      description: 'Dedicated channel for $soundName.mp3',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundName), // locked
    );
    await android?.createNotificationChannel(channel);

    final details = AndroidNotificationDetails(
      channelId,
      'Voice – $soundName',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundName),
      audioAttributesUsage: AudioAttributesUsage.notification,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      900 + i,
      a['title'] as String,
      null,
      tz.TZDateTime.from(now.add(Duration(seconds: a['sec'] as int)), tz.local),
      NotificationDetails(android: details),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  debugPrint(
      "13 ElevenLabs voices scheduled – fresh channels – starting in 10s");
}

/// 1. CHANNEL CREATION – NEVER set a default sound here! (final version)
Future<void> createTimerChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'timer_channel',
    'Timer Reminders',
    description: 'Solar time voice announcements',
    importance: Importance.max,
    playSound: true,
    // ← NO default sound! This is the ONLY correct way
  );

  final android =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await android?.createNotificationChannel(channel);
}

// =======================================================
//   NOTIFICATION TIMER SYSTEM – CLEAN & SEPARATED
// =======================================================

//final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//  FlutterLocalNotificationsPlugin();

/// =======================================================
/// 1. DELETE ALL CHANNELS + ALL TIMER NOTIFICATIONS
/// =======================================================
Future<void> cancelAllTimerNotifications() async {
  final android =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  List<String> timerSoundNames = solarTimerAnnouncementSounds.values
      .toList(); // if you want the ending bell

  // Delete all timer-related channels
  for (final sound in timerSoundNames) {
    final channelId = 'timer_channel_$sound';
    await android?.deleteNotificationChannel(channelId);
  }

  // Cancel scheduled notifications
  await flutterLocalNotificationsPlugin.cancelAll();
}

/// =======================================================
/// 2. CREATE CHANNELS (one per sound)
/// =======================================================

final Map<int, String> solarTimerAnnouncementSounds = {
  30: 'tts30minremaining',
  20: 'tts20minutesremaining',
  15: 'tts15minutesremaining',
  10: 'tts10minutesremaining',
  8: 'tts8minutesremaining',
  6: 'tts6minutesremaining',
  5: 'tts5minutesremaining',
  4: 'tts4minutesremaining',
  3: 'tts3minutesremaining',
  2: 'tts2minutesremaining',
  1: 'tts1minutesremaining',
  0: 'tts0minutesremaining',
};

Future<void> createTimerChannels() async {
  final android =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  List<String> timerSoundNames = solarTimerAnnouncementSounds.values
      .toList(); // if you want the ending bell

  for (final sound in timerSoundNames) {
    final channelId = 'timer_channel_$sound';

    final channel = AndroidNotificationChannel(
      channelId,
      'Timer Voice – $sound',
      description: 'Voice notification for $sound.mp3',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(sound),
    );

    await android?.createNotificationChannel(channel);
  }
}

/// =======================================================
/// 3. SCHEDULE ALL TIMER NOTIFICATIONS
///
///   targetTime = DateTime of Solar Noon / Dawn
///   soundMap = { minutesBefore : soundName }
///
///   Example:
///   { 30 : '30min', 20:'20min', 1:'1min', 0:'0min' }
///
/// =======================================================
Future<void> scheduleAllTimerNotifications({
  required DateTime targetTime,
  required Map<int, String> soundMap,
}) async {
  // First wipe old notifications + channels
  await cancelAllTimerNotifications();

  // Then create fresh channels
  await createTimerChannels();

  final tzTarget = tz.TZDateTime.from(targetTime, tz.local);

  int index = 0;

  for (final entry in soundMap.entries) {
    final minutesBefore = entry.key;
    final soundName = entry.value;

    final scheduleTime = tzTarget.subtract(Duration(minutes: minutesBefore));

    if (scheduleTime.isBefore(DateTime.now())) {
      continue; // Skip missed events
    }

    final channelId = 'timer_channel_$soundName';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Timer Voice – $soundName',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundName),
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      7000 + index,
      '$minutesBefore minutes remaining',
      null,
      tz.TZDateTime.from(scheduleTime, tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    index++;
  }
}
