import 'package:flutter/material.dart';

import '../domain/notification_appearance.dart';

extension NotificationAccentDisplay on NotificationAccent {
  String get label => switch (this) {
        NotificationAccent.blue => 'Azul',
        NotificationAccent.green => 'Verde',
        NotificationAccent.orange => 'Laranja',
        NotificationAccent.purple => 'Roxo',
        NotificationAccent.red => 'Vermelho',
        NotificationAccent.yellow => 'Amarelo',
      };

  Color get color => Color(colorValue);
}

extension NotificationSymbolDisplay on NotificationSymbol {
  String get label => switch (this) {
        NotificationSymbol.bell => 'Sino',
        NotificationSymbol.star => 'Estrela',
        NotificationSymbol.check => 'Concluído',
      };

  IconData get icon => switch (this) {
        NotificationSymbol.bell => Icons.notifications_rounded,
        NotificationSymbol.star => Icons.star_rounded,
        NotificationSymbol.check => Icons.check_circle_rounded,
      };
}
