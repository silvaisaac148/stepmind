import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/providers.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Ocultar barra de estado y navegación
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    // Configurar animación
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    
    // Navegar a la pantalla de login después de 2 segundos
    _navigateToLogin();
  }

  @override
  void dispose() {
    _animationController.dispose();
    // Restaurar barra de estado y navegación
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// Con sesión iniciada, o si ya eligió usar la app sin cuenta, va directo
  /// al inicio; si no, al login.
  Future<void> _navigateToLogin() async {
    final prefs = SharedPreferences.getInstance();
    await Future<void>.delayed(const Duration(seconds: 2));
    final skipped = (await prefs).getBool(LoginScreen.skippedKey) ?? false;
    final loggedIn = ref.read(authServiceProvider)?.currentUser != null;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => loggedIn || skipped ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF282524),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo principal de la app - Icono original
              Icon(
                Icons.psychology,
                size: 100,
                color: const Color(0xFFFFD700), // Color amarillo como en la imagen
              ),
              const SizedBox(height: 24),
              // Nombre de la app
              const Text(
                'StepMind',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              // Slogan
              const Text(
                'Fomenta hábitos beneficiosos',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFBDBDBD),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 40),
              // Indicador de carga
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFFFFD700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
