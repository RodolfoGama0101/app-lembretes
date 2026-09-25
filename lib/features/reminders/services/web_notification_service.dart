import '../domain/reminder.dart';
import 'notification_service.dart';

/// Browser preview: reminders stay local, but no background alerts are sent.
class LocalNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission(ReminderAlertMode mode) async => false;

  @override
  Future<NotificationDeliveryStatus> schedule(Reminder reminder) async =>
      NotificationDeliveryStatus.unavailable;

  @override
  Future<void> restorePersistent(Reminder reminder) async {}

  @override
  Future<Map<String, NotificationDeliveryStatus>> reconcile(
          List<Reminder> reminders) async =>
      {
        for (final reminder in reminders)
          reminder.id: NotificationDeliveryStatus.unavailable,
      };

  @override
  Future<void> cancel(int notificationId) async {}
}
