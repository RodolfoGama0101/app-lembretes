enum NotificationKind { temporary, persistent }

class Reminder {
  const Reminder({
    required this.id,
    required this.notificationId,
    required this.title,
    required this.scheduledAt,
    required this.kind,
    this.notes = '',
    this.isCompleted = false,
    this.keepNotificationAfterCompletion = false,
    required this.createdAt,
  });

  final String id;
  final int notificationId;
  final String title;
  final String notes;
  final DateTime scheduledAt;
  final NotificationKind kind;
  final bool isCompleted;
  final bool keepNotificationAfterCompletion;
  final DateTime createdAt;

  bool get isPast => scheduledAt.isBefore(DateTime.now());

  Reminder copyWith({
    String? title,
    String? notes,
    DateTime? scheduledAt,
    NotificationKind? kind,
    bool? isCompleted,
    bool? keepNotificationAfterCompletion,
  }) {
    return Reminder(
      id: id,
      notificationId: notificationId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      kind: kind ?? this.kind,
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
        'scheduledAt': scheduledAt.toIso8601String(),
        'kind': kind.name,
        'isCompleted': isCompleted,
        'keepNotificationAfterCompletion': keepNotificationAfterCompletion,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Reminder.fromJson(Map<String, Object?> json) {
    return Reminder(
      id: json['id']! as String,
      notificationId: json['notificationId']! as int,
      title: json['title']! as String,
      notes: (json['notes'] as String?) ?? '',
      scheduledAt: DateTime.parse(json['scheduledAt']! as String),
      kind: NotificationKind.values.byName(json['kind']! as String),
      isCompleted: (json['isCompleted'] as bool?) ?? false,
      keepNotificationAfterCompletion:
          (json['keepNotificationAfterCompletion'] as bool?) ?? false,
      createdAt: DateTime.parse(json['createdAt']! as String),
    );
  }
}
