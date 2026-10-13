import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Base de datos local (fuente de verdad en el dispositivo).
class AppDatabase {
  static const _version = 3;

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
        onUpgrade: _upgrade,
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
    _addSyncColumns(batch);
    _createRecoveryTables(batch);
    await batch.commit(noResult: true);
  }

  static Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    final batch = db.batch();
    if (oldVersion < 2) _addSyncColumns(batch);
    if (oldVersion < 3) _createRecoveryTables(batch);
    await batch.commit(noResult: true);
  }

  /// v2: columnas para sincronizar con la nube.
  /// - `updated_at`: última modificación (ms); gana el cambio más reciente.
  /// - `dirty`: 1 si hay cambios locales sin subir. Los datos que ya existían
  ///   nacen pendientes para subirse al iniciar sesión por primera vez.
  /// - `deleted`: borrado lógico, para que el borrado también se sincronice.
  static void _addSyncColumns(Batch batch) {
    for (final table in syncedTables) {
      batch
        ..execute('ALTER TABLE $table ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0')
        ..execute('ALTER TABLE $table ADD COLUMN dirty INTEGER NOT NULL DEFAULT 1');
    }
    batch
      ..execute('ALTER TABLE checkins ADD COLUMN deleted INTEGER NOT NULL DEFAULT 0')
      ..execute('ALTER TABLE events ADD COLUMN deleted INTEGER NOT NULL DEFAULT 0')
      ..execute('UPDATE habits SET updated_at = created_at')
      ..execute('UPDATE checkins SET updated_at = created_at');
  }

  /// v3: módulo de adicciones. Se queda en el teléfono salvo que el usuario
  /// active su sincronización.
  static void _createRecoveryTables(Batch batch) {
    batch
      ..execute('''
        CREATE TABLE recovery_goals (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          started_at INTEGER NOT NULL,
          why TEXT NOT NULL DEFAULT '',
          plans_json TEXT NOT NULL DEFAULT '[]',
          created_at INTEGER NOT NULL,
          archived_at INTEGER,
          updated_at INTEGER NOT NULL DEFAULT 0,
          dirty INTEGER NOT NULL DEFAULT 1
        )''')
      ..execute('''
        CREATE TABLE recovery_events (
          id TEXT PRIMARY KEY,
          goal_id TEXT NOT NULL REFERENCES recovery_goals(id) ON DELETE CASCADE,
          kind TEXT NOT NULL,
          at INTEGER NOT NULL,
          emotion TEXT,
          situation TEXT,
          intensity INTEGER,
          resisted INTEGER NOT NULL DEFAULT 0,
          note TEXT,
          deleted INTEGER NOT NULL DEFAULT 0,
          updated_at INTEGER NOT NULL DEFAULT 0,
          dirty INTEGER NOT NULL DEFAULT 1
        )''')
      ..execute('CREATE INDEX idx_recovery_events_goal ON recovery_events(goal_id, at)');
  }

  /// Tablas del módulo de adicciones (sincronización opcional).
  static const recoveryTables = ['recovery_goals', 'recovery_events'];

  /// Tablas que se sincronizan, en orden (los hábitos antes que sus marcas).
  static const syncedTables = ['habits', 'checkins', 'events'];

  /// Inserta o actualiza sin borrar la fila. `INSERT OR REPLACE` borra y
  /// vuelve a insertar, lo que dispara `ON DELETE CASCADE` y borraría las
  /// marcas del hábito.
  static Future<void> upsert(
    DatabaseExecutor db,
    String table,
    Map<String, Object?> values,
    List<String> keyColumns,
  ) {
    final columns = values.keys.toList();
    final updates = [
      for (final c in columns)
        if (!keyColumns.contains(c)) '$c = excluded.$c',
    ];
    return db.execute(
      'INSERT INTO $table (${columns.join(', ')}) '
      'VALUES (${List.filled(columns.length, '?').join(', ')}) '
      'ON CONFLICT(${keyColumns.join(', ')}) DO UPDATE SET ${updates.join(', ')}',
      values.values.toList(),
    );
  }

  /// Marca todo como pendiente de subir (p. ej. al entrar en otra cuenta).
  Future<void> markAllDirty() async {
    final batch = db.batch();
    for (final table in [...syncedTables, ...recoveryTables]) {
      batch.update(table, {'dirty': 1});
    }
    await batch.commit(noResult: true);
  }

  /// Borra todos los datos del teléfono (al cerrar sesión si se pide).
  Future<void> clearAll() async {
    final batch = db.batch()
      ..delete('recovery_events')
      ..delete('recovery_goals')
      ..delete('checkins')
      ..delete('habits')
      ..delete('events');
    await batch.commit(noResult: true);
  }

  Future<void> close() => db.close();
}
