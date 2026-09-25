import 'dart:convert';

import 'package:lembretes/features/reminders/data/local_reminder_repository.dart';
import 'package:lembretes/features/reminders/domain/notification_appearance.dart';
import 'package:lembretes/features/reminders/domain/reminder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ignora registro inválido e preserva os lembretes válidos', () async {
    final valid = Reminder(
      id: 'valid',
      notificationId: 1,
      title: 'Lembrar da consulta',
      scheduledAt: DateTime(2030, 5, 1, 10),
      kind: NotificationKind.temporary,
      createdAt: DateTime(2030, 4, 1),
    );
    SharedPreferences.setMockInitialValues({
      'fio.reminders.v1': jsonEncode([
        valid.toJson(),
        {'id': 'broken', 'kind': 'unknown'},
      ]),
    });

    final reminders = await LocalReminderRepository().load();

    expect(reminders, hasLength(1));
    expect(reminders.single.id, 'valid');
  });
  test('dados antigos recebem a aparência original', () async {
    final original = Reminder(
      id: 'old',
      notificationId: 3,
      title: 'Aviso antigo',
      scheduledAt: DateTime(2030, 5, 1, 10),
      kind: NotificationKind.temporary,
      createdAt: DateTime(2030, 4, 1),
    ).toJson()
      ..remove('visualStyle')
      ..remove('accent')
      ..remove('symbol');
    SharedPreferences.setMockInitialValues({
      'fio.reminders.v1': jsonEncode([original]),
    });

    final reminders = await LocalReminderRepository().load();

    expect(reminders, hasLength(1));
    expect(reminders.single.visualStyle, NotificationVisualStyle.expanded);
    expect(reminders.single.accent, NotificationAccent.blue);
    expect(reminders.single.symbol, NotificationSymbol.bell);
  });

  test('preserva a cor amarela ao salvar e reabrir', () async {
    SharedPreferences.setMockInitialValues({});
    final reminder = Reminder(
      id: 'yellow',
      notificationId: 4,
      title: 'Consulta',
      scheduledAt: DateTime(2030, 5, 1, 10),
      kind: NotificationKind.temporary,
      accent: NotificationAccent.yellow,
      createdAt: DateTime(2030, 4, 1),
    );
    final repository = LocalReminderRepository();

    await repository.save([reminder]);
    final restored = await repository.load();

    expect(restored.single.accent, NotificationAccent.yellow);
    expect(restored.single.toJson()['accent'], 'yellow');
  });

  test('restaura lembrete sem horário salvo no dispositivo', () async {
    final unscheduled = Reminder(
      id: 'continuous',
      notificationId: 2,
      title: 'Sempre visível',
      scheduledAt: null,
      kind: NotificationKind.unscheduled,
      createdAt: DateTime(2030, 4, 1),
    );
    SharedPreferences.setMockInitialValues({
      'fio.reminders.v1': jsonEncode([unscheduled.toJson()]),
    });

    final reminders = await LocalReminderRepository().load();

    expect(reminders, hasLength(1));
    expect(reminders.single.scheduledAt, isNull);
    expect(reminders.single.keepNotificationAfterCompletion, isTrue);
  });
}
