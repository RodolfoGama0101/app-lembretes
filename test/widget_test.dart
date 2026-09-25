import 'package:lembretes/app.dart';
import 'package:lembretes/features/reminders/data/reminder_repository.dart';
import 'package:lembretes/features/reminders/domain/notification_appearance.dart';
import 'package:lembretes/features/reminders/domain/reminder.dart';
import 'package:lembretes/features/reminders/presentation/reminder_controller.dart';
import 'package:lembretes/features/reminders/services/notification_service.dart';
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

  testWidgets('mostra dados e permite tentar alertas novamente',
      (tester) async {
    await initializeDateFormatting('pt_BR');
    final repository = _MemoryRepository()
      ..items = [
        Reminder(
          id: 'saved',
          notificationId: 22,
          title: 'Dado salvo',
          scheduledAt: DateTime.now().add(const Duration(days: 1)),
          kind: NotificationKind.temporary,
          createdAt: DateTime.now(),
        ),
      ];
    final notifications = _FakeNotificationService()..failInitialize = true;
    final controller = ReminderController(
      repository: repository,
      notificationService: notifications,
      notificationsAvailable: false,
    );
    await controller.load();
    await controller.retryNotifications();

    await tester.pumpWidget(LembretesApp(controller: controller));
    expect(find.text('Dado salvo'), findsWidgets);
    expect(find.textContaining('Não foi possível iniciar os avisos'),
        findsOneWidget);

    notifications.failInitialize = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(controller.notificationsAvailable, isTrue);
    expect(find.textContaining('Não foi possível iniciar os avisos'),
        findsNothing);
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

    final date = find.textContaining(RegExp(r'\d{2}/\d{2}/\d{4}'));
    await tester.scrollUntilVisible(
      date,
      180,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(date, findsOneWidget);
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

  testWidgets('formulário salva estilo, cor e ícone escolhidos',
      (tester) async {
    await initializeDateFormatting('pt_BR');
    final repository = _MemoryRepository();
    final controller = ReminderController(
      repository: repository,
      notificationService: _FakeNotificationService(),
    );
    await controller.load();
    await tester.pumpWidget(LembretesApp(controller: controller));
    await tester.tap(find.text('Novo lembrete'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Personalizado');

    for (final label in ['Compacto', 'Amarelo', 'Estrela']) {
      await tester.scrollUntilVisible(
        find.text(label),
        180,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Salvar lembrete'));
    await tester.pumpAndSettle();

    expect(
        repository.items.single.visualStyle, NotificationVisualStyle.compact);
    expect(repository.items.single.accent, NotificationAccent.yellow);
    expect(repository.items.single.symbol, NotificationSymbol.star);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edita texto de lembrete atrasado sem reagendar', (tester) async {
    await initializeDateFormatting('pt_BR');
    final originalDate = DateTime.now().subtract(const Duration(days: 1));
    final repository = _MemoryRepository()
      ..items = [
        Reminder(
          id: 'overdue-edit',
          notificationId: 31,
          title: 'Texto antigo',
          scheduledAt: originalDate,
          kind: NotificationKind.temporary,
          createdAt: originalDate,
        ),
      ];
    final controller = ReminderController(
      repository: repository,
      notificationService: _FakeNotificationService(),
    );
    await controller.load();

    await tester.pumpWidget(LembretesApp(controller: controller));
    await tester.tap(find.text('Texto antigo').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).first, 'Texto atualizado');
    await tester.tap(find.text('Salvar lembrete'));
    await tester.pumpAndSettle();

    expect(repository.items.single.title, 'Texto atualizado');
    expect(repository.items.single.scheduledAt, originalDate);
    expect(find.text('Escolha um horário futuro.'), findsNothing);

    await tester.tap(find.text('Texto atualizado').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Data'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    if (tomorrow.month != now.month) {
      await tester.tap(find.byTooltip('Próximo mês'));
      await tester.pumpAndSettle();
    }
    await tester.tap(
      find
          .descendant(
            of: find.byType(CalendarDatePicker),
            matching: find.text(tomorrow.day.toString()),
          )
          .last,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar lembrete'));
    await tester.pumpAndSettle();

    expect(repository.items.single.scheduledAt!.year, tomorrow.year);
    expect(repository.items.single.scheduledAt!.month, tomorrow.month);
    expect(repository.items.single.scheduledAt!.day, tomorrow.day);
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
  bool failInitialize = false;

  @override
  Future<void> cancel(int notificationId) async {}

  @override
  Future<void> initialize() async {
    if (failInitialize) throw StateError('Serviço indisponível');
  }

  @override
  Future<void> reconcile(List<Reminder> reminders) async {}

  @override
  Future<bool> requestPermission(NotificationKind kind) async => true;

  @override
  Future<void> schedule(Reminder reminder) async {}

  @override
  Future<void> restorePersistent(Reminder reminder) async {}
}
