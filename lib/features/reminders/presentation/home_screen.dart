import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/reminder.dart';
import 'reminder_controller.dart';
import 'reminder_form_screen.dart';
import 'widgets/reminder_list_item.dart';

enum _HomeList { active, completed }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final ReminderController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _HomeList _selectedList = _HomeList.active;

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
                          padding: const EdgeInsets.only(bottom: 112),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final reminder = items[index];
                            final showDate =
                                index == 0 ||
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
                                  onToggle: () => widget.controller
                                      .toggleCompleted(reminder),
                                  onTap: reminder.isCompleted
                                      ? null
                                      : () => _openForm(reminder),
                                  onDelete: () => _confirmDelete(reminder),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openForm,
            backgroundColor: AppColors.blue,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Novo lembrete'),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('Excluir lembrete?'),
        content: Text('“${reminder.title}” será removido do aparelho.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.controller.remove(reminder);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final ReminderController controller;

  @override
  Widget build(BuildContext context) {
    final next = controller.nextReminder;
    final now = DateTime.now();
    final day = DateFormat('dd').format(now);
    final month = DateFormat('MMM', 'pt_BR').format(now).replaceAll('.', '');

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(day, style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      month.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE', 'pt_BR').format(now),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'FIO',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      next == null ? 'Tudo em dia' : 'Próximo lembrete',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      next == null ? 'Nenhum lembrete futuro' : next.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              if (next != null) ...[
                const SizedBox(width: 16),
                Text(
                  DateFormat('HH:mm').format(next.scheduledAt),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.blue,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: controller.todayProgress,
            minHeight: 3,
            backgroundColor: AppColors.line,
            color: AppColors.blue,
          ),
          const SizedBox(height: 8),
          Text(
            controller.remainingToday == 0
                ? 'Nada pendente para hoje'
                : '${controller.remainingToday} ${controller.remainingToday == 1 ? 'item restante' : 'itens restantes'} hoje',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SelectorButton(
              label: 'Lembretes',
              count: activeCount,
              selected: selected == _HomeList.active,
              onTap: () => onChanged(_HomeList.active),
            ),
          ),
          Container(width: 1, height: 52, color: AppColors.line),
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
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.blue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.ink : AppColors.muted,
              ),
            ),
            Text(
              count.toString().padLeft(2, '0'),
              style: TextStyle(
                color: selected ? AppColors.blue : AppColors.muted,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(today).inDays;
    final label = switch (difference) {
      0 => 'Hoje',
      1 => 'Amanhã',
      -1 => 'Ontem',
      _ => DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(date),
    };

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 9),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: .3,
        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              completed ? Icons.check_circle_outline : Icons.notifications_none,
              size: 42,
              color: AppColors.blue,
            ),
            const SizedBox(height: 18),
            Text(
              completed ? 'Nenhum item concluído' : 'Nenhum lembrete',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              completed
                  ? 'Os lembretes marcados como concluídos aparecem aqui.'
                  : 'Adicione o que você não quer esquecer.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
