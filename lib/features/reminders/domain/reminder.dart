import 'notification_appearance.dart';

enum NotificationKind { temporary, persistent, unscheduled }

class Reminder {
  const Reminder({
    required this.id,
    required this.notificationId,
    required this.title,
    required this.scheduledAt,
    required this.kind,
    this.notes = '',
    this.visualStyle = NotificationVisualStyle.expanded,
    this.accent = NotificationAccent.blue,
    this.symbol = NotificationSymbol.bell,
    this.isCompleted = false,
    bool keepNotificationAfterCompletion = false,
    required this.createdAt,
  })  : keepNotificationAfterCompletion =
            kind == NotificationKind.unscheduled ||
                (kind == NotificationKind.persistent &&
                    keepNotificationAfterCompletion),
        assert(
          (kind == NotificationKind.unscheduled) == (scheduledAt == null),
          'Only reminders without a time can omit scheduledAt.',
        );

  final String id;
  final int notificationId;
  final String title;
  final String notes;
  final NotificationVisualStyle visualStyle;
  final NotificationAccent accent;
  final NotificationSymbol symbol;
  final DateTime? scheduledAt;
  final NotificationKind kind;
  final bool isCompleted;
  final bool keepNotificationAfterCompletion;
  final DateTime createdAt;

  bool get isUnscheduled => kind == NotificationKind.unscheduled;
  bool get isPersistent => kind != NotificationKind.temporary;
  bool get isPast => scheduledAt?.isBefore(DateTime.now()) ?? false;

  Reminder copyWith({
    String? title,
    String? notes,
    NotificationVisualStyle? visualStyle,
    NotificationAccent? accent,
    NotificationSymbol? symbol,
    DateTime? scheduledAt,
    NotificationKind? kind,
    bool? isCompleted,
    bool? keepNotificationAfterCompletion,
  }) {
    final nextKind = kind ?? this.kind;
    return Reminder(
      id: id,
      notificationId: notificationId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      visualStyle: visualStyle ?? this.visualStyle,
      accent: accent ?? this.accent,
      symbol: symbol ?? this.symbol,
      scheduledAt: nextKind == NotificationKind.unscheduled
          ? null
          : scheduledAt ?? this.scheduledAt,
      kind: nextKind,
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
        'kind': kind.name,
        'isCompleted': isCompleted,
        'keepNotificationAfterCompletion': keepNotificationAfterCompletion,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Reminder.fromJson(Map<String, Object?> json) {
    final rawScheduledAt = json['scheduledAt'] as String?;
    final kind = NotificationKind.values.byName(json['kind']! as String);
    if ((kind == NotificationKind.unscheduled) != (rawScheduledAt == null)) {
      throw const FormatException('Tipo e horário incompatíveis.');
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
      kind: kind,
      isCompleted: (json['isCompleted'] as bool?) ?? false,
      keepNotificationAfterCompletion:
          (json['keepNotificationAfterCompletion'] as bool?) ?? false,
      createdAt: DateTime.parse(json['createdAt']! as String),
    );
  }
}
