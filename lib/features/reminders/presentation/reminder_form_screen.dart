import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/notification_appearance.dart';
import '../domain/reminder.dart';
import 'reminder_controller.dart';
import '../services/notification_service.dart';
import 'widgets/delete_reminder_dialog.dart';
import 'widgets/notification_appearance_selector.dart';

class ReminderFormScreen extends StatefulWidget {
  const ReminderFormScreen({
    super.key,
    required this.controller,
    this.reminder,
  });

  final ReminderController controller;
  final Reminder? reminder;

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late DateTime _scheduledAt;
  late NotificationKind _kind;
  late NotificationKind _lastTimedKind;
  late NotificationVisualStyle _visualStyle;
  late NotificationAccent _accent;
  late NotificationSymbol _symbol;
  bool _saving = false;

  bool get _isEditing => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    final initialDate = DateTime.now().add(const Duration(hours: 1));
    _titleController = TextEditingController(text: reminder?.title ?? '');
    _notesController = TextEditingController(text: reminder?.notes ?? '');
    _scheduledAt = reminder?.scheduledAt ??
        DateTime(
          initialDate.year,
          initialDate.month,
          initialDate.day,
          initialDate.hour,
        );
    _kind = reminder?.kind ?? NotificationKind.temporary;
    _visualStyle = reminder?.visualStyle ?? NotificationVisualStyle.expanded;
    _accent = reminder?.accent ?? NotificationAccent.red;
    _symbol = reminder?.symbol ?? NotificationSymbol.bell;
    _titleController.addListener(_refreshPreview);
    _notesController.addListener(_refreshPreview);
    _lastTimedKind = _kind == NotificationKind.persistent
        ? NotificationKind.persistent
        : NotificationKind.temporary;
  }

  void _refreshPreview() => setState(() {});

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          tooltip: 'Fechar',
        ),
        title: Text(_isEditing ? 'Editar lembrete' : 'Novo lembrete'),
        actions: [
          if (_isEditing)
            IconButton.filledTonal(
              onPressed: _saving ? null : _delete,
              tooltip: 'Excluir lembrete',
              style: IconButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.error.withValues(alpha: .12),
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
            children: [
              const _FieldLabel('O que lembrar?'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'Ex.: Tomar o remédio',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Digite um título.'
                    : null,
              ),
              const SizedBox(height: 28),
              const _FieldLabel('Quando fazer?'),
              const SizedBox(height: 8),
              Material(
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                child: SwitchListTile.adaptive(
                  title: const Text('Sem horário'),
                  subtitle: Text(
                    kIsWeb
                        ? 'Fica na lista sem data ou hora.'
                        : 'Aparece ao salvar. No Android, reaparece após cerca de um dia se for dispensado.',
                  ),
                  secondary: Icon(
                    Icons.push_pin_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  value: _kind == NotificationKind.unscheduled,
                  onChanged: (enabled) => setState(() {
                    _kind =
                        enabled ? NotificationKind.unscheduled : _lastTimedKind;
                  }),
                ),
              ),
              if (_kind != NotificationKind.unscheduled) ...[
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final date = _PickerButton(
                      icon: Icons.calendar_today_outlined,
                      caption: 'Data',
                      value: DateFormat('dd/MM/yyyy').format(_scheduledAt),
                      onPressed: _pickDate,
                    );
                    final time = _PickerButton(
                      icon: Icons.schedule_rounded,
                      caption: 'Hora',
                      value: DateFormat('HH:mm').format(_scheduledAt),
                      onPressed: _pickTime,
                    );
                    if (constraints.maxWidth < 360) {
                      return Column(
                        children: [date, const SizedBox(height: 8), time],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: date),
                        const SizedBox(width: 8),
                        Expanded(child: time),
                      ],
                    );
                  },
                ),
                if (!kIsWeb) ...[
                  if (_kind == NotificationKind.persistent) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Esse horário organiza a tarefa. A notificação aparece ao salvar.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 28),
                  const _FieldLabel('Tipo de notificação'),
                  const SizedBox(height: 8),
                  _NotificationOption(
                    title: 'Temporária',
                    description: 'Avisa no horário e pode ser dispensada.',
                    icon: Icons.notifications_none_rounded,
                    selected: _kind == NotificationKind.temporary,
                    onTap: () => setState(() {
                      _kind = NotificationKind.temporary;
                      _lastTimedKind = _kind;
                    }),
                  ),
                  const SizedBox(height: 8),
                  _NotificationOption(
                    title: 'Permanente',
                    description:
                        'Aparece ao salvar. No Android, reaparece após cerca de um dia se for dispensado.',
                    icon: Icons.notifications_active_outlined,
                    selected: _kind == NotificationKind.persistent,
                    onTap: () => setState(() {
                      _kind = NotificationKind.persistent;
                      _lastTimedKind = _kind;
                    }),
                  ),
                ],
              ],
              const SizedBox(height: 28),
              const _FieldLabel('Observação (opcional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 5,
                maxLength: 240,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'Adicione algum detalhe útil',
                ),
              ),
              const SizedBox(height: 28),
              NotificationAppearanceSelector(
                visualStyle: _visualStyle,
                accent: _accent,
                symbol: _symbol,
                kind: _kind,
                title: _titleController.text,
                notes: _notesController.text,
                onStyleChanged: (value) => setState(() => _visualStyle = value),
                onAccentChanged: (value) => setState(() => _accent = value),
                onSymbolChanged: (value) => setState(() => _symbol = value),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check_rounded),
            label: Text(_saving ? 'Salvando…' : 'Salvar lembrete'),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final value = await showDatePicker(
      context: context,
      initialDate:
          _scheduledAt.isBefore(DateTime.now()) ? DateTime.now() : _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (value == null) return;
    setState(() {
      _scheduledAt = DateTime(
        value.year,
        value.month,
        value.day,
        _scheduledAt.hour,
        _scheduledAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    FocusScope.of(context).unfocus();
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (value == null) return;
    setState(() {
      _scheduledAt = DateTime(
        _scheduledAt.year,
        _scheduledAt.month,
        _scheduledAt.day,
        value.hour,
        value.minute,
      );
    });
  }

  Future<void> _delete() async {
    final reminder = widget.reminder;
    if (reminder == null || _saving) return;
    if (!await showDeleteReminderDialog(context, reminder) || !mounted) return;

    setState(() => _saving = true);
    try {
      await widget.controller.remove(reminder);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir o lembrete.')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final original = widget.reminder;
    final keepsOverdueSchedule = original != null &&
        original.kind == _kind &&
        original.scheduledAt == _scheduledAt;
    if (_kind != NotificationKind.unscheduled &&
        !_scheduledAt.isAfter(DateTime.now()) &&
        !keepsOverdueSchedule) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha um horário futuro.')),
      );
      return;
    }

    setState(() => _saving = true);
    NotificationDeliveryStatus deliveryStatus;
    try {
      if (_isEditing) {
        deliveryStatus = await widget.controller.update(
          widget.reminder!.copyWith(
            title: _titleController.text.trim(),
            notes: _notesController.text.trim(),
            scheduledAt:
                _kind == NotificationKind.unscheduled ? null : _scheduledAt,
            kind: _kind,
            visualStyle: _visualStyle,
            accent: _accent,
            symbol: _symbol,
            keepNotificationAfterCompletion:
                _kind != NotificationKind.temporary,
          ),
        );
      } else {
        deliveryStatus = await widget.controller.add(
          title: _titleController.text,
          notes: _notesController.text,
          scheduledAt:
              _kind == NotificationKind.unscheduled ? null : _scheduledAt,
          kind: _kind,
          visualStyle: _visualStyle,
          accent: _accent,
          symbol: _symbol,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error is NotificationSchedulingFailure
              ? 'Não foi possível agendar o aviso. O lembrete não foi salvo.'
              : 'Não foi possível salvar. Tente novamente.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    final message = kIsWeb
        ? 'Lembrete salvo neste navegador, sem notificação.'
        : switch (deliveryStatus) {
            NotificationDeliveryStatus.approximate =>
              'Lembrete salvo com horário aproximado. Permita alarmes exatos nas configurações para maior precisão.',
            NotificationDeliveryStatus.permissionDenied =>
              'Lembrete salvo. Ative as notificações nas configurações do aparelho.',
            NotificationDeliveryStatus.unavailable =>
              'Lembrete salvo. Avisos indisponíveis; tente novamente na lista.',
            NotificationDeliveryStatus.scheduled ||
            NotificationDeliveryStatus.inactive =>
              null,
          };
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.caption,
    required this.value,
    required this.onPressed,
  });

  final IconData icon;
  final String caption;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Semantics(
      button: true,
      label: 'Selecionar $caption: $value',
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onPressed,
          excludeFromSemantics: true,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(icon, size: 21, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(caption,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: theme.textTheme.bodyMedium?.color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationOption extends StatelessWidget {
  const _NotificationOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color:
            selected ? accent.withValues(alpha: .1) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? accent : theme.dividerColor,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: selected ? .16 : .08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontSize: 16)),
                      const SizedBox(height: 3),
                      Text(description, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? accent : theme.textTheme.bodyMedium?.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
