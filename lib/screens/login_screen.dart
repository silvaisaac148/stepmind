import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/providers.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  /// Se guarda al elegir "Continuar sin cuenta" para no volver a preguntar.
  static const skippedKey = 'login_skipped';

  /// `true` si se abrió desde Ajustes: al terminar vuelve atrás en vez de ir
  /// al inicio, y no ofrece "Continuar sin cuenta".
  final bool fromSettings;

  const LoginScreen({super.key, this.fromSettings = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _done = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  AuthService? get _auth => ref.read(authServiceProvider);

  void _showMessage(String message, {Color color = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  /// Sale del login hacia la app (una sola vez).
  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    if (widget.fromSettings) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  Future<void> _continueWithoutAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(LoginScreen.skippedKey, true);
    _finish();
  }

  String? _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return 'Por favor completa todos los campos';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Ingresa un correo válido';
    }
    if (_isLogin) return null;
    if (password.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
    if (_confirmPasswordController.text != password) return 'Las contraseñas no coinciden';
    return null;
  }

  Future<void> _run(Future<void> Function(AuthService auth) action) async {
    final auth = _auth;
    if (auth == null) return;
    setState(() => _isLoading = true);
    try {
      await action(auth);
    } on AuthFailure catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _authenticate() async {
    final error = _validate();
    if (error != null) return _showMessage(error);
    final email = _emailController.text;
    final password = _passwordController.text;
    await _run((auth) async {
      if (_isLogin) {
        await auth.signInWithEmail(email, password);
        return; // La sesión llega por authUserProvider.
      }
      final needsConfirmation = await auth.signUpWithEmail(email, password);
      if (needsConfirmation) {
        _showMessage(
          'Te enviamos un correo a ${email.trim()}. Ábrelo desde este teléfono para activar tu cuenta.',
          color: Colors.green,
        );
        setState(() => _isLogin = true);
      }
    });
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return _showMessage('Escribe tu correo arriba y vuelve a tocar aquí');
    await _run((auth) async {
      await auth.sendPasswordReset(email);
      _showMessage(
        'Si existe una cuenta con $email, recibirás un enlace para cambiar la contraseña.',
        color: Colors.green,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authUserProvider, (_, next) {
      if (next.value != null) _finish();
    });
    final cloudAvailable = ref.watch(authServiceProvider) != null;

    return Scaffold(
      backgroundColor: const Color(0xFF282524),
      appBar: widget.fromSettings ? AppBar(title: const Text('Cuenta')) : null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3634),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.psychology,
                      size: 80,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'StepMind',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fomenta hábitos beneficiosos',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              if (cloudAvailable) _buildAccountForm(context),
              if (!widget.fromSettings) ...[
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: _isLoading ? null : _continueWithoutAccount,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF6A6563)),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Continuar sin cuenta'),
                ),
                const SizedBox(height: 8),
                Text(
                  cloudAvailable
                      ? 'Tus datos se guardan en este teléfono. Puedes crear una cuenta '
                          'más tarde desde Ajustes para tener copia en la nube.'
                      : 'Tus datos se guardan en este teléfono.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3634),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            _isLogin ? 'Iniciar Sesión' : 'Registrarse',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _run((auth) => auth.signInWithGoogle()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
              ),
              icon: const Text(
                'G',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
              ),
              label: const Text('Continuar con Google'),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFF6A6563))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('o con tu correo', style: TextStyle(color: Colors.grey)),
              ),
              Expanded(child: Divider(color: Color(0xFF6A6563))),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            autofillHints: [_isLogin ? AutofillHints.password : AutofillHints.newPassword],
            style: const TextStyle(color: Colors.white),
          ),
          if (!_isLogin) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              style: const TextStyle(color: Colors.white),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _authenticate,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_isLogin ? 'Entrar' : 'Registrarse'),
            ),
          ),
          if (_isLogin)
            TextButton(
              onPressed: _isLoading ? null : _resetPassword,
              child: const Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(color: Color(0xFF9E9893)),
              ),
            ),
          TextButton(
            onPressed: () => setState(() => _isLogin = !_isLogin),
            child: Text(
              _isLogin ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión',
              style: const TextStyle(color: Color(0xFF9E9893)),
            ),
          ),
        ],
      ),
    );
  }
}
