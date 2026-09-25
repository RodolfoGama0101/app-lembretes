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

    const android = AndroidInitializationSettings('ic_stat_lembretes');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
  }

  @override
  Future<bool> requestPermission(NotificationKind kind) async {
    if (kind == NotificationKind.inbox) return true;
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
  Future<NotificationDeliveryStatus> schedule(Reminder reminder) async {
    if (reminder.kind == NotificationKind.inbox) {
      throw ArgumentError('Um item da caixa de entrada não gera aviso.');
    }
    final persistent = reminder.isPersistent;
    final when = reminder.isUnscheduled
        ? 'Sem horário'
        : DateFormat('dd/MM • HH:mm', 'pt_BR').format(reminder.scheduledAt!);
    final body = _bodyFor(reminder);
    final androidDetails = AndroidNotificationDetails(
      persistent ? 'lembretes_persistent' : 'lembretes_temporary',
      persistent ? 'Lembretes permanentes' : 'Lembretes temporários',
      channelDescription: persistent
          ? 'Lembretes que aparecem ao salvar e reaparecem diariamente'
          : 'Lembretes que podem ser dispensados normalmente',
      icon: switch (reminder.symbol) {
        NotificationSymbol.bell => 'ic_stat_lembretes',
        NotificationSymbol.star => 'ic_stat_star',
        NotificationSymbol.check => 'ic_stat_check',
      },
      color: Color(reminder.accent.colorValue),
      largeIcon: DrawableResourceAndroidBitmap(
        reminder.accent.badgeName(reminder.symbol),
      ),
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
      if (Platform.isAndroid) {
        try {
          // Android 14+ lets users swipe ongoing notifications away.
          // A daily repeat brings the reminder back without opening the app.
          await _plugin.periodicallyShowWithDuration(
            reminder.notificationId,
            reminder.title,
            body,
            const Duration(days: 1),
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: reminder.id,
          );
        } catch (_) {
          await _plugin.cancel(reminder.notificationId);
          rethrow;
        }
      }
      return NotificationDeliveryStatus.scheduled;
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
    return !Platform.isAndroid || canScheduleExactAlarms
        ? NotificationDeliveryStatus.scheduled
        : NotificationDeliveryStatus.approximate;
  }

  String _bodyFor(Reminder reminder) => reminder.notes.isNotEmpty
      ? reminder.notes
      : reminder.isUnscheduled
          ? 'Lembrete sem horário, fixado no painel'
          : reminder.isPersistent
              ? 'Lembrete fixado no painel'
              : 'Está na hora deste lembrete.';

  Future<bool> _notificationsAllowed() async {
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? false;
    }
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return (await ios?.checkPermissions())?.isEnabled ?? false;
    }
    return false;
  }

  @override
  Future<Map<String, NotificationDeliveryStatus>> reconcile(
      List<Reminder> reminders) async {
    final statuses = <String, NotificationDeliveryStatus>{};
    final notificationsAllowed = await _notificationsAllowed();
    final active = Platform.isAndroid || Platform.isIOS
        ? await _plugin.getActiveNotifications()
        : <ActiveNotification>[];
    final pending = await _plugin.pendingNotificationRequests();
    final existingIds = <int>{
      ...active.map((item) => item.id).whereType<int>(),
      ...pending.map((item) => item.id),
    };
    final retainedIds = <int>{
      for (final reminder in reminders)
        if ((reminder.isPersistent &&
                (!reminder.isCompleted ||
                    reminder.keepNotificationAfterCompletion)) ||
            (reminder.kind == NotificationKind.temporary &&
                !reminder.isCompleted))
          reminder.notificationId,
    };
    for (final id in existingIds.difference(retainedIds)) {
      await _plugin.cancel(id);
    }

    final now = DateTime.now();
    for (final reminder in reminders) {
      if (reminder.isPersistent &&
          (!reminder.isCompleted || reminder.keepNotificationAfterCompletion)) {
        if (!notificationsAllowed) {
          statuses[reminder.id] = NotificationDeliveryStatus.permissionDenied;
          continue;
        }
        final stale = active.any((item) =>
            item.id == reminder.notificationId &&
            ((item.title != null && item.title != reminder.title) ||
                (item.body != null && item.body != _bodyFor(reminder))));
        if (stale) await _plugin.cancel(reminder.notificationId);
        await restorePersistent(reminder);
        statuses[reminder.id] = NotificationDeliveryStatus.scheduled;
      } else if (reminder.kind == NotificationKind.temporary &&
          !reminder.isCompleted) {
        if (!notificationsAllowed) {
          statuses[reminder.id] = NotificationDeliveryStatus.permissionDenied;
          continue;
        }
        if (reminder.scheduledAt!.isAfter(now)) {
          await _plugin.cancel(reminder.notificationId);
          statuses[reminder.id] = await schedule(reminder);
        } else if (pending.any((item) => item.id == reminder.notificationId)) {
          await _plugin.cancel(reminder.notificationId);
        }
      }
    }
    return statuses;
  }

  @override
  Future<void> restorePersistent(Reminder reminder) async {
    if (Platform.isAndroid || Platform.isIOS) {
      final active = await _plugin.getActiveNotifications();
      if (active.any(
        (notification) => notification.id == reminder.notificationId,
      )) {
        if (!Platform.isAndroid) return;
        final pending = await _plugin.pendingNotificationRequests();
        if (pending.any(
          (request) => request.id == reminder.notificationId,
        )) {
          return;
        }
      }
    }
    await schedule(reminder);
  }

  @override
  Future<void> cancel(int notificationId) => _plugin.cancel(notificationId);
}
