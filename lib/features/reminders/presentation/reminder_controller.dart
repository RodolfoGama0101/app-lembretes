import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/reminder_repository.dart';
import '../domain/reminder.dart';
import '../services/notification_service.dart';

class ReminderController extends ChangeNotifier {
  ReminderController({
    required ReminderRepository repository,
    required NotificationService notificationService,
  }) : _repository = repository,
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

  Future<bool> add({
    required String title,
    required String notes,
    required DateTime scheduledAt,
    required NotificationKind kind,
  }) async {
    final now = DateTime.now();
    final rawId = now.microsecondsSinceEpoch;
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
    _reminders.add(reminder);
    await _repository.save(_reminders);
    if (permitted) await _notificationService.schedule(reminder);
    notifyListeners();
    return permitted;
  }

  Future<void> update(Reminder updated) async {
    final index = _reminders.indexWhere((item) => item.id == updated.id);
    if (index < 0) return;

    await _notificationService.cancel(updated.notificationId);
    _reminders[index] = updated;
    await _repository.save(_reminders);
    if (!updated.isCompleted && updated.scheduledAt.isAfter(DateTime.now())) {
      await _notificationService.schedule(updated);
    }
    notifyListeners();
  }

  Future<void> toggleCompleted(Reminder reminder) async {
    await update(reminder.copyWith(isCompleted: !reminder.isCompleted));
  }

  Future<void> remove(Reminder reminder) async {
    await _notificationService.cancel(reminder.notificationId);
    _reminders.removeWhere((item) => item.id == reminder.id);
    await _repository.save(_reminders);
    notifyListeners();
  }

  int get remainingToday {
    final now = DateTime.now();
    return active.where((item) {
      final date = item.scheduledAt;
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day &&
          date.isAfter(now);
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
