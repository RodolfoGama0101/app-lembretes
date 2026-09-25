import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/notification_appearance.dart';
import '../../domain/reminder.dart';
import '../notification_appearance_display.dart';

class NotificationAppearanceSelector extends StatelessWidget {
  const NotificationAppearanceSelector({
    super.key,
    required this.visualStyle,
    required this.accent,
    required this.symbol,
    required this.alertMode,
    required this.hasDate,
    required this.title,
    required this.notes,
    required this.onStyleChanged,
    required this.onAccentChanged,
    required this.onSymbolChanged,
  });

  final NotificationVisualStyle visualStyle;
  final NotificationAccent accent;
  final NotificationSymbol symbol;
  final ReminderAlertMode alertMode;
  final bool hasDate;
  final String title;
  final String notes;
  final ValueChanged<NotificationVisualStyle> onStyleChanged;
  final ValueChanged<NotificationAccent> onAccentChanged;
  final ValueChanged<NotificationSymbol> onSymbolChanged;

  static const _palette = [
    NotificationAccent.red,
    NotificationAccent.yellow,
    NotificationAccent.blue,
    NotificationAccent.green,
    NotificationAccent.orange,
    NotificationAccent.purple,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent.color;
    final darkSymbol = accent == NotificationAccent.yellow;
    final body = notes.trim().isNotEmpty
        ? notes.trim()
        : !hasDate
            ? 'Lembrete sem horário, fixado no painel'
            : alertMode == ReminderAlertMode.pinned
                ? 'Lembrete fixado no painel'
                : 'Está na hora deste lembrete.';
    final explanation = kIsWeb
        ? 'Exemplo do aviso no Android. O navegador não envia notificações.'
        : defaultTargetPlatform == TargetPlatform.iOS
            ? 'No iPhone, o sistema define o visual do banner. Cor e símbolo aparecem apenas no app.'
            : 'No Android, a cor aparece no ícone maior e em detalhes da notificação. O painel pode variar conforme o aparelho.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notificação no celular',
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
        const SizedBox(height: 6),
        Text(explanation, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        Text('Cor do ícone', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in _palette)
              ChoiceChip(
                avatar: CircleAvatar(
                  backgroundColor: option.color,
                  radius: 10,
                ),
                label: Text(option.label),
                selected: accent == option,
                selectedColor: option.color.withValues(alpha: .14),
                side: BorderSide(
                  color: accent == option ? option.color : theme.dividerColor,
                ),
                onSelected: (_) => onAccentChanged(option),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Símbolo', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
        const SizedBox(height: 18),
        Text('Texto', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
        const SizedBox(height: 6),
        Text('O Android decide quando o texto expandido aparece.',
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        Text('Exemplo no Android', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  symbol.icon,
                  color: darkSymbol ? const Color(0xFF342900) : Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lembretes',
                        style:
                            theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      title.trim().isEmpty
                          ? 'Título do lembrete'
                          : title.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      maxLines: visualStyle == NotificationVisualStyle.expanded
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
      ],
    );
  }
}
