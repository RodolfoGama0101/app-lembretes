import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/reminder.dart';
import 'reminder_controller.dart';

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
  }

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
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              const _FieldLabel('O que lembrar?'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                decoration: const InputDecoration(
                  hintText: 'Ex.: Tomar o remédio',
                  counterText: '',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Digite um título.'
                    : null,
              ),
              const SizedBox(height: 24),
              const _FieldLabel('Quando?'),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final date = _PickerButton(
                    icon: Icons.calendar_today_outlined,
                    label: DateFormat('dd/MM/yyyy').format(_scheduledAt),
                    onPressed: _pickDate,
                  );
                  final time = _PickerButton(
                    icon: Icons.schedule,
                    label: DateFormat('HH:mm').format(_scheduledAt),
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
                const SizedBox(height: 24),
                const _FieldLabel('Tipo de notificação'),
                const SizedBox(height: 8),
                _NotificationOption(
                  title: 'Temporária',
                  description: 'Pode ser dispensada normalmente.',
                  icon: Icons.notifications_none,
                  selected: _kind == NotificationKind.temporary,
                  onTap: () =>
                      setState(() => _kind = NotificationKind.temporary),
                ),
                const SizedBox(height: 8),
                _NotificationOption(
                  title: 'Fixa',
                  description:
                      'Permanece no painel até você concluir a tarefa.',
                  icon: Icons.push_pin_outlined,
                  selected: _kind == NotificationKind.persistent,
                  onTap: () =>
                      setState(() => _kind = NotificationKind.persistent),
                ),
              ],
              const SizedBox(height: 24),
              const _FieldLabel('Observação (opcional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 5,
                maxLength: 240,
                decoration: const InputDecoration(
                  hintText: 'Adicione algum detalhe útil',
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Salvando…' : 'Salvar lembrete'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_scheduledAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha um horário futuro.')),
      );
      return;
    }

    setState(() => _saving = true);
    bool permissionGranted;
    try {
      if (_isEditing) {
        permissionGranted = await widget.controller.update(
          widget.reminder!.copyWith(
            title: _titleController.text.trim(),
            notes: _notesController.text.trim(),
            scheduledAt: _scheduledAt,
            kind: _kind,
          ),
        );
      } else {
        permissionGranted = await widget.controller.add(
          title: _titleController.text,
          notes: _notesController.text,
          scheduledAt: _scheduledAt,
          kind: _kind,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar. Tente novamente.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    if (!permissionGranted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            kIsWeb
                ? 'Lembrete salvo neste navegador, sem notificação.'
                : 'Lembrete salvo. Ative as notificações nas configurações do aparelho.',
          ),
        ),
      );
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
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
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
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : AppColors.white,
            border: Border.all(
              color: selected ? AppColors.blue : AppColors.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? AppColors.blue : AppColors.muted),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.blue : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
