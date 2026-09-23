import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder.dart';
import 'notification_service.dart';

class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    tz.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(localTimezone));
    } on tz.LocationNotFoundException {
      throw StateError('Fuso horário local desconhecido: $localTimezone');
    }

    const android = AndroidInitializationSettings('ic_stat_fio');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
  }

  @override
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final notificationsAllowed =
          await android?.requestNotificationsPermission() ?? true;
      if (notificationsAllowed) {
        await android?.requestExactAlarmsPermission();
      }
      return notificationsAllowed;
    }
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  @override
  Future<void> schedule(Reminder reminder) async {
    final persistent = reminder.kind == NotificationKind.persistent;
    final androidDetails = AndroidNotificationDetails(
      persistent ? 'fio_persistent' : 'fio_temporary',
      persistent ? 'Lembretes fixos' : 'Lembretes temporários',
      channelDescription: persistent
          ? 'Lembretes que permanecem até serem dispensados'
          : 'Lembretes que podem ser dispensados normalmente',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: persistent,
      autoCancel: !persistent,
      category: AndroidNotificationCategory.reminder,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final canScheduleExactAlarms = Platform.isAndroid
        ? await _plugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>()
                ?.canScheduleExactNotifications() ??
            false
        : false;

    await _plugin.zonedSchedule(
      reminder.notificationId,
      reminder.title,
      reminder.notes.isEmpty ? 'Está na hora.' : reminder.notes,
      tz.TZDateTime.from(reminder.scheduledAt, tz.local),
      details,
      androidScheduleMode: canScheduleExactAlarms
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: reminder.id,
    );
  }

  @override
  Future<void> cancel(int notificationId) => _plugin.cancel(notificationId);
}
