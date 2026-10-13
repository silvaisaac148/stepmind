import 'package:sqflite/sqflite.dart';

import '../domain/habit_stats.dart';
import '../models/habit.dart';
import 'app_database.dart';

abstract class HabitRepository {
  Future<HabitData> load();

  /// Inserta o actualiza un hábito (archivar = guardar con `archivedAt`).
  Future<void> saveHabit(Habit habit);

  Future<void> setCheckin(String habitId, String day, {required bool done});
}

class SqliteHabitRepository implements HabitRepository {
  final AppDatabase _database;

  SqliteHabitRepository(this._database);

  Database get _db => _database.db;

  @override
  Future<HabitData> load() async {
    final habitRows = await _db.query('habits', orderBy: 'created_at');
    final checkinRows =
        await _db.query('checkins', columns: ['habit_id', 'day'], where: 'deleted = 0');
    final checkins = <String, Set<String>>{};
    for (final row in checkinRows) {
      checkins.putIfAbsent(row['habit_id'] as String, () => {}).add(row['day'] as String);
    }
    return HabitData(
      habits: habitRows.map(Habit.fromRow).toList(),
      checkins: checkins,
    );
  }

  @override
  Future<void> saveHabit(Habit habit) async {
    await AppDatabase.upsert(
      _db,
      'habits',
      {...habit.toRow(), 'updated_at': DateTime.now().millisecondsSinceEpoch, 'dirty': 1},
      ['id'],
    );
  }

  @override
  Future<void> setCheckin(String habitId, String day, {required bool done}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final deleted = done ? 0 : 1;
    // Desmarcar deja una marca borrada (no se elimina) para sincronizarlo.
    final changed = await _db.update(
      'checkins',
      {'deleted': deleted, 'updated_at': now, 'dirty': 1},
      where: 'habit_id = ? AND day = ? AND deleted != ?',
      whereArgs: [habitId, day, deleted],
    );
    if (changed == 0 && done) {
      await _db.insert(
        'checkins',
        {'habit_id': habitId, 'day': day, 'created_at': now, 'updated_at': now, 'dirty': 1},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
}
