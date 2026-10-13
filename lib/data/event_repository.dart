import '../models/calendar_event.dart';
import 'app_database.dart';

abstract class EventRepository {
  Future<List<CalendarEvent>> all();

  Future<void> add(CalendarEvent event);

  Future<void> delete(String id);
}

class SqliteEventRepository implements EventRepository {
  final AppDatabase _database;

  SqliteEventRepository(this._database);

  @override
  Future<List<CalendarEvent>> all() async {
    final rows = await _database.db.query('events', orderBy: 'day, rowid');
    return rows.map(CalendarEvent.fromRow).toList();
  }

  @override
  Future<void> add(CalendarEvent event) => _database.db.insert('events', event.toRow());

  @override
  Future<void> delete(String id) =>
      _database.db.delete('events', where: 'id = ?', whereArgs: [id]);
}
