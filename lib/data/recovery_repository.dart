import '../domain/recovery.dart';
import 'app_database.dart';

abstract class RecoveryRepository {
  Future<RecoveryData> load();

  /// Inserta o actualiza una meta (archivar = guardar con `archivedAt`).
  Future<void> saveGoal(RecoveryGoal goal);

  Future<void> addEvent(RecoveryEvent event);

  Future<void> deleteEvent(String id);
}

class SqliteRecoveryRepository implements RecoveryRepository {
  final AppDatabase _database;

  SqliteRecoveryRepository(this._database);

  @override
  Future<RecoveryData> load() async {
    final goals = await _database.db.query('recovery_goals', orderBy: 'created_at');
    final events =
        await _database.db.query('recovery_events', where: 'deleted = 0', orderBy: 'at');
    return RecoveryData(
      goals: goals.map(RecoveryGoal.fromRow).toList(),
      events: events.map(RecoveryEvent.fromRow).toList(),
    );
  }

  Map<String, Object?> _stamp(Map<String, Object?> row) =>
      {...row, 'updated_at': DateTime.now().millisecondsSinceEpoch, 'dirty': 1};

  @override
  Future<void> saveGoal(RecoveryGoal goal) =>
      AppDatabase.upsert(_database.db, 'recovery_goals', _stamp(goal.toRow()), ['id']);

  @override
  Future<void> addEvent(RecoveryEvent event) =>
      AppDatabase.upsert(_database.db, 'recovery_events', _stamp(event.toRow()), ['id']);

  /// Borrado lógico, para que también se borre en la nube si se sincroniza.
  @override
  Future<void> deleteEvent(String id) => _database.db.update(
        'recovery_events',
        _stamp({'deleted': 1}),
        where: 'id = ?',
        whereArgs: [id],
      );
}
