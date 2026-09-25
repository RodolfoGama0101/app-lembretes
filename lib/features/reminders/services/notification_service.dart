import '../domain/reminder.dart';

enum NotificationDeliveryStatus {
  scheduled,
  approximate,
  permissionDenied,
  unavailable,
  inactive,
}

abstract interface class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission(ReminderAlertMode mode);
  Future<NotificationDeliveryStatus> schedule(Reminder reminder);
  Future<void> restorePersistent(Reminder reminder);
  Future<Map<String, NotificationDeliveryStatus>> reconcile(
      List<Reminder> reminders);
  Future<void> cancel(int notificationId);
}
