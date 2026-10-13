import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stepmind/data/app_database.dart';
import 'package:stepmind/data/event_repository.dart';
import 'package:stepmind/data/habit_repository.dart';
import 'package:stepmind/data/legacy_migration.dart';
import 'package:stepmind/models/calendar_event.dart';
import 'package:stepmind/models/habit.dart';

void main() {
  late AppDatabase database;
  late SqliteHabitRepository habits;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    habits = SqliteHabitRepository(database);
  });

  tearDown(() => database.close());

  final created = DateTime(2026, 3, 1, 10);

  test('guarda y lee hábitos con sus marcas', () async {
    final habit = Habit(
      id: 'h1',
      name: 'Leer',
      time: const TimeOfDay(hour: 21, minute: 30),
      createdAt: created,
    );
    await habits.saveHabit(habit);
    await habits.setCheckin('h1', '2026-03-02', done: true);
    await habits.setCheckin('h1', '2026-03-02', done: true); // idempotente
    await habits.setCheckin('h1', '2026-03-03', done: true);
    await habits.setCheckin('h1', '2026-03-03', done: false);

    final data = await habits.load();
    expect(data.habits.single.name, 'Leer');
    expect(data.habits.single.formattedTime, '21:30');
    expect(data.habits.single.createdAt, created);
    expect(data.daysFor('h1'), {'2026-03-02'});
  });

  test('editar un hábito conserva sus marcas', () async {
    final habit = Habit(
      id: 'h1',
      name: 'Leer',
      time: const TimeOfDay(hour: 8, minute: 0),
      createdAt: created,
    );
    await habits.saveHabit(habit);
    await habits.setCheckin('h1', '2026-03-02', done: true);
    await habits.saveHabit(habit.copyWith(name: 'Leer 20 min'));

    final data = await habits.load();
    expect(data.habits.single.name, 'Leer 20 min');
    expect(data.daysFor('h1'), {'2026-03-02'});
  });

  test('desmarcar y volver a marcar deja la marca activa y pendiente de subir', () async {
    await habits.saveHabit(Habit(
      id: 'h1',
      name: 'Leer',
      time: const TimeOfDay(hour: 8, minute: 0),
      createdAt: created,
    ));
    await habits.setCheckin('h1', '2026-03-02', done: true);
    await habits.setCheckin('h1', '2026-03-02', done: false);
    expect((await habits.load()).daysFor('h1'), isEmpty);
    await habits.setCheckin('h1', '2026-03-02', done: true);

    expect((await habits.load()).daysFor('h1'), {'2026-03-02'});
    final rows = await database.db.query('checkins');
    expect(rows.single['deleted'], 0);
    expect(rows.single['dirty'], 1);
  });

  test('archivar guarda la fecha', () async {
    final habit = Habit(
      id: 'h1',
      name: 'Leer',
      time: const TimeOfDay(hour: 8, minute: 0),
      createdAt: created,
    );
    await habits.saveHabit(habit);
    await habits.saveHabit(habit.copyWith(archivedAt: DateTime(2026, 3, 5)));

    final data = await habits.load();
    expect(data.habits.single.archivedAt, DateTime(2026, 3, 5));
  });

  test('eventos del calendario se guardan y borran', () async {
    final events = SqliteEventRepository(database);
    await events.add(const CalendarEvent(id: 'e1', day: '2026-03-02', title: 'Cita'));
    await events.add(const CalendarEvent(id: 'e2', day: '2026-03-02', title: 'Gym'));
    await events.delete('e1');

    final all = await events.all();
    expect(all.map((e) => e.title), ['Gym']);
  });

  test('actualiza una base v1 conservando los datos', () async {
    final dir = await Directory.systemTemp.createTemp('stepmind_test');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'v1.db');
    final v1 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('CREATE TABLE habits (id TEXT PRIMARY KEY, name TEXT NOT NULL, '
              'reminder_minutes INTEGER NOT NULL, created_at INTEGER NOT NULL, archived_at INTEGER)');
          await db.execute('CREATE TABLE checkins (habit_id TEXT NOT NULL REFERENCES habits(id) '
              'ON DELETE CASCADE, day TEXT NOT NULL, created_at INTEGER NOT NULL, '
              'PRIMARY KEY (habit_id, day))');
          await db.execute(
              'CREATE TABLE events (id TEXT PRIMARY KEY, day TEXT NOT NULL, title TEXT NOT NULL)');
          await db.insert('habits', {
            'id': 'h1',
            'name': 'Leer',
            'reminder_minutes': 60,
            'created_at': 1000,
          });
          await db.insert('checkins', {'habit_id': 'h1', 'day': '2026-03-02', 'created_at': 2000});
          await db.insert('events', {'id': 'e1', 'day': '2026-03-02', 'title': 'Cita'});
        },
      ),
    );
    await v1.close();

    final upgraded = await AppDatabase.open(factory: databaseFactoryFfi, path: path);
    addTearDown(upgraded.close);

    final data = await SqliteHabitRepository(upgraded).load();
    expect(data.habits.single.name, 'Leer');
    expect(data.daysFor('h1'), {'2026-03-02'});
    expect((await SqliteEventRepository(upgraded).all()).single.title, 'Cita');
    final habitRow = (await upgraded.db.query('habits')).single;
    expect(habitRow['updated_at'], 1000);
    expect(habitRow['dirty'], 1);
  });

  test('migra los datos de la versión anterior y limpia contadores viejos', () async {
    SharedPreferences.setMockInitialValues({
      'habits': json.encode([
        {
          'id': '1700000000000',
          'name': 'Meditar',
          'timeHour': 7,
          'timeMinute': 5,
          'createdAt': DateTime(2026, 2, 1).millisecondsSinceEpoch,
          'completedDates': [
            DateTime(2026, 2, 2).millisecondsSinceEpoch,
            DateTime(2026, 2, 3).millisecondsSinceEpoch,
          ],
          'isCompletedToday': true,
        }
      ]),
      'current_streak': 5,
      'completed_2026_2_3': true,
      'user_profile': '{}',
    });
    final prefs = await SharedPreferences.getInstance();

    await LegacyMigration.run(prefs, habits);
    await LegacyMigration.run(prefs, habits); // segunda vez no hace nada

    final data = await habits.load();
    expect(data.habits.single.name, 'Meditar');
    expect(data.habits.single.formattedTime, '07:05');
    expect(data.daysFor('1700000000000'), {'2026-02-02', '2026-02-03'});
    expect(prefs.getKeys(), containsAll(['user_profile', 'legacy_migrated_v1']));
    expect(prefs.getKeys(), isNot(contains('habits')));
    expect(prefs.getKeys(), isNot(contains('current_streak')));
    expect(prefs.getKeys(), isNot(contains('completed_2026_2_3')));
  });
}
