import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/reminder_repository.dart';
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
    final sorted = [..._reminders]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return List.unmodifiable(sorted);
  }

  List<Reminder> get active =>
      reminders.where((item) => !item.isCompleted).toList();

  List<Reminder> get completed =>
      reminders.where((item) => item.isCompleted).toList().reversed.toList();

  Reminder? get nextReminder {
    final now = DateTime.now();
    for (final reminder in active) {
      if (reminder.scheduledAt.isAfter(now)) return reminder;
    }
    return null;
  }

  Future<void> load() async {
    _reminders
      ..clear()
      ..addAll(await _repository.load());
    notifyListeners();
  }

  Reminder? get oldestOverdue {
    final now = DateTime.now();
    for (final reminder in active) {
      if (reminder.scheduledAt.isBefore(now)) return reminder;
    }
    return null;
  }

  Future<bool> add({
    required String title,
    required String notes,
    required DateTime scheduledAt,
    required NotificationKind kind,
  }) async {
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
      createdAt: now,
    );

    final permitted = await _notificationService.requestPermission();
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
    final index = _reminders.indexWhere((item) => item.id == updated.id);
    if (index < 0) return true;

    final previous = _reminders[index];
    final shouldSchedule =
        !updated.isCompleted && updated.scheduledAt.isAfter(DateTime.now());
    final permitted =
        !shouldSchedule || await _notificationService.requestPermission();
    await _notificationService.cancel(previous.notificationId);
    try {
      if (shouldSchedule && permitted) {
        await _notificationService.schedule(updated);
      }
      final next = [..._reminders]..[index] = updated;
      await _repository.save(next);
    } catch (_) {
      try {
        await _notificationService.cancel(updated.notificationId);
        if (!previous.isCompleted &&
            previous.scheduledAt.isAfter(DateTime.now())) {
          await _notificationService.schedule(previous);
        }
      } catch (_) {
        // Preserve the original failure for the caller.
      }
      rethrow;
    }
    _reminders[index] = updated;
    notifyListeners();
    return permitted;
  }

  Future<void> toggleCompleted(Reminder reminder) async {
    await update(reminder.copyWith(isCompleted: !reminder.isCompleted));
  }

  Future<void> remove(Reminder reminder) async {
    await _notificationService.cancel(reminder.notificationId);
    try {
      await _repository.save(
        _reminders.where((item) => item.id != reminder.id).toList(),
      );
    } catch (_) {
      if (!reminder.isCompleted &&
          reminder.scheduledAt.isAfter(DateTime.now())) {
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
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  int get completedToday {
    final now = DateTime.now();
    return _reminders.where((item) {
      final date = item.scheduledAt;
      return item.isCompleted &&
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
