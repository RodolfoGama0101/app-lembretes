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

    await tester.pumpWidget(LembretesApp(controller: controller));
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

    await tester.pumpWidget(LembretesApp(controller: controller));
    await tester.tap(find.text('Novo lembrete'));
    await tester.pumpAndSettle();

    expect(find.textContaining(RegExp(r'\d{2}/\d{2}/\d{4}')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Tipo de notificação'),
      180,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
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

    await tester.pumpWidget(LembretesApp(controller: controller));
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

  testWidgets('exclusão na edição exige confirmação', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await initializeDateFormatting('pt_BR');
    final repository = _MemoryRepository()
      ..items = [
        Reminder(
          id: 'edit-delete',
          notificationId: 9,
          title: 'Lembrete editável',
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

    await tester.pumpWidget(LembretesApp(controller: controller));
    await tester.tap(find.text('Lembrete editável').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Excluir lembrete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.items, hasLength(1));

    await tester.tap(find.byTooltip('Excluir lembrete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(repository.items, isEmpty);
    expect(find.text('Nenhum lembrete'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('sem horário oculta data e salva aviso permanente',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await initializeDateFormatting('pt_BR');
    final repository = _MemoryRepository();
    final notifications = _FakeNotificationService();
    final controller = ReminderController(
      repository: repository,
      notificationService: notifications,
    );
    await controller.load();

    await tester.pumpWidget(LembretesApp(controller: controller));
    await tester.tap(find.text('Novo lembrete'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Sem prazo');
    await tester.tap(find.text('Sem horário'));
    await tester.pumpAndSettle();

    expect(find.textContaining(RegExp(r'\d{2}/\d{2}/\d{4}')), findsNothing);
    expect(find.text('Tipo de notificação'), findsNothing);
    await tester.tap(find.text('Salvar lembrete'));
    await tester.pumpAndSettle();

    expect(repository.items.single.kind, NotificationKind.unscheduled);
    expect(repository.items.single.scheduledAt, isNull);
    expect(repository.items.single.keepNotificationAfterCompletion, isTrue);
    expect(find.text('Sem horário'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
