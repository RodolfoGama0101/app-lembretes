import 'package:fio_lembretes/features/reminders/data/reminder_repository.dart';
import 'package:fio_lembretes/features/reminders/domain/reminder.dart';
import 'package:fio_lembretes/features/reminders/presentation/reminder_controller.dart';
import 'package:fio_lembretes/features/reminders/services/notification_service.dart';
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
  bool permissionGranted = true;
  bool failNextSchedule = false;

  @override
  Future<void> cancel(int notificationId) async {
    cancelled.add(notificationId);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> schedule(Reminder reminder) async {
    if (failNextSchedule) {
      failNextSchedule = false;
      throw StateError('Agendamento falhou');
    }
    scheduled.add(reminder);
  }
}
