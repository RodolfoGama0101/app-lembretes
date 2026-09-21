import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reminder.dart';
import 'reminder_repository.dart';

class LocalReminderRepository implements ReminderRepository {
  static const _storageKey = 'fio.reminders.v1';

  @override
  Future<List<Reminder>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey);
    if (encoded == null || encoded.isEmpty) return [];

    try {
      final items = jsonDecode(encoded) as List<dynamic>;
      return items
          .map(
            (item) => Reminder.fromJson(
              Map<String, Object?>.from(item as Map<dynamic, dynamic>),
            ),
          )
          .toList();
    } on FormatException {
      return [];
    }
  }

  @override
  Future<void> save(List<Reminder> reminders) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(reminders.map((item) => item.toJson()).toList());
    await preferences.setString(_storageKey, encoded);
  }
}
