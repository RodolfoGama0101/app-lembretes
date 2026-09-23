import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/reminder.dart';

class ReminderListItem extends StatelessWidget {
  const ReminderListItem({
    super.key,
    required this.reminder,
    required this.onToggle,
    required this.onDelete,
    this.onTap,
  });

  final Reminder reminder;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final persistent = reminder.kind == NotificationKind.persistent;
    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        color: AppColors.ink,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: AppColors.white),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 14, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  DateFormat('HH:mm').format(reminder.scheduledAt),
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 50,
                margin: const EdgeInsets.only(right: 14),
                color: AppColors.line,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            decoration: reminder.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: reminder.isCompleted
                                ? AppColors.muted
                                : AppColors.ink,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          kIsWeb
                              ? Icons.notifications_off_outlined
                              : persistent
                                  ? Icons.push_pin_outlined
                                  : Icons.notifications_none,
                          size: 15,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          kIsWeb
                              ? 'Sem notificação'
                              : persistent
                                  ? 'Fixa'
                                  : 'Temporária',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (reminder.isPast && !reminder.isCompleted) ...[
                          const SizedBox(width: 10),
                          const Text(
                            'Atrasado',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onToggle,
                    tooltip: reminder.isCompleted
                        ? 'Marcar como pendente'
                        : 'Marcar como concluído',
                    icon: Icon(
                      reminder.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: reminder.isCompleted
                          ? AppColors.blue
                          : AppColors.muted,
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Mais opções para ${reminder.title}',
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'delete', child: Text('Excluir')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
