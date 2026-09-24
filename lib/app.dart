import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/reminders/presentation/home_screen.dart';
import 'features/reminders/presentation/reminder_controller.dart';

class LembretesApp extends StatelessWidget {
  const LembretesApp({super.key, required this.controller});

  final ReminderController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lembretes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: HomeScreen(controller: controller),
    );
  }
}
