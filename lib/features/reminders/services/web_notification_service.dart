import '../domain/reminder.dart';
import 'notification_service.dart';

/// Browser preview: reminders stay local, but no background alerts are sent.
class LocalNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule(Reminder reminder) async {}

  @override
  Future<void> cancel(int notificationId) async {}
}
