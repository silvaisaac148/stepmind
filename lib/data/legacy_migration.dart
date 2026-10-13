import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/dates.dart';
import '../models/habit.dart';
import 'habit_repository.dart';

/// Pasa los hábitos guardados por la versión anterior (JSON en
/// SharedPreferences) a la base de datos, y borra los contadores viejos.
class LegacyMigration {
  static const _doneKey = 'legacy_migrated_v1';
  static const _obsoleteKeys = [
    'habits',
    'total_days',
    'achievements',
    'first_launch',
    'current_streak',
    'active_notification_times',
  ];

  static Future<void> run(SharedPreferences prefs, HabitRepository repository) async {
    if (prefs.getBool(_doneKey) ?? false) return;

    final raw = prefs.getString('habits');
    if (raw != null) {
      try {
        final list = json.decode(raw) as List<dynamic>;
        for (final item in list.cast<Map<String, dynamic>>()) {
          final habit = Habit(
            id: item['id'] as String,
            name: item['name'] as String,
            time: TimeOfDay(hour: item['timeHour'] as int, minute: item['timeMinute'] as int),
            createdAt: DateTime.fromMillisecondsSinceEpoch(item['createdAt'] as int),
          );
          await repository.saveHabit(habit);
          final dates = (item['completedDates'] as List<dynamic>? ?? const [])
              .map((ms) => DateTime.fromMillisecondsSinceEpoch(ms as int));
          for (final date in dates) {
            await repository.setCheckin(habit.id, dayKey(date), done: true);
          }
        }
      } catch (e) {
        debugPrint('No se pudieron migrar los hábitos antiguos: $e');
      }
    }

    for (final key in prefs.getKeys().toList()) {
      if (_obsoleteKeys.contains(key) || key.startsWith('completed_')) {
        await prefs.remove(key);
      }
    }
    await prefs.setBool(_doneKey, true);
  }
}
