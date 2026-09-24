import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/reminder.dart';
import 'reminder_controller.dart';
import 'reminder_form_screen.dart';
import 'widgets/delete_reminder_dialog.dart';
import 'widgets/reminder_list_item.dart';

enum _HomeList { active, completed }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final ReminderController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  _HomeList _selectedList = _HomeList.active;
  late final Timer _clock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _clock.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.controller.restorePersistentNotifications());
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível alterar o lembrete.')),
      );
    }
  }

  Future<void> _openForm([Reminder? reminder]) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ReminderFormScreen(
          controller: widget.controller,
          reminder: reminder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final items = _selectedList == _HomeList.active
            ? widget.controller.active
            : widget.controller.completed;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _Header(controller: widget.controller),
                if (kIsWeb)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Nesta versão Web, os lembretes ficam neste navegador. Notificações não são enviadas.',
                    ),
                  ),
                _ListSelector(
                  selected: _selectedList,
                  activeCount: widget.controller.active.length,
                  completedCount: widget.controller.completed.length,
                  onChanged: (value) => setState(() => _selectedList = value),
                ),
                Expanded(
                  child: items.isEmpty
                      ? _EmptyState(list: _selectedList)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final reminder = items[index];
                            final showDate = index == 0 ||
                                !_sameDay(
                                  items[index - 1].scheduledAt,
                                  reminder.scheduledAt,
                                );
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showDate)
                                  _DateDivider(date: reminder.scheduledAt),
                                ReminderListItem(
                                  reminder: reminder,
                                  onToggle: () => _runAction(
                                    () => widget.controller
                                        .toggleCompleted(reminder),
                                  ),
                                  onTap: reminder.isCompleted
                                      ? null
                                      : () => _openForm(reminder),
                                  onDelete: () => _confirmDelete(reminder),
                                ),
                                const SizedBox(height: 10),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openForm,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Novo lembrete'),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(Reminder reminder) async {
    if (await showDeleteReminderDialog(context, reminder)) {
      await _runAction(() => widget.controller.remove(reminder));
    }
  }

  bool _sameDay(DateTime? a, DateTime? b) => a == null || b == null
      ? a == null && b == null
      : a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});
  final ReminderController controller;

  @override
  Widget build(BuildContext context) {
    final overdue = controller.oldestOverdue;
    final next = overdue ?? controller.nextReminder;
    final timeless = controller.active.where((item) => item.isUnscheduled);
    final pinned = timeless.isEmpty ? null : timeless.first;
    final featured = next ?? pinned;
    final now = DateTime.now();
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final compact = MediaQuery.sizeOf(context).height < 600;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(now),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text('Lembretes', style: theme.textTheme.displayLarge),
          if (!compact) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 15, 18, 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .11),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      overdue != null
                          ? Icons.notifications_active_rounded
                          : pinned != null && next == null
                              ? Icons.push_pin_rounded
                              : Icons.notifications_rounded,
                      color: accent,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overdue != null
                              ? 'Lembrete atrasado'
                              : next != null
                                  ? 'Próximo lembrete'
                                  : pinned != null
                                      ? 'Sem horário • permanente'
                                      : 'Tudo em dia',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          featured?.title ?? 'Nenhum lembrete futuro',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  if (next != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      DateFormat(overdue == null ? 'HH:mm' : 'dd/MM')
                          .format(next.scheduledAt!),
                      style:
                          theme.textTheme.titleLarge?.copyWith(color: accent),
                    ),
                  ],
                ],
              ),
            ),
            if (controller.completedToday + controller.remainingToday > 0) ...[
              const SizedBox(height: 12),
              Semantics(
                label: 'Progresso dos lembretes de hoje',
                value: '${controller.completedToday} concluídos de '
                    '${controller.completedToday + controller.remainingToday}',
                child: LinearProgressIndicator(
                  value: controller.todayProgress,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                controller.remainingToday == 0
                    ? 'Nada pendente para hoje'
                    : controller.remainingToday.toString() +
                        (controller.remainingToday == 1
                            ? ' item restante hoje'
                            : ' itens restantes hoje'),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ListSelector extends StatelessWidget {
  const _ListSelector({
    required this.selected,
    required this.activeCount,
    required this.completedCount,
    required this.onChanged,
  });
  final _HomeList selected;
  final int activeCount;
  final int completedCount;
  final ValueChanged<_HomeList> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 2),
      child: Row(
        children: [
          Expanded(
            child: _SelectorButton(
              label: 'Pendentes',
              count: activeCount,
              selected: selected == _HomeList.active,
              onTap: () => onChanged(_HomeList.active),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SelectorButton(
              label: 'Concluídos',
              count: completedCount,
              selected: selected == _HomeList.completed,
              onTap: () => onChanged(_HomeList.completed),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorButton extends StatelessWidget {
  const _SelectorButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? theme.colorScheme.primary : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Text(
              '$label $count',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: selected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target =
        date == null ? null : DateTime(date!.year, date!.month, date!.day);
    final difference = target?.difference(today).inDays;
    final label = switch (difference) {
      null => 'Sem horário',
      0 => 'Hoje',
      1 => 'Amanhã',
      -1 => 'Ontem',
      _ => DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(date!),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 19, 4, 11),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.list});
  final _HomeList list;

  @override
  Widget build(BuildContext context) {
    final completed = list == _HomeList.completed;
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  completed
                      ? Icons.task_alt_rounded
                      : Icons.notifications_none_rounded,
                  size: 34,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                completed ? 'Nenhum item concluído' : 'Nenhum lembrete',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                completed
                    ? 'Os lembretes marcados como concluídos aparecem aqui.'
                    : 'Adicione o que você não quer esquecer.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
