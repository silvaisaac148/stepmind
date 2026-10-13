import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';

class AuthUser {
  final String id;
  final String? email;

  const AuthUser({required this.id, this.email});
}

/// Error de autenticación con un mensaje listo para mostrar al usuario.
class AuthFailure implements Exception {
  final String message;

  const AuthFailure(this.message);

  @override
  String toString() => message;
}

abstract class AuthService {
  AuthUser? get currentUser;

  /// Emite el usuario actual cada vez que cambia la sesión.
  Stream<AuthUser?> get userChanges;

  /// Se emite cuando el usuario abre el enlace de "olvidé mi contraseña".
  Stream<void> get passwordRecoveryRequests;

  Future<void> signInWithEmail(String email, String password);

  /// Devuelve `true` si hay que confirmar el correo antes de entrar.
  Future<bool> signUpWithEmail(String email, String password);

  /// Abre el navegador; la sesión llega luego por [userChanges].
  Future<void> signInWithGoogle();

  Future<void> sendPasswordReset(String email);

  Future<void> updatePassword(String newPassword);

  Future<void> signOut();
}

class SupabaseAuthService implements AuthService {
  GoTrueClient get _auth => Supabase.instance.client.auth;

  static AuthUser? _toUser(User? user) =>
      user == null ? null : AuthUser(id: user.id, email: user.email);

  @override
  AuthUser? get currentUser => _toUser(_auth.currentUser);

  @override
  Stream<AuthUser?> get userChanges =>
      _auth.onAuthStateChange.map((state) => _toUser(state.session?.user));

  @override
  Stream<void> get passwordRecoveryRequests => _auth.onAuthStateChange
      .where((state) => state.event == AuthChangeEvent.passwordRecovery);

  @override
  Future<void> signInWithEmail(String email, String password) =>
      _guard(() => _auth.signInWithPassword(email: email.trim(), password: password));

  @override
  Future<bool> signUpWithEmail(String email, String password) async {
    final response = await _guard(() => _auth.signUp(
          email: email.trim(),
          password: password,
          emailRedirectTo: SupabaseConfig.redirectUrl,
        ));
    return response.session == null;
  }

  @override
  Future<void> signInWithGoogle() => _guard(() => _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: SupabaseConfig.redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      ));

  @override
  Future<void> sendPasswordReset(String email) => _guard(
      () => _auth.resetPasswordForEmail(email.trim(), redirectTo: SupabaseConfig.redirectUrl));

  @override
  Future<void> updatePassword(String newPassword) =>
      _guard(() => _auth.updateUser(UserAttributes(password: newPassword)));

  @override
  Future<void> signOut() => _guard(() => _auth.signOut());

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    } catch (_) {
      throw const AuthFailure('No hay conexión. Revisa tu internet e inténtalo de nuevo.');
    }
  }

  static String _messageFor(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'Correo o contraseña incorrectos.';
      case 'email_not_confirmed':
        return 'Confirma tu correo con el enlace que te enviamos antes de entrar.';
      case 'user_already_exists':
      case 'email_exists':
        return 'Ya existe una cuenta con ese correo. Inicia sesión.';
      case 'weak_password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return 'Demasiados intentos. Espera unos minutos.';
      case 'validation_failed':
        return 'Revisa que el correo sea válido.';
      case 'same_password':
        return 'La nueva contraseña debe ser distinta de la anterior.';
    }
    return 'No se pudo completar: ${e.message}';
  }
}
