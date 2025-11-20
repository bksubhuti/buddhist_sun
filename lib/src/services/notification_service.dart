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

// ===============================================================
//  CANCEL ALL (Recommended on app start)
// ===============================================================
Future<void> cancelAllNotifications() async {
  await flutterLocalNotificationsPlugin.cancelAll();
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

// -----------------------------------------------------------
//  Single Uposatha scheduler
// -----------------------------------------------------------
Future<void> _scheduleSingleUposatha(DateTime date) async {
  final now = tz.TZDateTime.now(tz.local);

  final day6am = tz.TZDateTime(
    tz.local,
    date.year,
    date.month,
    date.day,
    6,
    0,
  );

  final prev6am = day6am.subtract(const Duration(days: 1));

  // Skip if the day-of itself is already in the past
  if (day6am.isBefore(now)) {
    debugPrint("⏩ Skipping past date ${date.toIso8601String()}");
    return;
  }

  // 1️⃣ Day-before (only if future)
  if (prev6am.isAfter(now)) {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      date.hashCode ^ 111,
      "Uposatha Tomorrow",
      "Tomorrow is Uposatha Day.",
      prev6am,
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
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint("🟢 Day-before scheduled for $prev6am");
  } else {
    debugPrint("⏩ Skipping day-before (already past)");
  }

  // 2️⃣ Day-of
  await flutterLocalNotificationsPlugin.zonedSchedule(
    date.hashCode,
    "Uposatha Today",
    "Today is Uposatha Day.",
    day6am,
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
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );

  debugPrint("🟢 Day-of scheduled for $day6am");
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
Future<void> oneMinuteNotification() async {
  try {
    final now = tz.TZDateTime.now(tz.local);
    final t = now.add(const Duration(minutes: 1));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      999999,
      "One-minute Test",
      "This should fire in 1 minute",
      t,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'uposatha_channel',
          'Uposatha Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint("🟢 1-min test @ $t");
  } catch (e) {
    debugPrint("❌ Test error: $e");
  }
}

Future<void> showInstantNotification() async {
  try {
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
      ),
    );

    debugPrint("🟢 Instant OK");
  } catch (e) {
    debugPrint("❌ Instant error: $e");
  }
}
