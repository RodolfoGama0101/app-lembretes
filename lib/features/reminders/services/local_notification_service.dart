import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../domain/notification_appearance.dart';
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
  Future<bool> requestPermission(NotificationKind kind) async {
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final notificationsAllowed =
          await android?.requestNotificationsPermission() ?? true;
      if (notificationsAllowed && kind == NotificationKind.temporary) {
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
    final persistent = reminder.isPersistent;
    final when = reminder.isUnscheduled
        ? 'Sem horário'
        : DateFormat('dd/MM • HH:mm', 'pt_BR').format(reminder.scheduledAt!);
    final body = reminder.notes.isNotEmpty
        ? reminder.notes
        : reminder.isUnscheduled
            ? 'Lembrete sem horário, fixado no painel'
            : persistent
                ? 'Lembrete fixado no painel'
                : 'Está na hora deste lembrete.';
    final androidDetails = AndroidNotificationDetails(
      persistent ? 'fio_persistent' : 'fio_temporary',
      persistent ? 'Lembretes permanentes' : 'Lembretes temporários',
      channelDescription: persistent
          ? 'Lembretes que aparecem ao salvar e ficam até a exclusão'
          : 'Lembretes que podem ser dispensados normalmente',
      icon: switch (reminder.symbol) {
        NotificationSymbol.bell => 'ic_stat_fio',
        NotificationSymbol.star => 'ic_stat_star',
        NotificationSymbol.check => 'ic_stat_check',
      },
      color: Color(reminder.accent.colorValue),
      subText: when,
      ticker: reminder.title,
      styleInformation: reminder.visualStyle == NotificationVisualStyle.expanded
          ? BigTextStyleInformation(
              body,
              contentTitle: reminder.title,
              summaryText: when,
            )
          : const DefaultStyleInformation(false, false),
      importance: Importance.max,
      priority: Priority.high,
      ongoing: persistent,
      autoCancel: !persistent,
      onlyAlertOnce: persistent,
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

    if (persistent) {
      final pending = await _plugin.pendingNotificationRequests();
      if (pending.any((request) => request.id == reminder.notificationId)) {
        await _plugin.cancel(reminder.notificationId);
      }
      await _plugin.show(
        reminder.notificationId,
        reminder.title,
        body,
        details,
        payload: reminder.id,
      );
      return;
    }

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
      body,
      tz.TZDateTime.from(reminder.scheduledAt!, tz.local),
      details,
      androidScheduleMode: canScheduleExactAlarms
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: reminder.id,
    );
  }

  @override
  Future<void> restorePersistent(Reminder reminder) async {
    if (Platform.isAndroid || Platform.isIOS) {
      final active = await _plugin.getActiveNotifications();
      if (active.any(
        (notification) => notification.id == reminder.notificationId,
      )) {
        return;
      }
    }
    await schedule(reminder);
  }

  @override
  Future<void> cancel(int notificationId) => _plugin.cancel(notificationId);
}
