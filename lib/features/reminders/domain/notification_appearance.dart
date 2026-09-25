enum NotificationVisualStyle { expanded, compact }

enum NotificationAccent { blue, green, orange, purple, red, yellow }

enum NotificationSymbol { bell, star, check }

extension NotificationAccentValue on NotificationAccent {
  String badgeName(NotificationSymbol symbol) =>
      'notification_badge_${name}_${symbol.name}';

  int get colorValue => switch (this) {
        NotificationAccent.blue => 0xFF0072DE,
        NotificationAccent.green => 0xFF16804A,
        NotificationAccent.orange => 0xFFB85D00,
        NotificationAccent.purple => 0xFF7752B4,
        NotificationAccent.red => 0xFFD92D3A,
        NotificationAccent.yellow => 0xFFF0B900,
      };
}
