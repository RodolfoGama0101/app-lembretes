import 'package:fio_lembretes/app.dart';
import 'package:fio_lembretes/features/reminders/data/reminder_repository.dart';
import 'package:fio_lembretes/features/reminders/domain/reminder.dart';
import 'package:fio_lembretes/features/reminders/presentation/reminder_controller.dart';
import 'package:fio_lembretes/features/reminders/services/notification_service.dart';
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
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(Reminder reminder) async {}
}
