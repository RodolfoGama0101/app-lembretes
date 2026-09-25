import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/reminder_repository.dart';
import '../domain/notification_appearance.dart';
import '../domain/reminder.dart';
import '../services/notification_service.dart';

class ReminderController extends ChangeNotifier {
  ReminderController({
    required ReminderRepository repository,
    required NotificationService notificationService,
  })  : _repository = repository,
        _notificationService = notificationService;

  final ReminderRepository _repository;
  final NotificationService _notificationService;
  final List<Reminder> _reminders = [];

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
    await restorePersistentNotifications();
    notifyListeners();
  }

  Future<void> restorePersistentNotifications() async {
    for (final reminder in _reminders) {
      if (_shouldShowPersistent(reminder)) {
        try {
          await _notificationService.restorePersistent(reminder);
        } catch (_) {
          // A notification failure must not prevent access to saved reminders.
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

  Future<bool> add({
    required String title,
    required String notes,
    required DateTime? scheduledAt,
    required NotificationKind kind,
    NotificationVisualStyle visualStyle = NotificationVisualStyle.expanded,
    NotificationAccent accent = NotificationAccent.blue,
    NotificationSymbol symbol = NotificationSymbol.bell,
  }) async {
    if ((kind == NotificationKind.unscheduled) != (scheduledAt == null)) {
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
      kind: kind,
      visualStyle: visualStyle,
      accent: accent,
      symbol: symbol,
      keepNotificationAfterCompletion: kind != NotificationKind.temporary,
      createdAt: now,
    );

    final permitted = await _notificationService.requestPermission(kind);
    if (permitted) await _notificationService.schedule(reminder);
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
    notifyListeners();
    return permitted;
  }

  Future<bool> update(Reminder updated) async {
    if ((updated.kind == NotificationKind.unscheduled) !=
        (updated.scheduledAt == null)) {
      throw ArgumentError('O tipo e o horário do lembrete não correspondem.');
    }
    final index = _reminders.indexWhere((item) => item.id == updated.id);
    if (index < 0) return true;

    final previous = _reminders[index];
    final replaceVisiblePersistent =
        _shouldShowPersistent(previous) && _shouldShowPersistent(updated);
    final notificationUnchanged = replaceVisiblePersistent &&
        previous.kind == updated.kind &&
        previous.scheduledAt == updated.scheduledAt &&
        previous.title == updated.title &&
        previous.notes == updated.notes &&
        previous.visualStyle == updated.visualStyle &&
        previous.accent == updated.accent &&
        previous.symbol == updated.symbol;
    final shouldSchedule = _shouldShowPersistent(updated) ||
        (updated.kind == NotificationKind.temporary &&
            !updated.isCompleted &&
            (updated.scheduledAt?.isAfter(DateTime.now()) ?? false));
    final permitted = notificationUnchanged ||
        !shouldSchedule ||
        await _notificationService.requestPermission(updated.kind);
    if (!notificationUnchanged && !replaceVisiblePersistent) {
      await _notificationService.cancel(previous.notificationId);
    }
    try {
      if (!notificationUnchanged && shouldSchedule && permitted) {
        await _notificationService.schedule(updated);
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
              (previous.kind == NotificationKind.temporary &&
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
    notifyListeners();
    return permitted;
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
    await _notificationService.cancel(reminder.notificationId);
    try {
      await _repository.save(
        _reminders.where((item) => item.id != reminder.id).toList(),
      );
    } catch (_) {
      if (_shouldShowPersistent(reminder) ||
          (reminder.kind == NotificationKind.temporary &&
              !reminder.isCompleted &&
              (reminder.scheduledAt?.isAfter(DateTime.now()) ?? false))) {
        try {
          await _notificationService.schedule(reminder);
        } catch (_) {
          // Preserve the storage failure for the caller.
        }
      }
      rethrow;
    }
    _reminders.removeWhere((item) => item.id == reminder.id);
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
