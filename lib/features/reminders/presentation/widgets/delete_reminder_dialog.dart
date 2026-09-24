import 'package:flutter/material.dart';

import '../../domain/reminder.dart';

Future<bool> showDeleteReminderDialog(
  BuildContext context,
  Reminder reminder,
) async {
  final colors = Theme.of(context).colorScheme;
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon:
              Icon(Icons.delete_outline_rounded, color: colors.error, size: 32),
          title: const Text('Excluir lembrete?'),
          content: Text('“${reminder.title}” será removido do aparelho.'),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
                minimumSize: const Size(0, 48),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Excluir'),
            ),
          ],
        ),
      ) ??
      false;
}
