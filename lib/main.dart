import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
import 'features/reminders/data/local_reminder_repository.dart';
import 'features/reminders/presentation/reminder_controller.dart';
import 'features/reminders/services/local_notification_service.dart'
    if (dart.library.js_interop) 'features/reminders/services/web_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('pt_BR');

    final notificationService = LocalNotificationService();
    final controller = ReminderController(
      repository: LocalReminderRepository(),
      notificationService: notificationService,
      notificationsAvailable: false,
    );
    await controller.load();
    await controller.retryNotifications();

    runApp(LembretesApp(controller: controller));
  } catch (error) {
    debugPrint('Falha ao iniciar Lembretes: $error');
    runApp(const _StartupErrorApp());
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lembretes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(title: const Text('Lembretes')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 16),
                const Text(
                  'Não foi possível iniciar o aplicativo Lembretes. Verifique as configurações '
                  'do aparelho e tente novamente.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async => main(),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
