import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'core/theme.dart';

import 'data/app_database.dart';
import 'data/habit_repository.dart';
import 'data/legacy_migration.dart';
import 'providers/providers.dart';
import 'screens/new_password_dialog.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'sync/sync_remote.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await AppDatabase.open();
  final prefs = await SharedPreferences.getInstance();
  await LegacyMigration.run(prefs, SqliteHabitRepository(database));

  // Inicializar el servicio de notificaciones
  await NotificationService().initialize();

  final cloud = await SupabaseConfig.initialize();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        if (cloud) ...[
          authServiceProvider.overrideWithValue(SupabaseAuthService()),
          syncRemoteProvider.overrideWithValue(SupabaseSyncRemote(Supabase.instance.client)),
        ],
      ],
      child: const StepMindApp(),
    ),
  );
}

class StepMindApp extends ConsumerStatefulWidget {
  const StepMindApp({super.key});

  @override
  ConsumerState<StepMindApp> createState() => _StepMindAppState();
}

class _StepMindAppState extends ConsumerState<StepMindApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<void>? _recovery;

  @override
  void initState() {
    super.initState();
    // El enlace de "olvidé mi contraseña" abre la app con sesión temporal:
    // se pide la nueva contraseña.
    _recovery = ref.read(authServiceProvider)?.passwordRecoveryRequests.listen((_) {
      final context = _navigatorKey.currentContext;
      if (context != null && context.mounted) showNewPasswordDialog(context, ref.read(authServiceProvider)!);
    });
  }

  @override
  void dispose() {
    _recovery?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'StepMind',
      theme: AppTheme.dark(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
