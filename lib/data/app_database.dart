import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Base de datos local (fuente de verdad en el dispositivo).
class AppDatabase {
  static const _version = 1;

  final Database db;

  AppDatabase._(this.db);

  /// [factory] y [path] permiten usar una base en memoria en los tests.
  static Future<AppDatabase> open({DatabaseFactory? factory, String? path}) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await dbFactory.getDatabasesPath(), 'stepmind.db');
    final db = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _create,
      ),
    );
    return AppDatabase._(db);
  }

  static Future<void> _create(Database db, int version) async {
    final batch = db.batch()
      ..execute('''
        CREATE TABLE habits (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          reminder_minutes INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          archived_at INTEGER
        )''')
      ..execute('''
        CREATE TABLE checkins (
          habit_id TEXT NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
          day TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          PRIMARY KEY (habit_id, day)
        )''')
      ..execute('CREATE INDEX idx_checkins_day ON checkins(day)')
      ..execute('''
        CREATE TABLE events (
          id TEXT PRIMARY KEY,
          day TEXT NOT NULL,
          title TEXT NOT NULL
        )''')
      ..execute('CREATE INDEX idx_events_day ON events(day)');
    await batch.commit(noResult: true);
  }

  Future<void> close() => db.close();
}
