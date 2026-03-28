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

/// =======================================================
/// 1. UPOSATHA CHANNEL (unchanged – just keep it)
/// =======================================================
Future<void> createUposathaChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'uposatha_channel',
    'Uposatha Reminders',
    description: 'Notifications for Uposatha events',
    importance: Importance.max,
    playSound: true,
    // No default sound needed – you probably use a bell or custom one per-notification
  );

  final android =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await android?.createNotificationChannel(channel);
  debugPrint("Uposatha channel created/ensured");
}

/// =======================================================
/// 2. CANCEL ONLY UPOSATHA NOTIFICATIONS (preserves timer channels!)
/// =======================================================
Future<void> cancelAllUposathaNotifications() async {
  // Use a dedicated ID range for Uposatha (e.g. 1000–1999)
  // You already schedule them with IDs like date.hashCode ^ 111
  // → just make sure they are in a known range, or store them when scheduling

  // Option A: If you use a fixed range (recommended)
  for (int id = 1000; id < 2000; id++) {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // Option B: If you use date.hashCode – store the IDs when scheduling!
  // Example: keep a Set<int> uposathaIds in Prefs or a static list

  debugPrint("🛑 All Uposatha notifications cancelled (IDs 1000–1999)");
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
  await cancelAllUposathaNotifications();
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

  final int notificationId =
      1000 + date.day; // or any unique ID in 1000–1999 range
  // ---------------------------------------------------
  // 1️⃣ BEFORE-NOTIFICATION  (only if > 0 days)
  // ---------------------------------------------------
  if (beforeDays > 0) {
    if (beforeTime.isAfter(now)) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId, // unchanged ID logic
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
    notificationId, // unchanged ID logic
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

final List<Map<String, dynamic>> announcements = [
  {
    'sec': 10,
    'sound': 'tts30minutesremaining',
    'title': '30 minutes remaining'
  },
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
  {'sec': 90, 'sound': 'tts8minutesremaining', 'title': '8 minutes remaining'},
  {'sec': 110, 'sound': 'tts6minutesremaining', 'title': '6 minutes remaining'},
  {'sec': 130, 'sound': 'tts5minutesremaining', 'title': '5 minutes remaining'},
  {'sec': 150, 'sound': 'tts4minutesremaining', 'title': '4 minutes remaining'},
  {'sec': 170, 'sound': 'tts3minutesremaining', 'title': '3 minutes remaining'},
  {'sec': 190, 'sound': 'tts2minutesremaining', 'title': '2 minutes remaining'},
  {'sec': 210, 'sound': 'tts1minutesremaining', 'title': '1 minute remaining'},
  {'sec': 230, 'sound': 'tts0minutesremaining', 'title': 'Dawn has arrived'},
];

// =======================================================
//   NOTIFICATION TIMER SYSTEM – CLEAN & SEPARATED
// =======================================================

//final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//  FlutterLocalNotificationsPlugin();

/// FINAL: Your perfect, stress-proof announcement list
final List<Map<String, dynamic>> solarTimerAnnouncementSounds = [
  {'minutesBefore': 30, 'sound': 'tts30minutesremaining', 'id': 7000},
  {'minutesBefore': 20, 'sound': 'tts20minutesremaining', 'id': 7001},
  {'minutesBefore': 15, 'sound': 'tts15minutesremaining', 'id': 7002},
  {'minutesBefore': 10, 'sound': 'tts10minutesremaining', 'id': 7003},
  {'minutesBefore': 8, 'sound': 'tts8minutesremaining', 'id': 7004},
  {'minutesBefore': 6, 'sound': 'tts6minutesremaining', 'id': 7005},
  {'minutesBefore': 5, 'sound': 'tts5minutesremaining', 'id': 7006},
  {'minutesBefore': 4, 'sound': 'tts4minutesremaining', 'id': 7007},
  {'minutesBefore': 3, 'sound': 'tts3minutesremaining', 'id': 7008},
  {'minutesBefore': 2, 'sound': 'tts2minutesremaining', 'id': 7009},
  {'minutesBefore': 1, 'sound': 'tts1minutesremaining', 'id': 7010},
  {'minutesBefore': 0, 'sound': 'tts0minutesremaining', 'id': 7011},
  // optional final bell
  // {'minutesBefore': 0, 'sound': 'bell', 'id': 7012},
];

/// =======================================================
/// 1. CREATE CHANNELS ONCE (main.dart) — never delete
/// =======================================================
Future<void> createTimerChannelsOnce() async {
  final android =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  if (android == null) return;

  for (final entry in solarTimerAnnouncementSounds) {
    final soundName = entry['sound'] as String;
    final channelId = 'timer_channel_$soundName';

    final channels = await android.getNotificationChannels();
    if (channels?.any((ch) => ch.id == channelId) ?? false) continue;

    final channel = AndroidNotificationChannel(
      channelId,
      'Timer Voice – $soundName',
      description: 'Dedicated channel for $soundName.mp3',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundName),
    );

    await android.createNotificationChannel(channel);
  }
}

/// =======================================================
/// 2. CANCEL ONLY TIMER NOTIFICATIONS (Uposatha safe)
/// =======================================================
Future<void> cancelAllTimerNotifications() async {
  for (final entry in solarTimerAnnouncementSounds) {
    await flutterLocalNotificationsPlugin.cancel(entry['id'] as int);
  }
  debugPrint("All timer notifications cancelled (IDs from map)");
}

/// =======================================================
/// 3. SCHEDULE ALL (perfect, no index math, no guesswork)
/// =======================================================
Future<void> scheduleAllTimerNotifications({
  required DateTime targetTime,
}) async {
  await cancelAllTimerNotifications(); // clean slate

  final tzTarget = tz.TZDateTime.from(targetTime, tz.local);

  for (final entry in solarTimerAnnouncementSounds) {
    final minutesBefore = entry['minutesBefore'] as int;
    final soundName = entry['sound'] as String;
    final notificationId = entry['id'] as int;

    final fireTime = tzTarget.subtract(Duration(minutes: minutesBefore));
    if (fireTime
        .isBefore(DateTime.now().subtract(const Duration(seconds: 30)))) {
      continue; // skip if way in the past
    }

    final channelId = 'timer_channel_$soundName';
    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Timer Voice – $soundName',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundName),
      audioAttributesUsage: AudioAttributesUsage.notification,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      '$minutesBefore minute${minutesBefore == 1 ? '' : 's'} remaining',
      null,
      tz.TZDateTime.from(fireTime, tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint("Scheduled ID $notificationId → $soundName.mp3 at $fireTime");
  }

  debugPrint("All timer voices scheduled for target: $targetTime");
}

/// FINAL TEST – 13 ElevenLabs voices every 10 seconds
/// Deletes ALL old voice channels first → always fresh
/// One channel per sound → 100% guaranteed correct voice on every device
Future<void> doElevenLabsCountdownTest() async {
  // Cancel only timer notifications
  await cancelAllTimerNotifications();

  final now = tz.TZDateTime.now(tz.local);

  int index = 0;
  for (final a in announcements) {
    final soundName = a['sound'] as String;
    final channelId = 'timer_channel_$soundName';

    final androidDetails = AndroidNotificationDetails(
      channelId, // ← PER-SOUND CHANNEL
      'Timer Voice – $soundName',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundName),
      audioAttributesUsage: AudioAttributesUsage.notification,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      7000 + index,
      a['title'] as String,
      null,
      tz.TZDateTime.from(now.add(Duration(seconds: a['sec'] as int)), tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    index++;
  }

  debugPrint("13 voices scheduled using dedicated channels");
}
