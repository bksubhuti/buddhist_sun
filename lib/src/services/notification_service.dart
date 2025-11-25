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
