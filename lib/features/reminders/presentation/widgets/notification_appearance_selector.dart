import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/notification_appearance.dart';
import '../notification_appearance_display.dart';

class NotificationAppearanceSelector extends StatelessWidget {
  const NotificationAppearanceSelector({
    super.key,
    required this.visualStyle,
    required this.accent,
    required this.symbol,
    required this.title,
    required this.notes,
    required this.onStyleChanged,
    required this.onAccentChanged,
    required this.onSymbolChanged,
  });

  final NotificationVisualStyle visualStyle;
  final NotificationAccent accent;
  final NotificationSymbol symbol;
  final String title;
  final String notes;
  final ValueChanged<NotificationVisualStyle> onStyleChanged;
  final ValueChanged<NotificationAccent> onAccentChanged;
  final ValueChanged<NotificationSymbol> onSymbolChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aparência do alerta',
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 15)),
        const SizedBox(height: 6),
        Text(
          kIsWeb
              ? 'Prévia visual. O navegador não envia notificações.'
              : defaultTargetPlatform == TargetPlatform.iOS
                  ? 'No iPhone, o sistema define a aparência do banner. Cor e ícone aparecem no app.'
                  : 'No Android, escolha o estilo, a cor de destaque e o ícone.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text('Estilo', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ChoiceChip(
              label: const Text('Expandido'),
              selected: visualStyle == NotificationVisualStyle.expanded,
              onSelected: (_) =>
                  onStyleChanged(NotificationVisualStyle.expanded),
            ),
            ChoiceChip(
              label: const Text('Compacto'),
              selected: visualStyle == NotificationVisualStyle.compact,
              onSelected: (_) =>
                  onStyleChanged(NotificationVisualStyle.compact),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Cor de destaque', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final option in NotificationAccent.values)
              ChoiceChip(
                avatar: CircleAvatar(backgroundColor: option.color, radius: 9),
                label: Text(option.label),
                selected: accent == option,
                onSelected: (_) => onAccentChanged(option),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Ícone', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final option in NotificationSymbol.values)
              ChoiceChip(
                avatar: Icon(option.icon, size: 18, color: color),
                label: Text(option.label),
                selected: symbol == option,
                onSelected: (_) => onSymbolChanged(option),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(symbol.icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.trim().isEmpty
                            ? 'Título do lembrete'
                            : title.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notes.trim().isEmpty
                            ? 'Detalhes do lembrete'
                            : notes.trim(),
                        maxLines:
                            visualStyle == NotificationVisualStyle.expanded
                                ? 4
                                : 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
