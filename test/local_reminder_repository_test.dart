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

  test('migra os quatro tipos antigos e conserva tarefas datadas sem aviso',
      () async {
    final date = DateTime(2030, 5, 1, 10);
    Map<String, Object?> oldRecord(String id, String kind, DateTime? when) {
      final json = Reminder(
        id: id,
        notificationId: id.hashCode,
        title: id,
        scheduledAt: when,
        alertMode:
            when == null ? ReminderAlertMode.none : ReminderAlertMode.atTime,
        createdAt: DateTime(2030, 4, 1),
      ).toJson();
      json.remove('alertMode');
      json['kind'] = kind;
      return json;
    }

    SharedPreferences.setMockInitialValues({
      'fio.reminders.v1': jsonEncode([
        oldRecord('temp', 'temporary', date),
        oldRecord('pinned', 'persistent', date),
        oldRecord('undated-pinned', 'unscheduled', null),
        oldRecord('inbox', 'inbox', null),
      ]),
    });
    final repository = LocalReminderRepository();
    final loaded = await repository.load();
    expect(loaded.map((item) => item.alertMode), [
      ReminderAlertMode.atTime,
      ReminderAlertMode.pinned,
      ReminderAlertMode.pinned,
      ReminderAlertMode.none,
    ]);
    expect(loaded.map((item) => item.scheduledAt), [date, date, null, null]);
    await repository.save([
      ...loaded,
      Reminder(
        id: 'dated-no-alert',
        notificationId: 44,
        title: 'Sem alerta',
        scheduledAt: date,
        alertMode: ReminderAlertMode.none,
        createdAt: DateTime(2030, 4, 1),
      ),
    ]);
    final restored = await repository.load();
    expect(restored, hasLength(5));
    expect(restored.last.scheduledAt, date);
    expect(restored.last.alertMode, ReminderAlertMode.none);
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

  test('mantém aviso antigo e item novo sem notificação na mesma lista',
      () async {
    final pinned = Reminder(
      id: 'legacy',
      notificationId: 7,
      title: 'Aviso antigo',
      scheduledAt: null,
      kind: NotificationKind.unscheduled,
      createdAt: DateTime(2030, 4, 1),
    );
    final inbox = Reminder(
      id: 'inbox',
      notificationId: 8,
      title: 'Ideia sem data',
      scheduledAt: null,
      kind: NotificationKind.inbox,
      createdAt: DateTime(2030, 4, 2),
    );
    SharedPreferences.setMockInitialValues({
      'fio.reminders.v1': jsonEncode([pinned.toJson(), inbox.toJson()]),
    });

    final reminders = await LocalReminderRepository().load();

    expect(reminders, hasLength(2));
    expect(reminders.first.kind, NotificationKind.unscheduled);
    expect(reminders.first.isPersistent, isTrue);
    expect(reminders.last.kind, NotificationKind.inbox);
    expect(reminders.last.isPersistent, isFalse);
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
