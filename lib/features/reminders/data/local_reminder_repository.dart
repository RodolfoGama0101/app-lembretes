import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reminder.dart';
import 'reminder_repository.dart';

class LocalReminderRepository implements ReminderRepository {
  // Preserve the legacy key so saved reminders still load on Web.
  static const _storageKey = 'fio.reminders.v1';

  @override
  Future<List<Reminder>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey);
    if (encoded == null || encoded.isEmpty) return [];

    try {
      final items = jsonDecode(encoded);
      if (items is! List) return [];
      final reminders = <Reminder>[];
      for (final item in items) {
        try {
          if (item is! Map) continue;
          reminders.add(
            Reminder.fromJson(Map<String, Object?>.from(item)),
          );
        } on FormatException catch (error) {
          // A bad record must not hide the reminders that still load.
          debugPrint('Ignoring an invalid reminder: $error');
        } on TypeError catch (error) {
          debugPrint('Ignoring an invalid reminder: $error');
        } on ArgumentError catch (error) {
          debugPrint('Ignoring an invalid reminder: $error');
        } on StateError catch (error) {
          debugPrint('Ignoring an invalid reminder: $error');
        }
      }
      return reminders;
    } on FormatException catch (error) {
      debugPrint('Ignoring invalid reminder storage: $error');
      return [];
    }
  }

  @override
  Future<void> save(List<Reminder> reminders) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(reminders.map((item) => item.toJson()).toList());
    final saved = await preferences.setString(_storageKey, encoded);
    if (!saved) throw StateError('Não foi possível salvar os lembretes.');
  }
}
