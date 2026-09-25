import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/reminder_repository.dart';
import '../domain/notification_appearance.dart';
import '../domain/reminder.dart';
import '../services/notification_service.dart';

enum NotificationFailure { initialization, restoration }

class NotificationSchedulingFailure implements Exception {
  const NotificationSchedulingFailure(this.cause);
  final Object cause;
}

class ReminderController extends ChangeNotifier {
  ReminderController({
    required ReminderRepository repository,
    required NotificationService notificationService,
    bool notificationsAvailable = true,
  })  : _repository = repository,
        _notificationService = notificationService,
        _notificationsAvailable = notificationsAvailable;

  final ReminderRepository _repository;
  final NotificationService _notificationService;
  final List<Reminder> _reminders = [];
  final Map<String, NotificationDeliveryStatus> _deliveryStatuses = {};
  bool _notificationsAvailable;
  NotificationFailure? _notificationFailure;
  Future<bool>? _retryInProgress;

  bool get notificationsAvailable => _notificationsAvailable;
  NotificationFailure? get notificationFailure => _notificationFailure;
  NotificationDeliveryStatus? statusFor(Reminder reminder) {
    if (reminder.alertMode == ReminderAlertMode.none ||
        (reminder.isCompleted && !reminder.keepNotificationAfterCompletion)) {
      return NotificationDeliveryStatus.inactive;
    }
    return _notificationsAvailable
        ? _deliveryStatuses[reminder.id]
        : NotificationDeliveryStatus.unavailable;
  }

  Future<NotificationDeliveryStatus> _schedule(Reminder reminder) async {
    try {
      return await _notificationService.schedule(reminder);
    } catch (error) {
      throw NotificationSchedulingFailure(error);
    }
  }

  Future<bool> retryNotifications() => _retryInProgress ??=
      _retryNotifications().whenComplete(() => _retryInProgress = null);

  Future<bool> _retryNotifications() async {
    var initialized = false;
    try {
      await _notificationService.initialize();
      initialized = true;
      final statuses = await _notificationService.reconcile(_reminders);
      _deliveryStatuses
        ..clear()
        ..addAll(statuses);
      _notificationsAvailable = true;
      _notificationFailure = null;
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint('Falha ao iniciar ou reconciliar notificações: $error');
      _notificationsAvailable = false;
      _notificationFailure = initialized
          ? NotificationFailure.restoration
          : NotificationFailure.initialization;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshNotificationStatuses() async {
    if (!_notificationsAvailable) return;
    try {
      final statuses = await _notificationService.reconcile(_reminders);
      _deliveryStatuses
        ..clear()
        ..addAll(statuses);
      notifyListeners();
    } catch (error) {
      debugPrint('Falha ao atualizar o estado dos avisos: $error');
      _notificationsAvailable = false;
      _notificationFailure = NotificationFailure.restoration;
      notifyListeners();
    }
  }

  List<Reminder> get reminders {
    final sorted = [..._reminders]..sort((a, b) {
        final aWhen = a.scheduledAt;
        final bWhen = b.scheduledAt;
        if (aWhen == null && bWhen == null) {
          return b.createdAt.compareTo(a.createdAt);
        }
        if (aWhen == null) return -1;
        if (bWhen == null) return 1;
        return aWhen.compareTo(bWhen);
      });
    return List.unmodifiable(sorted);
  }

  List<Reminder> get active =>
      reminders.where((item) => !item.isCompleted).toList();

  List<Reminder> get completed =>
      reminders.where((item) => item.isCompleted).toList().reversed.toList();

  Reminder? get nextReminder {
    final now = DateTime.now();
    for (final reminder in active) {
      if (reminder.scheduledAt?.isAfter(now) ?? false) return reminder;
    }
    return null;
  }

  Future<void> load() async {
    _reminders
      ..clear()
      ..addAll(await _repository.load());
    _deliveryStatuses.clear();
    if (_notificationsAvailable) await restorePersistentNotifications();
    notifyListeners();
  }

  Future<void> restorePersistentNotifications() async {
    if (!_notificationsAvailable) return;
    for (final reminder in _reminders) {
      if (_shouldShowPersistent(reminder)) {
        try {
          await _notificationService.restorePersistent(reminder);
        } catch (error) {
          debugPrint('Falha ao restaurar notificação: $error');
          _notificationsAvailable = false;
          _notificationFailure = NotificationFailure.restoration;
          notifyListeners();
          return;
        }
      }
    }
  }

  bool _shouldShowPersistent(Reminder reminder) =>
      reminder.isPersistent &&
      (!reminder.isCompleted || reminder.keepNotificationAfterCompletion);

  Reminder? get oldestOverdue {
    final now = DateTime.now();
    for (final reminder in active) {
      if (reminder.scheduledAt?.isBefore(now) ?? false) return reminder;
    }
    return null;
  }

  Future<NotificationDeliveryStatus> add({
    required String title,
    required String notes,
    required DateTime? scheduledAt,
    NotificationKind? kind,
    ReminderAlertMode? alertMode,
    NotificationVisualStyle visualStyle = NotificationVisualStyle.expanded,
    NotificationAccent accent = NotificationAccent.red,
    NotificationSymbol symbol = NotificationSymbol.bell,
  }) async {
    if ((kind == null) == (alertMode == null)) {
      throw ArgumentError('Informe apenas um modo de aviso.');
    }
    final mode = alertMode ??
        switch (kind!) {
          NotificationKind.temporary => ReminderAlertMode.atTime,
          NotificationKind.persistent ||
          NotificationKind.unscheduled =>
            ReminderAlertMode.pinned,
          NotificationKind.inbox => ReminderAlertMode.none,
        };
    if ((mode == ReminderAlertMode.atTime && scheduledAt == null) ||
        ((kind == NotificationKind.unscheduled ||
                kind == NotificationKind.inbox) &&
            scheduledAt != null) ||
        ((kind == NotificationKind.temporary ||
                kind == NotificationKind.persistent) &&
            scheduledAt == null)) {
      throw ArgumentError('O tipo e o horário do lembrete não correspondem.');
    }
    final now = DateTime.now();
    var rawId = now.microsecondsSinceEpoch;
    while (_reminders.any(
      (item) =>
          item.id == rawId.toString() ||
          item.notificationId == rawId.remainder(2147483647),
    )) {
      rawId++;
    }
    final reminder = Reminder(
      id: rawId.toString(),
      notificationId: rawId.remainder(2147483647),
      title: title.trim(),
      notes: notes.trim(),
      scheduledAt: scheduledAt,
      alertMode: mode,
      visualStyle: visualStyle,
      accent: accent,
      symbol: symbol,
      keepNotificationAfterCompletion: mode == ReminderAlertMode.pinned,
      createdAt: now,
    );

    final needsNotification = mode != ReminderAlertMode.none;
    final permitted = needsNotification &&
        _notificationsAvailable &&
        await _notificationService.requestPermission(mode);
    final status = !needsNotification
        ? NotificationDeliveryStatus.inactive
        : !_notificationsAvailable
            ? NotificationDeliveryStatus.unavailable
            : permitted
                ? await _schedule(reminder)
                : NotificationDeliveryStatus.permissionDenied;
    try {
      await _repository.save([..._reminders, reminder]);
    } catch (_) {
      if (permitted) {
        try {
          await _notificationService.cancel(reminder.notificationId);
        } catch (_) {
          // Preserve the storage error for the caller.
        }
      }
      rethrow;
    }
    _reminders.add(reminder);
    _deliveryStatuses[reminder.id] = status;
    notifyListeners();
    return status;
  }

  Future<NotificationDeliveryStatus> update(Reminder updated) async {
    if (updated.alertMode == ReminderAlertMode.atTime &&
        updated.scheduledAt == null) {
      throw ArgumentError('Aviso no horário exige data e hora.');
    }
    final index = _reminders.indexWhere((item) => item.id == updated.id);
    if (index < 0) return NotificationDeliveryStatus.inactive;

    if (!_notificationsAvailable) {
      final next = [..._reminders]..[index] = updated;
      await _repository.save(next);
      _reminders[index] = updated;
      _deliveryStatuses[updated.id] = NotificationDeliveryStatus.unavailable;
      notifyListeners();
      return NotificationDeliveryStatus.unavailable;
    }

    final previous = _reminders[index];
    final replaceVisiblePersistent =
        _shouldShowPersistent(previous) && _shouldShowPersistent(updated);
    final previousStatus = _deliveryStatuses[previous.id];
    final notificationUnchanged = replaceVisiblePersistent &&
        previousStatus != NotificationDeliveryStatus.permissionDenied &&
        previousStatus != NotificationDeliveryStatus.unavailable &&
        previous.alertMode == updated.alertMode &&
        previous.scheduledAt == updated.scheduledAt &&
        previous.title == updated.title &&
        previous.notes == updated.notes &&
        previous.visualStyle == updated.visualStyle &&
        previous.accent == updated.accent &&
        previous.symbol == updated.symbol;
    final shouldSchedule = _shouldShowPersistent(updated) ||
        (updated.alertMode == ReminderAlertMode.atTime &&
            !updated.isCompleted &&
            (updated.scheduledAt?.isAfter(DateTime.now()) ?? false));
    final permitted = notificationUnchanged ||
        !shouldSchedule ||
        await _notificationService.requestPermission(updated.alertMode);
    if (!notificationUnchanged &&
        !replaceVisiblePersistent &&
        previous.alertMode != ReminderAlertMode.none) {
      await _notificationService.cancel(previous.notificationId);
    }
    var status = NotificationDeliveryStatus.inactive;
    try {
      if (!shouldSchedule) {
        status = NotificationDeliveryStatus.inactive;
      } else if (!permitted) {
        status = NotificationDeliveryStatus.permissionDenied;
      } else if (notificationUnchanged) {
        status = previousStatus ?? NotificationDeliveryStatus.scheduled;
      } else {
        status = await _schedule(updated);
      }
      final next = [..._reminders]..[index] = updated;
      await _repository.save(next);
    } catch (_) {
      if (!notificationUnchanged) {
        try {
          if (!replaceVisiblePersistent) {
            await _notificationService.cancel(updated.notificationId);
          }
          if (_shouldShowPersistent(previous) ||
              (previous.alertMode == ReminderAlertMode.atTime &&
                  !previous.isCompleted &&
                  (previous.scheduledAt?.isAfter(DateTime.now()) ?? false))) {
            await _notificationService.schedule(previous);
          }
        } catch (_) {
          // Preserve the original failure for the caller.
        }
      }
      rethrow;
    }
    _reminders[index] = updated;
    _deliveryStatuses[updated.id] = status;
    notifyListeners();
    return status;
  }

  Future<void> toggleCompleted(Reminder reminder) async {
    await update(
      reminder.copyWith(
        isCompleted: !reminder.isCompleted,
        keepNotificationAfterCompletion: reminder.isPersistent,
      ),
    );
  }

  Future<void> remove(Reminder reminder) async {
    if (_notificationsAvailable &&
        reminder.alertMode != ReminderAlertMode.none) {
      await _notificationService.cancel(reminder.notificationId);
    }
    try {
      await _repository.save(
        _reminders.where((item) => item.id != reminder.id).toList(),
      );
    } catch (_) {
      if (_notificationsAvailable &&
          (_shouldShowPersistent(reminder) ||
              (reminder.alertMode == ReminderAlertMode.atTime &&
                  !reminder.isCompleted &&
                  (reminder.scheduledAt?.isAfter(DateTime.now()) ?? false)))) {
        try {
          await _notificationService.schedule(reminder);
        } catch (_) {
          // Preserve the storage failure for the caller.
        }
      }
      rethrow;
    }
    _reminders.removeWhere((item) => item.id == reminder.id);
    _deliveryStatuses.remove(reminder.id);
    notifyListeners();
  }

  int get remainingToday {
    final now = DateTime.now();
    return active.where((item) {
      final date = item.scheduledAt;
      return date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  int get completedToday {
    final now = DateTime.now();
    return _reminders.where((item) {
      final date = item.scheduledAt;
      return item.isCompleted &&
          date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  double get todayProgress {
    final total = remainingToday + completedToday;
    return total == 0 ? 0 : min(1, completedToday / total);
  }
}
