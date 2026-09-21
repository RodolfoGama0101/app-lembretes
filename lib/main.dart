import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'features/reminders/data/local_reminder_repository.dart';
import 'features/reminders/presentation/reminder_controller.dart';
import 'features/reminders/services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');

  final notificationService = LocalNotificationService();
  await notificationService.initialize();

  final controller = ReminderController(
    repository: LocalReminderRepository(),
    notificationService: notificationService,
  );
  await controller.load();

  runApp(FioApp(controller: controller));
}
