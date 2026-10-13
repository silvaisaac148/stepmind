import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuración de Supabase, inyectada al compilar:
/// `flutter run --dart-define-from-file=config/supabase.json`.
/// Sin ella la app funciona igual, solo sin cuentas ni nube.
class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Deep link al que vuelven el login con Google y los enlaces de correo.
  /// Debe estar en Supabase → Authentication → URL Configuration → Redirect URLs.
  static const redirectUrl = 'io.stepmind.app://login-callback';

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  /// Devuelve si Supabase quedó listo para usarse.
  static Future<bool> initialize() async {
    if (!isConfigured) return false;
    try {
      await Supabase.initialize(url: url, publishableKey: publishableKey);
      return true;
    } catch (e) {
      debugPrint('No se pudo inicializar Supabase: $e');
      return false;
    }
  }
}
