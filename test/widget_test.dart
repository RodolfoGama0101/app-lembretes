import 'package:fio_lembretes/app.dart';
import 'package:fio_lembretes/features/reminders/data/reminder_repository.dart';
import 'package:fio_lembretes/features/reminders/domain/reminder.dart';
import 'package:fio_lembretes/features/reminders/presentation/reminder_controller.dart';
import 'package:fio_lembretes/features/reminders/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mostra o estado vazio e abre o formulário', (tester) async {
    await initializeDateFormatting('pt_BR');
    final controller = ReminderController(
      repository: _MemoryRepository(),
      notificationService: _FakeNotificationService(),
    );
    await controller.load();

    await tester.pumpWidget(FioApp(controller: controller));
    expect(find.text('Nenhum lembrete'), findsOneWidget);

    await tester.tap(find.text('Novo lembrete'));
    await tester.pumpAndSettle();
    expect(find.text('O que lembrar?'), findsOneWidget);
    expect(find.text('Tipo de notificação'), findsOneWidget);
  });

  testWidgets('formulário compacto mantém a data legível e a opção selecionada',
      (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await initializeDateFormatting('pt_BR');
    final controller = ReminderController(
      repository: _MemoryRepository(),
      notificationService: _FakeNotificationService(),
    );
    await controller.load();

    await tester.pumpWidget(FioApp(controller: controller));
    await tester.tap(find.text('Novo lembrete'));
    await tester.pumpAndSettle();

    expect(find.textContaining(RegExp(r'\d{2}/\d{2}/\d{4}')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.selected == true,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu visível permite excluir com confirmação', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await initializeDateFormatting('pt_BR');
    final repository = _MemoryRepository()
      ..items = [
        Reminder(
          id: 'one',
          notificationId: 1,
          title: 'Lembrete para excluir',
          scheduledAt: DateTime.now().add(const Duration(hours: 2)),
          kind: NotificationKind.temporary,
          createdAt: DateTime.now(),
        ),
      ];
    final controller = ReminderController(
      repository: repository,
      notificationService: _FakeNotificationService(),
    );
    await controller.load();

    await tester.pumpWidget(FioApp(controller: controller));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Mais opções para Lembrete para excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir lembrete?'), findsOneWidget);

    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();
    expect(repository.items, isEmpty);
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
  @override
  Future<void> cancel(int notificationId) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission(NotificationKind kind) async => true;

  @override
  Future<void> schedule(Reminder reminder) async {}

  @override
  Future<void> restorePersistent(Reminder reminder) async {}
}
