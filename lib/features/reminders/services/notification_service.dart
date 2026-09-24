import '../domain/reminder.dart';

abstract interface class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission(NotificationKind kind);
  Future<void> schedule(Reminder reminder);
  Future<void> restorePersistent(Reminder reminder);
  Future<void> cancel(int notificationId);
}
