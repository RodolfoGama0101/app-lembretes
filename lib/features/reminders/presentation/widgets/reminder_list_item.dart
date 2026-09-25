import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../notification_appearance_display.dart';
import '../../domain/reminder.dart';
import '../../services/notification_service.dart';

class ReminderListItem extends StatelessWidget {
  const ReminderListItem({
    super.key,
    required this.reminder,
    required this.notificationStatus,
    required this.onToggle,
    required this.onDelete,
    this.onTap,
  });

  final Reminder reminder;
  final NotificationDeliveryStatus? notificationStatus;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final persistent = reminder.isPersistent;
    final accent = reminder.accent.color;
    final statusLabel = switch (notificationStatus) {
      NotificationDeliveryStatus.scheduled =>
        persistent ? 'Aviso configurado' : 'Aviso agendado',
      NotificationDeliveryStatus.approximate => 'Horário aproximado',
      NotificationDeliveryStatus.permissionDenied => 'Aviso desativado',
      NotificationDeliveryStatus.unavailable => 'Aviso indisponível',
      NotificationDeliveryStatus.inactive || null => null,
    };
    final statusHint = switch (notificationStatus) {
      NotificationDeliveryStatus.approximate =>
        'Permita alarmes exatos nas configurações para maior precisão.',
      NotificationDeliveryStatus.permissionDenied =>
        'Ative as notificações nas configurações do aparelho.',
      NotificationDeliveryStatus.unavailable =>
        'Tente novamente quando os avisos estiverem disponíveis.',
      _ => null,
    };
    final statusColor = switch (notificationStatus) {
      NotificationDeliveryStatus.permissionDenied ||
      NotificationDeliveryStatus.unavailable =>
        theme.colorScheme.error,
      NotificationDeliveryStatus.approximate => theme.colorScheme.tertiary,
      _ => theme.textTheme.bodyMedium?.color,
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Dismissible(
        key: ValueKey(reminder.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          onDelete();
          return false;
        },
        background: Container(
          color: theme.colorScheme.error,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.centerRight,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Excluir',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        child: Material(
          color: theme.colorScheme.surface,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 13, 8, 13),
              child: Row(
                children: [
                  Container(
                    width: 57,
                    height: 57,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: reminder.hasNoDate
                        ? Icon(
                            reminder.kind == NotificationKind.inbox
                                ? Icons.inbox_outlined
                                : reminder.symbol.icon,
                            color: accent,
                            size: 22,
                          )
                        : Text(
                            DateFormat('HH:mm').format(reminder.scheduledAt!),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                              fontSize: 12,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            decoration: reminder.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: reminder.isCompleted
                                ? theme.textTheme.bodyMedium?.color
                                : null,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              reminder.kind == NotificationKind.inbox
                                  ? Icons.notifications_off_outlined
                                  : reminder.symbol.icon,
                              size: 14,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                reminder.kind == NotificationKind.inbox
                                    ? 'Sem data • sem aviso'
                                    : reminder.isUnscheduled
                                        ? 'Sem horário • permanente'
                                        : kIsWeb
                                            ? 'Sem notificação'
                                            : persistent
                                                ? 'Permanente'
                                                : 'Temporária',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontSize: 12),
                              ),
                            ),
                            if (reminder.isPast && !reminder.isCompleted) ...[
                              const SizedBox(width: 6),
                              Text(
                                'Atrasado',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (!kIsWeb && statusLabel != null) ...[
                          const SizedBox(height: 4),
                          Tooltip(
                            message: statusHint ?? statusLabel,
                            child: Row(
                              children: [
                                Icon(
                                  notificationStatus ==
                                          NotificationDeliveryStatus.scheduled
                                      ? Icons.notifications_outlined
                                      : Icons.info_outline_rounded,
                                  size: 14,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    statusLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 12,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onToggle,
                    tooltip: reminder.isCompleted
                        ? 'Marcar como pendente'
                        : 'Marcar como concluído',
                    icon: Icon(
                      reminder.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: accent,
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Mais opções para ${reminder.title}',
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                color: Theme.of(context).colorScheme.error,
                                size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Excluir',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
