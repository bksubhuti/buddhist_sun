import 'dart:async';

import 'package:intl/intl.dart';

/// from the example file
/// import 'dart:async';
import 'dart:io';
// ignore: unnecessary_import

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:buddhist_sun/src/services/plugin.dart';

Future<void> configureLocalTimeZone() async {
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}

Future<void> cancelAllNotifications() async {
  await flutterLocalNotificationsPlugin.cancelAll();
}

Future<void> scheduleUpcomingUposathaNotifications() async {
  try {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/uposatha.json');
    if (!await file.exists()) return;

    final List<dynamic> jsonData = jsonDecode(await file.readAsString());
    final now = DateTime.now();

    for (var entry in jsonData) {
      final date = DateTime.tryParse(entry['date']);
      if (date == null || date.isBefore(now)) continue;

      // Schedule 6 AM on that day
      final day6am = tz.TZDateTime.from(
        DateTime(date.year, date.month, date.day, 6, 0),
        tz.local,
      );

      // Schedule 6 AM previous day
      final prev6am = day6am.subtract(const Duration(days: 1));

      await flutterLocalNotificationsPlugin.zonedSchedule(
        date.hashCode ^ 1,
        "Uposatha Reminder",
        "Tomorrow is Uposatha Day",
        prev6am,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'uposatha_channel',
            'Uposatha Reminders',
            channelDescription: 'Reminds one day before and on Uposatha day',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        date.hashCode,
        "Uposatha Today",
        "Today is Uposatha Day",
        day6am,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'uposatha_channel',
            'Uposatha Reminders',
            channelDescription: 'Reminds one day before and on Uposatha day',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  } catch (e) {
    debugPrint("❌ Failed to schedule Uposatha notifications: $e");
  }
}

Future<void> cancelUposathaNotifications() async {
  await flutterLocalNotificationsPlugin
      .cancelAll(); // or keep a list of IDs if you want finer control
}
