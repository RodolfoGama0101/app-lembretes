import 'package:lembretes/features/reminders/data/reminder_repository.dart';
import 'package:lembretes/features/reminders/domain/notification_appearance.dart';
import 'package:lembretes/features/reminders/domain/reminder.dart';
import 'package:lembretes/features/reminders/presentation/reminder_controller.dart';
import 'package:lembretes/features/reminders/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adiciona, agenda e persiste um lembrete', () async {
    final repository = _MemoryRepository();
    final notifications = _FakeNotificationService();
    final controller = ReminderController(
      repository: repository,
      notificationService: notifications,
    );

    await controller.add(
      title: '  Ligar para o médico  ',
      notes: 'Confirmar o horário',
      scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      kind: NotificationKind.persistent,
    );

    expect(controller.active, hasLength(1));
    expect(controller.active.single.title, 'Ligar para o médico');
    expect(repository.items, hasLength(1));
    expect(notifications.scheduled, hasLength(1));
    expect(repository.items.single.keepNotificationAfterCompletion, isTrue);
    expect(repository.items.single.accent, NotificationAccent.red);
  });

  test('salva aparência e republica ao editar apenas o visual', () async {
    final notifications = _FakeNotificationService();
    final controller = ReminderController(
      repository: _MemoryRepository(),
      notificationService: notifications,
    );
    await controller.add(
      title: 'Aviso colorido',
      notes: 'Detalhes',
      scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      kind: NotificationKind.persistent,
      visualStyle: NotificationVisualStyle.compact,
      accent: NotificationAccent.green,
      symbol: NotificationSymbol.star,
    );
    final reminder = controller.active.single;
    expect(reminder.visualStyle, NotificationVisualStyle.compact);
    expect(reminder.accent, NotificationAccent.green);
    expect(reminder.symbol, NotificationSymbol.star);
    expect(
        Reminder.fromJson(reminder.toJson()).symbol, NotificationSymbol.star);

    await controller
        .update(reminder.copyWith(accent: NotificationAccent.purple));

    expect(notifications.scheduled, hasLength(2));
    expect(notifications.scheduled.last.accent, NotificationAccent.purple);
  });

  test('concluir cancela a notificação e move o item', () async {
    final repository = _MemoryRepository();
    final notifications = _FakeNotificationService();
    final controller = ReminderController(
      repository: repository,
      notificationService: notifications,
    );
    await controller.add(
      title: 'Separar documentos',
      notes: '',
      scheduledAt: DateTime.now().add(const Duration(days: 1)),
      kind: NotificationKind.temporary,
    );

    await controller.toggleCompleted(controller.active.single);

    expect(controller.active, isEmpty);
    expect(controller.completed, hasLength(1));
    expect(notifications.cancelled, hasLength(1));
  });

  test('falha ao agendar não salva um lembrete sem aviso', () async {
    final repository = _MemoryRepository();
    final notifications = _FakeNotificationService()..failNextSchedule = true;
    final controller = ReminderController(
      repository: repository,
      notificationService: notifications,
    );

    await expectLater(
      controller.add(
        title: 'Enviar documento',
        notes: '',
        scheduledAt: DateTime.now().add(const Duration(hours: 1)),
        kind: NotificationKind.temporary,
      ),
      throwsStateError,
    );

    expect(controller.active, isEmpty);
    expect(repository.items, isEmpty);
  });

  test('permissão negada mantém o lembrete e informa a ausência do alerta',
      () async {
    final repository = _MemoryRepository();
    final notifications = _FakeNotificationService()..permissionGranted = false;
    final controller = ReminderController(
      repository: repository,
      notificationService: notifications,
    );

    final permitted = await controller.add(
      title: 'Enviar documento',
      notes: '',
      scheduledAt: DateTime.now().add(const Duration(hours: 1)),
      kind: NotificationKind.temporary,
    );

    expect(permitted, isFalse);
    expect(repository.items, hasLength(1));
    expect(notifications.scheduled, isEmpty);
  });

  test('falha na edição conserva o lembrete anterior', () async {
    final repository = _MemoryRepository();
    final notifications = _FakeNotificationService();
    final controller = ReminderController(
      repository: repository,
      notificationService: notifications,
    );
    await controller.add(
      title: 'Título original',
      notes: '',
      scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      kind: NotificationKind.temporary,
    );
    final original = controller.active.single;
    notifications.failNextSchedule = true;

    await expectLater(
      controller.update(original.copyWith(title: 'Título novo')),
      throwsStateError,
    );

    expect(controller.active.single.title, 'Título original');
    expect(repository.items.single.title, 'Título original');
    expect(notifications.scheduled.last.title, 'Título original');
  });

  test('restaura notificações permanentes ativas ao abrir o app', () async {
    final now = DateTime.now();
    final repository = _MemoryRepository()
      ..items = [
        Reminder(
          id: 'permanent',
          notificationId: 1,
          title: 'Visível agora',
          scheduledAt: now.subtract(const Duration(hours: 1)),
          kind: NotificationKind.persistent,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        Reminder(
          id: 'temporary',
          notificationId: 2,
          title: 'Somente no horário',
          scheduledAt: now.add(const Duration(hours: 1)),
          kind: NotificationKind.temporary,
          createdAt: now,
        ),
        Reminder(
          id: 'done',
          notificationId: 3,
          title: 'Já concluído',
          scheduledAt: now,
          kind: NotificationKind.persistent,
          isCompleted: true,
          createdAt: now,
        ),
      ];
    final notifications = _FakeNotificationService();
    final controller = ReminderController(
      repository: repository,
      notificationService: notifications,
    );

    await controller.load();

    expect(notifications.restored.map((item) => item.id), ['permanent']);
  });

  test('concluir um permanente não remove a notificação até excluí-lo',
      () async {
    final repository = _MemoryRepository();
    final notifications = _FakeNotificationService();
    final controller = ReminderController(
      repository: repository,
      notificationService: notifications,
    );
    await controller.add(
      title: 'Verificar tarefa',
      notes: '',
      scheduledAt: DateTime.now().add(const Duration(hours: 1)),
      kind: NotificationKind.persistent,
    );
    final original = controller.active.single;
    final overdue = original.copyWith(
      scheduledAt: DateTime.now().subtract(const Duration(hours: 1)),
    );

    await controller.update(overdue);
    await controller.toggleCompleted(controller.active.single);
    await controller.toggleCompleted(controller.completed.single);

    expect(notifications.scheduled, hasLength(2));
    expect(notifications.cancelled, isEmpty);
    expect(controller.active, hasLength(1));

    await controller.toggleCompleted(controller.active.single);
    expect(repository.items.single.keepNotificationAfterCompletion, isTrue);
    await controller.load();
    expect(notifications.restored.single.id, original.id);

    await controller.remove(controller.completed.single);
    expect(notifications.cancelled, [original.notificationId]);
    expect(controller.reminders, isEmpty);
  });

  test('excluir um permanente vencido remove a notificação', () async {
    final notifications = _FakeNotificationService();
    final controller = ReminderController(
      repository: _MemoryRepository(),
      notificationService: notifications,
    );
    await controller.add(
      title: 'Apagar',
      notes: '',
      scheduledAt: DateTime.now().add(const Duration(hours: 1)),
      kind: NotificationKind.persistent,
    );

    await controller.remove(controller.active.single);

    expect(notifications.cancelled, hasLength(1));
    expect(controller.reminders, isEmpty);
  });

  test('lembrete atrasado continua pendente hoje', () async {
    final now = DateTime.now();
    final repository = _MemoryRepository()
      ..items = [
        Reminder(
          id: 'late',
          notificationId: 7,
          title: 'Tarefa atrasada',
          scheduledAt: DateTime(now.year, now.month, now.day),
          kind: NotificationKind.temporary,
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
      ];
    final controller = ReminderController(
      repository: repository,
      notificationService: _FakeNotificationService(),
    );
    await controller.load();

    expect(controller.oldestOverdue?.title, 'Tarefa atrasada');
    expect(controller.remainingToday, 1);
    expect(controller.todayProgress, 0);
  });

  test('abre e edita lembretes enquanto alertas estão indisponíveis', () async {
    final now = DateTime.now();
    final repository = _MemoryRepository()
      ..items = [
        Reminder(
          id: 'offline',
          notificationId: 17,
          title: 'Título original',
          scheduledAt: now.add(const Duration(days: 1)),
          kind: NotificationKind.temporary,
          createdAt: now,
        ),
      ];
    final notifications = _FakeNotificationService()..failInitialize = true;
    final controller = ReminderController(
      repository: repository,
      notificationService: notifications,
      notificationsAvailable: false,
    );

    await controller.load();
    expect(controller.active.single.title, 'Título original');
    expect(await controller.retryNotifications(), isFalse);
    expect(controller.notificationsAvailable, isFalse);
    expect(controller.notificationFailure, NotificationFailure.initialization);

    final updated = controller.active.single.copyWith(title: 'Título alterado');
    expect(await controller.update(updated), isFalse);
    expect(repository.items.single.title, 'Título alterado');
    expect(notifications.scheduled, isEmpty);

    notifications.failInitialize = false;
    expect(await controller.retryNotifications(), isTrue);
    expect(controller.notificationsAvailable, isTrue);
    expect(notifications.reconciled.single.title, 'Título alterado');
  });

  test('falha de reconciliação mantém a lista acessível', () async {
    final now = DateTime.now();
    final repository = _MemoryRepository()
      ..items = [
        Reminder(
          id: 'restore-fail',
          notificationId: 19,
          title: 'Consulta',
          scheduledAt: now.add(const Duration(days: 1)),
          kind: NotificationKind.temporary,
          createdAt: now,
        ),
      ];
    final notifications = _FakeNotificationService()..failReconcile = true;
    final controller = ReminderController(
      repository: repository,
      notificationService: notifications,
      notificationsAvailable: false,
    );

    await controller.load();
    expect(await controller.retryNotifications(), isFalse);
    expect(controller.notificationFailure, NotificationFailure.restoration);
    expect(controller.active.single.title, 'Consulta');

    notifications.failReconcile = false;
    expect(await controller.retryNotifications(), isTrue);
    expect(controller.notificationFailure, isNull);
  });

  test('serialização preserva o tipo de notificação', () {
    final original = Reminder(
      id: '1',
      notificationId: 10,
      title: 'Revisar lista',
      notes: '',
      scheduledAt: DateTime(2030, 4, 3, 9, 30),
      kind: NotificationKind.persistent,
      createdAt: DateTime(2030, 4, 1),
    );

    final restored = Reminder.fromJson(original.toJson());

    expect(restored.title, original.title);
    expect(restored.kind, NotificationKind.persistent);
    expect(restored.scheduledAt, original.scheduledAt);
    expect(restored.keepNotificationAfterCompletion, isFalse);
  });

  test('serialização preserva permanência após conclusão', () {
    final reminder = Reminder(
      id: '2',
      notificationId: 11,
      title: 'Até excluir',
      scheduledAt: DateTime(2030, 4, 3, 9, 30),
      kind: NotificationKind.persistent,
      isCompleted: true,
      keepNotificationAfterCompletion: true,
      createdAt: DateTime(2030, 4, 1),
    );

    final restored = Reminder.fromJson(reminder.toJson());

    expect(restored.keepNotificationAfterCompletion, isTrue);
    expect(restored.isCompleted, isTrue);
  });
  test('sem horário publica aviso permanente e o mantém até excluir', () async {
    final repository = _MemoryRepository();
    final notifications = _FakeNotificationService();
    final controller = ReminderController(
      repository: repository,
      notificationService: notifications,
    );

    await controller.add(
      title: 'Lembrete contínuo',
      notes: '',
      scheduledAt: null,
      kind: NotificationKind.unscheduled,
    );

    final reminder = controller.active.single;
    expect(reminder.scheduledAt, isNull);
    expect(reminder.isPersistent, isTrue);
    expect(reminder.keepNotificationAfterCompletion, isTrue);
    expect(notifications.scheduled.single.id, reminder.id);
    expect(controller.nextReminder, isNull);
    expect(controller.oldestOverdue, isNull);
    expect(controller.remainingToday, 0);

    await controller.toggleCompleted(reminder);
    expect(notifications.cancelled, isEmpty);
    await controller.load();
    expect(notifications.restored.single.id, reminder.id);

    await controller.remove(controller.completed.single);
    expect(notifications.cancelled, [reminder.notificationId]);
    expect(repository.items, isEmpty);
  });

  test('alternar entre com e sem horário atualiza a notificação', () async {
    final notifications = _FakeNotificationService();
    final controller = ReminderController(
      repository: _MemoryRepository(),
      notificationService: notifications,
    );
    await controller.add(
      title: 'Trocar tipo',
      notes: '',
      scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      kind: NotificationKind.temporary,
    );
    final timed = controller.active.single;

    await controller.update(timed.copyWith(kind: NotificationKind.unscheduled));
    expect(controller.active.single.scheduledAt, isNull);
    expect(notifications.cancelled, [timed.notificationId]);
    expect(notifications.scheduled.last.kind, NotificationKind.unscheduled);

    await controller.update(controller.active.single.copyWith(
      kind: NotificationKind.temporary,
      scheduledAt: DateTime.now().add(const Duration(days: 1)),
      keepNotificationAfterCompletion: false,
    ));
    expect(controller.active.single.scheduledAt, isNotNull);
    expect(notifications.cancelled, hasLength(2));
    expect(notifications.scheduled.last.kind, NotificationKind.temporary);
  });

  test('serialização de lembrete sem horário preserva a permanência', () {
    final original = Reminder(
      id: 'no-time',
      notificationId: 42,
      title: 'Sempre visível',
      scheduledAt: null,
      kind: NotificationKind.unscheduled,
      createdAt: DateTime(2030, 4, 1),
    );

    final restored = Reminder.fromJson(original.toJson());

    expect(restored.scheduledAt, isNull);
    expect(restored.kind, NotificationKind.unscheduled);
    expect(restored.keepNotificationAfterCompletion, isTrue);
  });
}

class _MemoryRepository implements ReminderRepository {
  List<Reminder> items = [];

  @override
  Future<List<Reminder>> load() async => [...items];

  @override
  Future<void> save(List<Reminder> reminders) async {
    items = [...reminders];
  }
}

class _FakeNotificationService implements NotificationService {
  final List<Reminder> scheduled = [];
  final List<int> cancelled = [];
  final List<Reminder> restored = [];
  bool permissionGranted = true;
  bool failNextSchedule = false;
  bool failInitialize = false;
  bool failReconcile = false;
  final List<Reminder> reconciled = [];

  @override
  Future<void> cancel(int notificationId) async {
    cancelled.add(notificationId);
  }

  @override
  Future<void> initialize() async {
    if (failInitialize) throw StateError('Serviço indisponível');
  }

  @override
  Future<void> reconcile(List<Reminder> reminders) async {
    if (failReconcile) throw StateError('Restauração indisponível');
    reconciled
      ..clear()
      ..addAll(reminders);
  }

  @override
  Future<bool> requestPermission(NotificationKind kind) async =>
      permissionGranted;

  @override
  Future<void> restorePersistent(Reminder reminder) async {
    restored.add(reminder);
  }

  @override
  Future<void> schedule(Reminder reminder) async {
    if (failNextSchedule) {
      failNextSchedule = false;
      throw StateError('Agendamento falhou');
    }
    scheduled.add(reminder);
  }
}
