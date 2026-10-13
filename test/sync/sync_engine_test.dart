import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stepmind/data/app_database.dart';
import 'package:stepmind/data/event_repository.dart';
import 'package:stepmind/data/habit_repository.dart';
import 'package:stepmind/models/calendar_event.dart';
import 'package:stepmind/models/habit.dart';
import 'package:stepmind/models/user_profile.dart';
import 'package:stepmind/services/user_profile_service.dart';
import 'package:stepmind/sync/sync_engine.dart';
import 'package:stepmind/sync/sync_remote.dart';

/// Servidor en memoria que imita a Supabase: `synced_at` creciente y se
/// ignora un cambio más viejo que el guardado (como el trigger SQL).
class FakeRemote implements SyncRemote {
  final tables = <String, Map<String, Map<String, Object?>>>{};
  int _clock = 0;

  @override
  Future<void> upsert(String table, List<Map<String, Object?>> rows, List<String> keys) async {
    final t = tables.putIfAbsent(table, () => {});
    for (final row in rows) {
      final key = keys.map((k) => row[k]).join('|');
      final existing = t[key];
      if (existing != null && (row['updated_at'] as int) < (existing['updated_at'] as int)) {
        continue;
      }
      t[key] = {...?existing, ...row, 'synced_at': (++_clock).toString().padLeft(10, '0')};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> changedSince(String table, String? since, int limit) async {
    final rows = (tables[table]?.values ?? const <Map<String, Object?>>[])
        .where((r) => since == null || (r['synced_at'] as String).compareTo(since) > 0)
        .toList()
      ..sort((a, b) => (a['synced_at'] as String).compareTo(b['synced_at'] as String));
    return [for (final r in rows.take(limit)) Map<String, dynamic>.from(r)];
  }

  Map<String, Object?>? row(String table, String key) => tables[table]?[key];
}

/// Un "teléfono": base propia y preferencias propias.
class Phone {
  final AppDatabase database;
  final HabitRepository habits;
  final EventRepository events;
  final SyncEngine engine;
  Map<String, Object> _prefs = {};

  Phone._(this.database, FakeRemote remote)
      : habits = SqliteHabitRepository(database),
        events = SqliteEventRepository(database),
        engine = SyncEngine(database, remote, UserProfileService());

  /// Cada teléfono en su propio archivo (sqflite reutiliza la instancia
  /// si dos aperturas usan la misma ruta).
  static Future<Phone> open(FakeRemote remote, Directory dir, String name) async {
    final db = await AppDatabase.open(factory: databaseFactoryFfi, path: p.join(dir.path, name));
    return Phone._(db, remote);
  }

  /// Activa las preferencias de este teléfono mientras dura [action].
  Future<T> use<T>(Future<T> Function() action) async {
    SharedPreferences.setMockInitialValues(_prefs);
    try {
      return await action();
    } finally {
      final prefs = await SharedPreferences.getInstance();
      _prefs = {for (final k in prefs.getKeys()) k: prefs.get(k)!};
    }
  }

  Future<bool> sync(String userId) => use(() => engine.sync(userId));
}

Habit _habit(String id, String name) => Habit(
      id: id,
      name: name,
      time: const TimeOfDay(hour: 8, minute: 0),
      createdAt: DateTime(2026, 3, 1),
    );

void main() {
  late FakeRemote remote;
  late Phone a;
  late Phone b;
  late Directory dir;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    remote = FakeRemote();
    dir = await Directory.systemTemp.createTemp('stepmind_sync');
    a = await Phone.open(remote, dir, 'a.db');
    b = await Phone.open(remote, dir, 'b.db');
  });

  tearDown(() async {
    await a.database.close();
    await b.database.close();
    await dir.delete(recursive: true);
  });

  test('al iniciar sesión sube lo que ya había en el teléfono', () async {
    await a.habits.saveHabit(_habit('h1', 'Leer'));
    await a.habits.setCheckin('h1', '2026-03-02', done: true);
    await a.events.add(const CalendarEvent(id: 'e1', day: '2026-03-05', title: 'Cita'));
    await a.use(() => UserProfileService().saveProfile(UserProfile(
          firstName: 'Ana',
          lastName: 'Pérez',
          username: 'ana',
          age: 30,
          country: 'Chile',
          profileImagePath: '/local/foto.jpg',
        )));

    await a.sync('u1');

    expect(remote.row('habits', 'u1|h1')!['name'], 'Leer');
    expect(remote.row('checkins', 'u1|h1|2026-03-02')!['deleted'], false);
    expect(remote.row('events', 'u1|e1')!['title'], 'Cita');
    final profile = remote.row('profiles', 'u1')!;
    expect(profile['first_name'], 'Ana');
    expect(profile.containsKey('profileImagePath'), isFalse, reason: 'la foto no se sube');
    final dirty = await a.database.db.query('habits', where: 'dirty = 1');
    expect(dirty, isEmpty);
  });

  test('otro teléfono baja los datos y los borrados se propagan', () async {
    await a.habits.saveHabit(_habit('h1', 'Leer'));
    await a.habits.setCheckin('h1', '2026-03-02', done: true);
    await a.habits.setCheckin('h1', '2026-03-03', done: true);
    await a.events.add(const CalendarEvent(id: 'e1', day: '2026-03-05', title: 'Cita'));
    await a.sync('u1');

    expect(await b.sync('u1'), isTrue);
    expect((await b.habits.load()).daysFor('h1'), {'2026-03-02', '2026-03-03'});
    expect((await b.events.all()).single.title, 'Cita');

    await b.habits.setCheckin('h1', '2026-03-03', done: false);
    await b.events.delete('e1');
    await b.sync('u1');
    await a.sync('u1');

    expect((await a.habits.load()).daysFor('h1'), {'2026-03-02'});
    expect(await a.events.all(), isEmpty);
  });

  test('sin cambios remotos no recarga nada', () async {
    await a.habits.saveHabit(_habit('h1', 'Leer'));
    await a.sync('u1');
    expect(await a.sync('u1'), isFalse);
  });

  test('en un conflicto gana el cambio más reciente', () async {
    await a.habits.saveHabit(_habit('h1', 'Leer'));
    await a.sync('u1');
    await b.sync('u1');

    // Ambos editan sin conexión; B lo hace después.
    Future<void> rename(Phone phone, String name, int updatedAt) => phone.database.db.update(
          'habits',
          {'name': name, 'updated_at': updatedAt, 'dirty': 1},
          where: 'id = ?',
          whereArgs: ['h1'],
        );
    await rename(a, 'Leer (A)', 5000000000000);
    await rename(b, 'Leer (B)', 6000000000000);

    await b.sync('u1');
    await a.sync('u1'); // A trae el de B (más nuevo) y no lo pisa.

    expect((await a.habits.load()).habits.single.name, 'Leer (B)');
    expect(remote.row('habits', 'u1|h1')!['name'], 'Leer (B)');
  });

  test('baja por páginas cuando hay muchos cambios', () async {
    await a.habits.saveHabit(_habit('h1', 'Leer'));
    final start = DateTime(2024, 1, 1);
    for (var i = 0; i < SyncEngine.pageSize + 20; i++) {
      final d = start.add(Duration(days: i));
      final day = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      await a.habits.setCheckin('h1', day, done: true);
    }
    await a.sync('u1');
    await b.sync('u1');

    expect((await b.habits.load()).daysFor('h1').length, SyncEngine.pageSize + 20);
  });

  test('al entrar con otra cuenta, los datos del teléfono se suben a esa cuenta', () async {
    await a.habits.saveHabit(_habit('h1', 'Leer'));
    await a.sync('u1');
    await a.sync('u2');
    expect(remote.row('habits', 'u2|h1'), isNotNull);
  });
}
