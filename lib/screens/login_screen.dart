import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/providers.dart';
import '../services/auth_service.dart';
import '../widgets/brand.dart';
import 'home_screen.dart';
import '../core/theme.dart';

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
      extendBodyBehindAppBar: true,
      appBar: widget.fromSettings
          ? AppBar(backgroundColor: Colors.transparent, title: const Text('Cuenta'))
          : null,
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const StepMindLogo(size: 110),
                  const SizedBox(height: 12),
                  const Text(
                    'StepMind',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cada paso hacia adelante cuenta',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  if (cloudAvailable) _buildAccountForm(context),
                  if (!widget.fromSettings) ...[
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: _isLoading ? null : _continueWithoutAccount,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      child: const Text('Continuar sin cuenta'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      cloudAvailable
                          ? 'Tus datos se guardan en este teléfono. Puedes crear una cuenta '
                              'más tarde desde Ajustes para tener copia en la nube.'
                          : 'Tus datos se guardan en este teléfono.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ModeToggle(
              isLogin: _isLogin,
              onChanged: (isLogin) => setState(() => _isLogin = isLogin),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _run((auth) => auth.signInWithGoogle()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                ),
                icon: const Text(
                  'G',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: Color(0xFF4285F4),
                  ),
                ),
                label: const Text('Continuar con Google'),
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'o con tu correo',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
              autofillHints: [_isLogin ? AutofillHints.password : AutofillHints.newPassword],
              onSubmitted: (_) => _isLogin ? _authenticate() : null,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _isLogin
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar contraseña',
                          prefixIcon: Icon(Icons.lock_reset),
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _authenticate(),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _authenticate,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(_isLogin ? 'Entrar' : 'Crear cuenta'),
              ),
            ),
            if (_isLogin)
              TextButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Selector "Entrar / Crear cuenta" en forma de píldora (idea del Figma).
class _ModeToggle extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({required this.isLogin, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget option(String label, bool value) {
      final selected = isLogin == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.orange : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(children: [option('Entrar', true), option('Crear cuenta', false)]),
    );
  }
}
