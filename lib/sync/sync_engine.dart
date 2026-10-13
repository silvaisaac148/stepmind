import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import 'sync_remote.dart';

/// Cómo se traduce una tabla local a su tabla en la nube.
class _TableSpec {
  final String name;
  final List<String> keys;

  /// Columnas que viajan (sin `user_id`, `dirty` ni `synced_at`).
  final List<String> columns;

  /// Columnas guardadas como 0/1 en SQLite y como boolean en la nube.
  final List<String> booleans;

  const _TableSpec(this.name, this.keys, this.columns, {this.booleans = const []});
}

/// Sincroniza la base local con la nube. El teléfono es la fuente de verdad
/// y funciona sin conexión; ante un conflicto gana el cambio más reciente
/// (`updated_at`).
class SyncEngine {
  static const pageSize = 500;

  static const _tables = [
    _TableSpec('habits', ['id'],
        ['id', 'name', 'reminder_minutes', 'created_at', 'archived_at', 'updated_at']),
    _TableSpec('checkins', ['habit_id', 'day'],
        ['habit_id', 'day', 'created_at', 'deleted', 'updated_at'],
        booleans: ['deleted']),
    _TableSpec('events', ['id'], ['id', 'day', 'title', 'deleted', 'updated_at'],
        booleans: ['deleted']),
  ];

  static const _userKey = 'sync_user_id';

  final AppDatabase _database;
  final SyncRemote _remote;
  final UserProfileService _profiles;

  SyncEngine(this._database, this._remote, this._profiles);

  Database get _db => _database.db;

  static String _cursorKey(String userId, String table) => 'sync_cursor_${userId}_$table';

  /// Sincroniza todo. Devuelve `true` si cambiaron datos locales.
  Future<bool> sync(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_userKey) != userId) {
      // Primera vez con esta cuenta en este teléfono: lo que hay en el
      // teléfono se sube a la cuenta.
      await _database.markAllDirty();
      await _profiles.markProfileDirty();
      await prefs.setString(_userKey, userId);
    }

    var changed = false;
    for (final table in _tables) {
      changed |= await _pull(prefs, userId, table);
      await _push(userId, table);
    }
    changed |= await _syncProfile(prefs, userId);
    return changed;
  }

  /// Olvida qué cuenta se sincronizó (al borrar los datos del teléfono).
  static Future<void> forgetUser(SharedPreferences prefs) async {
    for (final key in prefs.getKeys().toList()) {
      if (key == _userKey || key.startsWith('sync_cursor_')) await prefs.remove(key);
    }
  }

  Future<bool> _pull(SharedPreferences prefs, String userId, _TableSpec table) async {
    final cursorKey = _cursorKey(userId, table.name);
    var changed = false;
    while (true) {
      final rows = await _remote.changedSince(table.name, prefs.getString(cursorKey), pageSize);
      if (rows.isEmpty) break;
      await _db.transaction((txn) async {
        for (final row in rows) {
          changed |= await _applyRemote(txn, table, row);
        }
      });
      await prefs.setString(cursorKey, rows.last['synced_at'] as String);
      if (rows.length < pageSize) break;
    }
    return changed;
  }

  Future<bool> _applyRemote(Transaction txn, _TableSpec table, Map<String, dynamic> row) async {
    final local = await txn.query(
      table.name,
      columns: ['updated_at', 'dirty'],
      where: table.keys.map((k) => '$k = ?').join(' AND '),
      whereArgs: [for (final k in table.keys) row[k]],
    );
    final remoteUpdated = (row['updated_at'] as num).toInt();
    if (local.isNotEmpty) {
      final localUpdated = local.single['updated_at'] as int;
      final dirty = local.single['dirty'] == 1;
      // Un cambio local más reciente gana: se subirá en el push.
      if (dirty && localUpdated >= remoteUpdated) return false;
      if (!dirty && localUpdated == remoteUpdated) return false;
    }
    final values = <String, Object?>{
      for (final c in table.columns)
        c: table.booleans.contains(c) ? ((row[c] as bool? ?? false) ? 1 : 0) : row[c],
      'dirty': 0,
    };
    try {
      await AppDatabase.upsert(txn, table.name, values, table.keys);
      return true;
    } on DatabaseException catch (e) {
      // P. ej. una marca de un hábito que aún no existe en el teléfono.
      debugPrint('No se pudo aplicar ${table.name} remoto: $e');
      return false;
    }
  }

  Future<void> _push(String userId, _TableSpec table) async {
    final rows = await _db.query(table.name, where: 'dirty = 1');
    for (var i = 0; i < rows.length; i += pageSize) {
      final page = rows.sublist(i, i + pageSize > rows.length ? rows.length : i + pageSize);
      await _remote.upsert(
        table.name,
        [
          for (final row in page)
            {
              'user_id': userId,
              for (final c in table.columns)
                c: table.booleans.contains(c) ? row[c] == 1 : row[c],
            },
        ],
        ['user_id', ...table.keys],
      );
      // Solo se limpia si no se volvió a modificar mientras se subía.
      final batch = _db.batch();
      for (final row in page) {
        batch.update(
          table.name,
          {'dirty': 0},
          where: [...table.keys.map((k) => '$k = ?'), 'updated_at = ?'].join(' AND '),
          whereArgs: [for (final k in table.keys) row[k], row['updated_at']],
        );
      }
      await batch.commit(noResult: true);
    }
  }

  Future<bool> _syncProfile(SharedPreferences prefs, String userId) async {
    var changed = false;
    final cursorKey = _cursorKey(userId, 'profiles');
    final rows = await _remote.changedSince('profiles', prefs.getString(cursorKey), 1);
    if (rows.isNotEmpty) {
      final row = rows.single;
      final remoteUpdated = (row['updated_at'] as num).toInt();
      final localUpdated = await _profiles.profileUpdatedAt();
      final localWins = await _profiles.isProfileDirty() && localUpdated >= remoteUpdated;
      if (!localWins && localUpdated != remoteUpdated) {
        await _profiles.applyRemoteProfile(
          UserProfile(
            firstName: row['first_name'] as String? ?? '',
            lastName: row['last_name'] as String? ?? '',
            username: row['username'] as String? ?? '',
            age: (row['age'] as num?)?.toInt() ?? 0,
            country: row['country'] as String? ?? '',
          ),
          remoteUpdated,
        );
        changed = true;
      }
      await prefs.setString(cursorKey, row['synced_at'] as String);
    }

    final profile = await _profiles.getProfile();
    if (profile != null && await _profiles.isProfileDirty()) {
      final updatedAt = await _profiles.profileUpdatedAt();
      await _remote.upsert('profiles', [
        {
          'user_id': userId,
          'first_name': profile.firstName,
          'last_name': profile.lastName,
          'username': profile.username,
          'age': profile.age,
          'country': profile.country,
          'updated_at': updatedAt,
        },
      ], ['user_id']);
      await _profiles.markProfileSynced(updatedAt);
    }
    return changed;
  }
}
