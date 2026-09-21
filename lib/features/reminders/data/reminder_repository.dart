import '../domain/reminder.dart';

abstract interface class ReminderRepository {
  Future<List<Reminder>> load();
  Future<void> save(List<Reminder> reminders);
}
