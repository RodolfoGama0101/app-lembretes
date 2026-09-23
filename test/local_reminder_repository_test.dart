import 'dart:convert';

import 'package:fio_lembretes/features/reminders/data/local_reminder_repository.dart';
import 'package:fio_lembretes/features/reminders/domain/reminder.dart';
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
}
