import 'package:supabase_flutter/supabase_flutter.dart';

/// Acceso a las tablas de la nube. Todas las filas pertenecen a un usuario
/// (`user_id`) y la seguridad la garantizan las políticas RLS del servidor.
abstract class SyncRemote {
  /// Inserta o actualiza [rows] (ya incluyen `user_id`).
  Future<void> upsert(String table, List<Map<String, Object?>> rows, List<String> keys);

  /// Filas modificadas en el servidor después de [since] (`synced_at`),
  /// ordenadas por `synced_at`, como máximo [limit].
  Future<List<Map<String, dynamic>>> changedSince(String table, String? since, int limit);
}

class SupabaseSyncRemote implements SyncRemote {
  final SupabaseClient _client;

  SupabaseSyncRemote(this._client);

  @override
  Future<void> upsert(String table, List<Map<String, Object?>> rows, List<String> keys) =>
      _client.from(table).upsert(rows, onConflict: keys.join(','));

  @override
  Future<List<Map<String, dynamic>>> changedSince(String table, String? since, int limit) {
    var query = _client.from(table).select();
    if (since != null) query = query.gt('synced_at', since);
    return query.order('synced_at').limit(limit);
  }
}
