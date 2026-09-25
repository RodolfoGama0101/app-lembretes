import 'notification_appearance.dart';

/// Values stored by versions before the task date and alert were independent.
enum NotificationKind { temporary, persistent, unscheduled, inbox }

enum ReminderAlertMode { none, atTime, pinned }

ReminderAlertMode _modeFromLegacy(NotificationKind kind) => switch (kind) {
      NotificationKind.temporary => ReminderAlertMode.atTime,
      NotificationKind.persistent ||
      NotificationKind.unscheduled =>
        ReminderAlertMode.pinned,
      NotificationKind.inbox => ReminderAlertMode.none,
    };

ReminderAlertMode _resolveMode(
    ReminderAlertMode? mode, NotificationKind? kind) {
  if ((mode == null) == (kind == null)) {
    throw ArgumentError('Informe apenas um modo de aviso.');
  }
  return mode ?? _modeFromLegacy(kind!);
}

class Reminder {
  Reminder({
    required this.id,
    required this.notificationId,
    required this.title,
    required this.scheduledAt,
    ReminderAlertMode? alertMode,
    NotificationKind? kind,
    this.notes = '',
    this.visualStyle = NotificationVisualStyle.expanded,
    this.accent = NotificationAccent.blue,
    this.symbol = NotificationSymbol.bell,
    this.isCompleted = false,
    bool keepNotificationAfterCompletion = false,
    required this.createdAt,
  })  : alertMode = _resolveMode(alertMode, kind),
        keepNotificationAfterCompletion =
            _resolveMode(alertMode, kind) == ReminderAlertMode.pinned &&
                (scheduledAt == null || keepNotificationAfterCompletion) {
    if (this.alertMode == ReminderAlertMode.atTime && scheduledAt == null) {
      throw ArgumentError('Aviso no horário exige data e hora.');
    }
  }

  final String id;
  final int notificationId;
  final String title;
  final String notes;
  final NotificationVisualStyle visualStyle;
  final NotificationAccent accent;
  final NotificationSymbol symbol;

  /// Date and time for doing the task, independent of when a pinned alert appears.
  final DateTime? scheduledAt;
  final ReminderAlertMode alertMode;
  final bool isCompleted;
  final bool keepNotificationAfterCompletion;
  final DateTime createdAt;

  /// Compatibility view for old records and callers still being migrated.
  NotificationKind get kind => switch (alertMode) {
        ReminderAlertMode.atTime => NotificationKind.temporary,
        ReminderAlertMode.pinned => scheduledAt == null
            ? NotificationKind.unscheduled
            : NotificationKind.persistent,
        ReminderAlertMode.none => NotificationKind.inbox,
      };

  bool get isUnscheduled =>
      alertMode == ReminderAlertMode.pinned && scheduledAt == null;
  bool get hasNoDate => scheduledAt == null;
  bool get isPersistent => alertMode == ReminderAlertMode.pinned;
  bool get isPast => scheduledAt?.isBefore(DateTime.now()) ?? false;

  Reminder copyWith({
    String? title,
    String? notes,
    NotificationVisualStyle? visualStyle,
    NotificationAccent? accent,
    NotificationSymbol? symbol,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
    ReminderAlertMode? alertMode,
    NotificationKind? kind,
    bool? isCompleted,
    bool? keepNotificationAfterCompletion,
  }) {
    final nextMode =
        alertMode ?? (kind == null ? this.alertMode : _modeFromLegacy(kind));
    final nextDate = clearScheduledAt ||
            kind == NotificationKind.unscheduled ||
            kind == NotificationKind.inbox
        ? null
        : scheduledAt ?? this.scheduledAt;
    return Reminder(
      id: id,
      notificationId: notificationId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      visualStyle: visualStyle ?? this.visualStyle,
      accent: accent ?? this.accent,
      symbol: symbol ?? this.symbol,
      scheduledAt: nextDate,
      alertMode: nextMode,
      isCompleted: isCompleted ?? this.isCompleted,
      keepNotificationAfterCompletion: keepNotificationAfterCompletion ??
          this.keepNotificationAfterCompletion,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'notificationId': notificationId,
        'title': title,
        'notes': notes,
        'visualStyle': visualStyle.name,
        'accent': accent.name,
        'symbol': symbol.name,
        'scheduledAt': scheduledAt?.toIso8601String(),
        'alertMode': alertMode.name,
        'isCompleted': isCompleted,
        'keepNotificationAfterCompletion': keepNotificationAfterCompletion,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Reminder.fromJson(Map<String, Object?> json) {
    final rawScheduledAt = json['scheduledAt'] as String?;
    final rawMode = json['alertMode'] as String?;
    final mode = rawMode == null
        ? _modeFromLegacy(
            NotificationKind.values.byName(json['kind']! as String),
          )
        : ReminderAlertMode.values.byName(rawMode);
    if (rawMode == null) {
      final legacyKind =
          NotificationKind.values.byName(json['kind']! as String);
      if ((legacyKind == NotificationKind.unscheduled ||
              legacyKind == NotificationKind.inbox) !=
          (rawScheduledAt == null)) {
        throw const FormatException('Tipo e horário incompatíveis.');
      }
    }
    if (mode == ReminderAlertMode.atTime && rawScheduledAt == null) {
      throw const FormatException('Aviso no horário sem data.');
    }
    return Reminder(
      id: json['id']! as String,
      notificationId: json['notificationId']! as int,
      title: json['title']! as String,
      notes: (json['notes'] as String?) ?? '',
      visualStyle: NotificationVisualStyle.values.byName(
        (json['visualStyle'] as String?) ??
            NotificationVisualStyle.expanded.name,
      ),
      accent: NotificationAccent.values.byName(
        (json['accent'] as String?) ?? NotificationAccent.blue.name,
      ),
      symbol: NotificationSymbol.values.byName(
        (json['symbol'] as String?) ?? NotificationSymbol.bell.name,
      ),
      scheduledAt:
          rawScheduledAt == null ? null : DateTime.parse(rawScheduledAt),
      alertMode: mode,
      isCompleted: (json['isCompleted'] as bool?) ?? false,
      keepNotificationAfterCompletion:
          (json['keepNotificationAfterCompletion'] as bool?) ?? false,
      createdAt: DateTime.parse(json['createdAt']! as String),
    );
  }
}
