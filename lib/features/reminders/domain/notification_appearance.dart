enum NotificationVisualStyle { expanded, compact }

enum NotificationAccent { blue, green, orange, purple }

enum NotificationSymbol { bell, star, check }

extension NotificationAccentValue on NotificationAccent {
  int get colorValue => switch (this) {
        NotificationAccent.blue => 0xFF0072DE,
        NotificationAccent.green => 0xFF16804A,
        NotificationAccent.orange => 0xFFB85D00,
        NotificationAccent.purple => 0xFF7752B4,
      };
}
